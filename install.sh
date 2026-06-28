#!/usr/bin/env bash

# Stop the script at any encountered error
set -e

_where=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
srcdir="${_where}"

# Command used for superuser privileges (`sudo`, `doas`, `su`)
if [[ ! -x "$(command -v sudo)" ]]; then
  if [[ -x "$(command -v doas)" ]]; then
    sudo() { doas "$@"; }
  elif [[ -x "$(command -v su)" && -x "$(command -v xargs)" ]]; then
    sudo() { echo "$@" | xargs -I {} su -c '{}'; }
  fi
fi

msg2() {
 echo -e " \033[1;34m->\033[1;0m \033[1;1m$1\033[1;0m" >&2
}

error() {
 echo -e " \033[1;31m==> ERROR: $1\033[1;0m" >&2
}

warning() {
 echo -e " \033[1;33m==> WARNING: $1\033[1;0m" >&2
}

plain() {
 echo -e "$1" >&2
}

# Set up environment and trap cleanup
source "${_where}/nvidia-all-config/prepare"
source "${_where}/nvidia-all-config/install-common"

_pkg_tmpdir=""
trap _exit_cleanup EXIT
trap 'trap - INT TERM; exit 130' INT
trap 'trap - INT TERM; exit 143' TERM

_detect_distro
if [[ "${_NV_DISTRO_FAMILY}" == "arch" ]]; then
  cd "${_where}"
  makepkg -si
  exit $?
fi

_frog_banner

# Create BIG_UGLY_FROGMINER only on first run and save in it all settings
_frogminer_bootstrap "${_where}/BIG_UGLY_FROGMINER" "${_where}/BIG_UGLY_FROGMINER.pending"

# curl + bsdtar are needed by _nv_initscript
if ! command -v curl &>/dev/null || ! command -v bsdtar &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get install -q curl libarchive-tools
  elif command -v dnf &>/dev/null; then
    dnf install curl bsdtar
  elif command -v zypper &>/dev/null; then
    zypper install curl libarchive-tools
  else
    _die "curl/bsdtar not found and no known package manager to install them."
  fi
fi

if which script &> /dev/null && [[ "${_logging_use_script:-}" =~ ^(Y|y|Yes|yes|true|1)$ && -z "${SCRIPT:-}" ]]; then
  export SCRIPT=1
  msg2 "Using script"
  script -q -e -c "$0 $*" shell-output.log
  exit
fi

# Set driver version and source directory
pkgver="${_driver_version}"
_pkg="NVIDIA-Linux-x86_64-${pkgver}"
srcdir="/tmp/nvidia-install-$$"
pkgdir=""   # empty because we don't use makepkg, but some prepare functions expect it to exist

msg2 "Detected distro family: ${_NV_DISTRO_FAMILY}"

# Distro selection prompt
_distro_prompt() {
  # If _distro is already set in customization.cfg, skip the prompt
  if [[ -n "${_distro:-}" ]]; then
    case "${_distro}" in
      Debian)  _NV_PKG_TARGET="debian" ; return 0 ;;
      Ubuntu)  _NV_PKG_TARGET="ubuntu" ; return 0 ;;
      Fedora)  _NV_PKG_TARGET="fedora" ; return 0 ;;
      Suse)    _NV_PKG_TARGET="suse"   ; return 0 ;;
      *)
        warning "_distro='${_distro}' is not a valid value. Valid values: Debian, Ubuntu, Fedora, Suse — prompting..."
        ;;
    esac
  fi

  # Unknown distros are not supported
  case "${_NV_DISTRO_FAMILY}" in
    generic|"")
      _die "Unknown distribution '${_NV_DISTRO_ID:-unknown}'. Only Debian, Ubuntu, Fedora and Suse are supported by the direct installer."
      ;;
  esac

  msg2 "Which Linux distribution are you running?"
  local _label
  case "${_NV_DISTRO_FAMILY}" in
    debian)
      case "${_NV_DISTRO_ID:-}" in
        ubuntu|linuxmint|pop|elementary|zorin)
          _label="Ubuntu"
          _default_index=1
          ;;
        *)
          _label="Debian"
          _default_index=0
          ;;
      esac
      ;;
    fedora)
      _label="Fedora"
      _default_index=2
      ;;
    suse)
      _label="Suse"
      _default_index=3
      ;;
  esac
  msg2 "Auto-detected: ${_NV_DISTRO_ID:-unknown} (${_NV_DISTRO_FAMILY}) → pre-selecting ${_label}"
  _prompt_from_array "Debian" "Ubuntu" "Fedora" "Suse"
  case "${_selected_value}" in
    "Debian")
      _NV_PKG_TARGET="debian" ;;
    "Ubuntu")
      _NV_PKG_TARGET="ubuntu" ;;
    "Fedora")
      _NV_PKG_TARGET="fedora" ;;
    "Suse")
      _NV_PKG_TARGET="suse" ;;
    *)
      _die "Unsupported distribution. Only Debian, Ubuntu, Fedora and Suse are supported by the direct installer."
      ;;
  esac
}
_distro_prompt

# Package targets disallow building/installing DKMS and prebuilt module variants together
if [[ "${_NV_PKG_TARGET:-}" =~ ^(debian|ubuntu|fedora|suse)$ ]] && [[ "${_dkms:-false}" == "full" ]]; then
  _die "_dkms=full is not supported on ${_NV_PKG_TARGET}. Choose exactly one module variant: _dkms=true (DKMS) or _dkms=false (prebuilt)."
fi

# Install build dependencies
_install_dependencies() {
  msg2 "Installing build dependencies for ${_NV_PKG_TARGET}..."
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)

  case "${_NV_PKG_TARGET}" in
    debian|ubuntu)
      # Enable i386 multiarch for lib32 packages
      if ! dpkg --print-foreign-architectures | grep -q i386; then
        msg2 "Enabling i386 multiarch support..."
        sudo dpkg --add-architecture i386
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -q
      fi

      local _kver
      for _kver in "${_kernels[@]+"${_kernels[@]}"}"; do
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "linux-headers-${_kver}"
      done

      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y dkms build-essential gcc-multilib dwarves libarchive-tools patchelf libglvnd-dev libvulkan-dev curl pciutils mokutil
      ;;
    fedora)
      local _kver
      for _kver in "${_kernels[@]+"${_kernels[@]}"}"; do
        sudo dnf install -y "kernel-devel-${_kver}"
      done

      sudo dnf install -y kernel-headers dkms gcc gcc-c++ make bsdtar libarchive patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      ;;
    suse)
      local _kver
      for _kver in "${_kernels[@]+"${_kernels[@]}"}"; do
        sudo zypper install -y "kernel-devel-${_kver}"
      done

      sudo zypper install -y dkms gcc gcc-c++ make libarchive-tools patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      ;;
    *)
      _die "Unsupported distribution '${_NV_PKG_TARGET}'. Only Debian, Ubuntu, Fedora and Suse are supported."
      ;;
  esac
}
_install_dependencies

#  select install mode
_NV_INSTALL_MODE="direct"

_install_mode() {
  case "${_NV_PKG_TARGET}" in
    debian|ubuntu|fedora|suse) ;;
    *) return 0 ;;
  esac

  # Build a native distro package
  _NV_INSTALL_MODE="package"
  if [[ -z "${PKG_FORMAT:-}" ]]; then
    case "${_NV_PKG_TARGET}" in
      debian|ubuntu)
        PKG_FORMAT="deb" ;;
      fedora|suse)
        PKG_FORMAT="rpm" ;;
    esac
  fi
  msg2 "Package format: ${PKG_FORMAT}"

  # _build_utils_package_only is an Arch/PKGBUILD-only
  if [[ "${_build_utils_package_only:-false}" == "true" ]]; then
    msg2 "_build_utils_package_only ignored for ${PKG_FORMAT} package builds — forcing false."
    _build_utils_package_only="false"
  fi

  local _deb=false _rpm=false
  ( command -v dpkg-deb &>/dev/null && command -v fakeroot &>/dev/null ) && _deb=true
  command -v rpmbuild &>/dev/null && _rpm=true

  if [[ "$PKG_FORMAT" == "deb" ]] && ! ${_deb}; then
    msg2 "dpkg-deb and/or fakeroot not found — installing required build tools..."
    sudo apt-get install dpkg fakeroot
  fi

  if [[ "$PKG_FORMAT" == "rpm" ]] && ! ${_rpm}; then
    msg2 "rpmbuild not found — installing required build tools..."
    case "${_NV_PKG_TARGET}" in
      fedora)
        sudo dnf install rpmdevtools ;;
      suse)
        sudo zypper install rpm-build ;;
      *)
        _die "Don't know how to install rpmbuild on this system." ;;
    esac
  fi
}
_install_mode

# Relocate ELF shared libraries to the distribution-canonical library prefix
_relocate_elfs() {
  local _pkgdir="$1"

  case "${_NV_PKG_TARGET:-}" in
    fedora|suse)
      # 64-bit ELF
      if [[ -d "${_pkgdir}/usr/lib" ]]; then
        mkdir -p "${_pkgdir}/usr/lib64"
        # Move ELF-containing subdirectories
        # non-ELF config dirs remain in usr/lib
        local _dir
        for _dir in gbm nvidia vdpau xorg tls; do
          [[ -d "${_pkgdir}/usr/lib/${_dir}" ]] && mv "${_pkgdir}/usr/lib/${_dir}" "${_pkgdir}/usr/lib64/"
        done
        # Move root-level shared libraries (.so / .so.N / .so.N.N.N …).
        find "${_pkgdir}/usr/lib" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) \
          -exec mv {} "${_pkgdir}/usr/lib64/" \;
      fi

      # 32-bit ELF
      if [[ -d "${_pkgdir}/usr/lib32" ]]; then
        mkdir -p "${_pkgdir}/usr/lib"
        cp -a "${_pkgdir}/usr/lib32/." "${_pkgdir}/usr/lib/"
        rm -rf "${_pkgdir}/usr/lib32"
      fi
      ;;

    debian|ubuntu)
      # 64-bit ELF
      if [[ -d "${_pkgdir}/usr/lib" ]]; then
        mkdir -p "${_pkgdir}/usr/lib/x86_64-linux-gnu"
        # Move ELF-containing subdirectories
        local _dir
        for _dir in gbm vdpau tls; do
          [[ -d "${_pkgdir}/usr/lib/${_dir}" ]] && mv "${_pkgdir}/usr/lib/${_dir}" "${_pkgdir}/usr/lib/x86_64-linux-gnu/"
        done
        # Move root-level shared libraries (.so / .so.N / .so.N.N.N …).
        find "${_pkgdir}/usr/lib" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) \
          -exec mv {} "${_pkgdir}/usr/lib/x86_64-linux-gnu/" \;
      fi

      # 32-bit ELF
      if [[ -d "${_pkgdir}/usr/lib32" ]]; then
        mkdir -p "${_pkgdir}/usr/lib/i386-linux-gnu"
        cp -a "${_pkgdir}/usr/lib32/." "${_pkgdir}/usr/lib/i386-linux-gnu/"
        rm -rf "${_pkgdir}/usr/lib32"
      fi
      ;;

    *)
      # All other targets: no relocation needed.
      ;;
  esac
}

# staging utilities
_stage_utils() {
  cd "${srcdir}/${_pkg}"
  _install_utils
  _install_egl_wayland # target-gated in install-common
  _install_egl_x11 # target-gated in install-common
  _relocate_elfs "${pkgdir}"
}

# staging utilities for 32-bit
_stage_lib32_utils() {
  cd "${srcdir}/${_pkg}/32"
  _install_lib32_utils
  _install_lib32_egl_wayland # target-gated in install-common
  _relocate_elfs "${pkgdir}"
}

# staging OpenCL ICD and libraries
_stage_opencl() {
  cd "${srcdir}/${_pkg}"
  _install_opencl
  _relocate_elfs "${pkgdir}"
}

# staging OpenCL ICD and libraries for 32-bit
_stage_lib32_opencl() {
  cd "${srcdir}/${_pkg}/32"
  _install_lib32_opencl
  _relocate_elfs "${pkgdir}"
}

# staging nvidia-settings
_stage_settings() {
  cd "${srcdir}/${_pkg}"
  _install_settings
  _relocate_elfs "${pkgdir}"
}

# Debian/Ubuntu initramfs-tools staging
_stage_initramfs() {
  printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
    install -Dm644 /dev/stdin "${pkgdir}/usr/share/initramfs-tools/modules.d/nvidia-tkg"

  install -Dm755 \
    "${_where}/nvidia-all-config/system/package-templates/deb/initramfs-hook.nvidia-tkg.in" \
    "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg"
  chmod 755 "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg"
}

# Autoload nvidia modules at boot
_stage_modules_load() {
  printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
    install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia.conf"
}

# Autoload nvidia-uvm at boot
_stage_uvm_load() {
  if [[ "${_blacklist_nouveau}" != "false" ]]; then
    echo "nvidia-uvm" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia-uvm.conf"
  else
    msg2 "Skipping nvidia-uvm autoload due to user config"
  fi
}

# Enable NVIDIA DRM KMS for proprietary modules.
_stage_closed_drm_kms() {
  local _opts="options nvidia-drm modeset=1"

  if (( ${pkgver%%.*} >= 520 )); then
    _opts+=" fbdev=1"
  fi

  echo "${_opts}" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-tkg-drm-kms.conf"
}

# This function is used for the non-DKMS package variant, where we stage precompiled kernel modules directly
_stage_kmod() {
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)
  local _kernel

  install -Dm755 "${_where}/nvidia-all-config/module-signing" "${pkgdir}/usr/lib/nvidia-tkg/module-signing"

  for _kernel in "${_kernels[@]}"; do
    msg2 "Staging kernel modules for ${_kernel}..."

    # Open-source modules.
    if [[ "${_open_source_modules:-}" = "true" ]]; then
      [[ -d "${srcdir}/open-kmods/${_kernel}" ]] || { error "Missing open kmods for ${_kernel}"; return 1; }

      install -Dt "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -m644 "${srcdir}/open-kmods/${_kernel}"/*.ko

      # Force module to load even on unsupported GPUs
      mkdir -p "${pkgdir}/usr/lib/modprobe.d"
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"

      # Early KMS autoload for prebuilt package variant
      if [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
        _stage_modules_load
      fi
    # Closed-source modules.
    else
      install -D -m644 "${srcdir}/${_pkg}/kernel-${_kernel}/"nvidia{,-drm,-modeset,-uvm}.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
      if [[ -e "${srcdir}/${_pkg}/kernel-${_kernel}/nvidia-peermem.ko" ]]; then
        install -D -m644 "${srcdir}/${_pkg}/kernel-${_kernel}/nvidia-peermem.ko" -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
      fi

      # Enable NVIDIA DRM KMS for proprietary modules.
      _stage_closed_drm_kms

      # Enable nvidia-uvm autoload at boot
      _stage_uvm_load
    fi

    _compress_modules_for_kernel "${_kernel}" "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
  done

  # Configure dracut for nvidia kernel modules
  if command -v dracut &>/dev/null; then
    if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
      echo 'force_drivers+=" nvidia nvidia-modeset nvidia-uvm nvidia-drm "' | \
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    else
      install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-dracut.conf" "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    fi
  elif [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
    _stage_initramfs
  fi
}

# Staging the DKMS source tree for the DKMS package variant
_stage_dkms() {
  # Open-source DKMS modules.
  if [[ "${_open_source_modules:-}" = "true" ]]; then
    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "${srcdir}/open-gpu-kernel-modules-dkms" \
      "${pkgdir}/usr/src/$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_NAME "nvidia")-$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_VERSION "${pkgver}")"
    mv \
      "${pkgdir}/usr/src/$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_NAME "nvidia")-$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_VERSION "${pkgver}")/kernel-open/dkms.conf" \
      "${pkgdir}/usr/src/$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_NAME "nvidia")-$(_dkms_conf_value "${srcdir}/open-gpu-kernel-modules-dkms/kernel-open/dkms.conf" PACKAGE_VERSION "${pkgver}")/dkms.conf"

    # Force module to load even on unsupported GPUs
    mkdir -p "${pkgdir}/usr/lib/modprobe.d"
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
       install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"

    # Debian for early KMS support.
    if [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
      _stage_modules_load
    fi

    install -Dm644 "${srcdir}/open-gpu-kernel-modules-dkms/COPYING" "${pkgdir}/usr/share/licenses/${pkgname}/COPYING"
  # Closed-source DKMS modules
  else
    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "${srcdir}/${_pkg}/kernel-dkms" \
      "${pkgdir}/usr/src/$(_dkms_conf_value "${srcdir}/${_pkg}/kernel-dkms/dkms.conf" PACKAGE_NAME "nvidia")-$(_dkms_conf_value "${srcdir}/${_pkg}/kernel-dkms/dkms.conf" PACKAGE_VERSION "${pkgver}")"

    # Enable NVIDIA DRM KMS for proprietary modules.
    _stage_closed_drm_kms

    install -Dm644 "${srcdir}/${_pkg}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  fi

  # Enable nvidia-uvm autoload at boot
  _stage_uvm_load

  # Configure dracut for nvidia kernel modules
  if command -v dracut &>/dev/null; then
    if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
      echo 'omit_drivers+=" nvidia nvidia-modeset nvidia-uvm nvidia-drm "' | \
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    else
      install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-dracut.conf" "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    fi
  elif [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
    _stage_initramfs
  fi
}

# main staging function
_stage_package() {
  pkgdir="$2"
  pkgname="$1"

  source "${_where}/BIG_UGLY_FROGMINER"
  source "${_where}/nvidia-all-config/prepare"
  source "${_where}/nvidia-all-config/install-common"

  case "${pkgname}" in
    nvidia-dkms-tkg|nvidia-open-dkms-tkg) _stage_dkms ;;
    nvidia-utils-tkg) _stage_utils ;;
    opencl-nvidia-tkg) [[ "${_opencl:-true}" == "true" ]] && _stage_opencl ;;
    nvidia-settings-tkg) [[ "${_nvsettings:-true}" == "true" ]] && _stage_settings ;;
    lib32-nvidia-utils-tkg) [[ "${_lib32:-true}" == "true" ]] && _stage_lib32_utils ;;
    lib32-opencl-nvidia-tkg) [[ "${_opencl:-true}" == "true" && "${_lib32:-true}" == "true" ]] && _stage_lib32_opencl ;;
    nvidia-tkg|nvidia-open-tkg) _stage_kmod ;;
    *) warning "No staging function for ${pkgname} — skipping." ;;
  esac
}

# Read a shell assignment from a dkms.conf file without sourcing it
_dkms_conf_value() {
  local _conf="$1" _key="$2" _default="${3:-}" _value
  _value=$(sed -nE "s/^${_key}=\"?([^\"#]+)\"?.*/\\1/p" "${_conf}" 2>/dev/null | head -n1)
  printf '%s' "${_value:-${_default}}"
}

_staged_dkms_conf() {
  find "$1/usr/src" -mindepth 2 -maxdepth 2 -name dkms.conf -print -quit 2>/dev/null
}

_staged_dkms_name() {
  _dkms_conf_value "$(_staged_dkms_conf "$1")" PACKAGE_NAME "nvidia"
}

# package metadata
declare -A _NV_META

_meta_nvidia_utils() {
  local _epoch="$1"
  _NV_META[nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries"
  _NV_META[nvidia-utils-tkg_depends_deb]="libc6, libglvnd0, libgl1-mesa-glx | libgl1, libvulkan1, libx11-6, libxext6, libwayland-client0"
  _NV_META[nvidia-utils-tkg_depends_rpm]="libglvnd >= 1.3, mesa-libGL, vulkan-loader"
  _NV_META[nvidia-utils-tkg_provides_deb]="nvidia-utils (= ${pkgver}), libgl1-nvidia-glvnd-glx, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_provides_rpm]="nvidia-utils = ${pkgver}, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_conflicts_deb]="nvidia-utils, nvidia-libgl, libgl1-nvidia-legacy-390xx-glx, libgl1-nvidia-glvnd-glx, nvidia-egl-icd, libglx-nvidia0, libgles-nvidia1, libgles-nvidia2, libnvidia-allocator1, libnvidia-cfg1, libnvidia-encode1, libnvidia-fbc1, nvidia-vulkan-icd"
  _NV_META[nvidia-utils-tkg_conflicts_rpm]="nvidia-utils, xorg-x11-drv-nvidia, xorg-x11-drv-nvidia-libs, xorg-x11-drv-nvidia-470xx, xorg-x11-drv-nvidia-580xx, nvidia-modprobe, nvidia-persistenced"
  _NV_META[nvidia-utils-tkg_replaces_deb]="nvidia-libgl, libgl1-nvidia-glvnd-glx, nvidia-egl-icd, libglx-nvidia0, libgles-nvidia1, libgles-nvidia2, libnvidia-allocator1, libnvidia-cfg1, libnvidia-encode1, libnvidia-fbc1, nvidia-vulkan-icd"

  _NV_META[lib32-nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries (32-bit)"
  _NV_META[lib32-nvidia-utils-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), gcc-multilib, libglvnd0:i386, libvulkan1:i386, libnvidia-egl-wayland1:i386"
  _NV_META[lib32-nvidia-utils-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, glibc(x86-32), libglvnd(x86-32)"
  _NV_META[lib32-nvidia-utils-tkg_provides_deb]="lib32-nvidia-utils (= ${pkgver}), lib32-nvidia-libgl, lib32-vulkan-driver, lib32-opengl-driver"
  _NV_META[lib32-nvidia-utils-tkg_provides_rpm]="lib32-nvidia-utils = ${pkgver}"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_deb]="lib32-nvidia-utils, lib32-nvidia-libgl, nvidia-egl-icd:i386, libglx-nvidia0:i386, libgles-nvidia1:i386, libgles-nvidia2:i386, libnvidia-allocator1:i386, libnvidia-encode1:i386, libnvidia-fbc1:i386"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_rpm]="lib32-nvidia-utils, xorg-x11-drv-nvidia-libs-i686, xorg-x11-drv-nvidia-470xx-libs"
  _NV_META[lib32-nvidia-utils-tkg_replaces_deb]="lib32-nvidia-libgl, nvidia-egl-icd:i386, libglx-nvidia0:i386, libgles-nvidia1:i386, libgles-nvidia2:i386, libnvidia-allocator1:i386, libnvidia-encode1:i386, libnvidia-fbc1:i386"
}

_meta_nvidia_dkms() {
  local _epoch="$1"
  _NV_META[nvidia-dkms-tkg_desc]="NVIDIA kernel module sources (DKMS)"
  _NV_META[nvidia-dkms-tkg_depends_deb]="dkms (>= 3.0.11), nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${_epoch}, dwarves"
  _NV_META[nvidia-dkms-tkg_provides_deb]="nvidia-kernel-dkms (= ${pkgver}), nvidia-kernel-${pkgver}, nvidia-dkms (= ${pkgver}), nvidia-dkms-kernel, NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_provides_rpm]="nvidia-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-tkg, nvidia-open-tkg, nvidia-dkms-kernel"
  _NV_META[nvidia-dkms-tkg_replaces_deb]="nvidia-open-dkms-tkg, nvidia-tkg, nvidia-open-tkg"
  _NV_META[nvidia-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-dkms-tkg_obsoletes_rpm]="nvidia-open-dkms-tkg < ${_epoch}, nvidia-tkg < ${_epoch}, nvidia-open-tkg < ${_epoch}"

  _NV_META[nvidia-open-dkms-tkg_desc]="NVIDIA open kernel module sources (DKMS)"
  _NV_META[nvidia-open-dkms-tkg_depends_deb]="dkms (>= 3.0.11), nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-open-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${_epoch}, dwarves"
  _NV_META[nvidia-open-dkms-tkg_provides_deb]="nvidia-open-kernel-dkms (= ${pkgver}), nvidia-open-kernel-${pkgver}, nvidia-open-dkms (= ${pkgver}), nvidia-dkms-kernel, NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_provides_rpm]="nvidia-open-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms, nvidia-dkms-tkg, nvidia-tkg, nvidia-open-tkg, nvidia-dkms-kernel"
  _NV_META[nvidia-open-dkms-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-tkg, nvidia-open-tkg"
  _NV_META[nvidia-open-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-open-dkms-tkg_obsoletes_rpm]="nvidia-dkms-tkg < ${_epoch}, nvidia-tkg < ${_epoch}, nvidia-open-tkg < ${_epoch}"
}

_meta_nvidia_kmod() {
  local _epoch="$1"
  _NV_META[nvidia-tkg_desc]="NVIDIA kernel modules (prebuilt)"
  _NV_META[nvidia-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, libglvnd"
  _NV_META[nvidia-tkg_provides_deb]="nvidia (= ${pkgver}), nvidia-kernel-${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-tkg_provides_rpm]="nvidia = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-dkms-tkg, nvidia-open, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-open-tkg"
  _NV_META[nvidia-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-open-tkg"
  _NV_META[nvidia-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-open, nvidia-open-kmod, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-tkg_obsoletes_rpm]="nvidia-dkms-tkg < ${_epoch}, nvidia-open-dkms-tkg < ${_epoch}, nvidia-open-tkg < ${_epoch}"

  _NV_META[nvidia-open-tkg_desc]="NVIDIA open kernel modules (prebuilt)"
  _NV_META[nvidia-open-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-open-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, libglvnd"
  _NV_META[nvidia-open-tkg_provides_deb]="nvidia-open (= ${pkgver}), nvidia-open-kernel-${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-open-tkg_provides_rpm]="nvidia-open = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-open-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-dkms-tkg, nvidia-open, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-tkg"
  _NV_META[nvidia-open-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-tkg"
  _NV_META[nvidia-open-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-kmod, nvidia-open, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-open-tkg_obsoletes_rpm]="nvidia-dkms-tkg < ${_epoch}, nvidia-open-dkms-tkg < ${_epoch}, nvidia-tkg < ${_epoch}"
}

_meta_nvidia_opencl() {
  _NV_META[opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation"
  _NV_META[opencl-nvidia-tkg_depends_deb]="zlib1g, nvidia-utils-tkg (= ${pkgver})"
  _NV_META[opencl-nvidia-tkg_depends_rpm]="zlib, (ocl-icd or OpenCL-ICD-Loader)"
  _NV_META[opencl-nvidia-tkg_provides_deb]="opencl-nvidia (= ${pkgver}), opencl-driver, opencl-icd"
  _NV_META[opencl-nvidia-tkg_provides_rpm]="opencl-nvidia = ${pkgver}"
  _NV_META[opencl-nvidia-tkg_conflicts_deb]="opencl-nvidia, nvidia-opencl-icd, libcuda1"
  _NV_META[opencl-nvidia-tkg_conflicts_rpm]="opencl-nvidia"
  _NV_META[opencl-nvidia-tkg_replaces_deb]="opencl-nvidia, nvidia-opencl-icd, libcuda1"

  _NV_META[lib32-opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation (32-bit)"
  _NV_META[lib32-opencl-nvidia-tkg_depends_deb]="zlib1g:i386, gcc-multilib, opencl-nvidia-tkg (= ${pkgver})"
  _NV_META[lib32-opencl-nvidia-tkg_depends_rpm]="zlib(x86-32)"
  _NV_META[lib32-opencl-nvidia-tkg_provides_deb]="lib32-opencl-nvidia (= ${pkgver}), lib32-opencl-driver, lib32-opencl-icd"
  _NV_META[lib32-opencl-nvidia-tkg_provides_rpm]="lib32-opencl-nvidia = ${pkgver}"
  _NV_META[lib32-opencl-nvidia-tkg_conflicts_deb]="lib32-opencl-nvidia"
  _NV_META[lib32-opencl-nvidia-tkg_conflicts_rpm]="lib32-opencl-nvidia"
}

_meta_nvidia_settings() {
  local _epoch="$1"
  _NV_META[nvidia-settings-tkg_desc]="NVIDIA GPU configuration tool"
  _NV_META[nvidia-settings-tkg_depends_deb]="nvidia-utils-tkg (>= ${pkgver}), libc6, libcairo2, libgdk-pixbuf-2.0-0, libglib2.0-0 | libglib2.0-0t64, libgtk-3-0 | libgtk-3-0t64, libjansson4, libpango-1.0-0, libpangocairo-1.0-0, libwayland-client0, libx11-6, libxext6, libxxf86vm1"
  _NV_META[nvidia-settings-tkg_recommends_deb]="libxv1 | libxv1t64, libvdpau1 | libvdpau1t64"
  _NV_META[nvidia-settings-tkg_depends_rpm]="nvidia-utils-tkg >= ${_epoch}, gtk3, jansson, libX11, libXext, libXxf86vm, cairo, gdk-pixbuf2, glib2, pango, libwayland-client.so.0()(64bit)"
  _NV_META[nvidia-settings-tkg_suggests_rpm]="libXv, libvdpau"
  _NV_META[nvidia-settings-tkg_provides_deb]="nvidia-settings (= ${pkgver})"
  _NV_META[nvidia-settings-tkg_provides_rpm]="nvidia-settings = ${pkgver}"
  _NV_META[nvidia-settings-tkg_conflicts_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_replaces_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_conflicts_rpm]="nvidia-settings"
}

_dpkg_installed_pkg_csv() {
  dpkg-query -W -f=$'${db:Status-Abbrev}\t${binary:Package}\n' "$1" 2>/dev/null | awk '
    $1 == "ii" {
      printf "%s%s", sep, $2
      sep = ", "
    }
  '
}

_build_metadata() {
  local _rpm_pkgver_epoch="300:${pkgver}"
  local _installed_pkgs=""

  _meta_nvidia_utils "${_rpm_pkgver_epoch}"
  _meta_nvidia_dkms "${_rpm_pkgver_epoch}"
  _meta_nvidia_kmod "${_rpm_pkgver_epoch}"
  _meta_nvidia_opencl
  _meta_nvidia_settings "${_rpm_pkgver_epoch}"

  if (( ${pkgver%%.*} >= 465 )); then
    _NV_META[nvidia-utils-tkg_provides_deb]+=", firmware-nvidia-gsp (= ${pkgver}), firmware-nvidia-gsp-${pkgver}"
    _NV_META[nvidia-utils-tkg_conflicts_deb]+=", firmware-nvidia-gsp, firmware-nvidia-gsp-${pkgver}"
    _NV_META[nvidia-utils-tkg_replaces_deb]+=", firmware-nvidia-gsp, firmware-nvidia-gsp-${pkgver}"
    _NV_META[nvidia-utils-tkg_provides_rpm]+=", firmware-nvidia-gsp = ${pkgver}"
    _NV_META[nvidia-utils-tkg_conflicts_rpm]+=", firmware-nvidia-gsp"
  fi

  # Fedora-specific metadata tuning based on available runtime package names
  if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
    _NV_META[nvidia-utils-tkg_depends_rpm]+=", pciutils, which, egl-wayland, egl-wayland2, egl-gbm, egl-x11"
    _NV_META[lib32-nvidia-utils-tkg_depends_rpm]+=", egl-wayland(x86-32), egl-wayland2(x86-32), egl-gbm(x86-32), egl-x11(x86-32)"
    _NV_META[nvidia-utils-tkg_suggests_rpm]="acpica-tools, vulkan-tools"
    _NV_META[opencl-nvidia-tkg_depends_rpm]="zlib, opencl-filesystem, libOpenCL.so.1()(64bit)"

    # libxnvctrl
    if [[ "${_nvsettings:-false}" == "true" ]]; then
      case "${_libxnvctrl:-external}" in
        true)
          _NV_META[nvidia-settings-tkg_provides_rpm]+=", libXNVCtrl = ${pkgver}"
          _NV_META[nvidia-settings-tkg_conflicts_rpm]+=", libXNVCtrl"
          ;;
        external)
          _NV_META[nvidia-settings-tkg_depends_rpm]+=", libXNVCtrl.so.0()(64bit)"
          ;;
      esac
    fi
  fi

  # detect .deb versioned NVIDIA packages
  if command -v dpkg &>/dev/null && [[ "${_NV_PKG_TARGET:-}" =~ ^(debian|ubuntu)$ ]]; then
    if (( ${pkgver%%.*} >= 470 )); then
      _NV_META[nvidia-utils-tkg_depends_deb]+=", libnvidia-egl-wayland1"
      if [[ -n "${_NV_META[nvidia-utils-tkg_recommends_deb]:-}" ]]; then
        _NV_META[nvidia-utils-tkg_recommends_deb]+=", libnvidia-egl-gbm1, libnvidia-egl-xcb1, libnvidia-egl-xlib1"
      else
        _NV_META[nvidia-utils-tkg_recommends_deb]="libnvidia-egl-gbm1, libnvidia-egl-xcb1, libnvidia-egl-xlib1"
      fi
      if [[ -n "${_NV_META[lib32-nvidia-utils-tkg_recommends_deb]:-}" ]]; then
        _NV_META[lib32-nvidia-utils-tkg_recommends_deb]+=", libnvidia-egl-gbm1:i386, libnvidia-egl-xcb1:i386, libnvidia-egl-xlib1:i386"
      else
        _NV_META[lib32-nvidia-utils-tkg_recommends_deb]="libnvidia-egl-gbm1:i386, libnvidia-egl-xcb1:i386, libnvidia-egl-xlib1:i386"
      fi
    fi

    # libxnvctrl
    if [[ "${_nvsettings:-false}" == "true" ]]; then
      case "${_libxnvctrl:-external}" in
        true)
          _NV_META[nvidia-settings-tkg_provides_deb]+=", libxnvctrl0 (= ${pkgver})"
          _NV_META[nvidia-settings-tkg_conflicts_deb]+=", libxnvctrl0"
          _NV_META[nvidia-settings-tkg_replaces_deb]+=", libxnvctrl0"
          ;;
        external)
          _NV_META[nvidia-settings-tkg_depends_deb]+=", libxnvctrl0"
          ;;
      esac
    fi

    # Map extends conflicts_deb + replaces_deb
    local -a _cr_map=(
      'libnvidia-compute-[0-9]*:opencl-nvidia-tkg'
      'nvidia-utils-[0-9]*:nvidia-utils-tkg'
      'nvidia-kernel-common-[0-9]*:nvidia-utils-tkg'
      'nvidia-firmware-[0-9]*:nvidia-utils-tkg'
      'libnvidia-extra-[0-9]*:nvidia-utils-tkg'
      'libnvidia-gl-[0-9]*:nvidia-utils-tkg'
      'xserver-xorg-video-nvidia-[0-9]*:nvidia-utils-tkg'
    )

    for _entry in "${_cr_map[@]}"; do
      _installed_pkgs="$(_dpkg_installed_pkg_csv "${_entry%%:*}")"
      if [[ -n "${_installed_pkgs}" ]]; then
        _NV_META[${_entry##*:}_conflicts_deb]+=", ${_installed_pkgs}"
        _NV_META[${_entry##*:}_replaces_deb]+=", ${_installed_pkgs}"
      fi
    done

    # Special case two packages, no replaces
    _installed_pkgs="$(_dpkg_installed_pkg_csv 'nvidia-dkms-[0-9]*-open')"
    if [[ -n "${_installed_pkgs}" ]]; then
      _NV_META[nvidia-dkms-tkg_conflicts_deb]+=", ${_installed_pkgs}"
      _NV_META[nvidia-open-dkms-tkg_conflicts_deb]+=", ${_installed_pkgs}"
    fi
  fi
}

# package builders
_build_pkg_list() {
  local -a _list=()
  local _open=""
  [[ "${_open_source_modules:-}" == "true" ]] && _open="-open"
  if [[ "${_dkms:-false}" == "true" ]]; then
    _list+=("nvidia${_open}-dkms-tkg")
  else
    _list+=("nvidia${_open}-tkg")
  fi
  _list+=("nvidia-utils-tkg")
  [[ "${_lib32:-false}" == "true" ]] && _list+=("lib32-nvidia-utils-tkg")
  [[ "${_opencl:-false}" == "true" ]] && _list+=("opencl-nvidia-tkg")
  [[ "${_opencl:-false}" == "true" && "${_lib32:-false}" == "true" ]] && _list+=("lib32-opencl-nvidia-tkg")
  [[ "${_nvsettings:-false}" == "true" ]] && _list+=("nvidia-settings-tkg")
  echo "${_list[@]}"
}

_pkg_template_path() {
  local _template="$1"
  printf '%s\n' "${_where}/nvidia-all-config/system/package-templates/${_template}"
}

_render_pkg_template() {
  local _template="$1" _content
  _content="$(<"$(_pkg_template_path "${_template}")")"
  _content="${_content//@PKGNAME@/${_tmpl_pkgname:-}}"
  _content="${_content//@PKGVER@/${pkgver}}"
  _content="${_content//@DESCRIPTION@/${_tmpl_description:-NVIDIA driver package}}"
  _content="${_content//@INSTALLED_SIZE@/${_tmpl_installed_size:-}}"
  _content="${_content//@DKMS_NAME@/${_tmpl_dkms_name:-}}"
  _content="${_content//@STAGEDIR@/${_tmpl_stagedir:-}}"
  _content="${_content//@DRACUTOPTS@/${_tmpl_dracutopts:-}}"
  printf '%s\n' "${_content}"
}

_write_pkg_template() {
  local _dest="$1" _template="$2"
  _render_pkg_template "${_template}" > "${_dest}"
}

_append_pkg_template() {
  local _dest="$1" _template="$2"
  _render_pkg_template "${_template}" >> "${_dest}"
}

_append_secure_boot_postinst_snippet() {
  case "${_module_signing:-autodetect}" in
    false) return 0 ;;
    true)
      _append_pkg_template "$1" "common/secure-boot-forced.in"
      return 0
      ;;
  esac

  _append_pkg_template "$1" "common/secure-boot-autodetect.in"
}

_deb_postinst() {
  local _debdir="$1" _mode="${2:-}" _stagedir="${3:-}" _pkgname="${4:-}"

  if [[ "${_mode}" == "dkms" ]]; then
    _tmpl_dkms_name="$(_staged_dkms_name "${_stagedir}")" _tmpl_pkgname="${_pkgname}" \
      _write_pkg_template "${_debdir}/DEBIAN/postinst" "deb/postinst.dkms.in"
    chmod 755 "${_debdir}/DEBIAN/postinst"
    return 0
  fi

  _write_pkg_template "${_debdir}/DEBIAN/postinst" "deb/postinst.base.in"

  if [[ "${_mode}" == "kmod" ]]; then
    _append_pkg_template "${_debdir}/DEBIAN/postinst" "deb/postinst.depmod.in"
    _append_secure_boot_postinst_snippet "${_debdir}/DEBIAN/postinst"
  fi

  if [[ "${_mode}" == "kmod" || "${_mode}" == "initramfs" ]]; then
    _append_pkg_template "${_debdir}/DEBIAN/postinst" "deb/postinst.initramfs.in"
  fi

  chmod 755 "${_debdir}/DEBIAN/postinst"
}

_deb_prerm() {
  local _debdir="$1" _mode="${2:-}" _stagedir="${3:-}"

  case "${_mode}" in
    dkms)
      _tmpl_dkms_name="$(_staged_dkms_name "${_stagedir}")" \
        _write_pkg_template "${_debdir}/DEBIAN/prerm" "deb/prerm.dkms.in"
      ;;
    kmod)
      _write_pkg_template "${_debdir}/DEBIAN/prerm" "deb/prerm.kmod.in"
      ;;
    *)
      return 0
      ;;
  esac

  chmod 755 "${_debdir}/DEBIAN/prerm"
}

_deb_postrm() {
  local _debdir="$1"
  _write_pkg_template "${_debdir}/DEBIAN/postrm" "deb/postrm.in"
  chmod 755 "${_debdir}/DEBIAN/postrm"
}

# .deb builder
_deb_builder() {
  local _pkgname="$1" _stagedir="$2" _outdir="$3"

  mkdir -p "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN"
  mkdir -p "${_where}/logs"
  cp -a "${_stagedir}/." "${_outdir}/${_pkgname}_${pkgver}_amd64/"
  _tmpl_pkgname="${_pkgname}" \
    _tmpl_installed_size="$(du -sk "${_stagedir}" | cut -f1)" \
    _tmpl_description="${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}" \
    _write_pkg_template "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control" "deb/control.in"
  [[ -n "${_NV_META[${_pkgname}_depends_deb]:-}" ]] && echo "Depends: ${_NV_META[${_pkgname}_depends_deb]}" >> "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control"
  [[ -n "${_NV_META[${_pkgname}_recommends_deb]:-}" ]] && echo "Recommends: ${_NV_META[${_pkgname}_recommends_deb]}" >> "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control"
  [[ -n "${_NV_META[${_pkgname}_provides_deb]:-}" ]] && echo "Provides: ${_NV_META[${_pkgname}_provides_deb]}" >> "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control"
  [[ -n "${_NV_META[${_pkgname}_conflicts_deb]:-}" ]] && echo "Conflicts: ${_NV_META[${_pkgname}_conflicts_deb]}" >> "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control"
  [[ -n "${_NV_META[${_pkgname}_replaces_deb]:-}" ]] && echo "Replaces: ${_NV_META[${_pkgname}_replaces_deb]}" >> "${_outdir}/${_pkgname}_${pkgver}_amd64/DEBIAN/control"

  local _mode=""
  if [[ "${_pkgname}" == *dkms* ]]; then
    _mode=dkms
  elif [[ "${_pkgname}" == nvidia-tkg || "${_pkgname}" == nvidia-open-tkg ]]; then
    _mode=kmod
  elif [[ "${_pkgname}" == nvidia-utils-tkg ]]; then
    _mode=initramfs
  fi

  _deb_postinst "${_outdir}/${_pkgname}_${pkgver}_amd64" "${_mode}" "${_stagedir}" "${_pkgname}"
  _deb_prerm "${_outdir}/${_pkgname}_${pkgver}_amd64" "${_mode}" "${_stagedir}"
  _deb_postrm "${_outdir}/${_pkgname}_${pkgver}_amd64"

  {
    echo "[PACKAGING] dpkg-deb: ${_pkgname} ${pkgver}"
    fakeroot dpkg-deb --build "${_outdir}/${_pkgname}_${pkgver}_amd64" "${_outdir}/${_pkgname}_${pkgver}_amd64.deb"
  } >> "${_where}/logs/prepare.log.txt" 2>&1 || {
    error "Packaging failed for ${_pkgname}. See ${_where}/logs/prepare.log.txt"
    return 1
  }
  rm -rf "${_outdir}/${_pkgname}_${pkgver}_amd64"
  msg2 "Built: ${_outdir}/${_pkgname}_${pkgver}_amd64.deb"
}

_rpm_spec_field() {
  local _specfile="$1" _field="$2" _value="$3"
  local -a _entries=()
  local _entry
  [[ -n "${_value}" ]] || return 0

  IFS=',' read -ra _entries <<< "${_value}"
  for _entry in "${_entries[@]}"; do
    _entry="${_entry#"${_entry%%[! ]*}"}"
    _entry="${_entry%"${_entry##*[! ]}"}"
    [[ -n "${_entry}" ]] && echo "${_field}: ${_entry}" >> "${_specfile}"
  done
}

# .rpm builder
_rpm_builder() {
  local _pkgname="$1" _stagedir="$2" _outdir="$3"
  local _is_fedora=false
  local _dracutopts="rd.driver.blacklist=nouveau,nova_core,nova_drm modprobe.blacklist=nouveau,nova_core,nova_drm"
  mkdir -p "${_where}/logs"
  if (( ${pkgver%%.*} >= 470 && ${pkgver%%.*} < 580 )); then
    _dracutopts+=" nvidia-drm.modeset=1"
    if (( ${pkgver%%.*} >= 520 )); then
      _dracutopts+=" nvidia-drm.fbdev=1"
    fi
  fi

  [[ "${_NV_PKG_TARGET:-}" == "fedora" ]] && _is_fedora=true

  _tmpl_pkgname="${_pkgname}" \
    _tmpl_description="${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}" \
    _write_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/spec-preamble.in"

  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Requires "${_NV_META[${_pkgname}_depends_rpm]:-}"
  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Provides "${_NV_META[${_pkgname}_provides_rpm]:-}"
  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Conflicts "${_NV_META[${_pkgname}_conflicts_rpm]:-}"
  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Obsoletes "${_NV_META[${_pkgname}_obsoletes_rpm]:-}"
  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Suggests "${_NV_META[${_pkgname}_suggests_rpm]:-}"
  _rpm_spec_field "${_outdir}/${_pkgname}.spec" Recommends "${_NV_META[${_pkgname}_recommends_rpm]:-}"

  _tmpl_description="${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}" \
    _tmpl_stagedir="${_stagedir}" \
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/spec-install.in"

  # DKMS packages need dkms add/build/install in %post and dkms remove in %preun
  # All other packages only need ldconfig + depmod
  if [[ "${_pkgname}" == *dkms* ]]; then
    local _nv_dkms_name
    _nv_dkms_name="$(_staged_dkms_name "${_stagedir}")"
    _tmpl_dkms_name="${_nv_dkms_name}" \
      _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/dkms-post.in"
    if [[ "${_is_fedora}" == true ]]; then
      _tmpl_dracutopts="${_dracutopts}" \
        _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/dkms-fedora-posttrans.in"
    fi
    _tmpl_dkms_name="${_nv_dkms_name}" \
      _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/dkms-preun.in"
    if [[ "${_is_fedora}" == true ]]; then
      _tmpl_dracutopts="${_dracutopts}" \
        _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/dkms-fedora-preun.in"
    fi
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/dkms-postun.in"
  elif [[ "${_pkgname}" == nvidia-tkg || "${_pkgname}" == nvidia-open-tkg ]]; then
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/kmod-post-head.in"
    _append_secure_boot_postinst_snippet "${_outdir}/${_pkgname}.spec"
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/kmod-post-tail.in"
    if [[ "${_is_fedora}" == true ]]; then
      _tmpl_dracutopts="${_dracutopts}" \
        _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/kmod-fedora-scriptlets.in"
    fi
  else
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/default-post.in"
    if [[ "${_is_fedora}" == true ]]; then
      _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/default-fedora-restorecon.in"
    fi
    _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/default-postun.in"
  fi

  _append_pkg_template "${_outdir}/${_pkgname}.spec" "rpm/files-header.in"

  # %files list: one path per line, appended directly under the %files header
  find "${_stagedir}" -type f -o -type l | sed "s|^${_stagedir}||" >> "${_outdir}/${_pkgname}.spec"

  # Minimal %changelog entry to suppress the Fedora RPM macro warning.
  {
    echo ""
    echo "%changelog"
    echo "* $(LC_ALL=C date +'%a %b %d %Y') nvidia-all-tkg <build@nvidia-all> - ${pkgver}-1"
    echo "- Automated build of NVIDIA ${pkgver}"
  } >> "${_outdir}/${_pkgname}.spec"

  {
    echo "[PACKAGING] rpmbuild: ${_pkgname} ${pkgver}"
    rpmbuild -bb \
      --define "_rpmdir ${_outdir}" \
      --define "_build_name_fmt ${_pkgname}-${pkgver}-1.x86_64.rpm" \
      --define "debug_package %{nil}" \
      --define "__os_install_post %{nil}" \
      --define "_build_id_links none" \
      --define "_unpackaged_files_terminate_build 0" \
      "${_outdir}/${_pkgname}.spec"
  } >> "${_where}/logs/prepare.log.txt" 2>&1 || {
    error "Packaging failed for ${_pkgname}. See ${_where}/logs/prepare.log.txt"
    return 1
  }
  msg2 "Built: ${_outdir}/${_pkgname}-${pkgver}-1.x86_64.rpm"
}

# package build path
_distdir="${_where}/dist/${_NV_DISTRO_ID:-${_NV_DISTRO_FAMILY}}"
mkdir -p "${_distdir}" "${srcdir}"

cd "${srcdir}"
_nv_download

cd "${srcdir}"
_nv_srcprep

if [[ "${_dkms:-false}" != "true" ]]; then
  cd "${srcdir}"
  _nv_build
fi

_build_metadata
IFS=' ' read -ra _packages <<< "$(_build_pkg_list)"
msg2 "Packages to build: ${_packages[*]}"
declare -a _built_pkg_files=()

for _pkgname in "${_packages[@]}"; do
  msg2 "Staging ${_pkgname}"
  _pkgstage="${srcdir}/stage-${_pkgname}"
  mkdir -p "${_pkgstage}"
  _stage_package "${_pkgname}" "${_pkgstage}"

  msg2 "Packaging ${_pkgname}"
  if [[ "$PKG_FORMAT" == "deb" ]]; then
    _deb_builder "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}_${pkgver}_amd64.deb")
  else
    _rpm_builder "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}-${pkgver}-1.x86_64.rpm")
  fi

  rm -rf "${_pkgstage}"
done

msg2 "All packages written to: ${_distdir}"
msg2 "Packages from current run:"
printf '  %s\n' "${_built_pkg_files[@]}"
plain ""

case "$PKG_FORMAT" in
  rpm)
    _rpm_install_cmd=(sudo rpm -Uvh --force --nodeps "${_built_pkg_files[@]}")
    case "${_NV_PKG_TARGET:-}" in
      fedora)
        _rpm_install_cmd=(sudo dnf install --nogpgcheck --allowerasing "${_built_pkg_files[@]}")
        ;;
      suse)
        _rpm_install_cmd=(sudo zypper install --no-gpg-checks --force -y "${_built_pkg_files[@]}")
        ;;
    esac

    _rpm_install_hint=""
    _arg=""
    _arg_quoted=""
    for _arg in "${_rpm_install_cmd[@]}"; do
      printf -v _arg_quoted '%q' "${_arg}"
      _rpm_install_hint+="${_rpm_install_hint:+ }${_arg_quoted}"
    done

    msg2 "To install manually:"
    msg2 "  ${_rpm_install_hint}"
    plain ""

    if [[ "${_set_default:-}" =~ ^(true|1|yes|y)$ ]]; then
      _install_ans="y"
      msg2 "Auto-accepting package installation (default: Y)"
    else
      read -rp " -> Install the built RPM packages now? [Y/n]: " _install_ans
    fi

    if [[ -z "${_install_ans}" || "${_install_ans}" =~ ^[Yy] ]]; then
      case "${_NV_PKG_TARGET:-}" in
        fedora)
          msg2 "Installing packages via DNF..."
          ;;
        suse)
          msg2 "Installing packages via zypper..."
          ;;
        *)
          msg2 "Installing packages via rpm..."
          ;;
      esac
      "${_rpm_install_cmd[@]}"
      msg2 "Installation complete. A system reboot is recommended."
    else
      msg2 "Skipping installation. Packages remain in: ${_distdir}"
    fi
    ;;
  deb)
    _deb_install_cmd=(sudo apt-get install -y --reinstall "${_built_pkg_files[@]}")
    _deb_install_hint=""
    _arg=""
    _arg_quoted=""
    for _arg in "${_deb_install_cmd[@]}"; do
      printf -v _arg_quoted '%q' "${_arg}"
      _deb_install_hint+="${_deb_install_hint:+ }${_arg_quoted}"
    done

    msg2 "To install manually:"
    msg2 "  ${_deb_install_hint}"
    plain ""

    if [[ "${_set_default:-}" =~ ^(true|1|yes|y)$ ]]; then
      _install_ans="y"
      msg2 "Auto-accepting package installation (default: Y)"
    else
      read -rp " -> Install the built DEB packages now? [Y/n]: " _install_ans
    fi

    if [[ -z "${_install_ans}" || "${_install_ans}" =~ ^[Yy] ]]; then
      msg2 "Installing packages via apt..."
      _pkg_tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/nvidia-all-pkg.XXXXXXXX")"
      install -d -m 755 "${_pkg_tmpdir}"
      _pkg_install_files=()
      for _pkgfile in "${_built_pkg_files[@]}"; do
        install -m 644 "${_pkgfile}" "${_pkg_tmpdir}/${_pkgfile##*/}"
        _pkg_install_files+=("${_pkg_tmpdir}/${_pkgfile##*/}")
      done

      _deb_install_cmd=(sudo apt-get install -y --reinstall "${_pkg_install_files[@]}")
      DEBIAN_FRONTEND=noninteractive "${_deb_install_cmd[@]}"
      msg2 "Installation complete. A system reboot is recommended."
    else
      msg2 "Skipping installation. Packages remain in: ${_distdir}"
    fi
    ;;
esac
exit 0

# vim: set ft=sh ts=2 sw=2 et:
