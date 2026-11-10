# Created by: Tk-Glitch <ti3nou at gmail dot com>
# Originally based on https://aur.archlinux.org/packages/nvidia-beta-all/

# Includes DKMS support, libglvnd compat, 32-bit libs and building for all kernels currently installed

_where=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Set up environment and trap cleanup
source "${_where}/nvidia-all-config/prepare"
source "${_where}/nvidia-all-config/install-common"

_frog_banner

_makepkg_cleanup="true"
trap _exit_cleanup EXIT

# Create BIG_UGLY_FROGMINER only on first run and save in it all settings
_frogminer_bootstrap "${_where}/BIG_UGLY_FROGMINER" "${_where}/BIG_UGLY_FROGMINER.pending"

_autoaddpatch="false"

_pkgname_array=()
declare -gA _module_kernels=()

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
  if [[ "${_dkms}" = "true" || "${_dkms}" = "full" ]]; then
    _pkgname_array+=("${__branchname}-dkms-tkg")
  fi
  if [[ "${_dkms}" = "false" || "${_dkms}" = "full" ]]; then
    _kernel_list=$(_detect_kernels) || _die "Could not detect target kernels."
    while IFS= read -r _kernel; do
      _kernel_pkgname=$(pacman -Qqo "/usr/lib/modules/${_kernel}/pkgbase") || _die "Could not determine kernel package for ${_kernel}."
      _module_pkgname="${_kernel_pkgname}-${__branchname}-tkg"
      [[ -z "${_module_kernels[${_module_pkgname}]:-}" ]] || _die "Multiple kernel versions found for ${_kernel_pkgname}."
      _module_kernels["${_module_pkgname}"]="${_kernel}"
      _pkgname_array+=("${_module_pkgname}")
    done <<< "${_kernel_list}"
  fi
fi

_pkgname_array+=("${_branchname}-utils-tkg")

if [[ "${_lib32:-true}" = "true" ]]; then
  _pkgname_array+=("lib32-${_branchname}-utils-tkg")
fi

if [[ "${_flatpak:-false}" = "true" ]]; then
  _pkgname_array+=("flatpak-${_branchname}-tkg")
  if [[ "${_lib32:-true}" = "true" ]]; then
    _pkgname_array+=("lib32-flatpak-${_branchname}-tkg")
  fi
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
pkgrel="${_pkgrel}"
arch=('x86_64')
url="http://www.nvidia.com/"
license=('custom:NVIDIA')
makedepends=('patchelf' 'pciutils')
if [[ "${_nvsettings:-true}" = "true" ]]; then
  makedepends+=('jansson' 'gtk3' 'libxv' 'libvdpau' 'libxext' 'vulkan-headers')
fi
optdepends=('linux-lts-headers: Build the module for LTS Arch kernel'
            'clang: Required when kernel was built with Clang'
            'llvm: Required when kernel was built with Clang (llvm-strip)'
            'lld: Required when kernel was built with Clang (ld.lld)')
options=('!strip')

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

  _nv_build
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
  if [[ -n "$(_eglw_so_ver "${srcdir}/${_pkg}/libnvidia-egl-wayland2.so.*.*.*")" ]]; then
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
    if (( ${pkgver%%.*} >= 580 )); then
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
  if [[ ! -d /run/systemd/system ]] && { [[ -d /run/dinit ]] || command -v dinitctl &>/dev/null; }; then
    provides+=('nvidia-utils-dinit')
    conflicts+=('nvidia-utils-dinit')
  fi
  install=nvidia-all-config/system/nvidia-utils.install

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

  if [[ "${_open_source_modules}" = "true" ]]; then
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" |
      install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/nvidia-open.conf"
  fi

  if [[ "${_dkms}" != "true" && "${_disable_libalpm_hook}" != "true" ]]; then
    install -Dm644 "${_where}/nvidia-all-config/system/nvidia.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia.hook"
  fi
}
source /dev/stdin <<EOF
package_${_branchname}-utils-tkg() {
  nvidia-utils-tkg
}
EOF

flatpak-nvidia-tkg() {
  pkgdesc="NVIDIA driver extension for Flatpak, matching the host driver"
  depends=('flatpak' "${_branchname}-utils-tkg=${pkgver}")
  provides=("flatpak-nvidia=${pkgver}" "flatpak-nvidia-tkg=${pkgver}")
  conflicts=('flatpak-nvidia' 'flatpak-nvidia-tkg' 'flatpak-host-driver-tkg')
  optdepends=()

  cd "${_pkg}"

  _install_flatpak
}
lib32-flatpak-nvidia-tkg() {
  pkgdesc="NVIDIA driver extension for Flatpak, matching the host driver (32-bit)"
  depends=("flatpak-${_branchname}-tkg=${pkgver}" "lib32-${_branchname}-utils-tkg=${pkgver}")
  provides=("lib32-flatpak-nvidia=${pkgver}" "lib32-flatpak-nvidia-tkg=${pkgver}")
  conflicts=('lib32-flatpak-nvidia' 'lib32-flatpak-nvidia-tkg' 'flatpak-host-driver-tkg')
  optdepends=()

  cd "${_pkg}"

  _install_lib32_flatpak
}
if [[ "${_flatpak:-false}" = "true" ]]; then
source /dev/stdin <<EOF
package_flatpak-${_branchname}-tkg() {
  flatpak-nvidia-tkg
}
EOF
  if [[ "${_lib32:-true}" = "true" ]]; then
source /dev/stdin <<EOF
package_lib32-flatpak-${_branchname}-tkg() {
  lib32-flatpak-nvidia-tkg
}
EOF
  fi
fi

nvidia-settings-tkg() {
  pkgdesc='Tool for configuring the NVIDIA graphics driver'
  depends=('nvidia-utils-tkg' 'jansson' 'gtk3' 'libxv' 'libvdpau')
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
    local _kernel="${_module_kernels[${pkgname}]}"
    local _kernel_pkgname="${pkgname%-${__branchname}-tkg}"
    depends=("${_kernel_pkgname}" "${_branchname}-utils-tkg=${pkgver}")
    provides=('NVIDIA-MODULE' "${_kernel_pkgname}-nvidia")
    conflicts=("${_kernel_pkgname}-nvidia" "${_kernel_pkgname}-nvidia-open" "${_kernel_pkgname}-nvidia-580xx"
               "${_branchname}-tkg" "${_branchname}-open-tkg" 'nvidia-dkms' 'nvidia-open-dkms')
    # Also replace regular/dev packages built without the per-kernel provide.
    if [[ "${_driver_branch}" = "vulkandev" ]]; then
      conflicts+=("${_kernel_pkgname}-nvidia-tkg" "${_kernel_pkgname}-nvidia-open-tkg")
    else
      conflicts+=("${_kernel_pkgname}-nvidia-dev-tkg" "${_kernel_pkgname}-nvidia-dev-open-tkg")
    fi
    if [[ "${_kernel_pkgname}" = "linux" ]]; then
      conflicts+=('nvidia' 'nvidia-open')
    elif [[ "${_kernel_pkgname}" = "linux-lts" ]]; then
      conflicts+=('nvidia-lts' 'nvidia-open-lts')
    fi
    if [[ "${_open_source_modules}" = "true" ]]; then
      pkgdesc="Open NVIDIA kernel modules for ${_kernel_pkgname}"
      conflicts+=("${_kernel_pkgname}-${_branchname}-tkg")
      msg2 "Installing open NVIDIA modules for kernel: ${_kernel}"
      install -Dm644 "${_srcbase}-${pkgver}/COPYING" "${pkgdir}/usr/share/licenses/${pkgname}"
    else
      pkgdesc="NVIDIA kernel modules for ${_kernel_pkgname}"
      conflicts+=("${_kernel_pkgname}-${_branchname}-open-tkg")
      msg2 "Installing NVIDIA modules for kernel: ${_kernel}"
      install -Dm644 "${_pkg}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
    fi
    _install_kernel_modules "${_kernel}"
  }
  for _module_pkgname in "${!_module_kernels[@]}"; do
source /dev/stdin <<EOF
package_${_module_pkgname}() {
  nvidia-tkg
}
EOF
  done
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
  depends=('lib32-zlib' 'lib32-gcc-libs' "nvidia-utils-tkg=${pkgver}" 'lib32-libglvnd' 'lib32-mesa' 'lib32-vulkan-icd-loader')
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
      depends=('dkms' "${_branchname}-utils-tkg=${pkgver}")
      conflicts=('nvidia-open' 'NVIDIA-MODULE' 'nvidia-dkms')
      provides=('nvidia-open' 'NVIDIA-MODULE')

      install -dm 755 "${pkgdir}"/usr/src
      cp -dr --no-preserve='ownership' open-gpu-kernel-modules-dkms "${pkgdir}/usr/src/nvidia-$pkgver"
      mv "${pkgdir}/usr/src/nvidia-$pkgver/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-$pkgver/dkms.conf"

      install -Dm644 "${_srcbase}-${pkgver}/COPYING" "${pkgdir}/usr/share/licenses/${pkgname}"
    else
      pkgdesc="NVIDIA kernel module sources (DKMS)"
      depends=('dkms' "${_branchname}-utils-tkg=${pkgver}" 'nvidia-libgl' 'pahole')
      provides=("nvidia=${pkgver}" 'nvidia-dkms' "nvidia-dkms-tkg=${pkgver}" 'NVIDIA-MODULE')
      conflicts=('nvidia' 'nvidia-dkms' 'NVIDIA-MODULE')

      cd "${_pkg}"

      install -dm 755 "${pkgdir}"/usr/{lib/modprobe.d,src}
      cp -dr --no-preserve='ownership' kernel-dkms "${pkgdir}/usr/src/nvidia-${pkgver}"

      install -Dt "${pkgdir}/usr/share/licenses/${pkgname}" -m644 "${srcdir}/${_pkg}/LICENSE"
    fi
    conflicts+=("${_branchname}-tkg" "${_branchname}-open-tkg")
  }
source /dev/stdin <<EOF
package_${__branchname}-dkms-tkg() {
  nvidia-dkms-tkg
}
EOF
fi

# vim: set ft=sh ts=2 sw=2 et:
