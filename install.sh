#!/usr/bin/env bash

# Stop the script at any encountered error
set -e

_where=`pwd`
srcdir="$_where"

# Command used for superuser privileges (`sudo`, `doas`, `su`)
if [ ! -x "$(command -v sudo)" ]; then
  if [ -x "$(command -v doas)" ]; then
    sudo() { doas "$@"; }
  elif [ -x "$(command -v su)" -a -x "$(command -v xargs)" ]; then
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

plain '       .---.`               `.---.'
plain '    `/syhhhyso-           -osyhhhys/`'
plain '   .syNMdhNNhss/``.---.``/sshNNhdMNys.'
plain '   +sdMh.`+MNsssssssssssssssNM+`.hMds+'
plain '   :syNNdhNNhssssssssssssssshNNhdNNys:'
plain '    /ssyhhhysssssssssssssssssyhhhyss/'
plain '    .ossssssssssssssssssssssssssssssso.'
plain '   :sssssssssssssssssssssssssssssssss:'
plain '  /sssssssssssssssssssssssssssssssssss/   nvidia-all'
plain ' :sssssssssssssoosssssssoosssssssssssss:        AIO drivers'
plain ' osssssssssssssoosssssssoossssssssssssso'
plain ' osssssssssssyyyyhhhhhhhyyyyssssssssssso'
plain ' /yyyyyyhhdmmmmNNNNNNNNNNNmmmmdhhyyyyyy/'
plain '  smmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmms'
plain '   /dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd/'
plain '    `:sdNNNNNNNNNNNNNNNNNNNNNNNNNds:`'
plain '       `-+shdNNNNNNNNNNNNNNNdhs+-`'
plain '             `.-:///////:-.`'

if ! command -v vercmp &>/dev/null; then
  vercmp() {
    [[ "$1" == "$2" ]] && { echo 0; return; }
    local _newer
    _newer="$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)"
    [[ "$_newer" == "$1" ]] && echo 1 || echo -1
  }
fi

for _required in "$_where/customization.cfg" "$_where/nvidia-all-config/prepare"; do
  if [[ ! -f "$_required" ]]; then
    error "Required file not found: $_required"
    error "Run install.sh from the nvidia-all project root."
    exit 1
  fi
done

if which script &> /dev/null && [[ "${_logging_use_script:-}" =~ ^(Y|y|Yes|yes)$ && -z "${SCRIPT:-}" ]]; then
  export SCRIPT=1
  msg2 "Using script"
  script -q -e -c "$0 $*" shell-output.log
  exit
fi

if [[ ! -e "$_where/BIG_UGLY_FROGMINER" ]]; then
  cp "$_where/customization.cfg" "$_where/BIG_UGLY_FROGMINER"
  echo >> "$_where/BIG_UGLY_FROGMINER"

  # extract and define value of _EXT_CONFIG_PATH from customization file
  if [[ -z "$_EXT_CONFIG_PATH" ]]; then
    eval "$(grep _EXT_CONFIG_PATH "$_where"/customization.cfg 2>/dev/null || true)"
  fi

  if [[ -f "${_EXT_CONFIG_PATH:-/dev/null}" ]]; then
    msg2 "External config '${_EXT_CONFIG_PATH}' will override customization.cfg values."
    cat "$_EXT_CONFIG_PATH" >> "$_where/BIG_UGLY_FROGMINER"
    echo >> "$_where/BIG_UGLY_FROGMINER"
  fi

  declare -p -x >> "$_where/BIG_UGLY_FROGMINER"
  echo "_where=\"$_where\"" >> "$_where/BIG_UGLY_FROGMINER"

  source "$_where/BIG_UGLY_FROGMINER"
  source "$_where/nvidia-all-config/prepare"
  # curl + bsdtar are needed by _nv_initscript — install them early if missing
  if ! command -v curl &>/dev/null || ! command -v bsdtar &>/dev/null; then
    if command -v apt-get &>/dev/null; then
      apt-get install -y -q curl libarchive-tools
    elif command -v dnf &>/dev/null; then
      dnf install -y curl bsdtar
    elif command -v zypper &>/dev/null; then
      zypper install -y curl libarchive-tools
    else
      error "curl/bsdtar not found and no known package manager to install them."
      exit 1
    fi
  fi

  _nv_initscript
fi

source "$_where/BIG_UGLY_FROGMINER"
source "$_where/nvidia-all-config/prepare"

# Set driver version and source directory
pkgver="$_driver_version"
_pkg="NVIDIA-Linux-x86_64-$pkgver"
srcdir="/tmp/nvidia-install-$$"
pkgdir=""   # empty because we don't use makepkg, but some prepare functions expect it to exist

# Distro detection
_detect_distro
msg2 "Detected distro family: $_NV_DISTRO_FAMILY"

# Distro selection prompt
_distro_prompt() {
  # Unknown distros are not supported
  case "$_NV_DISTRO_FAMILY" in
    generic|"")
      error "Unknown distribution '${_NV_DISTRO_ID:-unknown}'. Only Debian, Ubuntu, Fedora, Suse/openSUSE and Arch are supported."
      plain ""
      exit 1
      ;;
  esac

  plain ""
  plain "Which Linux distribution are you running?"
  local _detected_label
  case "$_NV_DISTRO_FAMILY" in
    debian)
      case "${_NV_DISTRO_ID:-}" in
        ubuntu|linuxmint|pop|elementary|zorin)
          _default_index=1 ; _detected_label="Ubuntu" ;;
        *) 
          _default_index=0 ; _detected_label="Debian" ;;
      esac
      ;;
    fedora)
      _default_index=2 ; _detected_label="Fedora" ;;
    suse)
      _default_index=3 ; _detected_label="Suse/openSUSE" ;;
    arch)
      _default_index=4 ; _detected_label="Arch Linux (makepkg -si)" ;;
  esac
  msg2 "Auto-detected: ${_NV_DISTRO_ID:-unknown} (${_NV_DISTRO_FAMILY}) → pre-selecting ${_detected_label}"
  _prompt_from_array "Debian" "Ubuntu" "Fedora" "Suse/openSUSE" "Arch Linux (makepkg -si)"
  case "$_selected_value" in
    "Debian")
      _NV_PKG_TARGET="debian" ;;
    "Ubuntu")
      _NV_PKG_TARGET="ubuntu" ;;
    "Fedora")
      _NV_PKG_TARGET="fedora" ;;
    "Suse/openSUSE")
      _NV_PKG_TARGET="suse" ;;
    "Arch Linux (makepkg -si)")
      msg2 "Starting makepkg -si in $_where ..."
      cd "$_where"
      exec makepkg -si
      ;;
    *)
      error "Unsupported distribution. Only Debian, Ubuntu, Fedora, Suse/openSUSE and Arch are supported."
      exit 1
      ;;
  esac
}
_distro_prompt

# Install build dependencies
_install_dependencies() {
  msg2 "Installing build dependencies for ${_NV_PKG_TARGET}..."
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)

  case "$_NV_PKG_TARGET" in
    debian|ubuntu)
      local _kver
      for _kver in "${_kernels[@]}"; do
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "linux-headers-${_kver}"
      done
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y dkms build-essential libarchive-tools patchelf libglvnd-dev libvulkan-dev curl
      ;;
    fedora)
      local _kver
      for _kver in "${_kernels[@]}"; do
        sudo dnf install -y "kernel-devel-${_kver}"
      done
      sudo dnf install -y kernel-headers dkms gcc make bsdtar libarchive patchelf libXext-devel libglvnd-devel curl
      ;;
    suse)
      local _kver
      for _kver in "${_kernels[@]}"; do
        sudo zypper install -y "kernel-devel-${_kver}"
      done
      sudo zypper install -y dkms gcc make libarchive-tools patchelf libXext-devel libglvnd-devel curl
      ;;
    *)
      error "Unsupported distribution '${_NV_PKG_TARGET}'. Only Debian, Ubuntu, Fedora and Suse/openSUSE are supported."
      exit 1
      ;;
  esac
}
_install_dependencies

#  select install mode
_NV_INSTALL_MODE="direct"

_install_mode() {
  case "$_NV_PKG_TARGET" in
    debian|ubuntu|fedora|suse) ;;
    *) return 0 ;;
  esac

  local -a _install_modes=(
    "Direct system install (classic)"
    "Build native distro package (.deb/.rpm) — managed by your package manager"
  )
  plain ""
  plain "How do you want to install NVIDIA ${pkgver}?"
  _default_index=1
  _prompt_from_array "${_install_modes[@]}"
  plain ""
  if (( _selected_index == 0 )); then
    return 0
  fi

  # Prompt package build
  _NV_INSTALL_MODE="package"
  if [[ -z "${PKG_FORMAT:-}" ]]; then
    case "$_NV_PKG_TARGET" in
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

  if [[ "$PKG_FORMAT" == "deb" ]] && ! $_deb; then
    warning "dpkg-deb and/or fakeroot not found — required for .deb building."
    msg2 "Install with: sudo apt-get install dpkg fakeroot"
    plain ""
    plain "Install missing tools now? [Y/n]: "
    read -rp "" _ans
    if [[ -z "$_ans" || "$_ans" =~ ^[Yy] ]]; then
      sudo apt-get install -y dpkg fakeroot
    else
      msg2 "Falling back to direct install."
      _NV_INSTALL_MODE="direct"
      return 0
    fi
  fi

  if [[ "$PKG_FORMAT" == "rpm" ]] && ! $_rpm; then
    warning "rpmbuild not found — required for .rpm building."
    case "$_NV_PKG_TARGET" in
      fedora)
        msg2 "Install with: sudo dnf install rpmdevtools" ;;
      suse)
        msg2 "Install with: sudo zypper install rpm-build" ;;
    esac
    plain ""
    plain "Install missing tools now? [Y/n]: "
    read -rp "" _ans
    if [[ -z "$_ans" || "$_ans" =~ ^[Yy] ]]; then
      case "$_NV_PKG_TARGET" in
        fedora)
          sudo dnf install -y rpmdevtools ;;
        suse)
          sudo zypper install -y rpm-build ;;
        *)
          error "Don't know how to install rpmbuild on this system."
          _NV_INSTALL_MODE="direct"
          return 0 ;;
      esac
    else
      msg2 "Falling back to direct install."
      _NV_INSTALL_MODE="direct"
      return 0
    fi
  fi
}
_install_mode

# staging utilities
_stage_utils() {
  cd "$srcdir/$_pkg"

  # X driver
  install -D -m755 nvidia_drv.so "${pkgdir}/usr/lib/xorg/modules/drivers/nvidia_drv.so"

  if [[ $pkgver = 396* ]]; then
    # GLX extension module for X
    install -D -m755 "libglx.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglx.so.${pkgver}"
    ln -s "libglx.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglx.so.1"	# X doesn't find glx otherwise
    ln -s "libglx.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglx.so"	# X doesn't find glx otherwise
  else
    # GLX extension module for X
    install -D -m755 "libglxserver_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglxserver_nvidia.so.${pkgver}"
    # Ensure that X finds glx
    ln -s "libglxserver_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglxserver_nvidia.so.1"
    ln -s "libglxserver_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/nvidia/xorg/libglxserver_nvidia.so"
  fi

  if [[ $pkgver != 396* ]] && [[ $pkgver != 410* ]] && [[ $pkgver != 415* ]]; then
    # optical flow
    install -D -m755 "libnvidia-opticalflow.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-opticalflow.so.${pkgver}"
  else
    # X wrapped software rendering
    install -D -m755 "libnvidia-wfb.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-wfb.so.${pkgver}"
  fi

  install -D -m755 "libGLX_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/libGLX_nvidia.so.${pkgver}"

  # OpenGL libraries
  install -D -m755 "libEGL_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/libEGL_nvidia.so.${pkgver}"
  install -D -m755 "libGLESv1_CM_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/libGLESv1_CM_nvidia.so.${pkgver}"
  install -D -m755 "libGLESv2_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/libGLESv2_nvidia.so.${pkgver}"
  install -D -m644 "10_nvidia.json" "${pkgdir}/usr/share/glvnd/egl_vendor.d/10_nvidia.json"

  # OpenGL core library
  install -D -m755 "libnvidia-glcore.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-glcore.so.${pkgver}"
  install -D -m755 "libnvidia-eglcore.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-eglcore.so.${pkgver}"
  install -D -m755 "libnvidia-glsi.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-glsi.so.${pkgver}"

  # misc
  if [[ -e libnvidia-ifr.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-ifr.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-ifr.so.${pkgver}"
  fi
  install -D -m755 "libnvidia-fbc.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-fbc.so.${pkgver}"
  install -D -m755 "libnvidia-encode.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-encode.so.${pkgver}"
  install -D -m755 "libnvidia-cfg.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-cfg.so.${pkgver}"
  install -D -m755 "libnvidia-ml.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-ml.so.${pkgver}"
  install -D -m755 "libnvidia-glvkspirv.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-glvkspirv.so.${pkgver}"

  if [[ -e libnvidia-api.so.1 ]]; then
    install -D -m755 "libnvidia-api.so.1" "${pkgdir}/usr/lib/libnvidia-api.so.1"
  fi

  # Allocator library
  if [[ -e libnvidia-allocator.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-allocator.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-allocator.so.${pkgver}"
    mkdir -p "${pkgdir}/usr/lib/gbm" && ln -sr "${pkgdir}/usr/lib/libnvidia-allocator.so.${pkgver}" "${pkgdir}/usr/lib/gbm/nvidia-drm_gbm.so"
  fi

  # GPU shader compilation helper
  if [[ -e libnvidia-gpucomp.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-gpucomp.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-gpucomp.so.${pkgver}"
  fi

  if [[ $pkgver != 396* ]]; then
    # Ray tracing
    install -D -m755 "libnvoptix.so.${pkgver}" "${pkgdir}/usr/lib/libnvoptix.so.${pkgver}"
    if [ -e "nvoptix.bin" ]; then
      install -D -m644 "nvoptix.bin" "${pkgdir}/usr/share/nvidia/nvoptix.bin"
    fi
    install -D -m755 "libnvidia-rtcore.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-rtcore.so.${pkgver}"
    if [ -e "libnvidia-cbl.so.${pkgver}" ]; then
      install -D -m755 "libnvidia-cbl.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-cbl.so.${pkgver}"
    fi
  fi

  # Vulkan ICD
  if [[ $pkgver != 396* ]] && [[ $pkgver != 410* ]] && [[ $pkgver != 415* ]] && [[ $pkgver != 418* ]] && [[ $pkgver != 430* ]]; then
    install -D -m644 "nvidia_icd.json" "${pkgdir}/usr/share/vulkan/icd.d/nvidia_icd.json"
  else
    install -D -m644 "nvidia_icd.json.template" "${pkgdir}/usr/share/vulkan/icd.d/nvidia_icd.json"
  fi
  if [ -e nvidia_layers.json ]; then
    install -D -m644 "nvidia_layers.json" "${pkgdir}/usr/share/vulkan/implicit_layer.d/nvidia_layers.json"
  fi
  if [[ -e libnvidia-vulkan-producer.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-vulkan-producer.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-vulkan-producer.so.${pkgver}"
    ln -s "libnvidia-vulkan-producer.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-vulkan-producer.so.1"
    ln -s "libnvidia-vulkan-producer.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-vulkan-producer.so"
  fi

  # VKSC
  if [[ -e libnvidia-vksc-core.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-vksc-core.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-vksc-core.so.${pkgver}"
    ln -s "libnvidia-vksc-core.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-vksc-core.so.1"
    install -D -m644 "nvidia_icd_vksc.json" "${pkgdir}/usr/share/vulkansc/icd.d/nvidia_icd_vksc.json"
  fi
  if [[ -e nvidia-pcc ]]; then
    install -D -m755 nvidia-pcc "${pkgdir}/usr/bin/nvidia-pcc"
  fi

  # VDPAU
  install -D -m755 "libvdpau_nvidia.so.${pkgver}" "${pkgdir}/usr/lib/vdpau/libvdpau_nvidia.so.${pkgver}"

  # nvidia-tls library
  install -D -m755 "libnvidia-tls.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-tls.so.${pkgver}"

  if [[ $pkgver = 396* ]] || [[ $pkgver = 410* ]]; then
    install -D -m755 "tls/libnvidia-tls.so.${pkgver}" "${pkgdir}/usr/lib/tls/libnvidia-tls.so.${pkgver}"
  fi

  # CUDA
  install -D -m755 "libcuda.so.${pkgver}" "${pkgdir}/usr/lib/libcuda.so.${pkgver}"
  install -D -m755 "libnvcuvid.so.${pkgver}" "${pkgdir}/usr/lib/libnvcuvid.so.${pkgver}"
  if [ -e "libcudadebugger.so.${pkgver}" ]; then
    install -D -m755 "libcudadebugger.so.${pkgver}" "${pkgdir}/usr/lib/libcudadebugger.so.${pkgver}"
  fi
  if [ -e "libnvidia-sandboxutils.so.${pkgver}" ]; then
    install -D -m755 "libnvidia-sandboxutils.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-sandboxutils.so.${pkgver}"
  fi

  # pkcs11
  if (( ${pkgver%%.*} >= 535 )); then
    install -D -m755 "libnvidia-pkcs11-openssl3.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-pkcs11-openssl3.so.${pkgver}"
    install -D -m755 "libnvidia-pkcs11.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-pkcs11.so.${pkgver}"
  fi

  # PTX JIT Compiler (Parallel Thread Execution (PTX) is a pseudo-assembly language for CUDA)
  install -D -m755 "libnvidia-ptxjitcompiler.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-ptxjitcompiler.so.${pkgver}"

  # nvvm
  if [[ -e libnvidia-nvvm.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-nvvm.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-nvvm.so.${pkgver}"
    ln -s "libnvidia-nvvm.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-nvvm.so.4"
    ln -s "libnvidia-nvvm.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-nvvm.so"
  elif [[ -e libnvidia-nvvm.so.4.0.0 ]]; then
    install -D -m755 "libnvidia-nvvm.so.4.0.0" "${pkgdir}/usr/lib/libnvidia-nvvm.so.4.0.0"
    ln -s "libnvidia-nvvm.so.4.0.0" "${pkgdir}/usr/lib/libnvidia-nvvm.so.${pkgver}"
    ln -s "libnvidia-nvvm.so.4.0.0" "${pkgdir}/usr/lib/libnvidia-nvvm.so"
  fi
  if [[ -e libnvidia-nvvm70.so.4 ]]; then
    install -D -m755 "libnvidia-nvvm70.so.4" "${pkgdir}/usr/lib/libnvidia-nvvm70.so.4"
  fi

  if [[ -e libnvidia-present.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-present.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-present.so.${pkgver}"
  fi

  # Fat (multiarchitecture) binary loader
  if [[ $pkgver = 396* ]] || [[ $pkgver = 41* ]] || [[ $pkgver = 43* ]] || [[ $pkgver = 44* ]]; then
    install -D -m755 "libnvidia-fatbinaryloader.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-fatbinaryloader.so.${pkgver}"
  else
    install -D -m755 "libnvidia-ngx.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-ngx.so.${pkgver}"

    # wine nvngx lib
    if (( ${pkgver%%.*} >= 470 )); then
      install -D -m755 "nvngx.dll" "${pkgdir}/usr/lib/nvidia/wine/nvngx.dll"
      install -D -m755 "_nvngx.dll" "${pkgdir}/usr/lib/nvidia/wine/_nvngx.dll"
    fi
    if (( ${pkgver%%.*} >= 570 )); then
      install -D -m755 "nvngx_dlssg.dll" "${pkgdir}/usr/lib/nvidia/wine/nvngx_dlssg.dll"
    fi
  fi
  if (( ${pkgver%%.*} >= 455 )); then
    install -D -m755 nvidia-ngx-updater "${pkgdir}/usr/bin/nvidia-ngx-updater"
  fi

  # DEBUG
  install -D -m755 nvidia-debugdump "${pkgdir}/usr/bin/nvidia-debugdump"

  # nvidia-xconfig
  install -D -m755 nvidia-xconfig "${pkgdir}/usr/bin/nvidia-xconfig"
  install -D -m644 nvidia-xconfig.1.gz "${pkgdir}/usr/share/man/man1/nvidia-xconfig.1.gz"

  # nvidia-bug-report
  install -D -m755 nvidia-bug-report.sh "${pkgdir}/usr/bin/nvidia-bug-report.sh"

  # nvidia-smi
  install -D -m755 nvidia-smi "${pkgdir}/usr/bin/nvidia-smi"
  install -D -m644 nvidia-smi.1.gz "${pkgdir}/usr/share/man/man1/nvidia-smi.1.gz"

  # nvidia-cuda-mps
  install -D -m755 nvidia-cuda-mps-server "${pkgdir}/usr/bin/nvidia-cuda-mps-server"
  install -D -m755 nvidia-cuda-mps-control "${pkgdir}/usr/bin/nvidia-cuda-mps-control"
  install -D -m644 nvidia-cuda-mps-control.1.gz "${pkgdir}/usr/share/man/man1/nvidia-cuda-mps-control.1.gz"

  # nvidia-modprobe
  # This should be removed if nvidia fixed their uvm module!
  install -D -m4755 nvidia-modprobe "${pkgdir}/usr/bin/nvidia-modprobe"
  install -D -m644 nvidia-modprobe.1.gz "${pkgdir}/usr/share/man/man1/nvidia-modprobe.1.gz"

  # Detect init system
  if [ -d /run/systemd/system ]; then
    _detected_init="systemd"
  elif [ -d /run/dinit ] || command -v dinitctl &>/dev/null; then
    _detected_init="dinit"
  elif [ -e /usr/lib/elogind ] || command -v elogind &>/dev/null; then
    _detected_init="elogind"
  else
    _detected_init="other"
  fi
  msg2 "Detected init system: ${_detected_init}"

  # nvidia-persistenced
  install -D -m755 nvidia-persistenced "${pkgdir}/usr/bin/nvidia-persistenced"
  install -D -m644 nvidia-persistenced.1.gz "${pkgdir}/usr/share/man/man1/nvidia-persistenced.1.gz"
  if [ "${_detected_init}" = "systemd" ] && [ -e nvidia-persistenced-init/systemd/nvidia-persistenced.service.template ]; then
    install -D -m644 nvidia-persistenced-init/systemd/nvidia-persistenced.service.template "${pkgdir}/usr/lib/systemd/system/nvidia-persistenced.service"
    sed -i 's/__USER__/nvidia-persistenced/' "${pkgdir}/usr/lib/systemd/system/nvidia-persistenced.service"
  elif [ "${_detected_init}" = "dinit" ]; then
    install -D -m644 "${_where}/nvidia-persistenced.dinit" "${pkgdir}/etc/dinit.d/nvidia-persistenced"
  fi

  # application profiles
  install -D -m644 nvidia-application-profiles-${pkgver}-rc "${pkgdir}/usr/share/nvidia/nvidia-application-profiles-${pkgver}-rc"
  install -D -m644 nvidia-application-profiles-${pkgver}-key-documentation "${pkgdir}/usr/share/nvidia/nvidia-application-profiles-${pkgver}-key-documentation"

  install -D -m644 LICENSE "${pkgdir}/usr/share/licenses/nvidia-utils/LICENSE"
  install -D -m644 README.txt "${pkgdir}/usr/share/doc/nvidia/README"
  install -D -m644 NVIDIA_Changelog "${pkgdir}/usr/share/doc/nvidia/NVIDIA_Changelog"
  cp -r html "${pkgdir}/usr/share/doc/nvidia/"
  ln -s nvidia "${pkgdir}/usr/share/doc/nvidia-utils"

  if [[ $pkgver != 396* ]] && [[ $pkgver != 415* ]] && [[ $pkgver != 418* ]]; then
    if (( ${pkgver%%.*} >= 465 )); then
      _path_addon1="systemd/system/"
      _path_addon2="systemd/system-sleep/"
      _path_addon3="systemd/"
    fi
    # new power management support
    if [ "${_detected_init}" = "systemd" ]; then
      # systemd
      install -D -m644 ${_path_addon1}nvidia-suspend.service "${pkgdir}/usr/lib/systemd/system/nvidia-suspend.service"
      install -D -m644 ${_path_addon1}nvidia-hibernate.service "${pkgdir}/usr/lib/systemd/system/nvidia-hibernate.service"
      install -D -m644 ${_path_addon1}nvidia-resume.service "${pkgdir}/usr/lib/systemd/system/nvidia-resume.service"
      if [ -e ${_path_addon1}nvidia-suspend-then-hibernate.service ]; then
        install -D -m644 ${_path_addon1}nvidia-suspend-then-hibernate.service "${pkgdir}/usr/lib/systemd/system/nvidia-suspend-then-hibernate.service"
      fi
      # systemd sleep hook
      install -D -m755 ${_path_addon2}nvidia "${pkgdir}/usr/lib/systemd/system-sleep/nvidia"
    elif [ "${_detected_init}" = "elogind" ]; then
      install -D -m755 ${_path_addon2}nvidia "${pkgdir}/usr/lib/elogind/system-sleep/nvidia"
    fi
    # nvidia-sleep.sh
    install -D -m755 ${_path_addon3}nvidia-sleep.sh "${pkgdir}/usr/bin/nvidia-sleep.sh"
    # nvidia-powerd
    if [ -e nvidia-powerd ] && [ "${_detected_init}" != "other" ]; then
      install -D -m755 nvidia-powerd "${pkgdir}/usr/bin/nvidia-powerd"
      install -D -m644 nvidia-dbus.conf "${pkgdir}/usr/share/dbus-1/system.d/nvidia-dbus.conf"
      if [ "${_detected_init}" = "systemd" ]; then
        install -D -m644 ${_path_addon1}nvidia-powerd.service "${pkgdir}/usr/lib/systemd/system/nvidia-powerd.service"
      fi
    fi
    # systemd-homed override
    if [ "${_detected_init}" = "systemd" ] && (( ${pkgver%%.*} >= 580 )); then
      install -Dm644 "${_where}/systemd-homed-override.conf" "${pkgdir}/usr/lib/systemd/system/systemd-homed.service.d/10-nvidia-no-freeze-session.conf"
      install -Dm644 "${_where}/systemd-suspend-override.conf" "${pkgdir}/usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf"
      install -Dm644 "${_where}/systemd-suspend-override.conf" "${pkgdir}/usr/lib/systemd/system/systemd-suspend-then-hibernate.service.d/10-nvidia-no-freeze-session.conf"
      install -Dm644 "${_where}/systemd-suspend-override.conf" "${pkgdir}/usr/lib/systemd/system/systemd-hibernate.service.d/10-nvidia-no-freeze-session.conf"
      install -Dm644 "${_where}/systemd-suspend-override.conf" "${pkgdir}/usr/lib/systemd/system/systemd-hybrid-sleep.service.d/10-nvidia-no-freeze-session.conf"
    fi
  fi

  # gsp firmware
  if (( ${pkgver%%.*} >= 530 )); then
    install -D -m644 firmware/gsp_ga10x.bin "${pkgdir}/usr/lib/firmware/nvidia/${pkgver}/gsp_ga10x.bin"
    install -D -m644 firmware/gsp_tu10x.bin "${pkgdir}/usr/lib/firmware/nvidia/${pkgver}/gsp_tu10x.bin"
  elif (( ${pkgver%%.*} >= 525 )); then
    install -D -m644 firmware/gsp_ad10x.bin "${pkgdir}/usr/lib/firmware/nvidia/${pkgver}/gsp_ad10x.bin"
    install -D -m644 firmware/gsp_tu10x.bin "${pkgdir}/usr/lib/firmware/nvidia/${pkgver}/gsp_tu10x.bin"
  elif (( ${pkgver%%.*} >= 465 )); then
    install -D -m644 firmware/gsp.bin "${pkgdir}/usr/lib/firmware/nvidia/${pkgver}/gsp.bin"
  fi

  # Distro-specific files must be installed in /usr/share/X11/xorg.conf.d
  install -Dm644 "${_where}/10-nvidia-drm-outputclass.conf" "$pkgdir"/usr/share/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf

  install -Dm644 "${_where}/nvidia-utils-tkg.sysusers" "$pkgdir"/usr/lib/sysusers.d/$pkgname.conf

  install -Dm644 "${_where}/60-nvidia.rules" "$pkgdir"/usr/lib/udev/rules.d/60-nvidia.rules

  if (( ${pkgver%%.*} >= 595 )); then
    # 595+ open modules use kernel suspend notifiers for video memory preservation
    echo 'options nvidia NVreg_UseKernelSuspendNotifiers=1 NVreg_TemporaryFilePath=/var/tmp' | \
      install -Dm644 /dev/stdin "$pkgdir"/usr/lib/modprobe.d/nvidia-sleep.conf
  else
    # Enable PreserveVideoMemoryAllocations and TemporaryFilePath
    # Fixes Wayland Sleep, when restoring the session
    install -Dm644 "${_where}/nvidia-sleep.conf" "$pkgdir"/usr/lib/modprobe.d/nvidia-sleep.conf
  fi

  # Lists NVIDIA driver files for container runtimes like nvidia-container-toolkit
  if [[ -e "sandboxutils-filelist.json" ]]; then
    install -Dm644 sandboxutils-filelist.json "${pkgdir}/usr/share/nvidia/files.d/sandboxutils-filelist.json"
  fi

  # https://github.com/microsoft/TileIR
  if [[ -e "libnvidia-tileiras.so.${pkgver}" ]]; then
    install -Dm755 "libnvidia-tileiras.so.${pkgver}" "${pkgdir}/usr/lib/libnvidia-tileiras.so.${pkgver}"
  fi

  if (( ${pkgver%%.*} >= 580 )); then
    # reduce idle power (CUDA contexts)
    install -Dm644 "${_where}/50-nvidia-cuda-disable-perf-boost.conf" "${pkgdir}/usr/lib/environment.d/50-nvidia-cuda-disable-perf-boost.conf"
  fi

  # perf optimizations (false/true/cuda/vram)
  _perf_optimizations="${_perf_optimizations:-false}"
  if [[ "${_perf_optimizations}" != "false" ]]; then
    if (( ${pkgver%%.*} >= 580 )); then
      if [[ "${_perf_optimizations}" == "true" ]] || [[ "${_perf_optimizations}" == "vram" ]]; then
        msg2 "Applying VRAM usage limit optimization..."
        # limit-vram-usage (stolen from NextWork123/CachyOS)
        install -Dm644 "${_where}/limit-vram-usage" "${pkgdir}/etc/nvidia/nvidia-application-profiles-rc.d/limit-vram-usage"
      fi
      if [[ "${_perf_optimizations}" == "true" ]] || [[ "${_perf_optimizations}" == "cuda" ]]; then
        msg2 "Applying CUDA performance optimization..."
        install -Dm644 "${_where}/cuda-no-stable-perf-limit" "${pkgdir}/etc/nvidia/nvidia-application-profiles-rc.d/cuda-no-stable-perf-limit"
      fi
    else
      warning "Performance optimizations require driver version >= 580 (current: ${pkgver})"
    fi
  fi

  # nvidia-modprobe config
  _modprobe="${_modprobe:-false}"
  _modprobe_mobile="${_modprobe_mobile:-false}"
  # Check driver version and apply advanced NVIDIA module parameters (NVreg_*)
  if (( ${pkgver%%.*} >= 580 )); then
    if [[ "${_modprobe}" == "true" ]]; then
      msg2 "Applying advanced NVIDIA module parameters..."
      install -Dm644 "${_where}/nvidia-modprobe.conf" "${pkgdir}/usr/lib/modprobe.d/${pkgname}-modprobe.conf"
    fi

    if [[ "${_modprobe_mobile}" == "true" ]]; then
      msg2 "Applying advanced NVIDIA module parameters for mobile devices..."
      install -Dm644 "${_where}/nvidia-modprobe-mobile.conf" "${pkgdir}/usr/lib/modprobe.d/${pkgname}-modprobe.conf"
    fi
  else
    if [[ "${_modprobe}" == "true" ]] || [[ "${_modprobe_mobile}" == "true" ]]; then
      warning "Advanced NVIDIA module parameters require driver version >= 590 (current: ${pkgver})"
    fi
  fi

  # Install nvidia-patch from https://github.com/keylase/nvidia-patch
  # Default to false if _nvidia_patch_enc_fbc is empty
  _nvidia_patch_enc_fbc="${_nvidia_patch_enc_fbc:-false}"
  # Check and apply nvidia-patch for NVENC/NVFBC
  if [[ "${_nvidia_patch_enc_fbc}" == "true" ]]; then
    # Check for conflicting packages
    if pacman -Q nvidia-patch &>/dev/null || pacman -Q nvidia-patch-git &>/dev/null; then
      warning "nvidia-patch or nvidia-patch-git package is installed. Skipping integrated nvidia-patch to avoid conflicts."
      warning "Please uninstall nvidia-patch/nvidia-patch-git or disable _nvidia_patch_enc_fbc in customization.cfg"
    else
      msg2 "Applying nvidia-patch to remove NVENC session limit and enable NVFBC..."
      # Source the nvidia-patch.sh script to get patch definitions
      if [[ -f "${_where}/nvidia-patch.sh" ]]; then
        source "${_where}/nvidia-patch.sh"
      fi
      # Apply NVENC patch (libnvidia-encode)
      if [[ -f "${pkgdir}/usr/lib/libnvidia-encode.so.${pkgver}" ]]; then
        if [[ -n "${enc_patch_list[$pkgver]}" ]]; then
          msg2 "  - Version ${pkgver} detected and supported for NVENC patching"
          # Apply the sed patch directly to the library
          sed -i "${enc_patch_list[$pkgver]}" "${pkgdir}/usr/lib/libnvidia-encode.so.${pkgver}"
          msg2 "  - Patched libnvidia-encode.so.${pkgver} (NVENC session limit removed)"
        else
          warning "NVENC patch not available for driver version ${pkgver}"
        fi
      fi
      # Apply NVFBC patch (libnvidia-fbc)
      if [[ -f "${pkgdir}/usr/lib/libnvidia-fbc.so.${pkgver}" ]]; then
        if [[ -n "${fbc_patch_list[$pkgver]}" ]]; then
          msg2 "  - Version ${pkgver} detected and supported for NVFBC patching"
          # Apply the sed patch directly to the library
          sed -i "${fbc_patch_list[$pkgver]}" "${pkgdir}/usr/lib/libnvidia-fbc.so.${pkgver}"
          msg2 "  - Patched libnvidia-fbc.so.${pkgver} (NVFBC enabled on consumer cards)"
        else
          warning "NVFBC patch not available for driver version ${pkgver}"
        fi
      fi
    fi
  fi

  # create missing soname links
  _create_links

  # Blacklist nouveau
  if [[ "$_blacklist_nouveau" != "false" ]]; then
    echo -e "blacklist nouveau\nblacklist lbm-nouveau\nblacklist nova_core\nblacklist nova_drm" |
      install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/${pkgname}-blacklist.conf"
  else
    msg2 "Skipping nouveau blacklist due to user config"
  fi
}

_stage_lib32_utils() {
  cd "$srcdir/$_pkg/32"

  install -D -m755 "libGLX_nvidia.so.${pkgver}" "${pkgdir}/usr/lib32/libGLX_nvidia.so.${pkgver}"

  # OpenGL libraries
  install -D -m755 "libEGL_nvidia.so.${pkgver}" "${pkgdir}/usr/lib32/libEGL_nvidia.so.${pkgver}"
  install -D -m755 "libGLESv1_CM_nvidia.so.${pkgver}" "${pkgdir}/usr/lib32/libGLESv1_CM_nvidia.so.${pkgver}"
  install -D -m755 "libGLESv2_nvidia.so.${pkgver}" "${pkgdir}/usr/lib32/libGLESv2_nvidia.so.${pkgver}"

  # OpenGL core library
  install -D -m755 "libnvidia-glcore.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-glcore.so.${pkgver}"
  install -D -m755 "libnvidia-eglcore.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-eglcore.so.${pkgver}"
  install -D -m755 "libnvidia-glsi.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-glsi.so.${pkgver}"

  # Allocator library
  if [[ -e libnvidia-allocator.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-allocator.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-allocator.so.${pkgver}"
    mkdir -p "${pkgdir}/usr/lib32/gbm" && ln -sr "${pkgdir}/usr/lib32/libnvidia-allocator.so.${pkgver}" "${pkgdir}/usr/lib32/gbm/nvidia-drm_gbm.so"
  fi

  # GPU shader compilation helper
  if [[ -e libnvidia-gpucomp.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-gpucomp.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-gpucomp.so.${pkgver}"
  fi

  if [[ -e libnvidia-ifr.so.${pkgver} ]]; then
    install -D -m755 "libnvidia-ifr.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ifr.so.${pkgver}"
  fi
  install -D -m755 "libnvidia-fbc.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-fbc.so.${pkgver}"
  install -D -m755 "libnvidia-encode.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-encode.so.${pkgver}"
  install -D -m755 "libnvidia-ml.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ml.so.${pkgver}"
  install -D -m755 "libnvidia-glvkspirv.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-glvkspirv.so.${pkgver}"

  # egl-xlib/xcb
  if [ "${_eglx11:-external}" != "false" ]; then
    if [[ -e libnvidia-egl-xlib.so.1 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1" "${pkgdir}/usr/lib32/libnvidia-egl-xlib.so.1"
    elif [[ -e libnvidia-egl-xlib.so.1.0.0 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1.0.0" "${pkgdir}/usr/lib32/libnvidia-egl-xlib.so.1.0.0"
    fi
    if [[ -e libnvidia-egl-xcb.so.1 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1" "${pkgdir}/usr/lib32/libnvidia-egl-xcb.so.1"
    elif [[ -e libnvidia-egl-xcb.so.1.0.0 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1.0.0" "${pkgdir}/usr/lib32/libnvidia-egl-xcb.so.1.0.0"
    fi
  fi

  # VDPAU
  install -D -m755 "libvdpau_nvidia.so.${pkgver}" "${pkgdir}/usr/lib32/vdpau/libvdpau_nvidia.so.${pkgver}"

  # nvidia-tls library
  install -D -m755 "libnvidia-tls.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-tls.so.${pkgver}"

  if [[ $pkgver = 396* ]] || [[ $pkgver = 410* ]]; then
    install -D -m755 "tls/libnvidia-tls.so.${pkgver}" "${pkgdir}/usr/lib32/tls/libnvidia-tls.so.${pkgver}"
  fi

  # CUDA
  install -D -m755 "libcuda.so.${pkgver}" "${pkgdir}/usr/lib32/libcuda.so.${pkgver}"
  install -D -m755 "libnvcuvid.so.${pkgver}" "${pkgdir}/usr/lib32/libnvcuvid.so.${pkgver}"

  # PTX JIT Compiler
  install -D -m755 "libnvidia-ptxjitcompiler.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ptxjitcompiler.so.${pkgver}"

  # nvvm
  if [[ -e libnvidia-nvvm.so.${pkgver} ]]; then
    install -D -m644 "libnvidia-nvvm.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-nvvm.so.${pkgver}"
  fi

  # Fat (multiarchitecture) binary loader
  if [[ $pkgver = 396* ]] || [[ $pkgver = 41* ]] || [[ $pkgver = 43* ]] || [[ $pkgver = 44* ]]; then
    install -D -m755 "libnvidia-fatbinaryloader.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-fatbinaryloader.so.${pkgver}"
  fi

  # Optical flow
  if [[ ${pkgver} != 396* ]] && [[ ${pkgver} != 410* ]] && [[ ${pkgver} != 415* ]]; then
    install -Dm755 "libnvidia-opticalflow.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-opticalflow.so.${pkgver}"
  else
    install -Dm755 "libnvidia-wfb.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-wfb.so.${pkgver}"
  fi

  # https://github.com/microsoft/TileIR
  if [[ -e libnvidia-tileiras.so.${pkgver} ]]; then
    install -Dm755 "libnvidia-tileiras.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-tileiras.so.${pkgver}"
  fi

  # create missing soname links
  _create_links

  mkdir -p "${pkgdir}/usr/share/licenses"
  ln -s nvidia-utils/ "${pkgdir}/usr/share/licenses/lib32-nvidia-utils-tkg"
}

_stage_opencl() {
  cd "$srcdir/$_pkg"

  # OpenCL
  install -Dm644 nvidia.icd "$pkgdir"/etc/OpenCL/vendors/nvidia.icd
  if [[ -e libnvidia-compiler.so.${pkgver} ]]; then
    install -Dm755 libnvidia-compiler.so.$pkgver "$pkgdir"/usr/lib/libnvidia-compiler.so.$pkgver
  fi
  if [[ -e libnvidia-compiler-next.so.${pkgver} ]]; then
    install -Dm755 libnvidia-compiler-next.so.$pkgver "$pkgdir"/usr/lib/libnvidia-compiler-next.so.$pkgver
  fi
  install -Dm755 libnvidia-opencl.so.$pkgver "$pkgdir"/usr/lib/libnvidia-opencl.so.$pkgver

  # create missing soname links
  _create_links

  # License (link)
  install -d "$pkgdir"/usr/share/licenses/
  ln -s nvidia-utils "$pkgdir"/usr/share/licenses/opencl-nvidia
}

_stage_lib32_opencl() {
  cd "$srcdir/$_pkg/32"
  # OpenCL
  if [[ -e libnvidia-compiler.so.${pkgver} ]]; then
    install -D -m755 libnvidia-compiler.so.$pkgver "$pkgdir"/usr/lib32/libnvidia-compiler.so.$pkgver
  fi
  install -D -m755 libnvidia-opencl.so.$pkgver "$pkgdir"/usr/lib32/libnvidia-opencl.so.$pkgver

  # create missing soname links
  _create_links

  # License (link)
  install -d "$pkgdir"/usr/share/licenses/
  ln -s nvidia-utils/ "$pkgdir"/usr/share/licenses/lib32-opencl-nvidia
}

_stage_settings() {
  cd "$srcdir/$_pkg"
  install -D -m755 nvidia-settings -t "${pkgdir}/usr/bin"
  install -D -m644 nvidia-settings.1.gz -t "${pkgdir}/usr/share/man/man1"
  install -D -m644 nvidia-settings.png -t "${pkgdir}/usr/share/pixmaps"
  install -D -m644 nvidia-settings.desktop -t "${pkgdir}/usr/share/applications"
  sed -e 's:__UTILS_PATH__:/usr/bin:' -e 's:__PIXMAP_PATH__/nvidia-settings.png:nvidia-settings:' \
      -e 's/__NVIDIA_SETTINGS_DESKTOP_CATEGORIES__/Settings;HardwareSettings;/' \
      -i "${pkgdir}/usr/share/applications/nvidia-settings.desktop"

  install -D -m755 "libnvidia-gtk3.so.${pkgver}" -t "${pkgdir}/usr/lib"

  if [[ -e libnvidia-wayland-client.so.${pkgver} ]]; then
    install -Dm755 libnvidia-wayland-client.so."${pkgver}" "${pkgdir}"/usr/lib/libnvidia-wayland-client.so."${pkgver}"
    ln -s libnvidia-wayland-client.so."${pkgver}" "${pkgdir}"/usr/lib/libnvidia-wayland-client.so
  fi

  # license
  install -D -m644 LICENSE -t "${pkgdir}/usr/share/licenses/${pkgname}"  
}

# This function stages the DKMS source tree for the DKMS package variant.
# It also handles blacklisting nouveau and loading nvidia-uvm.
_stage_dkms() {
  local _dkms_src
  if [[ "${_open_source_modules:-}" = "true" ]]; then
    _dkms_src="${srcdir}/open-gpu-kernel-modules-dkms"
    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "$_dkms_src" "${pkgdir}/usr/src/nvidia-${pkgver}"
    mv "${pkgdir}/usr/src/nvidia-${pkgver}/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-${pkgver}/dkms.conf"
    mkdir -p "${pkgdir}/usr/lib/modprobe.d"
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"
  else
    _dkms_src="${srcdir}/${_pkg}/kernel-dkms"
    install -dm755 "${pkgdir}/usr/src"
    cp -dr --no-preserve='ownership' "$_dkms_src" "${pkgdir}/usr/src/nvidia-${pkgver}"
  fi

  # Enable nvidia-uvm autoload at boot
  if [[ "${_blacklist_nouveau}" != "false" ]]; then
    echo "nvidia-uvm" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia-uvm.conf"
  else
    msg2 "Skipping nvidia-uvm autoload due to user config"
  fi
}

# This function is used for the non-DKMS package variant, where we stage precompiled kernel modules directly.
# It also handles blacklisting nouveau and loading nvidia-uvm.
_stage_kmod() {
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)
  local _kernel
  for _kernel in "${_kernels[@]}"; do
    msg2 "Staging kernel modules for ${_kernel}..."
    if [[ "${_open_source_modules:-}" = "true" ]]; then
      local _open_kmods_dir="${srcdir}/open-kmods/${_kernel}"
      [[ -d "$_open_kmods_dir" ]] || { error "Missing open kmods for ${_kernel}"; return 1; }
      install -Dt "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -m644 "${_open_kmods_dir}"/*.ko
    else
      install -D -m644 "${srcdir}/${_pkg}/kernel-${_kernel}/"nvidia{,-drm,-modeset,-uvm}.ko \
        -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
    fi
    find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec gzip -n {} + 2>/dev/null || \
      find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec xz {} +
  done

  # Enable nvidia-uvm autoload at boot
  if [[ "${_blacklist_nouveau}" != "false" ]]; then
    echo "nvidia-uvm" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/nvidia-uvm.conf"
  else
    msg2 "Skipping nvidia-uvm autoload due to user config"
  fi
}

# main staging function
_stage_package() {
  local _pkgname="$1" _stagedir="$2"
  pkgdir="$_stagedir"
  export pkgdir
  source "$_where/BIG_UGLY_FROGMINER"
  source "$_where/nvidia-all-config/prepare"
  case "$_pkgname" in
    nvidia-utils-tkg|nvidia*-utils-tkg) _stage_utils ;;
    lib32-nvidia-utils-tkg|lib32-nvidia*-utils-tkg)
      [[ "${_lib32:-false}" == "true" ]] && _stage_lib32_utils ;;
    nvidia-dkms-tkg|nvidia*-dkms-tkg) _stage_dkms ;;
    nvidia-settings-tkg|nvidia*-settings-tkg)
      [[ "${_nvsettings:-false}" == "true" ]] && _stage_settings ;;
    nvidia-tkg|nvidia*-tkg) _stage_kmod ;;
    opencl-nvidia-tkg|opencl-nvidia*-tkg)
      [[ "${_opencl:-false}" == "true" ]] && _stage_opencl ;;
    lib32-opencl-nvidia-tkg|lib32-opencl-nvidia*-tkg)
      [[ "${_opencl:-false}" == "true" && "${_lib32:-false}" == "true" ]] && _stage_lib32_opencl ;;
    *) warning "No staging function for $_pkgname — skipping." ;;
  esac
}

# package metadata
declare -A _NV_META

_build_metadata() {
  _NV_META[nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries"
  _NV_META[nvidia-utils-tkg_depends_deb]="libglvnd0, libgl1-mesa-glx | libgl1, libvulkan1"
  _NV_META[nvidia-utils-tkg_depends_rpm]="libglvnd >= 1.3, mesa-libGL, vulkan-loader"
  _NV_META[nvidia-utils-tkg_provides_deb]="nvidia-utils (= ${pkgver}), libgl1-nvidia-glvnd-glx, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_provides_rpm]="nvidia-utils = ${pkgver}, nvidia-libgl, vulkan-driver, opengl-driver"
  _NV_META[nvidia-utils-tkg_conflicts_deb]="nvidia-utils, nvidia-libgl, libgl1-nvidia-legacy-390xx-glx"
  _NV_META[nvidia-utils-tkg_conflicts_rpm]="nvidia-utils, xorg-x11-drv-nvidia-libs"
  _NV_META[nvidia-utils-tkg_replaces_deb]="nvidia-libgl, libgl1-nvidia-glvnd-glx"

  _NV_META[lib32-nvidia-utils-tkg_desc]="NVIDIA driver utilities and libraries (32-bit)"
  _NV_META[lib32-nvidia-utils-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), gcc-multilib, libglvnd0:i386, libvulkan1:i386"
  _NV_META[lib32-nvidia-utils-tkg_depends_rpm]="nvidia-utils-tkg = ${pkgver}, glibc(x86-32), libglvnd(x86-32)"
  _NV_META[lib32-nvidia-utils-tkg_provides_deb]="lib32-nvidia-utils (= ${pkgver}), lib32-nvidia-libgl, lib32-vulkan-driver, lib32-opengl-driver"
  _NV_META[lib32-nvidia-utils-tkg_provides_rpm]="lib32-nvidia-utils = ${pkgver}"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_deb]="lib32-nvidia-utils, lib32-nvidia-libgl"
  _NV_META[lib32-nvidia-utils-tkg_conflicts_rpm]="lib32-nvidia-utils"
  _NV_META[lib32-nvidia-utils-tkg_replaces_deb]="lib32-nvidia-libgl"

  _NV_META[nvidia-dkms-tkg_desc]="NVIDIA kernel module sources (DKMS)"
  _NV_META[nvidia-dkms-tkg_depends_deb]="dkms, nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${pkgver}, dwarves"
  _NV_META[nvidia-dkms-tkg_provides_deb]="nvidia-kernel-dkms (= ${pkgver}), nvidia-dkms (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_provides_rpm]="nvidia-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms"
  _NV_META[nvidia-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia"

  _NV_META[nvidia-open-dkms-tkg_desc]="NVIDIA open kernel module sources (DKMS)"
  _NV_META[nvidia-open-dkms-tkg_depends_deb]="dkms, nvidia-utils-tkg (= ${pkgver}), pahole"
  _NV_META[nvidia-open-dkms-tkg_depends_rpm]="dkms, nvidia-utils-tkg = ${pkgver}, dwarves"
  _NV_META[nvidia-open-dkms-tkg_provides_deb]="nvidia-open-kernel-dkms (= ${pkgver}), nvidia-open-dkms (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_provides_rpm]="nvidia-open-dkms = ${pkgver}, NVIDIA-MODULE"
  _NV_META[nvidia-open-dkms-tkg_conflicts_deb]="nvidia-kernel-dkms, nvidia-dkms, nvidia-open-dkms"
  _NV_META[nvidia-open-dkms-tkg_conflicts_rpm]="nvidia-dkms, nvidia-open-dkms, kmod-nvidia"

  _NV_META[nvidia-tkg_desc]="NVIDIA kernel modules (prebuilt)"
  _NV_META[nvidia-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-tkg_depends_rpm]="nvidia-utils-tkg = ${pkgver}, libglvnd"
  _NV_META[nvidia-tkg_provides_deb]="nvidia (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-tkg_provides_rpm]="nvidia = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-open"
  _NV_META[nvidia-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-open"

  _NV_META[nvidia-open-tkg_desc]="NVIDIA open kernel modules (prebuilt)"
  _NV_META[nvidia-open-tkg_depends_deb]="nvidia-utils-tkg (= ${pkgver}), libglvnd0"
  _NV_META[nvidia-open-tkg_depends_rpm]="nvidia-utils-tkg = ${pkgver}, libglvnd"
  _NV_META[nvidia-open-tkg_provides_deb]="nvidia-open (= ${pkgver}), NVIDIA-MODULE"
  _NV_META[nvidia-open-tkg_provides_rpm]="nvidia-open = ${pkgver}, NVIDIA-MODULE, kmod-nvidia"
  _NV_META[nvidia-open-tkg_conflicts_deb]="nvidia-96xx, nvidia-173xx, nvidia, nvidia-dkms, nvidia-open"
  _NV_META[nvidia-open-tkg_conflicts_rpm]="nvidia, nvidia-dkms, kmod-nvidia, nvidia-open"

  _NV_META[opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation"
  _NV_META[opencl-nvidia-tkg_depends_deb]="zlib1g"
  _NV_META[opencl-nvidia-tkg_depends_rpm]="zlib, (ocl-icd or OpenCL-ICD-Loader)"
  _NV_META[opencl-nvidia-tkg_provides_deb]="opencl-nvidia (= ${pkgver}), opencl-driver"
  _NV_META[opencl-nvidia-tkg_provides_rpm]="opencl-nvidia = ${pkgver}"
  _NV_META[opencl-nvidia-tkg_conflicts_deb]="opencl-nvidia"
  _NV_META[opencl-nvidia-tkg_conflicts_rpm]="opencl-nvidia"

  _NV_META[lib32-opencl-nvidia-tkg_desc]="NVIDIA OpenCL implementation (32-bit)"
  _NV_META[lib32-opencl-nvidia-tkg_depends_deb]="zlib1g:i386, gcc-multilib"
  _NV_META[lib32-opencl-nvidia-tkg_depends_rpm]="zlib(x86-32)"
  _NV_META[lib32-opencl-nvidia-tkg_provides_deb]="lib32-opencl-nvidia (= ${pkgver}), lib32-opencl-driver"
  _NV_META[lib32-opencl-nvidia-tkg_provides_rpm]="lib32-opencl-nvidia = ${pkgver}"
  _NV_META[lib32-opencl-nvidia-tkg_conflicts_deb]="lib32-opencl-nvidia"
  _NV_META[lib32-opencl-nvidia-tkg_conflicts_rpm]="lib32-opencl-nvidia"

  _NV_META[nvidia-settings-tkg_desc]="NVIDIA GPU configuration tool"
  _NV_META[nvidia-settings-tkg_depends_deb]="nvidia-utils-tkg (>= ${pkgver}), libjansson4"
  _NV_META[nvidia-settings-tkg_recommends_deb]="libgtk-3-0 | libgtk-3-0t64, libxv1 | libxv1t64, libvdpau1 | libvdpau1t64"
  _NV_META[nvidia-settings-tkg_depends_rpm]="nvidia-utils-tkg >= ${pkgver}, jansson"
  _NV_META[nvidia-settings-tkg_suggests_rpm]="gtk3, libXv, libvdpau"
  _NV_META[nvidia-settings-tkg_provides_deb]="nvidia-settings (= ${pkgver})"
  _NV_META[nvidia-settings-tkg_provides_rpm]="nvidia-settings = ${pkgver}"
  _NV_META[nvidia-settings-tkg_conflicts_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_replaces_deb]="nvidia-settings"
  _NV_META[nvidia-settings-tkg_conflicts_rpm]="nvidia-settings"

  # detect Ubuntu-style versioned NVIDIA packages
  if command -v dpkg &>/dev/null && [[ "${_NV_PKG_TARGET:-}" =~ ^(debian|ubuntu)$ ]]; then
    local _u_libnvidia _u_nvutils
    _u_libnvidia=$(dpkg -l 'libnvidia-compute-[0-9]*' 2>/dev/null \
      | awk '/^ii/ {print $2}' | paste -sd', ' || true)
    _u_nvutils=$(dpkg -l 'nvidia-utils-[0-9]*' 2>/dev/null \
      | awk '/^ii/ {print $2}' | paste -sd', ' || true)
    if [[ -n "$_u_libnvidia" ]]; then
      _NV_META[opencl-nvidia-tkg_conflicts_deb]+=", ${_u_libnvidia}"
      _NV_META[opencl-nvidia-tkg_replaces_deb]+=", ${_u_libnvidia}"
    fi
    if [[ -n "$_u_nvutils" ]]; then
      _NV_META[nvidia-utils-tkg_conflicts_deb]+=", ${_u_nvutils}"
      _NV_META[nvidia-utils-tkg_replaces_deb]+=", ${_u_nvutils}"
    fi
  fi
}

# package builders
_build_pkg_list() {
  local -a _list=()
  local _open=""
  [[ "${_open_source_modules:-}" == "true" ]] && _open="-open"
  if [[ "${_dkms:-false}" == "full" ]]; then
    _list+=("nvidia${_open}-dkms-tkg" "nvidia${_open}-tkg")
  elif [[ "${_dkms:-false}" == "true" ]]; then
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
  [[ -n "$_deps" ]] && echo "Depends: ${_deps}" >> "${_debdir}/DEBIAN/control"
  local _recs="${_NV_META[${_pkgname}_recommends_deb]:-}"
  [[ -n "$_recs" ]] && echo "Recommends: ${_recs}" >> "${_debdir}/DEBIAN/control"
  local _prov="${_NV_META[${_pkgname}_provides_deb]:-}"
  [[ -n "$_prov" ]] && echo "Provides: ${_prov}" >> "${_debdir}/DEBIAN/control"
  local _conf="${_NV_META[${_pkgname}_conflicts_deb]:-}"
  [[ -n "$_conf" ]] && echo "Conflicts: ${_conf}" >> "${_debdir}/DEBIAN/control"
  local _repl="${_NV_META[${_pkgname}_replaces_deb]:-}"
  [[ -n "$_repl" ]] && echo "Replaces: ${_repl}" >> "${_debdir}/DEBIAN/control"

  if [[ "$_pkgname" == *dkms* ]]; then
    cat > "${_debdir}/DEBIAN/postinst" <<POSTINST
#!/bin/sh
set -e
dkms add -m nvidia -v ${pkgver} || true
dkms build -m nvidia -v ${pkgver}
dkms install -m nvidia -v ${pkgver}
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all
elif command -v dracut >/dev/null 2>&1; then
  dracut --force
fi
systemctl daemon-reload 2>/dev/null || true
POSTINST
  elif [[ "$_pkgname" == nvidia-tkg || "$_pkgname" == nvidia-open-tkg ]]; then
    cat > "${_debdir}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
ldconfig
for kver in $(ls /lib/modules/ 2>/dev/null); do
  depmod -a "$kver" 2>/dev/null || true
done
if command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u -k all
elif command -v dracut >/dev/null 2>&1; then
  dracut --force
fi
systemctl daemon-reload 2>/dev/null || true
POSTINST
  else
    cat > "${_debdir}/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
ldconfig
POSTINST
  fi
  chmod 755 "${_debdir}/DEBIAN/postinst"

  if [[ "$_pkgname" == *dkms* ]]; then
    cat > "${_debdir}/DEBIAN/prerm" <<PRERM
#!/bin/sh
set -e
if dkms status -m nvidia -v ${pkgver} 2>/dev/null | grep -q .; then
  dkms remove -m nvidia -v ${pkgver} --all
fi
PRERM
    chmod 755 "${_debdir}/DEBIAN/prerm"
  fi

  if [[ "$_pkgname" == *dkms* ]]; then
    cat > "${_debdir}/DEBIAN/postrm" <<'POSTRM'
#!/bin/sh
ldconfig
for kver in $(ls /lib/modules/ 2>/dev/null); do depmod -a "$kver" 2>/dev/null; done
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
for kver in $(ls /lib/modules/ 2>/dev/null); do depmod -a "$kver" 2>/dev/null; done
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

  cat > "$_specfile" <<SPEC
Name: ${_pkgname}
Version: ${pkgver}
Release: 1%{?dist}
Summary: ${_NV_META[${_pkgname}_desc]:-NVIDIA driver package}
License: custom:NVIDIA
URL: https://github.com/Frogging-Family/nvidia-all
AutoReqProv: no
SPEC

  # lib32 packages contain 32-bit ELF binaries packaged in an x86_64 RPM.
  # Suppress the architecture-mismatch check that would otherwise terminate the build.
  if [[ "$_pkgname" == lib32-* ]]; then
    echo "%define __arch_install_post %{nil}" >> "$_specfile"
  fi

  local _deps="${_NV_META[${_pkgname}_depends_rpm]:-}"
  if [[ -n "$_deps" ]]; then
    IFS=',' read -ra _dep_arr <<< "$_deps"
    for _d in "${_dep_arr[@]}"; do
      _d="${_d#"${_d%%[! ]*}"}"
      _d="${_d%"${_d##*[! ]}"}"
      [[ -n "$_d" ]] && echo "Requires: $_d" >> "$_specfile"
    done
  fi
  local _prov="${_NV_META[${_pkgname}_provides_rpm]:-}"
  if [[ -n "$_prov" ]]; then
    IFS=',' read -ra _prov_arr <<< "$_prov"
    for _p in "${_prov_arr[@]}"; do
      _p="${_p#"${_p%%[! ]*}"}"
      _p="${_p%"${_p##*[! ]}"}" 
      [[ -n "$_p" ]] && echo "Provides: $_p" >> "$_specfile"
    done
  fi
  local _conf="${_NV_META[${_pkgname}_conflicts_rpm]:-}"
  if [[ -n "$_conf" ]]; then
    IFS=',' read -ra _conf_arr <<< "$_conf"
    for _c in "${_conf_arr[@]}"; do
      _c="${_c#"${_c%%[! ]*}"}"
      _c="${_c%"${_c##*[! ]}"}" 
      [[ -n "$_c" ]] && echo "Conflicts: $_c" >> "$_specfile"
    done
  fi
  local _sugg="${_NV_META[${_pkgname}_suggests_rpm]:-}"
  if [[ -n "$_sugg" ]]; then
    IFS=',' read -ra _sugg_arr <<< "$_sugg"
    for _s in "${_sugg_arr[@]}"; do
      _s="${_s#"${_s%%[! ]*}"}"
      _s="${_s%"${_s##*[! ]}"}"
      [[ -n "$_s" ]] && echo "Suggests: $_s" >> "$_specfile"
    done
  fi

  cat >> "$_specfile" <<SPEC

%description
${_NV_META[${_pkgname}_desc]:-NVIDIA driver package} version ${pkgver}.

%install
cp -a ${_stagedir}/. %{buildroot}/

SPEC

  # DKMS packages need dkms add/build/install in %post and dkms remove in %preun.
  # All other packages only need ldconfig + depmod.
  if [[ "$_pkgname" == *dkms* ]]; then
    cat >> "$_specfile" <<SPEC
%post
dkms add -m nvidia -v ${pkgver} || true
dkms build -m nvidia -v ${pkgver}
dkms install -m nvidia -v ${pkgver}
dracut --force
systemctl daemon-reload
exit 0

%preun
if dkms status -m nvidia -v ${pkgver} 2>/dev/null | grep -q .; then
  dkms remove -m nvidia -v ${pkgver} --all || true
fi
exit 0

%postun
ldconfig
dracut --force 2>/dev/null || true
exit 0

SPEC
  elif [[ "$_pkgname" == nvidia-tkg || "$_pkgname" == nvidia-open-tkg ]]; then
    cat >> "$_specfile" <<SPEC
%post
ldconfig
for kver in \$(ls /lib/modules/); do
  depmod -a "\$kver"
done
dracut --force
systemctl daemon-reload
exit 0

%postun
ldconfig
exit 0

SPEC
  else
    cat >> "$_specfile" <<SPEC
%post
ldconfig
exit 0

%postun
ldconfig
exit 0

SPEC
  fi

  cat >> "$_specfile" <<SPEC
%files
SPEC

  # %files list: one path per line, appended directly under the %files header.
  find "$_stagedir" -type f -o -type l | sed "s|^${_stagedir}||" >> "$_specfile"

  # Minimal %changelog entry to suppress the Fedora RPM macro warning:
  # "%source_date_epoch_from_changelog is set, but %changelog has no entries"
  {
    echo ""
    echo "%changelog"
    echo "* $(date +'%a %b %d %Y') nvidia-all-tkg <build@nvidia-all> - ${pkgver}-1"
    echo "- Automated build of NVIDIA ${pkgver}"
  } >> "$_specfile"

  rpmbuild -bb \
    --define "_rpmdir ${_outdir}" \
    --define "_build_name_fmt ${_pkgname}-${pkgver}-1.x86_64.rpm" \
    --define "debug_package %{nil}" \
    --define "__os_install_post %{nil}" \
    --define "_build_id_links none" \
    --define "_unpackaged_files_terminate_build 0" \
    "$_specfile"
  msg2 "Built: ${_outdir}/${_pkgname}-${pkgver}-1.x86_64.rpm"
}

# package build path
if [[ "$_NV_INSTALL_MODE" == "package" ]]; then

  _distdir="${_where}/dist/${_NV_DISTRO_ID:-${_NV_DISTRO_FAMILY}}"
  mkdir -p "$_distdir" "$srcdir"
  cd "$srcdir"
  _nv_download
  cd "$srcdir"
  _nv_srcprep
  if [[ "${_dkms:-false}" != "true" ]]; then
    cd "$srcdir"
    _nv_build
  fi

  _build_metadata
  IFS=' ' read -ra _packages <<< "$(_build_pkg_list)"
  msg2 "Packages to build: ${_packages[*]}"

  for _pname in "${_packages[@]}"; do
    msg2 "=== Staging ${_pname} ==="
    _pkgstage="${_srcdir}/stage-${_pname}"
    mkdir -p "$_pkgstage"
    _stage_package "$_pname" "$_pkgstage"

    msg2 "=== Packaging ${_pname} as .${PKG_FORMAT} ==="
    if [[ "$PKG_FORMAT" == "deb" ]]; then
      _build_deb "$_pname" "$_pkgstage" "$_distdir"
    else
      _build_rpm "$_pname" "$_pkgstage" "$_distdir"
    fi
    rm -rf "$_pkgstage"
  done

  msg2 "All packages written to: $_distdir"
  ls -lh "$_distdir"/*.${PKG_FORMAT}
  plain ""
  case "$PKG_FORMAT" in
    rpm)
      msg2 "To install manually:"
      msg2 "  sudo dnf install '${_distdir}'/*.rpm --allowerasing"
      plain ""
      read -rp " -> Install the built RPM packages now? [Y/n]: " _install_ans
      if [[ -z "$_install_ans" || "$_install_ans" =~ ^[Yy] ]]; then
        msg2 "Installing packages via DNF..."
        sudo dnf install "${_distdir}"/*.rpm --allowerasing
        msg2 "Installation complete. A system reboot is recommended."
      else
        msg2 "Skipping installation. Packages remain in: ${_distdir}"
      fi
      ;;
    deb)
      msg2 "To install manually:"
      msg2 "  sudo apt-get install '${_distdir}'/*.deb"
      plain ""
      read -rp " -> Install the built DEB packages now? [Y/n]: " _install_ans
      if [[ -z "$_install_ans" || "$_install_ans" =~ ^[Yy] ]]; then
        msg2 "Installing packages via apt..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${_distdir}"/*.deb
        msg2 "Installation complete. A system reboot is recommended."
      else
        msg2 "Skipping installation. Packages remain in: ${_distdir}"
      fi
      ;;
  esac
  rm -rf "$_srcdir"
  rm -f "$_where/BIG_UGLY_FROGMINER"
  exit 0
fi

# download
mkdir -p "$srcdir"
cd "$srcdir"
_nv_download

# extract + patch
cd "$srcdir"
_nv_srcprep

# build kmods
if [[ "${_dkms:-false}" != "true" ]]; then
  cd "$srcdir"
  _nv_build
fi

# install kmods
_install_modules() {
  local -a _kernels
  mapfile -t _kernels < <(_detect_kernels)

  if [[ "${_dkms:-false}" = "true" ]]; then
    msg2 "Registering modules with DKMS..."

    local _dkms_src
    if [[ "${_open_source_modules:-}" = "true" ]]; then
      _dkms_src="${srcdir}/open-gpu-kernel-modules-dkms"
    else
      _dkms_src="${srcdir}/${_pkg}/kernel-dkms"
    fi

    if [[ ! -d "$_dkms_src" ]]; then
      error "DKMS source directory not found: $_dkms_src"
      return 1
    fi

    local _dkms_dest="/usr/src/nvidia-${pkgver}"
    sudo rm -rf "$_dkms_dest"
    sudo cp -r "${_dkms_src}/." "$_dkms_dest/"

    if sudo dkms status -m nvidia -v "$pkgver" 2>/dev/null | grep -q .; then
      sudo dkms remove -m nvidia -v "$pkgver" --all
    fi
    sudo dkms add -m nvidia -v "$pkgver"
    sudo dkms build -m nvidia -v "$pkgver"
    sudo dkms install -m nvidia -v "$pkgver"
  # If not using DKMS, install modules directly to the system
  else
    msg2 "Installing modules manually..."
    local _kernel
    for _kernel in "${_kernels[@]}"; do
      local _destdir="/lib/modules/${_kernel}/kernel/drivers/video/nvidia"
      sudo mkdir -p "$_destdir"
      if [[ "${_open_source_modules:-}" = "true" ]]; then
        local _open_kmods_dir="${srcdir}/open-kmods/${_kernel}"
        if [[ ! -d "$_open_kmods_dir" ]]; then
          error "Missing built open kernel modules for ${_kernel} in ${_open_kmods_dir}"
          return 1
        fi
        sudo install -m644 -t "$_destdir" "${_open_kmods_dir}"/*.ko
      else
        sudo install -m644 -t "$_destdir" "${srcdir}/${_pkg}/kernel-${_kernel}"/*.ko
      fi
      sudo depmod -a "$_kernel"
      msg2 "Kernel modules installed for ${_kernel}."
    done
  fi
}
_install_modules

# userspace install (.run silent)
_install_userspace() {
  msg2 "Installing userspace (driver ${pkgver})..."

  local -a _args=(
    --silent
    --no-kernel-modules
    --accept-license
    --no-check-for-alternate-installs
    --no-x-check
  )
  [[ "${_lib32:-false}" = "true" ]] && _args+=(--install-compat32-libs)

  if ! sudo sh "${srcdir}/${_pkg}.run" "${_args[@]}"; then
    error "NVIDIA userspace installer failed."
    error "Check '${_where}/logs/' and run with NVIDIA_INSTALLER_FORCE=1 if needed."
    return 1
  fi
}
_install_userspace

# post-install
sudo ldconfig

# modprobe config
if (( ${pkgver%%.*} >= 595 )); then
  printf 'options nvidia NVreg_UseKernelSuspendNotifiers=1 NVreg_TemporaryFilePath=/var/tmp\n' | \
    sudo install -Dm644 /dev/stdin /usr/lib/modprobe.d/nvidia-sleep.conf
elif [[ -f "${_where}/nvidia-all-config/system/nvidia-sleep.conf" ]]; then
  sudo install -Dm644 "${_where}/nvidia-all-config/system/nvidia-sleep.conf" /usr/lib/modprobe.d/nvidia-sleep.conf
fi

# nouveau blacklist
if [[ "${_blacklist_nouveau:-true}" != "false" ]]; then
  msg2 "nouveau blacklisted via /etc/modprobe.d/nvidia-nouveau-blacklist.conf"
  printf 'blacklist nouveau\nblacklist lbm-nouveau\nblacklist nova_core\nblacklist nova_drm\n' | \
    sudo install -Dm644 /dev/stdin /etc/modprobe.d/nvidia-nouveau-blacklist.conf
  if [[ "$_NV_DISTRO_FAMILY" == "fedora" ]] && command -v grubby &>/dev/null; then
    sudo grubby --update-kernel=ALL --args="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau"
  fi
fi

# initramfs
case "$_NV_DISTRO_FAMILY" in
  debian)
    sudo update-initramfs -u -k all ;;
  fedora|suse)
    sudo dracut --force ;;
  *)
    error "Unsupported distribution '${_NV_DISTRO_FAMILY}'. Only Debian/Ubuntu, Fedora and Suse/openSUSE are supported."
    exit 1
    ;;
esac

msg2 "NVIDIA driver ${pkgver} (${_driver_branch}) installed successfully."
msg2 "A system reboot is recommended to ensure the new driver is fully loaded."
