# Created by: Tk-Glitch <ti3nou at gmail dot com>
# Originally based on https://aur.archlinux.org/packages/nvidia-beta-all/

# Includes DKMS support, libglvnd compat, 32-bit libs and building for all kernels currently installed

plain '       .---.`               `.---.'
plain '    `/syhhhyso-           -osyhhhys/`'
plain '   .syNMdhNNhss/``.---.``/sshNNhdMNys.'
plain '   +sdMh.`+MNsssssssssssssssNM+`.hMds+'
plain '   :syNNdhNNhssssssssssssssshNNhdNNys:'
plain '    /ssyhhhysssssssssssssssssyhhhyss/'
plain '    .ossssssssssssssssssssssssssssso.'
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

_where=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Set up environment and trap cleanup
source "${_where}/nvidia-all-config/prepare"
source "${_where}/nvidia-all-config/install-common"
trap _exit_cleanup EXIT

# Create BIG_UGLY_FROGMINER only on first run and save in it all settings
_frogminer_bootstrap "${_where}/BIG_UGLY_FROGMINER" "${_where}/BIG_UGLY_FROGMINER.pending"

_autoaddpatch="false"

_pkgname_array=()

# optional series in pkgname
if [[ "${_series_in_pkgname}" = "true" ]]; then
  _series="-${_driver_version%%.*}xx"
fi

if [[ "${_driver_branch}" = "vulkandev" ]]; then
  _branchname="nvidia${_series}-dev"
else
  _branchname="nvidia${_series}"
fi

# packages
if [[ "${_open_source_modules}" = "true" ]]; then
  __branchname="${_branchname}-open"
else
  __branchname="${_branchname}"
fi

if [[ "${_build_utils_package_only:-false}" != "true" ]]; then
  if [[ "${_dkms}" = "full" ]]; then
    _pkgname_array+=("${__branchname}-dkms-tkg")
    _pkgname_array+=("${__branchname}-tkg")
  elif [[ "${_dkms}" = "true" ]]; then
    _pkgname_array+=("${__branchname}-dkms-tkg")
  else
    _pkgname_array+=("${__branchname}-tkg")
  fi
fi

_pkgname_array+=("${_branchname}-utils-tkg")

if [[ "${_lib32:-true}" = "true" ]]; then
  _pkgname_array+=("lib32-${_branchname}-utils-tkg")
fi

if [[ "${_opencl:-true}" = "true" ]]; then
  _pkgname_array+=("opencl-${_branchname}-tkg")
  if [[ "${_lib32:-true}" = "true" ]]; then
    _pkgname_array+=("lib32-opencl-${_branchname}-tkg")
  fi
fi

if [[ "${_nvsettings:-true}" = "true" ]]; then
  _pkgname_array+=("${_branchname}-settings-tkg")
fi

if [[ "${_libxnvctrl}" = "true" ]]; then
  if [[ "${_driver_branch}" = "vulkandev" ]]; then
    warning "libxnvctrl-tkg: vulkandev tag unavailable."
    warning "Falling back to external 'libxnvctrl'; replacing an installed TKG provider may require manual 'pacman -S libxnvctrl'."
    _libxnvctrl="external"
    echo "_libxnvctrl='external'" >> "${_where}/BIG_UGLY_FROGMINER"
  else
    if [[ "${_nvsettings:-true}" != "true" ]]; then
      warning "_libxnvctrl requires _nvsettings=true. Enabling nvidia-settings automatically."
      _nvsettings="true"
      _pkgname_array+=("${_branchname}-settings-tkg")
    fi
    _pkgname_array+=("${_branchname}-libxnvctrl-tkg")
  fi
fi

if [[ "${_eglwayland}" = "true" ]]; then
  _pkgname_array+=("${_branchname}-egl-wayland-tkg")
fi

if [[ "${_eglx11}" = "true" ]]; then
  _pkgname_array+=("${_branchname}-egl-x11-tkg")
fi

pkgname=("${_pkgname_array[@]}")
pkgver="${_driver_version}"
pkgrel=300
arch=('x86_64')
url="http://www.nvidia.com/"
license=('custom:NVIDIA')
makedepends=('linux-headers' 'patchelf' 'pciutils')
if [[ "${_nvsettings:-true}" = "true" ]]; then
  makedepends+=('jansson' 'gtk3' 'libxv' 'libvdpau' 'libxext' 'vulkan-headers')
fi
optdepends=('linux-lts-headers: Build the module for LTS Arch kernel'
            'clang: Required when kernel was built with Clang'
            'llvm: Required when kernel was built with Clang (llvm-strip)'
            'lld: Required when kernel was built with Clang (ld.lld)')
options=('!strip' '!debug')

# Installer name
_pkg="NVIDIA-Linux-x86_64-${pkgver}"

source=("${_source_name}")
md5sums=('SKIP')

if [[ -n "${_source_open:-}" ]]; then
  source+=("${_source_open}")
  md5sums+=('SKIP')
fi

if [[ -n "${_source_libxnvctrl:-}" ]]; then
  source+=("${_source_libxnvctrl}")
  md5sums+=('SKIP')
fi

prepare() {
  source "${_where}/BIG_UGLY_FROGMINER"
  source "${_where}/nvidia-all-config/prepare"

  _nv_srcprep
}

build() {
  source "${_where}/BIG_UGLY_FROGMINER"
  source "${_where}/nvidia-all-config/prepare"

  local _build_start=$SECONDS
  if _nv_build; then
    _runtime="$((SECONDS - _build_start))s"
  else
    _runtime="$((SECONDS - _build_start))s (failed)"
    return 1
  fi
}

opencl-nvidia-tkg() {
  pkgdesc="NVIDIA's OpenCL implemention for 'nvidia-utils-tkg'"
  depends=('zlib')
  optdepends=('opencl-headers: headers necessary for OpenCL development')
  provides=("opencl-nvidia=${pkgver}" "opencl-nvidia-tkg=${pkgver}" 'opencl-driver')
  conflicts=('opencl-nvidia')

  cd "${_pkg}"

  _install_opencl
}
source /dev/stdin <<EOF
package_opencl-${_branchname}-tkg() {
  opencl-nvidia-tkg
}
EOF

nvidia-egl-wayland-tkg() {
  depends=('nvidia-utils-tkg' 'eglexternalplatform')
  provides=("egl-wayland" "nvidia-egl-wayland-tkg")
  conflicts=('egl-wayland')
  if [[ "${_eglgbm:-external}" != "external" ]]; then
    provides+=("egl-gbm")
    conflicts+=('egl-gbm')
  fi
  if (( ${pkgver%%.*} >= 590 )); then
    provides+=("egl-wayland2")
    conflicts+=('egl-wayland2')
  fi

  cd "${_pkg}"

  local _eglwver
  _eglwver=$(_eglw_so_ver "libnvidia-egl-wayland.so.*.*.*")
  pkgdesc="NVIDIA EGL Wayland library (libnvidia-egl-wayland.so.${_eglwver}) for 'nvidia-utils-tkg'"

  _install_egl_wayland

  # Arch-specific: wayland-eglstream pkgconfig and XML protocol files
  install -Dm755 "${_where}"/nvidia-all-config/system/egl-wayland/licenses/egl-wayland/COPYING "${pkgdir}"/usr/share/licenses/egl-wayland/COPYING
  install -Dm755 "${_where}"/nvidia-all-config/system/egl-wayland/pkgconfig/wayland-eglstream-protocols.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
  install -Dm755 "${_where}"/nvidia-all-config/system/egl-wayland/pkgconfig/wayland-eglstream.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc
  install -Dm755 "${_where}"/nvidia-all-config/system/egl-wayland/wayland-eglstream/wayland-eglstream-controller.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream-controller.xml
  install -Dm755 "${_where}"/nvidia-all-config/system/egl-wayland/wayland-eglstream/wayland-eglstream.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream.xml

  sed -i "s/Version:.*/Version: ${_eglwver}/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
  sed -i "s/Version:.*/Version: ${_eglwver}/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc

  # lib32
  if [[ "${_lib32:-true}" = "true" ]]; then
    cd 32
    _install_lib32_egl_wayland
  fi
}
source /dev/stdin <<EOF
package_${_branchname}-egl-wayland-tkg() {
  nvidia-egl-wayland-tkg
}
EOF

nvidia-egl-x11-tkg() {
  pkgdesc="NVIDIA EGL X11 libraries (egl-xlib + egl-xcb) for 'nvidia-utils-tkg'"
  depends=('nvidia-utils-tkg')
  provides=("egl-x11")
  conflicts=('egl-x11')

  cd "${_pkg}"

  _install_egl_x11
}
if [[ "${_eglx11}" = "true" ]]; then
source /dev/stdin <<EOF
package_${_branchname}-egl-x11-tkg() {
  nvidia-egl-x11-tkg
}
EOF
fi

nvidia-utils-tkg() {
  pkgdesc="NVIDIA driver utilities and libraries for 'nvidia-tkg'"
  depends=('libglvnd' 'mesa' 'vulkan-icd-loader')
  if [[ "${_eglgbm:-external}" = "external" ]]; then
    depends+=('egl-gbm')
  fi
  if [[ "${_eglwayland:-external}" = "external" ]]; then
    depends+=('egl-wayland')
    if (( ${pkgver%%.*} >= 590 )); then
      depends+=('egl-wayland2')
    fi
  fi
  _eglx11="${_eglx11:-external}"
  if [[ "${_eglx11}" = "external" ]]; then
    depends+=('egl-x11')
  elif [[ "${_eglx11}" = "true" ]]; then
    depends+=("${_branchname}-egl-x11-tkg")
  fi
  optdepends=('nvidia-settings: configuration tool'
              'gtk2: nvidia-settings (GTK+ v2)'
              'gtk3: nvidia-settings (GTK+ v3)'
              'opencl-nvidia-tkg: OpenCL support'
              'xorg-server' 'xorg-server-devel: nvidia-xconfig'
              'egl-wayland-git: for alternative, more advanced Wayland library (libnvidia-egl-wayland.so)')
  provides=("nvidia-utils=${pkgver}" "nvidia-utils-tkg=${pkgver}" 'vulkan-driver' 'opengl-driver' 'nvidia-libgl')
  conflicts=('nvidia-utils' 'nvidia-libgl')
  install=nvidia-all-config/system/nvidia-utils-tkg.install

  cd "${_pkg}"

  # Arch-only: skip nvidia-patch if conflicting AUR package is installed
  if [[ "${_nvidia_patch_enc_fbc:-false}" == "true" ]]; then
    if pacman -Q nvidia-patch &>/dev/null || pacman -Q nvidia-patch-git &>/dev/null; then
      warning "nvidia-patch or nvidia-patch-git is installed. Skipping integrated nvidia-patch to avoid conflicts."
      warning "Please uninstall nvidia-patch/nvidia-patch-git or disable _nvidia_patch_enc_fbc in customization.cfg"
      _nvidia_patch_enc_fbc="false"
    fi
  fi

  _install_utils
}
source /dev/stdin <<EOF
package_${_branchname}-utils-tkg() {
  nvidia-utils-tkg
}
EOF

nvidia-settings-tkg() {
  pkgdesc='Tool for configuring the NVIDIA graphics driver'
  depends=("nvidia-utils-tkg>=${pkgver}" 'jansson' 'gtk3' 'libxv' 'libvdpau')
  if [[ "${_libxnvctrl:-external}" = "true" ]]; then
    depends+=("${_branchname}-libxnvctrl-tkg")
  elif [[ "${_libxnvctrl:-external}" = "external" ]]; then
    depends+=('libxnvctrl')
  fi
  provides=("nvidia-settings=${pkgver}" "nvidia-settings-tkg=${pkgver}")
  conflicts=('nvidia-settings')
  options=('staticlibs')

  cd "${_pkg}"

  _install_settings
}
source /dev/stdin <<EOF
package_${_branchname}-settings-tkg() {
  nvidia-settings-tkg
}
EOF

libxnvctrl-tkg() {
  pkgdesc='NVIDIA NV-CONTROL X extension'
  depends=('libxext')
  provides=('libxnvctrl' 'libXNVCtrl.so')
  conflicts=('libxnvctrl')
  replaces=('libxnvctrl')

  cd "${srcdir}/nvidia-settings-${pkgver}"

  install -Dm644 doc/{NV-CONTROL-API.txt,FRAMELOCK.txt} -t "${pkgdir}/usr/share/doc/${pkgname}"
  install -Dm644 samples/{Makefile,README,*.c,*.h,*.mk} -t "${pkgdir}/usr/share/doc/${pkgname}/samples"
  install -Dm644 src/libXNVCtrl/*.h -t "${pkgdir}/usr/include/NVCtrl"
  install -d "${pkgdir}/usr/lib"
  cp -Pr src/out/libXNVCtrl.* -t "${pkgdir}/usr/lib"
}
if [[ "${_libxnvctrl}" = "true" ]]; then
source /dev/stdin <<EOF
package_${_branchname}-libxnvctrl-tkg() {
  libxnvctrl-tkg
}
EOF
fi

if [[ "${_dkms}" = "false" ]] || [[ "${_dkms}" = "full" ]]; then
  nvidia-tkg() {
  if [[ "${_open_source_modules}" = "true" ]]; then
    pkgdesc="Open NVIDIA kernel modules for all installed kernels"
    depends=('linux')
    conflicts=('NVIDIA-MODULE' 'nvidia-tkg')
    provides=('NVIDIA-MODULE')

    cd "${_srcbase}-${pkgver}"

    local _kernel
    local -a _kernels
    mapfile -t _kernels < <(_detect_kernels)

    for _kernel in "${_kernels[@]}"; do
      msg2 "Installing open NVIDIA modules for kernel: ${_kernel}"
      if [[ ! -d "${srcdir}/open-kmods/${_kernel}" ]]; then
        error "Missing staged open kernel modules for ${_kernel} in ${srcdir}/open-kmods/${_kernel}"
        return 1
      fi
      install -Dt "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -m644 "${srcdir}/open-kmods/${_kernel}"/*.ko
      # Strip debug symbols per-kernel
      if grep -q "CONFIG_CC_IS_CLANG=y" /usr/lib/modules/${_kernel}/build/.config 2>/dev/null; then
        find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec llvm-strip --strip-debug {} +
      else
        find "${pkgdir}/usr/lib/modules/${_kernel}/extramodules" -name '*.ko' -exec strip --strip-debug {} +
      fi
      _compress_modules_for_kernel "${_kernel}" "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
    done

    # Force module to load even on unsupported GPUs
    mkdir -p "${pkgdir}/usr/lib/modprobe.d"
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "${pkgdir}/usr/lib/modprobe.d/${pkgname}-gpus.conf"

    install -Dm644 COPYING "${pkgdir}/usr/share/licenses/${pkgname}"

    if [[ ! "${_disable_libalpm_hook}" == "true" ]]; then
      if [[ "${_module_signing:-autodetect}" = "true" ]] ||
        {
          [[ "${_module_signing:-autodetect}" = "autodetect" ]] &&
            command -v mokutil >/dev/null 2>&1 &&
            mokutil --sb-state 2>/dev/null | grep -qi 'secure boot enabled'
        }; then
        msg2 "Secure Boot is active or module signing is enabled — installing mkinitcpio signing hook"
        install -Dm755 "${_where}/nvidia-all-config/module-signing" "${pkgdir}/usr/lib/nvidia-tkg/module-signing"
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-sign.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      else
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      fi
    else
      msg2 "Skipping mkinitcpio hook due to user config"
    fi
  else
    pkgdesc="Full NVIDIA drivers' package for all kernels on the system (drivers and shared utilities and libraries)"
    depends=("nvidia-utils-tkg>=${pkgver}" 'libglvnd')
    provides=("nvidia=${pkgver}" "nvidia-tkg>=${pkgver}")
    conflicts=('nvidia-96xx' 'nvidia-173xx' 'nvidia')
    install=nvidia-all-config/system/nvidia-tkg.install

    local _kernel
    local -a _kernels
    mapfile -t _kernels < <(_detect_kernels)

    for _kernel in "${_kernels[@]}"; do
      msg2 "Installing NVIDIA modules for kernel: ${_kernel}"
      install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia{,-drm,-modeset,-uvm}.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
      if [[ ${pkgver%%.*} = 465 ]]; then
        install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia-peermem.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
        install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia-ib-peermem-stub.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
      fi
      _compress_modules_for_kernel "${_kernel}" "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
    done

    # Enable nvidia-uvm autoload at boot
    if [[ "${_blacklist_nouveau}" != "false" ]]; then
      echo "nvidia-uvm" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/${pkgname}-uvm.conf"
    else
      msg2 "Skipping nvidia-uvm autoload due to user config"
    fi

    if [[ ! "${_disable_libalpm_hook}" == "true" ]]; then
      if [[ "${_module_signing:-autodetect}" = "true" ]] ||
        {
          [[ "${_module_signing:-autodetect}" = "autodetect" ]] &&
            command -v mokutil >/dev/null 2>&1 &&
            mokutil --sb-state 2>/dev/null | grep -qi 'secure boot enabled'
        }; then
        msg2 "Secure Boot is active or module signing is enabled — installing mkinitcpio signing hook"
        install -Dm755 "${_where}/nvidia-all-config/module-signing" "${pkgdir}/usr/lib/nvidia-tkg/module-signing"
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-sign.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      else
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      fi
    else
      msg2 "Skipping mkinitcpio hook due to user config"
    fi
  fi
}
source /dev/stdin <<EOF
package_${__branchname}-tkg() {
  nvidia-tkg
}
EOF
fi

lib32-opencl-nvidia-tkg() {
  pkgdesc="NVIDIA's OpenCL implemention for 'lib32-nvidia-utils-tkg' "
  depends=('lib32-zlib' 'lib32-gcc-libs')
  optdepends=('opencl-headers: headers necessary for OpenCL development')
  provides=("lib32-opencl-nvidia=${pkgver}" "lib32-opencl-nvidia-tkg=${pkgver}" 'lib32-opencl-driver')
  conflicts=('lib32-opencl-nvidia')

  cd "${_pkg}/32"

  _install_lib32_opencl
}
source /dev/stdin <<EOF
package_lib32-opencl-${_branchname}-tkg() {
  lib32-opencl-nvidia-tkg
}
EOF

lib32-nvidia-utils-tkg() {
  pkgdesc="NVIDIA driver utilities and libraries for 'nvidia-tkg' (32-bit)"
  depends=('lib32-zlib' 'lib32-gcc-libs' 'nvidia-utils-tkg' 'lib32-libglvnd' 'lib32-mesa' 'lib32-vulkan-icd-loader')
  optdepends=('lib32-opencl-nvidia-tkg: OpenCL support')
  provides=("lib32-nvidia-utils=${pkgver}" "lib32-nvidia-utils-tkg=${pkgver}" 'lib32-vulkan-driver' 'lib32-opengl-driver' 'lib32-nvidia-libgl')
  conflicts=('lib32-nvidia-utils' 'lib32-nvidia-libgl')

  cd "${_pkg}/32"

  _install_lib32_utils
  rm -rf "${pkgdir}"/usr/{include,share,bin}
}
source /dev/stdin <<EOF
package_lib32-${_branchname}-utils-tkg() {
  lib32-nvidia-utils-tkg
}
EOF

if [[ "${_dkms}" = "true" ]] || [[ "${_dkms}" = "full" ]]; then
  nvidia-dkms-tkg() {
    if [[ "${_open_source_modules}" = "true" ]]; then
      depends=('dkms')
      conflicts=('nvidia-open' 'NVIDIA-MODULE' 'nvidia-dkms')
      provides=('nvidia-open' 'NVIDIA-MODULE')

      install -dm 755 "${pkgdir}"/usr/src
      cp -dr --no-preserve='ownership' open-gpu-kernel-modules-dkms "${pkgdir}/usr/src/nvidia-$pkgver"
      mv "${pkgdir}/usr/src/nvidia-$pkgver/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-$pkgver/dkms.conf"

      # Force module to load even on unsupported GPUs
      mkdir -p "${pkgdir}/usr/lib/modprobe.d"
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"

      install -Dm644 "${_srcbase}-${pkgver}/COPYING" "${pkgdir}/usr/share/licenses/${pkgname}"
    else
      pkgdesc="NVIDIA kernel module sources (DKMS)"
      depends=('dkms' "nvidia-utils-tkg>=${pkgver}" 'nvidia-libgl' 'pahole')
      provides=("nvidia=${pkgver}" 'nvidia-dkms' "nvidia-dkms-tkg=${pkgver}" 'NVIDIA-MODULE')
      conflicts=('nvidia' 'nvidia-dkms')

      cd "${_pkg}"

      install -dm 755 "${pkgdir}"/usr/{lib/modprobe.d,src}
      cp -dr --no-preserve='ownership' kernel-dkms "${pkgdir}/usr/src/nvidia-${pkgver}"

      if [[ ! "${_disable_libalpm_hook}" == "true" ]]; then
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      else
        msg2 "Skipping mkinitcpio hook due to user config"
      fi

      install -Dt "${pkgdir}/usr/share/licenses/${pkgname}" -m644 "${srcdir}/${_pkg}/LICENSE"
    fi

    # Enable nvidia-uvm autoload at boot
    if [[ "${_blacklist_nouveau}" != "false" ]]; then
      echo "nvidia-uvm" | install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/${pkgname}-uvm.conf"
    else
      msg2 "Skipping nvidia-uvm autoload due to user config"
    fi
  }
source /dev/stdin <<EOF
package_${__branchname}-dkms-tkg() {
  nvidia-dkms-tkg
}
EOF
fi

# vim: set ft=sh ts=2 sw=2 et:
