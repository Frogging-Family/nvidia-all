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

_where="$PWD" # track basedir as different Arch based distros are moving srcdir around

# Create BIG_UGLY_FROGMINER only on first run and save in it all settings
if [ ! -e "$_where/BIG_UGLY_FROGMINER" ]; then

  cp "$_where/customization.cfg" "$_where/BIG_UGLY_FROGMINER"
  echo >> "$_where/BIG_UGLY_FROGMINER"

  # extract and define value of _EXT_CONFIG_PATH from customization file
  if [[ -z "$_EXT_CONFIG_PATH" ]]; then
    eval "$(grep '_EXT_CONFIG_PATH=' "$_where/customization.cfg" 2>/dev/null || true)"
  fi

  if [ -f "$_EXT_CONFIG_PATH" ]; then
    msg2 "External configuration file '$_EXT_CONFIG_PATH' will be used and will override customization.cfg values."
    cat "$_EXT_CONFIG_PATH" >> "$_where/BIG_UGLY_FROGMINER"
    echo >> "$_where/BIG_UGLY_FROGMINER"
  fi

  declare -p -x >> "$_where/BIG_UGLY_FROGMINER"
  echo "_where=\"$_where\"" >> "$_where/BIG_UGLY_FROGMINER"

  source "$_where/BIG_UGLY_FROGMINER"
  source "$_where/nvidia-all-config/prepare"
  _nv_initscript
fi

source "$_where/BIG_UGLY_FROGMINER"
source "$_where/nvidia-all-config/prepare"

_autoaddpatch="false"

_pkgname_array=()

# optional series in pkgname
if [ "$_series_in_pkgname" = "true" ]; then
  _series="-${_driver_version%%.*}xx"
fi

if [ "$_driver_branch" = "vulkandev" ]; then
  _branchname="nvidia$_series-dev"
else
  _branchname="nvidia$_series"
fi

# packages
if [ "$_open_source_modules" = "true" ]; then
  __branchname="$_branchname-open"
else
  __branchname="$_branchname"
fi

if [ "${_build_utils_package_only:-false}" != "true" ]; then
  if [ "$_dkms" = "full" ]; then
    _pkgname_array+=("$__branchname-dkms-tkg")
    _pkgname_array+=("$__branchname-tkg")
  elif [ "$_dkms" = "true" ]; then
    _pkgname_array+=("$__branchname-dkms-tkg")
  else
    _pkgname_array+=("$__branchname-tkg")
  fi
fi

_pkgname_array+=("$_branchname-utils-tkg")

if [ "$_lib32" = "true" ]; then
  _pkgname_array+=("lib32-$_branchname-utils-tkg")
fi

if [ "$_opencl" = "true" ]; then
  _pkgname_array+=("opencl-$_branchname-tkg")
  if [ "$_lib32" = "true" ]; then
    _pkgname_array+=("lib32-opencl-$_branchname-tkg")
  fi
fi

if [ "$_nvsettings" = "true" ]; then
  _pkgname_array+=("$_branchname-settings-tkg")
fi

if [ "$_libxnvctrl" = "true" ]; then
  if [ "$_driver_branch" = "vulkandev" ]; then
    warning "libxnvctrl-tkg: vulkandev tag unavailable."
    warning "Falling back to external 'libxnvctrl'; replacing an installed TKG provider may require manual 'pacman -S libxnvctrl'."
    _libxnvctrl="external"
    echo "_libxnvctrl='external'" >> "$_where/BIG_UGLY_FROGMINER"
  else
    if [ "$_nvsettings" != "true" ]; then
      warning "_libxnvctrl requires _nvsettings=true. Enabling nvidia-settings automatically."
      _nvsettings="true"
      _pkgname_array+=("$_branchname-settings-tkg")
    fi
    _pkgname_array+=("$_branchname-libxnvctrl-tkg")
  fi
fi

if [ "$_eglwayland" = "true" ]; then
  _pkgname_array+=("$_branchname-egl-wayland-tkg")
fi

if [ "$_eglx11" = "true" ]; then
  _pkgname_array+=("$_branchname-egl-x11-tkg")
fi

pkgname=("${_pkgname_array[@]}")
pkgver=$_driver_version
pkgrel=300
arch=('x86_64')
url="http://www.nvidia.com/"
license=('custom:NVIDIA')
makedepends=('linux-headers' 'patchelf')
if [ "$_nvsettings" = "true" ]; then
  makedepends+=('jansson' 'gtk3' 'libxv' 'libvdpau' 'libxext' 'vulkan-headers')
fi
optdepends=('linux-lts-headers: Build the module for LTS Arch kernel'
            'clang: Required when kernel was built with Clang'
            'llvm: Required when kernel was built with Clang (llvm-strip)'
            'lld: Required when kernel was built with Clang (ld.lld)')
options=('!strip' '!buildflags')

# Installer name
_pkg="NVIDIA-Linux-x86_64-$pkgver"

source=($_source_name)
md5sums=('SKIP')

[[ -n "${_source_open:-}" ]] && { source+=("$_source_open"); md5sums+=('SKIP'); }
[[ -n "${_source_libxnvctrl:-}" ]] && { source+=("$_source_libxnvctrl"); md5sums+=('SKIP'); }

# _create_links, _detect_kernels, _build_flags are defined in prepare

prepare() {
  source "$_where/BIG_UGLY_FROGMINER"
  source "$_where/nvidia-all-config/prepare"

  _nv_srcprep
}

build() {
  source "$_where/BIG_UGLY_FROGMINER"
  source "$_where/nvidia-all-config/prepare"

  _nv_build
}

opencl-nvidia-tkg() {
  pkgdesc="NVIDIA's OpenCL implemention for 'nvidia-utils-tkg'"
  depends=('zlib')
  optdepends=('opencl-headers: headers necessary for OpenCL development')
  provides=("opencl-nvidia=$pkgver" "opencl-nvidia-tkg=$pkgver" 'opencl-driver')
  conflicts=('opencl-nvidia')
  cd $_pkg

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
source /dev/stdin <<EOF
package_opencl-$_branchname-tkg() {
  opencl-nvidia-tkg
}
EOF

# egl-wayland version
if (( ${pkgver%%.*} >= 580 )); then
  _eglwver="1.1.20"
elif (( ${pkgver%%.*} >= 575 )) || [[ "${pkgver}" = 570.123.* ]]; then
  _eglwver="1.1.19"
elif (( ${pkgver%%.*} >= 570 )); then
  _eglwver="1.1.18"
elif (( ${pkgver%%.*} >= 565 )); then
  _eglwver="1.1.17"
elif (( ${pkgver%%.*} >= 550 )); then
  _eglwver="1.1.13"
elif (( ${pkgver%%.*} >= 545 )); then
  _eglwver="1.1.12"
elif (( ${pkgver%%.*} >= 530 )); then
  _eglwver="1.1.11"
elif (( ${pkgver%%.*} >= 525 )); then
  _eglwver="1.1.10"
elif (( ${pkgver%%.*} >= 495 )); then
  _eglwver="1.1.9"
elif [[ $pkgver = 470* ]]; then
  _eglwver="1.1.7"
elif (( ${pkgver%%.*} >= 455 )); then
  _eglwver="1.1.5"
elif (( ${pkgver%%.*} >= 440 )); then
  _eglwver="1.1.4"
elif [[ $pkgver = 435* ]]; then
  _eglwver="1.1.3"
elif (( ${pkgver%%.*} >= 418 )); then
  _eglwver="1.1.2"
elif (( ${pkgver%%.*} >= 410 )); then
  _eglwver="1.1.0"
elif [[ $pkgver = 396* ]]; then
  _eglwver="1.0.3"
fi

# egl-wayland2 version
if (( ${pkgver%%.*} >= 590 )); then
  _eglwver2="1.0.1"
fi

# egl-gbm version
if (( ${pkgver%%.*} >= 590 )); then
  _eglgver="1.1.3"
elif (( ${pkgver%%.*} >= 565 )); then
  _eglgver="1.1.2"
elif (( ${pkgver%%.*} >= 550 )); then
  _eglgver="1.1.1"
elif (( ${pkgver%%.*} >= 495 )); then
  _eglgver="1.1.0"
fi

nvidia-egl-wayland-tkg() {
  pkgdesc="NVIDIA EGL Wayland library (libnvidia-egl-wayland.so.$_eglwver) for 'nvidia-utils-tkg'"
  depends=('nvidia-utils-tkg' 'eglexternalplatform')
  provides=("egl-wayland" "nvidia-egl-wayland-tkg")
  conflicts=('egl-wayland')
  if [ "${_eglgbm}" != "external" ]; then
    provides+=("egl-gbm")
    conflicts+=('egl-gbm')
  fi
  if (( ${pkgver%%.*} >= 590 )); then
    provides+=("egl-wayland2")
    conflicts+=('egl-wayland2')
  fi

  cd $_pkg

    install -Dm755 libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so."${_eglwver}"
    ln -s libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so.1
    ln -s libnvidia-egl-wayland.so.1 "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so

    install -Dm755 10_nvidia_wayland.json "${pkgdir}"/usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json
    install -Dm755 "$_where"/egl-wayland/licenses/egl-wayland/COPYING "${pkgdir}"/usr/share/licenses/egl-wayland/COPYING
    install -Dm755 "$_where"/egl-wayland/pkgconfig/wayland-eglstream-protocols.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
    install -Dm755 "$_where"/egl-wayland/pkgconfig/wayland-eglstream.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc
    install -Dm755 "$_where"/egl-wayland/wayland-eglstream/wayland-eglstream-controller.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream-controller.xml
    install -Dm755 "$_where"/egl-wayland/wayland-eglstream/wayland-eglstream.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream.xml

    sed -i "s/Version:.*/Version: $_eglwver/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
    sed -i "s/Version:.*/Version: $_eglwver/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc

    # egl-wayland2
    if [[ -e libnvidia-egl-wayland2.so."${_eglwver2}" ]]; then
      install -Dm755 libnvidia-egl-wayland2.so."${_eglwver2}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland2.so."${_eglwver2}"
      ln -s libnvidia-egl-wayland2.so."${_eglwver2}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland2.so.1
      ln -s libnvidia-egl-wayland2.so.1 "${pkgdir}"/usr/lib/libnvidia-egl-wayland2.so
    fi
    if [[ -e 99_nvidia_wayland2.json ]]; then
      install -Dm755 99_nvidia_wayland2.json "${pkgdir}"/usr/share/egl/egl_external_platform.d/99_nvidia_wayland2.json
    fi

    # egl-gbm
    if [ "$_eglgbm" = "true" ]; then
      if [ -n "${_eglgver:-}" ]; then
        install -Dm755 libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so."${_eglgver}"
        ln -s libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so.1
        ln -s libnvidia-egl-gbm.so.1 "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so
      fi
      if [[ -e 15_nvidia_gbm.json ]]; then
        install -Dm755 15_nvidia_gbm.json "${pkgdir}"/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json
      fi
    fi

    # lib32
    if [ "$_lib32" = "true" ]; then
      cd 32
      if [[ -e libnvidia-egl-wayland.so."${_eglwver}" ]]; then
        install -Dm755 libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib32/libnvidia-egl-wayland.so."${_eglwver}"
        ln -s libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib32/libnvidia-egl-wayland.so.1
        ln -s libnvidia-egl-wayland.so.1 "${pkgdir}"/usr/lib32/libnvidia-egl-wayland.so
      fi
      if [[ -e libnvidia-egl-wayland2.so."${_eglwver2}" ]]; then
        install -Dm755 libnvidia-egl-wayland2.so."${_eglwver2}" "${pkgdir}"/usr/lib32/libnvidia-egl-wayland2.so."${_eglwver2}"
        ln -s libnvidia-egl-wayland2.so."${_eglwver2}" "${pkgdir}"/usr/lib32/libnvidia-egl-wayland2.so.1
        ln -s libnvidia-egl-wayland2.so.1 "${pkgdir}"/usr/lib32/libnvidia-egl-wayland2.so
      fi
      if [ "$_eglgbm" = "true" ]; then
        if [ -n "${_eglgver:-}" ] && [[ -e libnvidia-egl-gbm.so."${_eglgver}" ]]; then
          install -Dm755 libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib32/libnvidia-egl-gbm.so."${_eglgver}"
          ln -s libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib32/libnvidia-egl-gbm.so.1
          ln -s libnvidia-egl-gbm.so.1 "${pkgdir}"/usr/lib32/libnvidia-egl-gbm.so
        fi
      fi
    fi
}
source /dev/stdin <<EOF
package_$_branchname-egl-wayland-tkg() {
  nvidia-egl-wayland-tkg
}
EOF

nvidia-egl-x11-tkg() {
  pkgdesc="NVIDIA EGL X11 libraries (egl-xlib + egl-xcb) for 'nvidia-utils-tkg'"
  depends=('nvidia-utils-tkg')
  provides=("egl-x11")
  conflicts=('egl-x11')
  cd $_pkg

    # egl-xlib
    if [[ -e libnvidia-egl-xlib.so.1 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1" "${pkgdir}/usr/lib/libnvidia-egl-xlib.so.1"
    elif [[ -e libnvidia-egl-xlib.so.1.0.0 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1.0.0" "${pkgdir}/usr/lib/libnvidia-egl-xlib.so.1.0.0"
    elif [[ -e libnvidia-egl-xlib.so.1.0.1 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1.0.1" "${pkgdir}/usr/lib/libnvidia-egl-xlib.so.1.0.1"
    elif [[ -e libnvidia-egl-xlib.so.1.0.3 ]]; then
      install -D -m755 "libnvidia-egl-xlib.so.1.0.3" "${pkgdir}/usr/lib/libnvidia-egl-xlib.so.1.0.3"
    fi
    if [[ -e 20_nvidia_xlib.json ]]; then
      install -D -m644 "20_nvidia_xlib.json" "${pkgdir}/usr/share/egl/egl_external_platform.d/20_nvidia_xlib.json"
    fi

    # egl-xcb
    if [[ -e libnvidia-egl-xcb.so.1 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1" "${pkgdir}/usr/lib/libnvidia-egl-xcb.so.1"
    elif [[ -e libnvidia-egl-xcb.so.1.0.0 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1.0.0" "${pkgdir}/usr/lib/libnvidia-egl-xcb.so.1.0.0"
    elif [[ -e libnvidia-egl-xcb.so.1.0.1 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1.0.1" "${pkgdir}/usr/lib/libnvidia-egl-xcb.so.1.0.1"
    elif [[ -e libnvidia-egl-xcb.so.1.0.3 ]]; then
      install -D -m755 "libnvidia-egl-xcb.so.1.0.3" "${pkgdir}/usr/lib/libnvidia-egl-xcb.so.1.0.3"
    fi
    if [[ -e 20_nvidia_xcb.json ]]; then
      install -D -m644 "20_nvidia_xcb.json" "${pkgdir}/usr/share/egl/egl_external_platform.d/20_nvidia_xcb.json"
    fi
}
if [ "$_eglx11" = "true" ]; then
source /dev/stdin <<EOF
package_$_branchname-egl-x11-tkg() {
  nvidia-egl-x11-tkg
}
EOF
fi

nvidia-utils-tkg() {
  pkgdesc="NVIDIA driver utilities and libraries for 'nvidia-tkg'"
  depends=('libglvnd' 'mesa' 'vulkan-icd-loader')
  if [ "$_eglgbm" = "external" ]; then
    depends+=('egl-gbm')
  fi
  if [ "$_eglwayland" = "external" ]; then
    depends+=('egl-wayland')
    if (( ${pkgver%%.*} >= 590 )); then
      depends+=('egl-wayland2')
    fi
  fi
  _eglx11="${_eglx11:-external}"
  if [ "$_eglx11" = "external" ]; then
    depends+=('egl-x11')
  elif [ "$_eglx11" = "true" ]; then
    depends+=("$_branchname-egl-x11-tkg")
  fi
  optdepends=('nvidia-settings: configuration tool'
              'gtk2: nvidia-settings (GTK+ v2)'
              'gtk3: nvidia-settings (GTK+ v3)'
              'opencl-nvidia-tkg: OpenCL support'
              'xorg-server' 'xorg-server-devel: nvidia-xconfig'
              'egl-wayland-git: for alternative, more advanced Wayland library (libnvidia-egl-wayland.so)')
  provides=("nvidia-utils=$pkgver" "nvidia-utils-tkg=$pkgver" 'vulkan-driver' 'opengl-driver' 'nvidia-libgl')
  conflicts=('nvidia-utils' 'nvidia-libgl')
  install=nvidia-utils-tkg.install
  cd $_pkg

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
        source "${_where}/nvidia-patch.sh" 2>/dev/null || true
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
source /dev/stdin <<EOF
package_$_branchname-utils-tkg() {
  nvidia-utils-tkg
}
EOF

nvidia-settings-tkg() {
  pkgdesc='Tool for configuring the NVIDIA graphics driver'
  depends=("nvidia-utils-tkg>=${pkgver}" 'jansson' 'gtk3' 'libxv' 'libvdpau')
  if [ "$_libxnvctrl" = "true" ]; then
    depends+=("$_branchname-libxnvctrl-tkg")
  elif [ "$_libxnvctrl" = "external" ]; then
    depends+=('libxnvctrl')
  fi
  provides=("nvidia-settings=${pkgver}" "nvidia-settings-tkg=${pkgver}")
  conflicts=('nvidia-settings')
  options=('staticlibs')

  cd "$_pkg"

  install -D -m755 nvidia-settings         -t "${pkgdir}/usr/bin"
  install -D -m644 nvidia-settings.1.gz    -t "${pkgdir}/usr/share/man/man1"
  install -D -m644 nvidia-settings.png     -t "${pkgdir}/usr/share/pixmaps"
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
source /dev/stdin <<EOF
package_$_branchname-settings-tkg() {
  nvidia-settings-tkg
}
EOF

libxnvctrl-tkg() {
  pkgdesc='NVIDIA NV-CONTROL X extension'
  depends=('libxext')
  provides=('libxnvctrl' 'libXNVCtrl.so')
  conflicts=('libxnvctrl')
  replaces=('libxnvctrl')

  cd "$srcdir/nvidia-settings-$pkgver"

  install -Dm644 doc/{NV-CONTROL-API.txt,FRAMELOCK.txt} -t "${pkgdir}/usr/share/doc/${pkgname}"
  install -Dm644 samples/{Makefile,README,*.c,*.h,*.mk} -t "${pkgdir}/usr/share/doc/${pkgname}/samples"

  install -Dm644 src/libXNVCtrl/*.h -t "${pkgdir}/usr/include/NVCtrl"
  install -d "${pkgdir}/usr/lib"
  cp -Pr src/out/libXNVCtrl.* -t "${pkgdir}/usr/lib"
}
if [ "$_libxnvctrl" = "true" ]; then
source /dev/stdin <<EOF
package_$_branchname-libxnvctrl-tkg() {
  libxnvctrl-tkg
}
EOF
fi

if [ "$_dkms" = "false" ] || [ "$_dkms" = "full" ]; then
  nvidia-tkg() {
  if [ "$_open_source_modules" = "true" ]; then
    pkgdesc="Open NVIDIA kernel modules for all installed kernels"
    depends=('linux')
    conflicts=('NVIDIA-MODULE' 'nvidia-tkg')
    provides=('NVIDIA-MODULE')

    cd ${_srcbase}-${pkgver}

    local _kernel
    local -a _kernels
    mapfile -t _kernels < <(_detect_kernels)

    for _kernel in "${_kernels[@]}"; do
      msg2 "Installing open NVIDIA modules for kernel: ${_kernel}"
      local _extradir="/usr/lib/modules/${_kernel}/extramodules"
      local _open_kmods_dir="${srcdir}/open-kmods/${_kernel}"
      if [ ! -d "$_open_kmods_dir" ]; then
        error "Missing staged open kernel modules for ${_kernel} in ${_open_kmods_dir}"
        return 1
      fi
      install -Dt "${pkgdir}${_extradir}" -m644 "${_open_kmods_dir}"/*.ko
      # Strip debug symbols per-kernel
      if grep -q "CONFIG_CC_IS_CLANG=y" /usr/lib/modules/${_kernel}/build/.config 2>/dev/null; then
        find "${pkgdir}${_extradir}" -name '*.ko' -exec llvm-strip --strip-debug {} +
      else
        find "${pkgdir}${_extradir}" -name '*.ko' -exec strip --strip-debug {} +
      fi
      find "${pkgdir}${_extradir}" -name '*.ko' -exec xz {} +
    done

    # Force module to load even on unsupported GPUs
    mkdir -p "$pkgdir"/usr/lib/modprobe.d
    echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "$pkgdir"/usr/lib/modprobe.d/${pkgname}-gpus.conf

    install -Dm644 COPYING "$pkgdir"/usr/share/licenses/$pkgname

    if [[ ! "$_disable_libalpm_hook" == "true" ]]; then
      if [ "${_module_signing:-false}" = "true" ]; then
        install -Dm755 "${_where}/nvidia-all-config/nvidia-sign-modules" "${pkgdir}/usr/lib/nvidia-tkg/sign-modules"
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-sign.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      else
        install -Dm644 "${_where}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      fi
    else
      echo "Skipping mkinitcpio hook due to user config"
    fi
  else
    pkgdesc="Full NVIDIA drivers' package for all kernels on the system (drivers and shared utilities and libraries)"
    depends=("nvidia-utils-tkg>=$pkgver" 'libglvnd')
    provides=("nvidia=$pkgver" "nvidia-tkg>=$pkgver")
    conflicts=('nvidia-96xx' 'nvidia-173xx' 'nvidia')
    install=nvidia-tkg.install

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
      find "$pkgdir" -name '*.ko' -exec gzip -n {} +
    done

    # Enable nvidia-uvm autoload at boot
    if [[ "$_blacklist_nouveau" != "false" ]]; then
      echo "nvidia-uvm" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/${pkgname}-uvm.conf"
    else
      msg2 "Skipping nvidia-uvm autoload due to user config"
    fi

    if [[ ! "$_disable_libalpm_hook" == "true" ]]; then
      if [ "${_module_signing:-false}" = "true" ]; then
        install -Dm755 "${_where}/nvidia-all-config/nvidia-sign-modules" "${pkgdir}/usr/lib/nvidia-tkg/sign-modules"
        install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-sign.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      else
        install -Dm644 "${_where}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
      fi
    else
      echo "Skipping mkinitcpio hook due to user config"
    fi
  fi
}
source /dev/stdin <<EOF
package_$__branchname-tkg() {
  nvidia-tkg
}
EOF
fi

lib32-opencl-nvidia-tkg() {
  pkgdesc="NVIDIA's OpenCL implemention for 'lib32-nvidia-utils-tkg' "
  depends=('lib32-zlib' 'lib32-gcc-libs')
  optdepends=('opencl-headers: headers necessary for OpenCL development')
  provides=("lib32-opencl-nvidia=$pkgver" "lib32-opencl-nvidia-tkg=$pkgver" 'lib32-opencl-driver')
  conflicts=('lib32-opencl-nvidia')
  cd $_pkg/32

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
source /dev/stdin <<EOF
package_lib32-opencl-$_branchname-tkg() {
  lib32-opencl-nvidia-tkg
}
EOF

lib32-nvidia-utils-tkg() {
  pkgdesc="NVIDIA driver utilities and libraries for 'nvidia-tkg' (32-bit)"
  depends=('lib32-zlib' 'lib32-gcc-libs' 'nvidia-utils-tkg' 'lib32-libglvnd' 'lib32-mesa' 'lib32-vulkan-icd-loader')
  optdepends=('lib32-opencl-nvidia-tkg: OpenCL support')
  provides=("lib32-nvidia-utils=$pkgver" "lib32-nvidia-utils-tkg=$pkgver" 'lib32-vulkan-driver' 'lib32-opengl-driver' 'lib32-nvidia-libgl')
  conflicts=('lib32-nvidia-utils' 'lib32-nvidia-libgl')
  cd $_pkg/32

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


    # PTX JIT Compiler (Parallel Thread Execution (PTX) is a pseudo-assembly language for CUDA)
    install -D -m755 "libnvidia-ptxjitcompiler.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ptxjitcompiler.so.${pkgver}"

    # NVVM Compiler library loaded by the CUDA driver to do JIT link-time-optimization
    if [[ -e libnvidia-nvvm.so.${pkgver} ]]; then
      install -D -m644 "libnvidia-nvvm.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-nvvm.so.${pkgver}"
    fi

    # Fat (multiarchitecture) binary loader
    if [[ $pkgver = 396* ]] || [[ $pkgver = 41* ]] || [[ $pkgver = 43* ]] || [[ $pkgver = 44* ]]; then
      install -D -m755 "libnvidia-fatbinaryloader.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-fatbinaryloader.so.${pkgver}"
    fi

    # Optical flow
    # https://gitlab.archlinux.org/archlinux/packaging/packages/lib32-nvidia-utils/-/blob/main/PKGBUILD?ref_type=heads#L98
    if [[ ${pkgver} != 396* ]] && [[ ${pkgver} != 410* ]] && [[ ${pkgver} != 415* ]]; then
      install -Dm755 "libnvidia-opticalflow.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-opticalflow.so.${pkgver}"
    else
      # X wrapped software rendering
      install -Dm755 "libnvidia-wfb.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-wfb.so.${pkgver}"
    fi

    # https://github.com/microsoft/TileIR
    if [[ -e libnvidia-tileiras.so.${pkgver} ]]; then
      install -Dm755 "libnvidia-tileiras.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-tileiras.so.${pkgver}"
    fi

    # create missing soname links
    _create_links

    rm -rf "${pkgdir}"/usr/{include,share,bin}
    mkdir -p "${pkgdir}/usr/share/licenses"
    ln -s nvidia-utils/ "${pkgdir}/usr/share/licenses/${pkgname}"
}
source /dev/stdin <<EOF
package_lib32-$_branchname-utils-tkg() {
  lib32-nvidia-utils-tkg
}
EOF

if [ "$_dkms" = "true" ] || [ "$_dkms" = "full" ]; then
  nvidia-dkms-tkg() {
    if [ "$_open_source_modules" = "true" ]; then
      depends=('dkms')
      conflicts=('nvidia-open' 'NVIDIA-MODULE' 'nvidia-dkms')
      provides=('nvidia-open' 'NVIDIA-MODULE')

      install -dm 755 "${pkgdir}"/usr/src
      # cp -dr --no-preserve='ownership' kernel-open "${pkgdir}/usr/src/nvidia-$pkgver"
      cp -dr --no-preserve='ownership' open-gpu-kernel-modules-dkms "${pkgdir}/usr/src/nvidia-$pkgver"
      mv "${pkgdir}/usr/src/nvidia-$pkgver/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-$pkgver/dkms.conf"

      # Force module to load even on unsupported GPUs
      mkdir -p "$pkgdir"/usr/lib/modprobe.d
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "$pkgdir"/usr/lib/modprobe.d/nvidia-open.conf

      install -Dm644 ${_srcbase}-${pkgver}/COPYING "$pkgdir"/usr/share/licenses/$pkgname
    else
      pkgdesc="NVIDIA kernel module sources (DKMS)"
      depends=('dkms' "nvidia-utils-tkg>=${pkgver}" 'nvidia-libgl' 'pahole')
      provides=("nvidia=${pkgver}" 'nvidia-dkms' "nvidia-dkms-tkg=${pkgver}" 'NVIDIA-MODULE')
      conflicts=('nvidia' 'nvidia-dkms')

      cd ${_pkg}
      install -dm 755 "${pkgdir}"/usr/{lib/modprobe.d,src}
      cp -dr --no-preserve='ownership' kernel-dkms "${pkgdir}/usr/src/nvidia-${pkgver}"

      if [[ ! "$_disable_libalpm_hook" == "true" ]]; then
        if [ "${_module_signing:-false}" = "true" ]; then
          install -Dm755 "${_where}/nvidia-all-config/nvidia-sign-modules" "${pkgdir}/usr/lib/nvidia-tkg/sign-modules"
          install -Dm644 "${_where}/nvidia-all-config/system/nvidia-tkg-sign.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
        else
          install -Dm644 "${_where}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
        fi
      else
        echo "Skipping mkinitcpio hook due to user config"
      fi

      install -Dt "${pkgdir}/usr/share/licenses/${pkgname}" -m644 "${srcdir}/${_pkg}/LICENSE"
    fi

    # Enable nvidia-uvm autoload at boot
    if [[ "$_blacklist_nouveau" != "false" ]]; then
      echo "nvidia-uvm" |
        install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modules-load.d/${pkgname}-uvm.conf"
    else
      msg2 "Skipping nvidia-uvm autoload due to user config"
    fi
  }
source /dev/stdin <<EOF
package_$__branchname-dkms-tkg() {
  nvidia-dkms-tkg
}
EOF
fi

# exit_cleanup and trap are defined in nvidia-all-config/prepare
