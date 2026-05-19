#!/usr/bin/env bash

# Stop the script at any encountered error
set -e

_where="$(pwd)"
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

plain '           .---.`               `.---.'
plain '        `/syhhhyso-           -osyhhhys/`'
plain '       .syNMdhNNhss/``.---.``/sshNNhdMNys.'
plain '       +sdMh.`+MNsssssssssssssssNM+`.hMds+'
plain '       :syNNdhNNhssssssssssssssshNNhdNNys:'
plain '        /ssyhhhysssssssssssssssssyhhhyss/'
plain '        .ossssssssssssssssssssssssssssssso.'
plain '       :sssssssssssssssssssssssssssssssss:'
plain '      /sssssssssssssssssssssssssssssssssss/   nvidia-all'
plain '     :sssssssssssssoosssssssoosssssssssssss:        AIO drivers'
plain '     osssssssssssssoosssssssoossssssssssssso'
plain '     osssssssssssyyyyhhhhhhhyyyyssssssssssso'
plain '     /yyyyyyhhdmmmmNNNNNNNNNNNmmmmdhhyyyyyy/'
plain '      smmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmms'
plain '       /dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd/'
plain '        `:sdNNNNNNNNNNNNNNNNNNNNNNNNNds:`'
plain '           `-+shdNNNNNNNNNNNNNNNdhs+-`'
plain '                 `.-:///////:-.`'

if ! command -v vercmp &>/dev/null; then
  vercmp() {
    [[ "$1" == "$2" ]] && { echo 0; return; }
    local _newer
    _newer="$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)"
    [[ "${_newer}" == "$1" ]] && echo 1 || echo -1
  }
fi

for _required in "${_where}/customization.cfg" "${_where}/nvidia-all-config/prepare"; do
  if [[ ! -f "${_required}" ]]; then
    error "Required file not found: ${_required}"
    error "Run install.sh from the nvidia-all project root."
    exit 1
  fi
done

source "${_where}/nvidia-all-config/prepare"

# Cleanup on any exit
_cleanup() {
  [[ "${srcdir:-}" == /tmp/* && -d "${srcdir}" ]] && \
    rm -rf "${srcdir}"

  [[ -f "${_where}/BIG_UGLY_FROGMINER" ]] && \
    rm -f "${_where}/BIG_UGLY_FROGMINER"
}
trap _cleanup EXIT

if [[ ! -e "${_where}/BIG_UGLY_FROGMINER" ]]; then
  aggregate_user_config
  echo "_where=\"${_where}\"" >> "${_where}/BIG_UGLY_FROGMINER"

  source "${_where}/BIG_UGLY_FROGMINER"

  # curl + bsdtar are needed by _nv_initscript
  if ! command -v curl &>/dev/null || ! command -v bsdtar &>/dev/null; then
    if command -v apt-get &>/dev/null; then
      apt-get install -q curl libarchive-tools
    elif command -v dnf &>/dev/null; then
      dnf install curl bsdtar
    elif command -v zypper &>/dev/null; then
      zypper install curl libarchive-tools
    else
      error "curl/bsdtar not found and no known package manager to install them."
      exit 1
    fi
  fi

  _nv_initscript
fi

source "${_where}/BIG_UGLY_FROGMINER"

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

# Distro detection
_detect_distro
msg2 "Detected distro family: ${_NV_DISTRO_FAMILY}"

# Distro selection prompt
_distro_prompt() {
  # If _distro is already set in customization.cfg, skip the prompt
  if [[ -n "${_distro:-}" ]]; then
    case "${_distro}" in
      Arch)
        cd "${_where}"
        exec makepkg -si
        ;;
      Debian)  _NV_PKG_TARGET="debian" ; return 0 ;;
      Ubuntu)  _NV_PKG_TARGET="ubuntu" ; return 0 ;;
      Fedora)  _NV_PKG_TARGET="fedora" ; return 0 ;;
      Suse)    _NV_PKG_TARGET="suse"   ; return 0 ;;
      *)
        warning "_distro='${_distro}' is not a valid value. Valid values: Arch, Debian, Ubuntu, Fedora, Suse — prompting..."
        ;;
    esac
  fi

  # Unknown distros are not supported
  case "${_NV_DISTRO_FAMILY}" in
    generic|"")
      error "Unknown distribution '${_NV_DISTRO_ID:-unknown}'. Only Arch, Debian, Ubuntu, Fedora and Suse are supported."
      plain ""
      exit 1
      ;;
  esac

  msg2 "Which Linux distribution are you running?"
  local _detected_label
  local _default_index
  case "${_NV_DISTRO_FAMILY}" in
    arch)
      _default_index=0 ; _detected_label="Arch" ;;
    debian)
      case "${_NV_DISTRO_ID:-}" in
        ubuntu|linuxmint|pop|elementary|zorin)
          _default_index=2 ; _detected_label="Ubuntu" ;;
        *)
          _default_index=1 ; _detected_label="Debian" ;;
      esac
      ;;
    fedora)
      _default_index=3 ; _detected_label="Fedora" ;;
    suse)
      _default_index=4 ; _detected_label="Suse" ;;
  esac
  msg2 "Auto-detected: ${_NV_DISTRO_ID:-unknown} (${_NV_DISTRO_FAMILY}) → pre-selecting ${_detected_label}"
  _prompt_from_array "Arch" "Debian" "Ubuntu" "Fedora" "Suse"
  case "${_selected_value}" in
    "Arch")
      msg2 "Arch Linux detected. Starting makepkg -si ..."
      cd "${_where}"
      exec makepkg -si
      ;;
    "Debian")
      _NV_PKG_TARGET="debian" ;;
    "Ubuntu")
      _NV_PKG_TARGET="ubuntu" ;;
    "Fedora")
      _NV_PKG_TARGET="fedora" ;;
    "Suse")
      _NV_PKG_TARGET="suse" ;;
    *)
      error "Unsupported distribution. Only Arch, Debian, Ubuntu, Fedora and Suse are supported."
      exit 1
      ;;
  esac
}
_distro_prompt

# Package targets disallow building/installing DKMS and prebuilt module variants together.
if [[ "${_NV_PKG_TARGET:-}" =~ ^(debian|ubuntu|fedora|suse)$ ]] && [[ "${_dkms:-false}" == "full" ]]; then
  error "_dkms=full is not supported on ${_NV_PKG_TARGET}. Choose exactly one module variant: _dkms=true (DKMS) or _dkms=false (prebuilt)."
  exit 1
fi

# Install build dependencies
_install_dependencies() {
  msg2 "Installing build dependencies for ${_NV_PKG_TARGET}..."
  local -a _kernels
  local _utils_only="${_build_utils_package_only:-false}"
  if [[ "${_utils_only}" != "true" ]]; then
    mapfile -t _kernels < <(_detect_kernels)
  fi

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
        sudo DEBIAN_FRONTEND=noninteractive apt-get install "linux-headers-${_kver}"
      done

      if [[ "${_utils_only}" != "true" ]]; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install dkms build-essential gcc-multilib dwarves libarchive-tools patchelf libglvnd-dev libvulkan-dev curl pciutils mokutil
      else
        sudo DEBIAN_FRONTEND=noninteractive apt-get install gcc-multilib dwarves libarchive-tools patchelf libglvnd-dev libvulkan-dev curl pciutils mokutil
      fi
      ;;

    fedora)
      local _kver
      for _kver in "${_kernels[@]+"${_kernels[@]}"}"; do
        sudo dnf install "kernel-devel-${_kver}"
      done

      if [[ "${_utils_only}" != "true" ]]; then
        sudo dnf install kernel-headers dkms gcc gcc-c++ make bsdtar libarchive patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      else
        sudo dnf install bsdtar libarchive patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      fi
      ;;

    suse)
      local _kver
      for _kver in "${_kernels[@]+"${_kernels[@]}"}"; do
        sudo zypper install "kernel-devel-${_kver}"
      done

      if [[ "${_utils_only}" != "true" ]]; then
        sudo zypper install dkms gcc gcc-c++ make libarchive-tools patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      else
        sudo zypper install libarchive-tools patchelf libXext-devel libglvnd-devel curl pciutils mokutil
      fi
      ;;
    *)
      error "Unsupported distribution '${_NV_PKG_TARGET}'. Only Debian, Ubuntu, Fedora and Suse are supported."
      exit 1
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
        error "Don't know how to install rpmbuild on this system."
        exit 1 ;;
    esac
  fi
}
_install_mode

# Relocate ELF shared libraries to the distribution-canonical library prefix.
_relocate_elfs() {
  local _pkgdir="$1"
  local _lib="${_pkgdir}/usr/lib"
  local _lib32="${_pkgdir}/usr/lib32"

  case "${_NV_PKG_TARGET:-}" in
    fedora)
      # 64-bit ELF: usr/lib → usr/lib64
      local _lib64="${_pkgdir}/usr/lib64"
      if [[ -d "${_lib}" ]]; then
        mkdir -p "${_lib64}"
        # Move ELF-containing subdirectories
        # non-ELF config dirs remain in usr/lib.
        local _dir
        for _dir in gbm nvidia vdpau xorg tls; do
          [[ -d "${_lib}/${_dir}" ]] && mv "${_lib}/${_dir}" "${_lib64}/"
        done
        # Move root-level shared libraries (.so / .so.N / .so.N.N.N …).
        find "${_lib}" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) \
          -exec mv {} "${_lib64}/" \;
      fi

      # 32-bit ELF: usr/lib32 → usr/lib.
      if [[ -d "${_lib32}" ]]; then
        mkdir -p "${_lib}"
        cp -a "${_lib32}/." "${_lib}/"
        rm -rf "${_lib32}"
      fi
      ;;

    debian|ubuntu)
      # 64-bit ELF: usr/lib → usr/lib/x86_64-linux-gnu.
      local _libma="${_pkgdir}/usr/lib/x86_64-linux-gnu"
      if [[ -d "${_lib}" ]]; then
        mkdir -p "${_libma}"
        # Move ELF-containing subdirectories
        local _dir
        for _dir in gbm vdpau tls; do
          [[ -d "${_lib}/${_dir}" ]] && mv "${_lib}/${_dir}" "${_libma}/"
        done
        # Move root-level shared libraries (.so / .so.N / .so.N.N.N …).
        find "${_lib}" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) \
          -exec mv {} "${_libma}/" \;
      fi

      # 32-bit ELF: usr/lib32 → usr/lib/i386-linux-gnu.
      if [[ -d "${_lib32}" ]]; then
        local _libma32="${_pkgdir}/usr/lib/i386-linux-gnu"
        mkdir -p "${_libma32}"
        cp -a "${_lib32}/." "${_libma32}/"
        rm -rf "${_lib32}"
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
  _install_egl_wayland # only on .deb targets
  _install_egl_x11 # only on .deb targets
  _relocate_elfs "${pkgdir}"
}

# staging utilities for 32-bit
_stage_lib32_utils() {
  cd "${srcdir}/${_pkg}/32"
  _install_lib32_utils
  _install_lib32_egl_wayland # only on .deb targets
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

# Staging the DKMS source tree for the DKMS package variant.
_stage_dkms() {
  local _dkms_src

  # Open-source DKMS modules.
  if [[ "${_open_source_modules:-}" = "true" ]]; then
    _dkms_src="${srcdir}/open-gpu-kernel-modules-dkms"

    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "${_dkms_src}" "${pkgdir}/usr/src/nvidia-${pkgver}"
    mv "${pkgdir}/usr/src/nvidia-${pkgver}/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-${pkgver}/dkms.conf"

    # Force module to load even on unsupported GPUs
    mkdir -p "${pkgdir}/usr/lib/modprobe.d"
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
       install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"

    # Debian for early KMS support.
    if [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
      printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia.conf"
    fi

    install -Dm644 "${_dkms_src}/COPYING" "${pkgdir}/usr/share/licenses/${pkgname}/COPYING"
  # Closed-source DKMS modules.
  else
    _dkms_src="${srcdir}/${_pkg}/kernel-dkms"

    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "${_dkms_src}" "${pkgdir}/usr/src/nvidia-${pkgver}"

    install -Dm644 "${srcdir}/${_pkg}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  fi

  # Enable nvidia-uvm autoload at boot
  if [[ "${_blacklist_nouveau}" != "false" ]]; then
    echo "nvidia-uvm" |
      install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia-uvm.conf"
  else
    msg2 "Skipping nvidia-uvm autoload due to user config"
  fi

  # Configure dracut for nvidia kernel modules.
  if command -v dracut &>/dev/null; then
    if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
      echo 'omit_drivers+=" nvidia nvidia-modeset nvidia-uvm nvidia-drm "' | \
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    else
      install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-dracut.conf" "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    fi
  elif [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
    # Debian for early KMS support.
    printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
      install -Dm644 /dev/stdin "${pkgdir}/usr/share/initramfs-tools/modules.d/nvidia-tkg"

    # initramfs hook: embeds DKMS modules from the build directory into the image.
    install -dm755 "${pkgdir}/usr/share/initramfs-tools/hooks"
    cat > "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg" <<'HOOK'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
prereqs) prereqs; exit 0 ;;
esac
. /usr/share/initramfs-tools/hook-functions
for mod in nvidia nvidia-modeset nvidia-uvm nvidia-drm; do
  manual_add_modules "$mod" || true
done
HOOK
    chmod 755 "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg"
  fi
}

# This function is used for the non-DKMS package variant, where we stage precompiled kernel modules directly.
_stage_kmod() {
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)
  local _kernel

  for _kernel in "${_kernels[@]}"; do
    msg2 "Staging kernel modules for ${_kernel}..."

    # Open-source modules.
    if [[ "${_open_source_modules:-}" = "true" ]]; then
      local _open_kmods_dir="${srcdir}/open-kmods/${_kernel}"
      [[ -d "${_open_kmods_dir}" ]] || { error "Missing open kmods for ${_kernel}"; return 1; }

      install -Dt "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -m644 "${_open_kmods_dir}"/*.ko

      # Force module to load even on unsupported GPUs
      mkdir -p "${pkgdir}/usr/lib/modprobe.d"
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"

      # Early KMS autoload for prebuilt package variant.
      if [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
        printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
          install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia.conf"
      fi
    # Closed-source modules.
    else
      install -D -m644 "${srcdir}/${_pkg}/kernel-${_kernel}/"nvidia{,-drm,-modeset,-uvm}.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"

      # Enable nvidia-uvm autoload at boot
      if [[ "${_blacklist_nouveau}" != "false" ]]; then
        echo "nvidia-uvm" |
          install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia-uvm.conf"
      else
        msg2 "Skipping nvidia-uvm autoload due to user config"
      fi
    fi

    # Sign modules for Secure Boot.
    bash "${_where}/nvidia-all-config/nvidia-sign-modules" --mok-stage \
      "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
    find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec gzip -n {} + 2>/dev/null || \
      find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec xz {} +
  done

  # Configure dracut for nvidia kernel modules.
  if command -v dracut &>/dev/null; then
    if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
      echo 'force_drivers+=" nvidia nvidia-modeset nvidia-uvm nvidia-drm "' | \
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    else
      install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-dracut.conf" "${pkgdir}/usr/lib/dracut/dracut.conf.d/nvidia-tkg.conf"
    fi
  elif [[ "${_NV_DISTRO_FAMILY:-}" == "debian" ]]; then
    printf 'nvidia\nnvidia-modeset\nnvidia-drm\nnvidia-uvm\n' | \
      install -Dm644 /dev/stdin "${pkgdir}/usr/share/initramfs-tools/modules.d/nvidia-tkg"

    # initramfs hook: embeds DKMS modules from the build directory into the image.
    install -dm755 "${pkgdir}/usr/share/initramfs-tools/hooks"
    cat > "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg" <<'HOOK'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in
prereqs) prereqs; exit 0 ;;
esac
. /usr/share/initramfs-tools/hook-functions
for mod in nvidia nvidia-modeset nvidia-uvm nvidia-drm; do
  manual_add_modules "$mod" || true
done
HOOK
    chmod 755 "${pkgdir}/usr/share/initramfs-tools/hooks/nvidia-tkg"
  fi
}

# main staging function
_stage_package() {
  local _pkgname="$1" _stagedir="$2"
  pkgdir="${_stagedir}"
  pkgname="${_pkgname}"

  export pkgdir
  source "${_where}/BIG_UGLY_FROGMINER"
  source "${_where}/nvidia-all-config/prepare"
  source "${_where}/nvidia-all-config/install-common"

  case "${_pkgname}" in
    nvidia-dkms-tkg|nvidia-open-dkms-tkg) _stage_dkms ;;
    nvidia-utils-tkg) _stage_utils ;;
    opencl-nvidia-tkg) [[ "${_opencl:-true}" == "true" ]] && _stage_opencl ;;
    nvidia-settings-tkg) [[ "${_nvsettings:-true}" == "true" ]] && _stage_settings ;;
    lib32-nvidia-utils-tkg) [[ "${_lib32:-true}" == "true" ]] && _stage_lib32_utils ;;
    lib32-opencl-nvidia-tkg) [[ "${_opencl:-true}" == "true" && "${_lib32:-true}" == "true" ]] && _stage_lib32_opencl ;;
    nvidia-tkg|nvidia-open-tkg) _stage_kmod ;;
    *) warning "No staging function for ${_pkgname} — skipping." ;;
  esac
}

# package metadata
declare -A _NV_META

_meta_nvidia_utils() {
  local _epoch="$1"
  _NV_META[nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries"
  _NV_META[nvidia-utils-tkg_depends_deb]="libglvnd0, libgl1-mesa-glx | libgl1, libvulkan1"
  _NV_META[nvidia-utils-tkg_depends_rpm]="libglvnd >= 1.3, mesa-libGL, vulkan-loader"
  _NV_META[nvidia-utils-tkg_provides_deb]="nvidia-utils (= ${pkgver}), libgl1-nvidia-glvnd-glx, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_provides_rpm]="nvidia-utils = ${pkgver}, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_conflicts_deb]="nvidia-utils, nvidia-libgl, libgl1-nvidia-legacy-390xx-glx"
  _NV_META[nvidia-utils-tkg_conflicts_rpm]="nvidia-utils, xorg-x11-drv-nvidia, xorg-x11-drv-nvidia-libs, xorg-x11-drv-nvidia-470xx, xorg-x11-drv-nvidia-580xx, nvidia-modprobe, nvidia-persistenced"
  _NV_META[nvidia-utils-tkg_replaces_deb]="nvidia-libgl, libgl1-nvidia-glvnd-glx"

  _NV_META[lib32-nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries (32-bit)"
  _NV_META[lib32-nvidia-utils-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), gcc-multilib, libglvnd0:i386, libvulkan1:i386, libnvidia-egl-wayland1:i386"
  _NV_META[lib32-nvidia-utils-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, glibc(x86-32), libglvnd(x86-32)"
  _NV_META[lib32-nvidia-utils-tkg_provides_deb]="lib32-nvidia-utils (= ${pkgver}), lib32-nvidia-libgl, lib32-vulkan-driver, lib32-opengl-driver"
  _NV_META[lib32-nvidia-utils-tkg_provides_rpm]="lib32-nvidia-utils = ${pkgver}"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_deb]="lib32-nvidia-utils, lib32-nvidia-libgl"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_rpm]="lib32-nvidia-utils, xorg-x11-drv-nvidia-libs-i686, xorg-x11-drv-nvidia-470xx-libs"
  _NV_META[lib32-nvidia-utils-tkg_replaces_deb]="lib32-nvidia-libgl"
}

_meta_nvidia_dkms() {
  local _epoch="$1"
  _NV_META[nvidia-dkms-tkg_desc]="NVIDIA kernel module sources (DKMS)"
  _NV_META[nvidia-dkms-tkg_depends_deb]="dkms, nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${_epoch}, dwarves"
  _NV_META[nvidia-dkms-tkg_provides_deb]="nvidia-kernel-dkms (= ${pkgver}), nvidia-dkms (= ${pkgver}), nvidia-dkms-kernel, NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_provides_rpm]="nvidia-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-tkg, nvidia-open-tkg, nvidia-dkms-kernel"
  _NV_META[nvidia-dkms-tkg_replaces_deb]="nvidia-open-dkms-tkg, nvidia-tkg, nvidia-open-tkg"
  _NV_META[nvidia-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-dkms-tkg_obsoletes_rpm]="nvidia-open-dkms-tkg, nvidia-tkg, nvidia-open-tkg"

  _NV_META[nvidia-open-dkms-tkg_desc]="NVIDIA open kernel module sources (DKMS)"
  _NV_META[nvidia-open-dkms-tkg_depends_deb]="dkms, nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-open-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${_epoch}, dwarves"
  _NV_META[nvidia-open-dkms-tkg_provides_deb]="nvidia-open-kernel-dkms (= ${pkgver}), nvidia-open-dkms (= ${pkgver}), nvidia-dkms-kernel, NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_provides_rpm]="nvidia-open-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms, nvidia-dkms-tkg, nvidia-tkg, nvidia-open-tkg, nvidia-dkms-kernel"
  _NV_META[nvidia-open-dkms-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-tkg, nvidia-open-tkg"
  _NV_META[nvidia-open-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-open-dkms-tkg_obsoletes_rpm]="nvidia-dkms-tkg, nvidia-tkg, nvidia-open-tkg"
}

_meta_nvidia_kmod() {
  local _epoch="$1"
  _NV_META[nvidia-tkg_desc]="NVIDIA kernel modules (prebuilt)"
  _NV_META[nvidia-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, libglvnd"
  _NV_META[nvidia-tkg_provides_deb]="nvidia (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-tkg_provides_rpm]="nvidia = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-dkms-tkg, nvidia-open, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-open-tkg"
  _NV_META[nvidia-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-open-tkg"
  _NV_META[nvidia-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-open, nvidia-open-kmod, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-tkg_obsoletes_rpm]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-open-tkg"

  _NV_META[nvidia-open-tkg_desc]="NVIDIA open kernel modules (prebuilt)"
  _NV_META[nvidia-open-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-open-tkg_depends_rpm]="nvidia-utils-tkg = ${_epoch}, libglvnd"
  _NV_META[nvidia-open-tkg_provides_deb]="nvidia-open (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-open-tkg_provides_rpm]="nvidia-open = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-open-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-dkms-tkg, nvidia-open, nvidia-open-dkms, nvidia-open-dkms-tkg, nvidia-tkg"
  _NV_META[nvidia-open-tkg_replaces_deb]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-tkg"
  _NV_META[nvidia-open-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-kmod, nvidia-open, akmod-nvidia, akmod-nvidia-open"
  _NV_META[nvidia-open-tkg_obsoletes_rpm]="nvidia-dkms-tkg, nvidia-open-dkms-tkg, nvidia-tkg"
}

_meta_opencl() {
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
  _NV_META[nvidia-settings-tkg_depends_deb]="nvidia-utils-tkg (>= ${pkgver}), libjansson4"
  _NV_META[nvidia-settings-tkg_recommends_deb]="libgtk-3-0 | libgtk-3-0t64, libxv1 | libxv1t64, libvdpau1 | libvdpau1t64"
  _NV_META[nvidia-settings-tkg_depends_rpm]="nvidia-utils-tkg >= ${_epoch}, jansson"
  _NV_META[nvidia-settings-tkg_suggests_rpm]="gtk3, libXv, libvdpau"
  _NV_META[nvidia-settings-tkg_provides_deb]="nvidia-settings (= ${pkgver})"
  _NV_META[nvidia-settings-tkg_provides_rpm]="nvidia-settings = ${pkgver}"
  _NV_META[nvidia-settings-tkg_conflicts_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_replaces_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_conflicts_rpm]="nvidia-settings"
}

_build_metadata() {
  local _rpm_pkgver_epoch="3:${pkgver}"

  _meta_nvidia_utils "${_rpm_pkgver_epoch}"
  _meta_nvidia_dkms "${_rpm_pkgver_epoch}"
  _meta_nvidia_kmod "${_rpm_pkgver_epoch}"
  _meta_opencl
  _meta_nvidia_settings "${_rpm_pkgver_epoch}"

  # Fedora-specific metadata tuning based on available runtime package names.
  if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]]; then
    _NV_META[nvidia-utils-tkg_depends_rpm]+=", pciutils, which, egl-wayland, egl-wayland2, egl-gbm, egl-x11"
    _NV_META[nvidia-utils-tkg_suggests_rpm]="acpica-tools, vulkan-tools"
    _NV_META[opencl-nvidia-tkg_depends_rpm]="zlib, opencl-filesystem, libOpenCL.so.1()(64bit)"

    # libxnvctrl: bundled inside nvidia-settings-tkg ("true") or expected
    # as a system RPM ("external"); "false" means compiled without support.
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

  # detect Ubuntu-style versioned NVIDIA packages
  if command -v dpkg &>/dev/null && [[ "${_NV_PKG_TARGET:-}" =~ ^(debian|ubuntu)$ ]]; then
    if (( ${pkgver%%.*} >= 470 )); then
      # Debian/Ubuntu consume egl-gbm from distro.
      _NV_META[nvidia-utils-tkg_depends_deb]+=", libnvidia-egl-wayland1, libnvidia-egl-gbm1"
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

    local _entry _pat _key _pkgs
    for _entry in "${_cr_map[@]}"; do
      _pat="${_entry%%:*}"
      _key="${_entry##*:}"
      _pkgs=$(dpkg -l "${_pat}" 2>/dev/null | awk '/^ii/ {print $2}' | paste -sd', ' || true)
      if [[ -n "${_pkgs}" ]]; then
        _NV_META[${_key}_conflicts_deb]+=", ${_pkgs}"
        _NV_META[${_key}_replaces_deb]+=", ${_pkgs}"
      fi
    done

    # Special case two packages, no replaces
    local _u_nvdkms_open
    _u_nvdkms_open=$(dpkg -l 'nvidia-dkms-[0-9]*-open' 2>/dev/null | awk '/^ii/ {print $2}' | paste -sd', ' || true)
    if [[ -n "${_u_nvdkms_open}" ]]; then
      _NV_META[nvidia-dkms-tkg_conflicts_deb]+=", ${_u_nvdkms_open}"
      _NV_META[nvidia-open-dkms-tkg_conflicts_deb]+=", ${_u_nvdkms_open}"
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

# .deb builder
_build_deb() {
  local _pkgname="$1" _stagedir="$2" _outdir="$3"
  local _debdir="${_outdir}/${_pkgname}_${pkgver}_amd64"
  mkdir -p "${_debdir}/DEBIAN"
  cp -a "${_stagedir}/." "${_debdir}/"
  local _inst_size
  _inst_size=$(du -sk "${_stagedir}" | cut -f1)
  cat > "${_debdir}/DEBIAN/control" <<EOF
Package: ${_pkgname}
Version: ${pkgver}
Architecture: amd64
Maintainer: nvidia-all-tkg <https://github.com/Frogging-Family/nvidia-all>
Installed-Size: ${_inst_size}
Description: ${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}
EOF
  local _deps="${_NV_META[${_pkgname}_depends_deb]:-}"
  [[ -n "${_deps}" ]] && echo "Depends: ${_deps}" >> "${_debdir}/DEBIAN/control"
  local _recs="${_NV_META[${_pkgname}_recommends_deb]:-}"
  [[ -n "${_recs}" ]] && echo "Recommends: ${_recs}" >> "${_debdir}/DEBIAN/control"
  local _prov="${_NV_META[${_pkgname}_provides_deb]:-}"
  [[ -n "${_prov}" ]] && echo "Provides: ${_prov}" >> "${_debdir}/DEBIAN/control"
  local _conf="${_NV_META[${_pkgname}_conflicts_deb]:-}"
  [[ -n "${_conf}" ]] && echo "Conflicts: ${_conf}" >> "${_debdir}/DEBIAN/control"
  local _repl="${_NV_META[${_pkgname}_replaces_deb]:-}"
  [[ -n "${_repl}" ]] && echo "Replaces: ${_repl}" >> "${_debdir}/DEBIAN/control"

  if [[ "${_pkgname}" == *dkms* ]]; then
    # Derive the DKMS module name from the staged dkms.conf so that postinst
    # and prerm stay consistent with the source tree without hardcoding "nvidia".
    local _nv_dkms_name
    _nv_dkms_name=$(grep -Po 'PACKAGE_NAME="\K[^"]+' \
      "${_stagedir}/usr/src/nvidia-${pkgver}/dkms.conf" 2>/dev/null || echo "nvidia")
    cat > "${_debdir}/DEBIAN/postinst" <<POSTINST
#!/bin/sh
set -e
DKMS_NAME=${_nv_dkms_name}
DKMS_VERSION=${pkgver}
DKMS_PACKAGE_NAME=${_pkgname}

case "\$1" in
  configure)
    # Update initramfs first so the nouveau blacklist ends up in the initramfs
    if command -v update-initramfs >/dev/null 2>&1; then
      update-initramfs -u
    fi
    postinst_found=0
    # Prefer Debian/Ubuntu standard DKMS helper
    if [ -f /usr/lib/dkms/common.postinst ]; then
      _ARCH="\$(dpkg --print-architecture 2>/dev/null | sed 's/amd64/x86_64/;s/i386/i686/')"
      /usr/lib/dkms/common.postinst "\$DKMS_NAME" "\$DKMS_VERSION" "" "\$_ARCH" "\$2"
      postinst_found=1
    fi
    if [ "\$postinst_found" -eq 0 ]; then
      # Manual DKMS steps if common.postinst is missing.
      echo "WARNING: /usr/lib/dkms/common.postinst not found — using manual DKMS fallback." >&2
      dkms add -m "\$DKMS_NAME" -v "\$DKMS_VERSION" || true
      dkms build -m "\$DKMS_NAME" -v "\$DKMS_VERSION"
      dkms install -m "\$DKMS_NAME" -v "\$DKMS_VERSION"
    fi
    if command -v update-initramfs >/dev/null 2>&1; then
      update-initramfs -u -k all
    elif command -v dracut >/dev/null 2>&1; then
      dracut --force
    fi
    systemctl daemon-reload 2>/dev/null || true
    ;;
esac
POSTINST
  elif [[ "${_pkgname}" == nvidia-tkg || "${_pkgname}" == nvidia-open-tkg ]]; then
    cat > "${_debdir}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
ldconfig
for moddir in /lib/modules/*; do
  [ -d "$moddir" ] || continue
  kver=${moddir##*/}
  depmod -a "$kver" 2>/dev/null || true
done
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all
elif command -v dracut >/dev/null 2>&1; then
  dracut --force
fi
systemctl daemon-reload 2>/dev/null || true
POSTINST
  elif [[ "${_pkgname}" == nvidia-utils-tkg ]]; then
    cat > "${_debdir}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
ldconfig
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all
elif command -v dracut >/dev/null 2>&1; then
  dracut --force
fi
POSTINST
  else
    cat > "${_debdir}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
ldconfig
POSTINST
  fi
  chmod 755 "${_debdir}/DEBIAN/postinst"

  if [[ "${_pkgname}" == *dkms* ]]; then
    cat > "${_debdir}/DEBIAN/prerm" <<PRERM
#!/bin/sh
set -e
DKMS_NAME=${_nv_dkms_name}
DKMS_VERSION=${pkgver}

case "\$1" in
  remove|upgrade|deconfigure)
    if [ "\$(dkms status -m "\$DKMS_NAME" -v "\$DKMS_VERSION" 2>/dev/null)" ]; then
      dkms remove -m "\$DKMS_NAME" -v "\$DKMS_VERSION" --all
    fi
    ;;
esac
PRERM
    chmod 755 "${_debdir}/DEBIAN/prerm"
  elif [[ "${_pkgname}" == nvidia-tkg || "${_pkgname}" == nvidia-open-tkg ]]; then
    cat > "${_debdir}/DEBIAN/prerm" <<'PRERM'
#!/bin/sh
set -e
case "$1" in
  remove|upgrade|deconfigure)
    for moddir in /lib/modules/*; do
      [ -d "$moddir" ] || continue
      kver=${moddir##*/}
      depmod -a "$kver" 2>/dev/null || true
    done
    ;;
esac
PRERM
    chmod 755 "${_debdir}/DEBIAN/prerm"
  fi

  if [[ "${_pkgname}" == *dkms* ]]; then
    cat > "${_debdir}/DEBIAN/postrm" <<'POSTRM'
#!/bin/sh
ldconfig
for moddir in /lib/modules/*; do
  [ -d "$moddir" ] || continue
  kver=${moddir##*/}
  depmod -a "$kver" 2>/dev/null
done
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all 2>/dev/null || true
elif command -v dracut >/dev/null 2>&1; then
  dracut --force 2>/dev/null || true
fi
POSTRM
  else
    cat > "${_debdir}/DEBIAN/postrm" <<'POSTRM'
#!/bin/sh
ldconfig
for moddir in /lib/modules/*; do
  [ -d "$moddir" ] || continue
  kver=${moddir##*/}
  depmod -a "$kver" 2>/dev/null
done
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all 2>/dev/null || true
elif command -v dracut >/dev/null 2>&1; then
  dracut --force 2>/dev/null || true
fi
POSTRM
  fi
  chmod 755 "${_debdir}/DEBIAN/postrm"

  fakeroot dpkg-deb --build "${_debdir}" "${_outdir}/${_pkgname}_${pkgver}_amd64.deb"
  rm -rf "${_debdir}"
  msg2 "Built: ${_outdir}/${_pkgname}_${pkgver}_amd64.deb"
}

# .rpm builder
_build_rpm() {
  local _pkgname="$1" _stagedir="$2" _outdir="$3"
  local _specfile="${_outdir}/${_pkgname}.spec"
  local _is_fedora=false
  local _dracutopts="rd.driver.blacklist=nouveau,nova_core,nova_drm modprobe.blacklist=nouveau,nova_core,nova_drm"
  if (( ${pkgver%%.*} >= 470 && ${pkgver%%.*} < 580 )); then
    _dracutopts+=" nvidia-drm.modeset=1"
    if (( ${pkgver%%.*} >= 520 )); then
      _dracutopts+=" nvidia-drm.fbdev=1"
    fi
  fi

  [[ "${_NV_PKG_TARGET:-}" == "fedora" ]] && _is_fedora=true

  cat > "${_specfile}" <<SPEC
Name: ${_pkgname}
Epoch: 3
Version: ${pkgver}
Release: 1%{?dist}
Summary: ${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}
License: custom:NVIDIA
URL: https://github.com/Frogging-Family/nvidia-all
AutoReqProv: no
SPEC

  # Suppress the architecture-mismatch check that would otherwise terminate the build.
  if [[ "${_pkgname}" == lib32-* ]]; then
    echo "%define __arch_install_post %{nil}" >> "${_specfile}"
  fi

  local _deps="${_NV_META[${_pkgname}_depends_rpm]:-}"
  if [[ -n "${_deps}" ]]; then
    IFS=',' read -ra _dep_arr <<< "${_deps}"
    for _d in "${_dep_arr[@]}"; do
      _d="${_d#"${_d%%[! ]*}"}"
      _d="${_d%"${_d##*[! ]}"}"
      [[ -n "${_d}" ]] && echo "Requires: ${_d}" >> "${_specfile}"
    done
  fi
  local _prov="${_NV_META[${_pkgname}_provides_rpm]:-}"
  if [[ -n "${_prov}" ]]; then
    IFS=',' read -ra _prov_arr <<< "${_prov}"
    for _p in "${_prov_arr[@]}"; do
      _p="${_p#"${_p%%[! ]*}"}"
      _p="${_p%"${_p##*[! ]}"}" 
      [[ -n "${_p}" ]] && echo "Provides: ${_p}" >> "${_specfile}"
    done
  fi
  local _conf="${_NV_META[${_pkgname}_conflicts_rpm]:-}"
  if [[ -n "${_conf}" ]]; then
    IFS=',' read -ra _conf_arr <<< "${_conf}"
    for _c in "${_conf_arr[@]}"; do
      _c="${_c#"${_c%%[! ]*}"}"
      _c="${_c%"${_c##*[! ]}"}" 
      [[ -n "${_c}" ]] && echo "Conflicts: ${_c}" >> "${_specfile}"
    done
  fi
  local _obso="${_NV_META[${_pkgname}_obsoletes_rpm]:-}"
  if [[ -n "${_obso}" ]]; then
    IFS=',' read -ra _obso_arr <<< "${_obso}"
    for _o in "${_obso_arr[@]}"; do
      _o="${_o#"${_o%%[! ]*}"}"
      _o="${_o%"${_o##*[! ]}"}"
      [[ -n "${_o}" ]] && echo "Obsoletes: ${_o}" >> "${_specfile}"
    done
  fi
  local _sugg="${_NV_META[${_pkgname}_suggests_rpm]:-}"
  if [[ -n "${_sugg}" ]]; then
    IFS=',' read -ra _sugg_arr <<< "${_sugg}"
    for _s in "${_sugg_arr[@]}"; do
      _s="${_s#"${_s%%[! ]*}"}"
      _s="${_s%"${_s##*[! ]}"}"
      [[ -n "${_s}" ]] && echo "Suggests: ${_s}" >> "${_specfile}"
    done
  fi
  local _reco="${_NV_META[${_pkgname}_recommends_rpm]:-}"
  if [[ -n "${_reco}" ]]; then
    IFS=',' read -ra _reco_arr <<< "${_reco}"
    for _r in "${_reco_arr[@]}"; do
      _r="${_r#"${_r%%[! ]*}"}"
      _r="${_r%"${_r##*[! ]}"}"
      [[ -n "${_r}" ]] && echo "Recommends: ${_r}" >> "${_specfile}"
    done
  fi

  cat >> "${_specfile}" <<SPEC

%description
${_NV_META[${_pkgname}_desc]:-NVIDIA driver package} version ${pkgver}.

%install
cp -a ${_stagedir}/. %{buildroot}/

SPEC

  # DKMS packages need dkms add/build/install in %post and dkms remove in %preun.
  # All other packages only need ldconfig + depmod.
  if [[ "${_pkgname}" == *dkms* ]]; then
    local _nv_dkms_name
    _nv_dkms_name=$(grep -Po 'PACKAGE_NAME="\K[^"]+' \
      "${_stagedir}/usr/src/nvidia-${pkgver}/dkms.conf" 2>/dev/null || echo "nvidia")
    cat >> "${_specfile}" <<SPEC
%post
if command -v dkms >/dev/null 2>&1; then
  dkms add -m ${_nv_dkms_name} -v ${pkgver} || true
  dkms build -m ${_nv_dkms_name} -v ${pkgver} || true
  dkms install -m ${_nv_dkms_name} -v ${pkgver} || true
fi
if command -v dracut >/dev/null 2>&1; then
  dracut --force 2>/dev/null || true
fi
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload || true
fi
exit 0

SPEC
    if [[ "${_is_fedora}" == true ]]; then
      cat >> "${_specfile}" <<SPEC
%posttrans
if [ "\${1:-0}" -eq "1" ] && command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args='nomodeset' --args='${_dracutopts}' >/dev/null 2>&1 || true
fi
exit 0

SPEC
    fi
    cat >> "${_specfile}" <<SPEC
%preun
if command -v dkms >/dev/null 2>&1; then
  if dkms status -m ${_nv_dkms_name} -v ${pkgver} 2>/dev/null | grep -q .; then
    dkms remove -m ${_nv_dkms_name} -v ${pkgver} --all || true
  fi
fi
SPEC
    if [[ "${_is_fedora}" == true ]]; then
      cat >> "${_specfile}" <<SPEC
if [ "\${1:-0}" -eq "0" ] && command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args='${_dracutopts}' >/dev/null 2>&1 || true
fi
SPEC
    fi
    cat >> "${_specfile}" <<SPEC
exit 0

%postun
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
if command -v dracut >/dev/null 2>&1; then
  dracut --force 2>/dev/null || true
fi
exit 0

SPEC
  elif [[ "${_pkgname}" == nvidia-tkg || "${_pkgname}" == nvidia-open-tkg ]]; then
    cat >> "${_specfile}" <<SPEC
%post
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
for moddir in /lib/modules/*; do
  [ -d "\$moddir" ] || continue
  kver=\${moddir##*/}
  if command -v depmod >/dev/null 2>&1; then
    depmod -a "\$kver" || true
  fi
done
if command -v dracut >/dev/null 2>&1; then
  dracut --force 2>/dev/null || true
fi
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload || true
fi
exit 0

%postun
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
exit 0

SPEC
    if [[ "${_is_fedora}" == true ]]; then
      cat >> "${_specfile}" <<SPEC
%posttrans
if [ "\${1:-0}" -eq "1" ] && command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args='nomodeset' --args='${_dracutopts}' >/dev/null 2>&1 || true
fi
exit 0

%preun
if [ "\${1:-0}" -eq "0" ] && command -v grubby >/dev/null 2>&1; then
  grubby --update-kernel=ALL --remove-args='${_dracutopts}' >/dev/null 2>&1 || true
fi
exit 0

SPEC
    fi
  else
    cat >> "${_specfile}" <<SPEC
%post
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
SPEC
    if [[ "${_is_fedora}" == true ]]; then
      cat >> "${_specfile}" <<'SPEC'
# Restore SELinux file contexts for NVIDIA shared libraries.
if command -v restorecon >/dev/null 2>&1; then
  restorecon -Rv /usr/lib64/ /usr/lib/ /usr/share/glvnd/ 2>/dev/null || true
fi
SPEC
    fi
    cat >> "${_specfile}" <<'SPEC'
exit 0

%postun
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
exit 0

SPEC
  fi

  cat >> "${_specfile}" <<SPEC
%files
SPEC

  # %files list: one path per line, appended directly under the %files header.
  find "${_stagedir}" -type f -o -type l | sed "s|^${_stagedir}||" >> "${_specfile}"

  # Minimal %changelog entry to suppress the Fedora RPM macro warning.
  {
    echo ""
    echo "%changelog"
    echo "* $(LC_ALL=C date +'%a %b %d %Y') nvidia-all-tkg <build@nvidia-all> - ${pkgver}-1"
    echo "- Automated build of NVIDIA ${pkgver}"
  } >> "${_specfile}"

  rpmbuild -bb \
    --define "_rpmdir ${_outdir}" \
    --define "_build_name_fmt ${_pkgname}-${pkgver}-1.x86_64.rpm" \
    --define "debug_package %{nil}" \
    --define "__os_install_post %{nil}" \
    --define "_build_id_links none" \
    --define "_unpackaged_files_terminate_build 0" \
    "${_specfile}"
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
    _build_deb "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}_${pkgver}_amd64.deb")
  else
    _build_rpm "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}-${pkgver}-1.x86_64.rpm")
  fi

  rm -rf "${_pkgstage}"
done

msg2 "All packages written to: ${_distdir}"
ls -lh "${_distdir}"/*.${PKG_FORMAT}
msg2 "Packages from current run:"
printf '  %s\n' "${_built_pkg_files[@]}"
plain ""

# Shared helper: check and enroll the MOK signing key if Secure Boot is active.
_enroll_mok_if_needed() {
  if ! command -v mokutil &>/dev/null; then
    warning "Secure Boot is active, but mokutil is not installed. Cannot verify or enroll the MOK key."
    warning "Install mokutil and rerun the installer, or disable Secure Boot."
    return 0
  fi

  mokutil --sb-state 2>/dev/null | grep -qi 'secure boot enabled' || return 0
  msg2 "Secure Boot is active — checking MOK key enrollment..."

  _mok_pub=""
  [[ -f /var/lib/dkms/mok.pub ]] && _mok_pub="/var/lib/dkms/mok.pub"
  [[ -z "${_mok_pub}" && -f /var/lib/nvidia-all/mok/mok.der ]] && _mok_pub="/var/lib/nvidia-all/mok/mok.der"

  if [[ -n "${_mok_pub}" ]]; then
    if ! mokutil --test-key "${_mok_pub}" 2>/dev/null | grep -qi 'already enrolled'; then
      msg2 "Enrolling MOK signing key. Enter a one-time password when prompted."
      msg2 "At the next reboot, select 'Enroll MOK' and enter that password."
      sudo mokutil --import "${_mok_pub}"
      warning "REBOOT REQUIRED to complete MOK enrollment."
      warning "Without this, kernel modules will not load under Secure Boot."
    else
      msg2 "MOK key already enrolled — Secure Boot is OK."
    fi
  else
    warning "Secure Boot is active but no MOK key found."
    warning "After building/installing DKMS, run:"
    warning "  sudo mokutil --import /var/lib/dkms/mok.pub"
  fi
}

case "$PKG_FORMAT" in
  rpm)
    _rpm_install_hint="sudo rpm -Uvh --force --nodeps '${_distdir}'/*.rpm"
    _rpm_install_cmd=(sudo rpm -Uvh --force --nodeps "${_distdir}"/*.rpm)
    case "${_NV_PKG_TARGET:-}" in
      fedora)
        _rpm_install_hint="sudo dnf install --nogpgcheck --allowerasing '${_distdir}'/*.rpm"
        _rpm_install_cmd=(sudo dnf install --nogpgcheck --allowerasing "${_distdir}"/*.rpm)
        ;;
      suse)
        _rpm_install_hint="sudo zypper install --no-gpg-checks --force '${_distdir}'/*.rpm"
        _rpm_install_cmd=(sudo zypper install --no-gpg-checks --force -y "${_distdir}"/*.rpm)
        ;;
    esac

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
      # On Fedora (SELinux Enforcing), restore library file contexts
      if [[ "${_NV_PKG_TARGET:-}" == "fedora" ]] && command -v restorecon &>/dev/null; then
        msg2 "Restoring SELinux file contexts for NVIDIA libraries..."
        sudo restorecon -Rv /usr/lib64/ /usr/lib/ || true
      fi
      # Secure Boot: enroll the signing key if needed.
      _enroll_mok_if_needed
      msg2 "Installation complete. A system reboot is recommended."
    else
      msg2 "Skipping installation. Packages remain in: ${_distdir}"
    fi
    ;;
  deb)
    msg2 "To install manually:"
    msg2 "  sudo apt-get install '${_distdir}'/*.deb"
    plain ""

    if [[ "${_set_default:-}" =~ ^(true|1|yes|y)$ ]]; then
      _install_ans="y"
      msg2 "Auto-accepting package installation (default: Y)"
    else
      read -rp " -> Install the built DEB packages now? [Y/n]: " _install_ans
    fi

    if [[ -z "${_install_ans}" || "${_install_ans}" =~ ^[Yy] ]]; then
      msg2 "Installing packages via apt..."
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall "${_built_pkg_files[@]}"
      # Debian/Ubuntu + Secure Boot: enroll the signing key so kernel modules load.
      _enroll_mok_if_needed
      msg2 "Installation complete. A system reboot is recommended."
    else
      msg2 "Skipping installation. Packages remain in: ${_distdir}"
    fi
    ;;
esac
exit 0

# vim: set ft=sh ts=2 sw=2 et:
