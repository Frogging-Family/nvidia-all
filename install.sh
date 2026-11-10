#!/usr/bin/env bash

# Stop the script at any encountered error
set -e

_where=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
srcdir="${_where}"

# Command used for superuser privileges (`sudo`, `doas`, `su`)
if [[ ! -x "$(command -v sudo)" ]]; then
  sudo() { "${_where}/nvidia-all-config/run-root" "$@"; }
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

# Keep package transaction output visible and preserve failures from the command or tee.
_run_package_install() (
  set -o pipefail
  mkdir -p "${_where}/logs"
  "$@" 2>&1 | tee -a "${_where}/logs/install.log.txt"
)

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

source "${_where}/nvidia-all-config/install-deb"
source "${_where}/nvidia-all-config/install-rpm"

_frog_banner

# Install prerequisites before resolving driver versions and preparing sources.
if ! command -v curl &>/dev/null || ! command -v bsdtar &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    _deb_install_prerequisites
  elif command -v dnf &>/dev/null; then
    _rpm_install_prerequisites dnf
  elif command -v zypper &>/dev/null; then
    _rpm_install_prerequisites zypper
  else
    _die "curl/bsdtar not found and no known package manager to install them."
  fi
fi

# Create BIG_UGLY_FROGMINER only on first run and save in it all settings
_NV_INSTALL_MODE="package"
_frogminer_bootstrap "${_where}/BIG_UGLY_FROGMINER" "${_where}/BIG_UGLY_FROGMINER.pending"

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
    if [[ "${_distro}" = "Debian" ]]; then
      _NV_PKG_TARGET="debian"
      return 0
    elif [[ "${_distro}" = "Ubuntu" ]]; then
      _NV_PKG_TARGET="ubuntu"
      return 0
    elif [[ "${_distro}" = "Fedora" ]]; then
      _NV_PKG_TARGET="fedora"
      return 0
    elif [[ "${_distro}" = "Suse" ]]; then
      _NV_PKG_TARGET="suse"
      return 0
    else
      warning "_distro='${_distro}' is not a valid value. Valid values: Debian, Ubuntu, Fedora, Suse — prompting..."
    fi
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
  if [[ "${_selected_value}" = "Debian" ]]; then
    _NV_PKG_TARGET="debian"
  elif [[ "${_selected_value}" = "Ubuntu" ]]; then
    _NV_PKG_TARGET="ubuntu"
  elif [[ "${_selected_value}" = "Fedora" ]]; then
    _NV_PKG_TARGET="fedora"
  elif [[ "${_selected_value}" = "Suse" ]]; then
    _NV_PKG_TARGET="suse"
  else
    _die "Unsupported distribution. Only Debian, Ubuntu, Fedora and Suse are supported by the direct installer."
  fi
}
_distro_prompt

# Install build dependencies
_install_dependencies() {
  msg2 "Installing build dependencies for ${_NV_PKG_TARGET}..."
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)

  case "${_NV_PKG_TARGET}" in
    debian|ubuntu) _deb_install_dependencies "${_kernels[@]}" ;;
    fedora|suse) _rpm_install_dependencies "${_kernels[@]}" ;;
    *) _die "Unsupported distribution '${_NV_PKG_TARGET}'. Only Debian, Ubuntu, Fedora and Suse are supported." ;;
  esac
}
_install_dependencies

_install_mode() {
  if [[ "${_NV_PKG_TARGET}" != "debian" && "${_NV_PKG_TARGET}" != "ubuntu" &&
        "${_NV_PKG_TARGET}" != "fedora" && "${_NV_PKG_TARGET}" != "suse" ]]; then
    return 0
  fi

  # Build a native distro package
  if [[ -z "${PKG_FORMAT:-}" ]]; then
    if [[ "${_NV_PKG_TARGET}" = "debian" || "${_NV_PKG_TARGET}" = "ubuntu" ]]; then
      PKG_FORMAT="deb"
    elif [[ "${_NV_PKG_TARGET}" = "fedora" || "${_NV_PKG_TARGET}" = "suse" ]]; then
      PKG_FORMAT="rpm"
    fi
  fi
  msg2 "Package format: ${PKG_FORMAT}"

  # _build_utils_package_only is an Arch/PKGBUILD-only
  if [[ "${_build_utils_package_only:-false}" == "true" ]]; then
    msg2 "_build_utils_package_only ignored for ${PKG_FORMAT} package builds — forcing false."
    _build_utils_package_only="false"
  fi

  if [[ "$PKG_FORMAT" = "deb" ]]; then
    _deb_install_build_tools
  elif [[ "$PKG_FORMAT" = "rpm" ]]; then
    _rpm_install_build_tools
  fi
}
_install_mode

# Relocate ELF shared libraries to the distribution-canonical library prefix
_relocate_elfs() {
  if [[ "${_NV_PKG_TARGET:-}" = "debian" || "${_NV_PKG_TARGET:-}" = "ubuntu" ]]; then
    _deb_relocate_elfs "$1"
  elif [[ "${_NV_PKG_TARGET:-}" = "fedora" || "${_NV_PKG_TARGET:-}" = "suse" ]]; then
    _rpm_relocate_elfs "$1"
  fi
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

# staging Flatpak driver extensions
_stage_flatpak() {
  cd "${srcdir}/${_pkg}" || return
  # Flatpak has its own runtime layout; do not relocate these libraries.
  _install_flatpak
}

_stage_lib32_flatpak() {
  cd "${srcdir}/${_pkg}" || return
  _install_lib32_flatpak
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

  for _kernel in "${_kernels[@]}"; do
    msg2 "Staging kernel modules for ${_kernel}..."

    # Open-source modules.
    if [[ "${_open_source_modules:-}" = "true" ]]; then
      # Force module to load even on unsupported GPUs
      mkdir -p "${pkgdir}/usr/lib/modprobe.d"
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"
    # Closed-source modules.
    else
      # Enable NVIDIA DRM KMS for proprietary modules.
      _stage_closed_drm_kms
    fi

    _install_kernel_modules "${_kernel}"
  done
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
}

# main staging function
_stage_package() {
  pkgdir="$2"
  pkgname="$1"

  source "${_where}/BIG_UGLY_FROGMINER"
  source "${_where}/nvidia-all-config/prepare"
  source "${_where}/nvidia-all-config/install-common"

  if [[ "${pkgname}" = "nvidia-dkms-tkg" || "${pkgname}" = "nvidia-open-dkms-tkg" ]]; then
    _stage_dkms
  elif [[ "${pkgname}" = "nvidia-utils-tkg" ]]; then
    _stage_utils
  elif [[ "${pkgname}" = "opencl-nvidia-tkg" ]]; then
    [[ "${_opencl:-true}" == "true" ]] && _stage_opencl
  elif [[ "${pkgname}" = "nvidia-settings-tkg" ]]; then
    [[ "${_nvsettings:-true}" == "true" ]] && _stage_settings
  elif [[ "${pkgname}" = "lib32-nvidia-utils-tkg" ]]; then
    [[ "${_lib32:-true}" == "true" ]] && _stage_lib32_utils
  elif [[ "${pkgname}" = "lib32-opencl-nvidia-tkg" ]]; then
    [[ "${_opencl:-true}" == "true" && "${_lib32:-true}" == "true" ]] && _stage_lib32_opencl
  elif [[ "${pkgname}" = "flatpak-nvidia-tkg" ]]; then
    [[ "${_flatpak:-false}" == "true" ]] && _stage_flatpak
  elif [[ "${pkgname}" = "lib32-flatpak-nvidia-tkg" ]]; then
    [[ "${_flatpak:-false}" == "true" && "${_lib32:-true}" == "true" ]] && _stage_lib32_flatpak
  elif [[ "${pkgname}" = "nvidia-tkg" || "${pkgname}" = "nvidia-open-tkg" ]]; then
    _stage_kmod
  else
    warning "No staging function for ${pkgname} — skipping."
  fi
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

_build_metadata() {
  _NV_META[nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries"
  _NV_META[lib32-nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries (32-bit)"
  _NV_META[flatpak-nvidia-tkg_desc]="NVIDIA driver extension for Flatpak, matching the host driver"
  _NV_META[lib32-flatpak-nvidia-tkg_desc]="NVIDIA driver extension for Flatpak, matching the host driver (32-bit)"
  _NV_META[nvidia-dkms-tkg_desc]="NVIDIA kernel module sources (DKMS)"
  _NV_META[nvidia-open-dkms-tkg_desc]="NVIDIA open kernel module sources (DKMS)"
  _NV_META[nvidia-tkg_desc]="NVIDIA kernel modules (prebuilt)"
  _NV_META[nvidia-open-tkg_desc]="NVIDIA open kernel modules (prebuilt)"
  _NV_META[opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation"
  _NV_META[lib32-opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation (32-bit)"
  _NV_META[nvidia-settings-tkg_desc]="NVIDIA GPU configuration tool"

  _deb_build_metadata
  _rpm_build_metadata
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
  if [[ "${_flatpak:-false}" == "true" ]]; then
    _list+=("flatpak-nvidia-tkg")
    [[ "${_lib32:-false}" == "true" ]] && _list+=("lib32-flatpak-nvidia-tkg")
  fi
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
  local _template="$1" _content _include _marker _path _snippet
  local _tmpl_kernels="${_package_kernels:-}"
  if [[ "${_dkms:-false}" == true && -z "${_kerneloverride:-}" ]]; then
    _tmpl_kernels=""
  fi
  _content="$(<"$(_pkg_template_path "${_template}")")"
  # Keep complete package scripts in templates; include shared and optional steps.
  for _include in \
    KERNEL_FUNCTIONS:common/kernel-functions.in \
    REMOVE_FUNCTIONS:common/kmod-remove.in \
    SERVICE_FUNCTIONS:common/nvidia-services.in \
    KMOD_POSTINST:common/kmod-postinst.in \
    FEDORA_DKMS_POSTTRANS:rpm/dkms-fedora-posttrans.in \
    FEDORA_DKMS_PREUN:rpm/dkms-fedora-preun.in \
    FEDORA_KMOD_POSTTRANS:rpm/kmod-fedora-scriptlets.in \
    FEDORA_KMOD_PREUN:rpm/kmod-fedora-preun.in \
    FEDORA_RESTORECON:rpm/default-fedora-restorecon.in; do
    _marker="@${_include%%:*}@"
    [[ "${_content}" == *"${_marker}"* ]] || continue
    _path="${_include#*:}"
    if [[ "${_include}" == FEDORA_* && "${_NV_PKG_TARGET:-}" != fedora ]]; then
      _path=""
    fi
    _snippet=""
    [[ -z "${_path}" ]] || _snippet="$(_render_pkg_template "${_path}")"
    _content="${_content//"${_marker}"/"${_snippet}"}"
  done
  _content="${_content//@KERNELS@/${_tmpl_kernels:-}}"
  _content="${_content//@PKGNAME@/${_tmpl_pkgname:-}}"
  _content="${_content//@PKGVER@/${pkgver}}"
  _content="${_content//@PKGREL@/${_pkgrel}}"
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

# Verify every selected kernel before reporting a completed DKMS installation.
_verify_dkms_install() {
  local _verify_kernels="${_package_kernels:-}" _build _kernel _status
  if [[ -z "${_kerneloverride:-}" ]]; then
    _verify_kernels=""
    for _build in /usr/lib/modules/*/build; do
      [[ -d "${_build}" ]] || continue
      _kernel="${_build%/build}"
      _verify_kernels+="${_kernel##*/}"$'\n'
    done
  fi
  [[ -n "${_verify_kernels}" ]] || _die "No selected kernel headers found for NVIDIA DKMS."
  while IFS= read -r _kernel; do
    [[ -n "${_kernel}" ]] || continue
    _status="$(sudo dkms status -m "${_built_dkms_name}" -v "${pkgver}" -k "${_kernel}" -a "$(uname -m)")"
    if [[ "${_status}" != *": installed"* ]]; then
      _die "NVIDIA DKMS ${pkgver} is not installed for ${_kernel}. Check the package transaction output and DKMS build log before rebooting."
    fi
  done <<< "${_verify_kernels}"
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

_package_kernels="$(_detect_kernels)"
_build_metadata
IFS=' ' read -ra _packages <<< "$(_build_pkg_list)"
msg2 "Packages to build: ${_packages[*]}"
declare -a _built_pkg_files=()

for _pkgname in "${_packages[@]}"; do
  msg2 "Staging ${_pkgname}"
  _pkgstage="${srcdir}/stage-${_pkgname}"
  mkdir -p "${_pkgstage}"
  _stage_package "${_pkgname}" "${_pkgstage}"
  if [[ "${_pkgname}" == *dkms* ]]; then
    _built_dkms_name="$(_staged_dkms_name "${_pkgstage}")"
  fi

  msg2 "Packaging ${_pkgname}"
  if [[ "$PKG_FORMAT" == "deb" ]]; then
    _deb_builder "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}_${pkgver}-${_pkgrel}_amd64.deb")
  else
    _rpm_builder "${_pkgname}" "${_pkgstage}" "${_distdir}"
    _built_pkg_files+=("${_distdir}/${_pkgname}-${pkgver}-${_pkgrel}.x86_64.rpm")
  fi

  rm -rf "${_pkgstage}"
done

msg2 "All packages written to: ${_distdir}"
msg2 "Packages from current run:"
printf '  %s\n' "${_built_pkg_files[@]}"
plain ""

if [[ "$PKG_FORMAT" = "rpm" ]]; then
  _rpm_install_packages
elif [[ "$PKG_FORMAT" = "deb" ]]; then
  _deb_install_packages
fi
exit 0

# vim: set ft=sh ts=2 sw=2 et:
