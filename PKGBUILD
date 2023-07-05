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
plain '  /sssssssssssssssssssssssssssssssssss/'
plain ' :sssssssssssssoosssssssoosssssssssssss:'
plain ' osssssssssssssoosssssssoossssssssssssso'
plain ' osssssssssssyyyyhhhhhhhyyyyssssssssssso'
plain ' /yyyyyyhhdmmmmNNNNNNNNNNNmmmmdhhyyyyyy/'
plain '  smmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmms'
plain '   /dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd/'
plain '    `:sdNNNNNNNNNNNNNNNNNNNNNNNNNds:`'
plain '       `-+shdNNNNNNNNNNNNNNNdhs+-`'
plain '             `.-:///////:-.`'
plain ''

where="$PWD" # track basedir as different Arch based distros are moving srcdir around
source "$where"/customization.cfg

# Load external configuration file if present. Available variable values will overwrite customization.cfg ones.
if [ -e "$_EXT_CONFIG_PATH" ]; then
  source "$_EXT_CONFIG_PATH" && msg2 "External configuration file '$_EXT_CONFIG_PATH' will be used to override customization.cfg values." && plain ""
fi

# Auto-add kernel userpatches to source
_autoaddpatch="false"

# Package type selector
if [ -z "$_driver_version" ] || [ "$_driver_version" = "latest" ] || [ -z "$_driver_branch" ] && [ ! -e options ]; then
  # Unset this just in case another prompt using CONDITION is ever added before this code.
  unset CONDITION
  if [ "$_driver_version" = "latest" ]; then
    if [ "$_driver_branch" = "regular" ]; then
      CONDITION="2"
    elif [ "$_driver_branch" = "vulkandev" ]; then
      CONDITION="1"
    else
      error "\"latest\" driver specified, but without branch. Make sure _driver_branch is set."
    fi
  fi
  if [[ -z $CONDITION ]]; then
    read -p "    What driver version do you want?`echo $'\n    > 1.Vulkan dev: 525.47.27\n      2.535 series: 535.54.03\n      3.530 series: 530.41.03\n      4.525 series: 525.116.04\n      5.520 series: 520.56.06\n      6.515 series: 515.86.01\n      7.510 series: 510.85.02\n      8.495 series: 495.46\n      9.470 series: 470.199.02\n      10.Older series\n      11.Custom version (396.xx series or higher)\n    choice[1-11?]: '`" CONDITION;
  fi
    # This will be treated as the latest regular driver.
    if [ "$CONDITION" = "2" ]; then
      echo '_driver_version=535.54.03' > options
      echo '_md5sum=ae579c6b94300b9d0f9289c9eaa704bb' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "3" ]; then
      echo '_driver_version=530.41.03' > options
      echo '_md5sum=9049dbe01410eac1e05b249de10f6b91' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "4" ]; then
      echo '_driver_version=525.116.04' > options
      echo '_md5sum=416818dcdf3c923b851e88a759bd0e00' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "5" ]; then
      echo '_driver_version=520.56.06' > options
      echo '_md5sum=18136ef051cbfc3850e88aa5184b31b8' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "6" ]; then
      echo '_driver_version=515.86.01' > options
      echo '_md5sum=5eaf6786f0c92cfcecb1ab950ff70df5' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "7" ]; then
      echo '_driver_version=510.85.02' > options
      echo '_md5sum=0367f772fc61bccecee8559c4fe9bb3d' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "8" ]; then
      echo '_driver_version=495.46' > options
      echo '_md5sum=db1d6b0f9e590249bbf940a99825f000' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "9" ]; then
      echo '_driver_version=470.199.02' > options
      echo '_md5sum=52d91b58029e6b79f33090c53ee9560f' >> options
      echo '_driver_branch=regular' >> options
    elif [ "$CONDITION" = "10" ]; then
      read -p "    Which legacy driver version do you want?`echo $'\n    > 1.465 series: 465.31\n      2.460 series: 460.91.03\n      3.455 series: 455.45.01\n      4.450 series: 450.119.03\n      5.440 series: 440.100 (kernel 5.8 or lower)\n      6.435 series: 435.21  (kernel 5.6 or lower)\n      7.430 series: 430.64  (kernel 5.5 or lower)\n      8.418 series: 418.113 (kernel 5.5 or lower)\n      9.415 series: 415.27  (kernel 5.4 or lower)\n      10.410 series: 410.104 (kernel 5.5 or lower)\n      11.396 series: 396.54  (kernel 5.3 or lower, 5.1 or lower recommended)\n    choice[1-11?]: '`" CONDITION;
      if [ "$CONDITION" = "2" ]; then
        echo '_driver_version=460.91.03' > options
        echo '_md5sum=15c5ada08bdb25d757d90e0f21b6f270' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "3" ]; then
        echo '_driver_version=455.45.01' > options
        echo '_md5sum=f0161877350aa9155eada811ff2844a8' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "4" ]; then
        echo '_driver_version=450.119.03' > options
        echo '_md5sum=b2725b8c15a364582be90c5fa1d6690f' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "5" ]; then
        echo '_driver_version=440.100' > options
        echo '_md5sum=7b99bcd2807ecd37af60d29de7bc30c2' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "6" ]; then
        echo '_driver_version=435.21' > options
        echo '_md5sum=050acb0aecc93ba15d1fc609ee82bebe' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "7" ]; then
        echo '_driver_version=430.64' > options
        echo '_md5sum=a4ea35bf913616c71f104f15092df714' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "8" ]; then
        echo '_driver_version=418.113' > options
        echo '_md5sum=0b21dbabaa25beed46c20a177e59642e' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "9" ]; then
        echo '_driver_version=415.27' > options
        echo '_md5sum=f4777691c4673c808d82e37695367f6d' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "10" ]; then
        echo '_driver_version=410.104' > options
        echo '_md5sum=4f3219b5fad99465dea399fc3f4bb866' >> options
        echo '_driver_branch=regular' >> options
      elif [ "$CONDITION" = "11" ]; then
        echo '_driver_version=396.54' > options
        echo '_md5sum=195afa93d400bdbb9361ede6cef95143' >> options
        echo '_driver_branch=regular' >> options
      else
        echo '_driver_version=465.31' > options
        echo '_md5sum=4996eefa54392b0c9541d22e88abab66' >> options
        echo '_driver_branch=regular' >> options
      fi
    elif [ "$CONDITION" = "11" ]; then
      echo '_driver_version=custom' > options
      read -p "What branch do you want?`echo $'\n> 1.Stable or regular beta\n  2.Vulkan dev\nchoice[1-2?]: '`" CONDITION;
      if [ "$CONDITION" = "2" ]; then
        echo '_driver_branch=vulkandev' >> options
        read -p "Type the desired version number (format: xxx.xx.xx): " _driver_version;
      else
        echo '_driver_branch=regular' >> options
        read -p "Type the desired version number (format: xxx.xx.xx or xxx.xxx or xxx.xx): " _driver_version;
      fi
      echo "_md5sum='SKIP'" >> options
      echo "_driver_version=$_driver_version" >> options
    # This (condition 1) will be treated as the latest Vulkan developer driver.
    else
      echo '_driver_version=525.47.27' > options
      echo '_md5sum=a0cb80ac18553a8eed2acb0f30729c48' >> options
      echo '_driver_branch=vulkandev' >> options
    fi
# Package type selector
  if [ -z "$_dkms" ]; then
    read -p "Build the dkms package or the regular one?`echo $'\n> 1.dkms (recommended)\n  2.regular\nchoice[1-2?]: '`" CONDITION;
      if [ "$CONDITION" = "2" ]; then
        echo '_dkms="false"' >> options
      else
        echo '_dkms="true"' >> options
      fi
  fi
else
  _md5sum='SKIP'
fi

if [ -e options ]; then
  source options
  if [ "$_open_source_modules" != "false" ]; then
    # Open source kernel module availability check
    if [[ "$( curl -Is "https://github.com/NVIDIA/open-gpu-kernel-modules/releases/tag/$_driver_version" | head -n 1 )" = *200* ]]; then
      if [ -z "$_open_source_modules" ]; then
        msg2 " - Open source kernel modules available - "
        warning "IT ONLY OFFERS SUPPORT FOR TURING AND NEWER, AND DOESN'T OFFER ALL THE FEATURES OF THE PROPRIETARY ONE."
        warning "SLI, G-Sync on notebooks and virtual GPU support are notably missing."
        plain "Do you want to use it instead of the proprietary one?"
        read -rp "`echo $'    > N/y : '`" _open_source;
        if [[ "$_open_source" =~ [yY] ]]; then
          echo '_open_source_modules="true"' >> options
        else
          echo '_open_source_modules="false"' >> options
        fi
      fi
    else
      msg2 "No open source kernel module available"
      echo '_open_source_modules="false"' >> options
    fi
    source options
  fi
fi

# Check if the version we are going for is newer or not if enabled
if [[ "$_only_update_if_newer" == "true" ]]; then
  # Check current version, if possible
  if pacman -Qs "nvidia-utils" >/dev/null; then
    # We have enough packages installed to get the version
    # returns a string, like "460.39" or "455.45.01"
    # HACK Checks the first nvidia-utils match, does not catch potential missmatches and other stuff
    _current_version=$(pacman -Q "nvidia-utils" | grep -oP '\d+(\.\d+)+' | head -n 1)
    _current_package_example=$(pacman -Q "nvidia-utils" | grep -oP '[a-z]+(\-[a-z]+)+' | head -n 1)
    msg2 "Found version $_current_version installed (from package '$_current_package_example')"

    ## HACK Stupid string compare
    ## TODO Ensure that nvidia versions do not differ from this format
    if [[ $_driver_version > $_current_version ]]; then
      # We have a newer version to install, do nothing
      msg2 "Selected version ($_driver_version, $_driver_branch) is newer than installed version, continuing."
    else
      # Older version, or at least not newer version
      msg2 "Selected version ($_driver_version, $_driver_branch) is not newer than installed version, exiting."
      plain ""
      if [ -e "$_EXT_CONFIG_PATH" ]; then
        plain "If this is not intended, have a look at '$_EXT_CONFIG_PATH'"
      else
        plain "If this is not intended, have a look at '"$where"/customization.cfg'"
      fi

      # We have to clean up "options"
      rm -f "${where}"/options
      # TODO Do we need to clean up something more?
      # TODO Should the exit_cleanup be called? (requires reorganization of script)
      exit 0
    fi
  else
    warning "'\$_only_update_if_newer' is enabled, but no installed driver found."
    warning "Continuing on as if '\$_only_update_if_newer' was not enabled."
    plain ""
  fi
fi

msg2 "Building driver version $_driver_version on branch $_driver_branch."

# Skip header check for dkms-only builds with explicit target kernel version
if [ "$_dkms" != "true" ] || [ -z "$_kerneloverride" ]; then
  # Some people seem to believe making blank headers is a good idea
  if [ $(pacman -Qs linux-headers | head -c1 | wc -c) -eq 0 ] && [ $(pacman -Qs linux-zen-headers | head -c1 | wc -c) -eq 0 ] && [ $(pacman -Qs linux-hardened-headers | head -c1 | wc -c) -eq 0 ] && [ $(pacman -Qs linux-neptune-dri-headers | head -c1 | wc -c) -eq 0 ] && [ $(pacman -Qs linux-cachyos-headers | head -c1 | wc -c) -eq 0 ] && [ $(pacman -Qs linux-cachyos-bore-headers | head -c1 | wc -c) -eq 0 ]; then
    error "A (correctly made?) linux-headers package can't be found."
    plain "If you're sure it's installed, blame your kernel maintainer."
    read -p "    Press enter to proceed anyway..."
  fi
fi

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
  __branchname="nvidia$_series-open"
else
  __branchname="$_branchname"
fi

if [ "$_dkms" = "full" ]; then
  _pkgname_array+=("$__branchname-dkms-tkg")
  _pkgname_array+=("$__branchname-tkg")
elif [ "$_dkms" = "true" ]; then
  _pkgname_array+=("$__branchname-dkms-tkg")
else
  _pkgname_array+=("$__branchname-tkg")
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

if [ "$_eglwayland" = "true" ]; then
  _pkgname_array+=("$_branchname-egl-wayland-tkg")
fi

pkgname=("${_pkgname_array[@]}")
pkgver=$_driver_version
pkgrel=248
arch=('x86_64')
url="http://www.nvidia.com/"
license=('custom:NVIDIA')
optdepends=('linux-headers' 'linux-lts-headers: Build the module for LTS Arch kernel')
options=(!strip !lto !buildflags)

cp "$where"/patches/* "$where" && cp -r "$where"/system/* "$where"

# Installer name
_pkg="NVIDIA-Linux-x86_64-$pkgver"

# Source
if [ "$_driver_branch" = "vulkandev" ]; then
  if (( ${pkgver%%.*} >= 525 )); then
    _source_name="NVIDIA-Linux-x86_64-$pkgver.run::https://developer.nvidia.com/downloads/vulkan-beta-${pkgver//.}-linux"
  elif [[ $pkgver = 396* ]]; then
    _source_name="NVIDIA-Linux-x86_64-$pkgver.run::https://developer.nvidia.com/linux-${pkgver//.}"
  else
    _source_name="NVIDIA-Linux-x86_64-$pkgver.run::https://developer.nvidia.com/vulkan-beta-${pkgver//.}-linux"
  fi
else
  _source_name="https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run"
fi

source=($_source_name
        '10-nvidia-drm-outputclass.conf'
        'nvidia-utils-tkg.sysusers'
        '60-nvidia.rules'
        'nvidia-tkg.hook'
        'nvidia-open-gcc-ibt-sls.diff'
        'linux-version.diff' # include linux version
        '01-ipmi-vm.diff' # ipmi & vm patch for older than 415.22 releases (2018.12.7) (396.xx)
        '02-ipmi-vm.diff' # ipmi & vm patch for older than 415.22 releases (2018.12.7) (addon for 410+)
        'list_is_first.diff' # fix for "redefinition of ‘list_is_first’" on <418.56 drivers when used on 5.1+
        'kernel-4.16.patch' # 4.16 workaround
        'kernel-4.19.patch' # 4.19 workaround
        'kernel-5.0.patch' # 5.0 workaround
        'kernel-5.1.patch' # 5.1 workaround
        'kernel-5.2.patch' # 5.2 workaround
        'kernel-5.3.patch' # 5.3 workaround
        'kernel-5.4.patch' # 5.4 workaround
        'kernel-5.4-symver.diff' # 5.4 symver fix only
        'kernel-5.4-prime.diff' # 5.4+ PRIME fixing attempt
        'kernel-5.5.patch' # 5.5 workaround
        'kernel-5.6.patch' # 5.6 workaround
        '5.6-legacy-includes.diff' # 5.6 includes needed for <440.59(stable) and <440.58.01(vk dev)
        '5.6-ioremap.diff' # 5.6 additional ioremap workaround (<440.64)
        'kernel-5.7.patch' # 5.7 workaround
        'kernel-5.8.patch' # 5.8 workaround
        '5.8-legacy.diff' # 5.8 additional vmalloc workaround (<450.57)
        'kernel-5.9.patch' # 5.9 workaround
        '5.9-gpl.diff' # 5.9 cuda/nvenc workaround
        'kernel-5.10.patch' # 5.10 workaround
        'kernel-5.11.patch' # 5.11 workaround
        '5.11-legacy.diff' # 5.11 additional workaround (<460.32.03)
        '455-crashfix.diff' # 455 drivers fix - https://forums.developer.nvidia.com/t/455-23-04-page-allocation-failure-in-kernel-module-at-random-points/155250/79
        'kernel-5.12.patch' # 5.12 workaround
        'kernel-5.14.patch' # 5.14 workaround
        'kernel-5.16.patch' # 5.16 workaround
        'kernel-5.16-std.diff' # 5.16 workaround for 470.6x
        'kernel-5.17.patch' # 5.17 workaround
        'kernel-6.0.patch'
        'kernel-6.0-470.patch' # acpi backports from 515.x for 470.x
        'kernel-6.2.patch'
        'kernel-6.3.patch'
)

msg2 "Selected driver integrity check behavior (md5sum or SKIP): $_md5sum" # If the driver is "known", return md5sum. If it isn't, return SKIP

md5sums=("$_md5sum"
         'cb27b0f4a78af78aa96c5aacae23256c'
         '3d2894e71d81570bd00bce416d3e547d'
         '3d32130235acc5ab514e1021f7f5c439'
         '596f7cbf2db48d4f5b1c38967bb93cea'
         '9b1543768ea75320fd0d2315de66d1c8'
         '7a825f41ada7e106c8c0b713a49b3bfa'
         'd961d1dce403c15743eecfe3201e4b6a'
         '14460615a9d4e247c8d9bcae8776ed48'
         '401859ea7bb4a9864af24ecd67abf34c'
         'adb83cede754daf5adb001f077b1ff67'
         '58d058367934813d29d38328bc3b4dcd'
         '6cff80c311debfdb6b543e575a81820a'
         'a3ce8ebab6506f556f4b222e2372ce87'
         '98b67a671ece0a796f9767793c209c93'
         '6f9a62ef76ac86f299b0174f44488987'
         '8bf41d705afdf9aad7d934be06a7b12b'
         '0d9aa49647cc73a4522246cc22ae15e1'
         'e6270c2d19afd982efc92bdecd9f48f0'
         '1c1966d6ee6f3cd381ebcc92f1488c68'
         'c44e43638e1ab708fbdd6d7aa76afcf2'
         '84dc2d2eff2846b2f961388b153e2a89'
         '1f11f5c765e42c471b202e630e3cd407'
         'd911a0531c6f270926cacabd1dd80f02'
         '589dfc0c801605018b7ccd690f06141a'
         'd67bf0a9aa5c19f07edbaf6bd157d661'
         '888d12b9aea711e6a025835b8ad063e2'
         '0758046ed7c50463fd0ec378e9e34f95'
         'bcdd512edad1bad8331a8872259d2581'
         'fd0d6e14e675a61f32279558678cfc36'
         '8764cc714e61363cc8f818315957ad17'
         '08bec554de265ce5fdcfdbd55fb608fc'
         '3980770412a1d4d7bd3a16c9042200df'
         'f5fd091893f513d2371654e83049f099'
         'd684ca11fdc9894c14ead69cb35a5946'
         '0f987607c98eb6faeb7d691213de6a70'
         'a70bc9cbbc7e8563b48985864a11de71'
         '31128900574dec9ebdb753db50ef4f16'
         '0b9b855d9be313153a5903e46e774a30'
         '5d573b1aa0712b9bd2000c9fefdf84c2'
         'a6acbba08173769399658914eb86a212')

if [ "$_open_source_modules" = "true" ]; then
  source+=("$pkgname-$pkgver.tar.gz::https://github.com/NVIDIA/open-gpu-kernel-modules/archive/refs/tags/${pkgver}.tar.gz")
  md5sums+=("SKIP")
fi

if [ "$_autoaddpatch" = "true" ]; then
  # Auto-add *.patch files from $startdir to source=()
  for _patch in $(find "$startdir" -maxdepth 1 -name '*.patch' -printf "%f\n"); do
    # Don't duplicate already listed ones
    if [[ ! " ${source[@]} " =~ " $_patch " ]]; then  # https://stackoverflow.com/a/15394738/1821548
      source+=("$_patch")
      md5sums+=('SKIP')
    fi
  done
fi

_create_links() {
  # create missing soname links
  find "$pkgdir" -type f -name '*.so*' ! -path '*xorg/*' -print0 | while read -d $'\0' _lib; do
    if [[ $_lib != *libnvidia-vulkan-producer.* ]]; then # Workaround no SONAME entry for libnvidia-vulkan-producer.so
      _dirname="$(dirname "${_lib}")"
      _original="$(basename "${_lib}")"
      _soname="$(readelf -d "${_lib}" | grep -Po 'SONAME.*: \[\K[^]]*' || true)" # Get soname/base name
      _base="$(echo ${_soname} | sed -r 's/(.*)\.so.*/\1.so/')"

      cd "${_dirname}"

      # Create missing links
      if ! [[ -z "${_soname}" ]]; then # if not empty
        if ! [[ -e "./${_soname}" ]]; then
          ln -s $(basename "${_lib}") "./${_soname}"
        fi
      fi
      if ! [[ -z "${_base}" ]]; then # if not empty (if _soname is empty, _base should be too)
        if ! [[ -e "./${_base}" ]]; then
          ln -s "./${_soname}" "./${_base}"
        fi
      fi
    fi
  done
  cd "${where}"
}

prepare() {
  # Remove previous builds
  [ -d "$_pkg" ] && rm -rf "$_pkg"

  # Use custom compiler paths if defined
  if [ -n "${CUSTOM_GCC_PATH}" ]; then
    PATH=${CUSTOM_GCC_PATH}/bin:${CUSTOM_GCC_PATH}/lib:${CUSTOM_GCC_PATH}/include:${PATH}
  fi

  # Extract
  msg2 "Self-Extracting $_pkg.run..."
  sh "$_pkg".run -x

  if [ "$_open_source_modules" = "true" ]; then
    cd open-gpu-kernel-modules-${pkgver}

    # Fix for https://bugs.archlinux.org/task/74886
    if (( ${pkgver%%.*} < 525 )); then
      patch -Np1 --no-backup-if-mismatch -i "$srcdir"/nvidia-open-gcc-ibt-sls.diff
    fi

    # Attempt to make this reproducible
    sed -i "s/^HOSTNAME.*/HOSTNAME = echo archlinux"/ utils.mk
    sed -i "s/^WHOAMI.*/WHOAMI = echo archlinux-builder"/ utils.mk
    sed -i "s/^DATE.*/DATE = date -r version.mk"/ utils.mk

    sed -i "s/__VERSION_STRING/${pkgver}/" kernel-open/dkms.conf
    sed -i 's/__JOBS/`nproc`/' kernel-open/dkms.conf
    sed -i 's/__EXCLUDE_MODULES//' kernel-open/dkms.conf
    sed -i 's/__DKMS_MODULES//' kernel-open/dkms.conf
    sed -i '$i\
BUILT_MODULE_NAME[0]="nvidia"\
BUILT_MODULE_LOCATION[0]="kernel-open"\
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"\
BUILT_MODULE_NAME[1]="nvidia-uvm"\
BUILT_MODULE_LOCATION[1]="kernel-open"\
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"\
BUILT_MODULE_NAME[2]="nvidia-modeset"\
BUILT_MODULE_LOCATION[2]="kernel-open"\
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"\
BUILT_MODULE_NAME[3]="nvidia-drm"\
BUILT_MODULE_LOCATION[3]="kernel-open"\
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"\
BUILT_MODULE_NAME[4]="nvidia-peermem"\
BUILT_MODULE_LOCATION[4]="kernel-open"\
DEST_MODULE_LOCATION[4]="/kernel/drivers/video"' kernel-open/dkms.conf

    # Clean version for later copying for DKMS
    cp -r ../open-gpu-kernel-modules-${pkgver} "$srcdir"/open-gpu-kernel-modules-dkms
  else
    cd "$_pkg"

    # linux-rt fix for newer drivers. This just passes the same value regardless of kernel type as a bypass. This was stolen from https://gitlab.manjaro.org/packages/community/realtime-kernels/linux416-rt-extramodules/blob/master/nvidia/PKGBUILD - Thanks Muhownage <3
    sed -i -e 's|PREEMPT_RT_PRESENT=1|PREEMPT_RT_PRESENT=0|g' kernel/conftest.sh

    # non-english locale workaround for 440.26
    if [[ $pkgver = 440.26 ]]; then
      sed -i -e 's|$CC $CFLAGS -c conftest_headers$$.c|LC_ALL=C $CC $CFLAGS -c conftest_headers$$.c|g' kernel/conftest.sh
    fi

    # 440.58.01 Unfrogging
    if [[ $pkgver = 440.58.01 ]]; then
      sed -i -e '/bug/d' nvidia-application-profiles-440.58.01-rc
    fi

    cp -a kernel kernel-dkms
    cd kernel-dkms
    sed -i "s/__VERSION_STRING/${pkgver}/" dkms.conf
    sed -i 's/__JOBS/`nproc`/' dkms.conf
    sed -i 's/__DKMS_MODULES//' dkms.conf
    if (( ${pkgver%%.*} >= 470 )); then
        sed -i '$iBUILT_MODULE_NAME[0]="nvidia"\
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"\
BUILT_MODULE_NAME[1]="nvidia-uvm"\
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"\
BUILT_MODULE_NAME[2]="nvidia-modeset"\
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"\
BUILT_MODULE_NAME[3]="nvidia-drm"\
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"\
BUILT_MODULE_NAME[4]="nvidia-peermem"\
DEST_MODULE_LOCATION[4]="/kernel/drivers/video"' dkms.conf
    elif (( ${pkgver%%.*} = 465 )); then
      sed -i '$iBUILT_MODULE_NAME[0]="nvidia"\
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"\
BUILT_MODULE_NAME[1]="nvidia-uvm"\
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"\
BUILT_MODULE_NAME[2]="nvidia-modeset"\
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"\
BUILT_MODULE_NAME[3]="nvidia-drm"\
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"\
BUILT_MODULE_NAME[4]="nvidia-peermem"\
DEST_MODULE_LOCATION[4]="/kernel/drivers/video"\
BUILT_MODULE_NAME[5]="nvidia-ib-peermem-stub"\
DEST_MODULE_LOCATION[5]="/kernel/drivers/video"' dkms.conf
    else
      sed -i '$iBUILT_MODULE_NAME[0]="nvidia"\
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"\
BUILT_MODULE_NAME[1]="nvidia-uvm"\
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"\
BUILT_MODULE_NAME[2]="nvidia-modeset"\
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"\
BUILT_MODULE_NAME[3]="nvidia-drm"\
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"' dkms.conf
    fi

    # Gift for linux-rt guys
    sed -i 's/NV_EXCLUDE_BUILD_MODULES/IGNORE_PREEMPT_RT_PRESENCE=1 NV_EXCLUDE_BUILD_MODULES/' dkms.conf

    cd ../
    bsdtar -xf nvidia-persistenced-init.tar.bz2

    if [[ $pkgver = 396* ]] || [[ $pkgver = 410* ]] || [[ $pkgver = 415* ]] || [[ $pkgver = 418* ]] || [[ $pkgver = 430* ]]; then
      sed -i 's/__NV_VK_ICD__/libGLX_nvidia.so.0/' nvidia_icd.json.template
    fi

    # Loop kernels (4.15.0-1-ARCH, 4.14.5-1-ck, ...)
    local -a _kernels
    if [ -n "$_kerneloverride" ]; then
      _kernels="$_kerneloverride"
    else
      mapfile -t _kernels < <(find /usr/lib/modules/*/build/version -exec cat {} + || find /usr/lib/modules/*/extramodules/version -exec cat {} +)
    fi
    for _kernel in "${_kernels[@]}"; do
      # Use separate source directories
      cp -r kernel kernel-"$_kernel"

      cd "$srcdir"/"$_pkg"/kernel-"$_kernel"
      if (( ${pkgver%%.*} <= 455 )); then
        msg2 "Applying linux-version.diff for $_kernel..."
        patch -p2 -i "$srcdir"/linux-version.diff
      fi

      # https://forums.developer.nvidia.com/t/455-23-04-page-allocation-failure-in-kernel-module-at-random-points/155250/77
      # Not sure if it actually affects 455.50.02 - let's skip the patch on that version for now
      if [[ $pkgver = 455.2* ]] || [[ $pkgver = 455.3* ]] || [[ $pkgver = 455.4* ]]; then
        msg2 "Applying 455 crashfix for $_kernel..."
        patch -p2 -i "$srcdir"/455-crashfix.diff
      fi
      cd ..

      ## kernel version variables, quirks & driver patch whitelists

      # https://bugs.archlinux.org/task/62142
      if [ "$_62142_fix" = "true" ]; then
        sed -i 's/return (ops->map_resource != NULL);/return (ops \&\& ops->map_resource);/' "$srcdir/$_pkg/kernel-$_kernel/nvidia/nv-dma.c" && msg2 "Applied fix for https://bugs.archlinux.org/task/62142"
      fi

      # 4.16
      if (( $(vercmp "$_kernel" "4.16") >= 0 )); then
        _kernel416="1"
        _whitelist416=( 396* 410* 415* 418.3* 418.4* 418.52.0* 418.52.10 418.52.14 )
      fi

      # 4.19
      if (( $(vercmp "$_kernel" "4.19") >= 0 )); then
        _kernel419="1"
        _whitelist419=( 396* )
      fi

      # 4.20
      if (( $(vercmp "$_kernel" "4.20") >= 0 )); then
        # Fix for "unknown type name 'ipmi_user_t'" (required for older than 2018.12.7 drivers when used on 4.20+)
        if [[ $pkgver = 396* ]] || [[ $pkgver = 410.5* ]] || [[ $pkgver = 410.6* ]] || [[ $pkgver = 410.7* ]] || [[ $pkgver = 415.1* ]]; then
          _oldstuff="1"
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 01-ipmi-vm.diff for $_kernel..."
          patch -p2 -i "$srcdir"/01-ipmi-vm.diff
          if [[ $pkgver != 396* ]]; then
            _youngeryetoldstuff="1"
            msg2 "Applying 02-ipmi-vm.diff for $_kernel..."
            patch -p2 -i "$srcdir"/02-ipmi-vm.diff
          fi
          cd ..
        else
          msg2 "Skipping ipmi-vm fixes (not needed for this driver/kernel combination)"
        fi
      fi

      # 5.0
      if (( $(vercmp "$_kernel" "5.0") >= 0 )); then
        _kernel50="1"
        _whitelist50=( 396* 410.5* 410.6* 410.7* 410.9* 415* )
      fi

      # 5.1
      if (( $(vercmp "$_kernel" "5.1") >= 0 )); then
        _kernel51="1"
        _whitelist51=( 396* 410* 415* 418.3* 418.4* 418.52.0* 418.52.10 )
        if [[ $pkgver != 430* ]]; then
          sed -i "s/static int nv_drm_vma_fault(struct vm_fault \*vmf)/#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 1, 0)\nstatic int nv_drm_vma_fault(struct vm_fault \*vmf)\n#else\nstatic vm_fault_t nv_drm_vma_fault(struct vm_fault \*vmf)\n#endif/g" "$srcdir/$_pkg/kernel-$_kernel/nvidia-drm/nvidia-drm-gem-nvkms-memory.c"
          if [[ $pkgver = 396* ]] || [[ $pkgver = 410* ]] || [[ $pkgver = 415* ]] || [[ $pkgver = 418.3* ]] || [[ $pkgver = 418.4* ]]; then
            _low418="1"
            cd "$srcdir"/"$_pkg"/kernel-$_kernel
            msg2 "Applying list_is_first.diff for $_kernel..."
            # Use sed for the moving parts of the patch - Fix for "redefinition of ‘list_is_first’" (required for older than 418.56 drivers when used on 5.1+)
            sed -i "s/static inline int list_is_first(const struct list_head \*list,/#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 1, 0)\nstatic inline int list_is_first(const struct list_head \*list,/g" "$srcdir/$_pkg/kernel-$_kernel/common/inc/nv-list-helpers.h"
            sed -i "s/                                const struct list_head \*head)/                                const struct list_head \*head)\n#else\nstatic inline int nv_list_is_first(const struct list_head \*list,\n                                   const struct list_head \*head)\n#endif/g" "$srcdir/$_pkg/kernel-$_kernel/common/inc/nv-list-helpers.h"
            patch -Np2 -i "$srcdir"/list_is_first.diff
            cd ..
          else
            msg2 "Skipping list_is_first fixes (not needed for this driver/kernel combination)"
          fi
        fi
      fi

      # 5.2
      if (( $(vercmp "$_kernel" "5.2") >= 0 )); then
        _kernel52="1"
        _whitelist52=( 396* 410* 415* 418.3* 418.4* 418.56 418.7* 418.52.0* 418.52.10 418.52.14 )
      fi

      # 5.3
      if (( $(vercmp "$_kernel" "5.3") >= 0 )); then
        _kernel53="1"
        _whitelist53=( 396* 410* 415* 418.3* 418.4* 418.5* 418.7* 418.8* )
      fi

      # 5.4
      if (( $(vercmp "$_kernel" "5.4") >= 0 )); then
        _kernel54="1"
        _whitelist54=( 410* 415* 418.3* 418.4* 418.5* 418.7* 418.8* 430.0* 430.1* 430.2* 430.3* 430.4* 430.5* 435.1* 435.21* 435.24* 435.27.01 )
        if [[ $pkgver = 435.27.02 ]] || [[ $pkgver = 435.27.03 ]] || [[ $pkgver = 435.27.06 ]] || [[ $pkgver = 435.27.07 ]] || [[ $pkgver = 435.27.08 ]] || [[ $pkgver = 440.26 ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying kernel-5.4-symver.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/kernel-5.4-symver.diff
          cd ..
        fi
        if [[ $pkgver = 410* ]] || [[ $pkgver = 415* ]] || [[ $pkgver = 418.* ]] || [[ $pkgver = 430.0* ]] || [[ $pkgver = 435.* ]] || [[ $pkgver = 440.2* ]] || [[ $pkgver = 440.3* ]] || [[ $pkgver = 440.43.* ]] || [[ $pkgver = 440.44 ]] && [ "$_54_prime_fixing_attempt" = "true" ]; then
          _54_prime="true"
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying kernel-5.4-prime.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/kernel-5.4-prime.diff
          cd ..
        fi
      fi

      # 5.5
      if (( $(vercmp "$_kernel" "5.5") >= 0 )); then
        _kernel55="1"
        _whitelist55=( 410* 418* 430* 435* 440.2* 440.3* 440.43.01 440.44 )
      fi

      # 5.6
      if (( $(vercmp "$_kernel" "5.6") >= 0 )); then
        _kernel56="1"
        _whitelist56=( 435* 440.2* 440.3* 440.4* 440.5* 440.6* )
        if [[ $pkgver = 418.* ]] || [[ $pkgver = 435.* ]] || [[ $pkgver = 440.2* ]] || [[ $pkgver = 440.3* ]] || [[ $pkgver = 440.4* ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 5.6-legacy-includes.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.6-legacy-includes.diff
          msg2 "Applying 5.6-ioremap.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.6-ioremap.diff
          cd ..
        elif [[ $pkgver = 440.5* ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 5.6-ioremap.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.6-ioremap.diff
          cd ..
        fi
      fi

      # 5.7
      if (( $(vercmp "$_kernel" "5.7") >= 0 )); then
        _kernel57="1"
        _whitelist57=( 440* )
      fi

      # 5.8
      if (( $(vercmp "$_kernel" "5.8") >= 0 )); then
        _kernel58="1"
        _whitelist58=( 440* 450.3* 450.51 450.56.01 )
        if [[ $pkgver = 44* ]] || [[ $pkgver = 450.3* ]] || [[ $pkgver = 450.51 ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 5.8-legacy.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.8-legacy.diff
          cd ..
        fi
      fi

      # 5.9
      if (( $(vercmp "$_kernel" "5.9") >= 0 )); then
        _kernel59="1"
        _whitelist59=( 450.5* 450.6* )
      fi

      # 5.9 - 5.10 quirk
      if (( $(vercmp "$_kernel" "5.9") >= 0 )) || (( $(vercmp "$_kernel" "5.10") >= 0 )); then
        if [[ $pkgver = 450* ]] || [[ $pkgver = 455.2* ]] || [[ $pkgver = 455.3* ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 5.9-gpl.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.9-gpl.diff
          cd ..
        fi
      fi

      # 5.10
      if (( $(vercmp "$_kernel" "5.10") >= 0 )); then
        _kernel510="1"
        _whitelist510=( 450.5* 450.6* 450.8* 455.2* 455.3* )
      fi

      # 5.11
      if (( $(vercmp "$_kernel" "5.11") >= 0 )); then
        _kernel511="1"
        _whitelist511=( 455.45* 455.50.0* 455.50.10 455.50.12 455.50.14 460.27* 460.32* )
        if [[ $pkgver = 455.45* ]] || [[ $pkgver = 455.50* ]] || [[ $pkgver = 460.27* ]] && [[ $pkgver != 455.50.19 ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying 5.11-legacy.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/5.11-legacy.diff
          cd ..
        fi
      fi

      # 5.12
      if (( $(vercmp "$_kernel" "5.12") >= 0 )); then
        _kernel512="1"
        _whitelist512=( 455.4* 455.5* )
      fi

      # 5.14
      if (( $(vercmp "$_kernel" "5.14") >= 0 )); then
        _kernel514="1"
        _whitelist514=( 465* 470.4* 470.5* )
      fi

      # 5.16
      if (( $(vercmp "$_kernel" "5.16") >= 0 )); then
        _kernel516="1"
        _whitelist516=( 470.8* 470.9* 495*)
        if [[ $pkgver = 470.62.* ]]; then
          cd "$srcdir"/"$_pkg"/kernel-$_kernel
          msg2 "Applying kernel-5.16-std.diff for $_kernel..."
          patch -Np2 -i "$srcdir"/kernel-5.16-std.diff
          cd ..
        fi
      fi

      # 5.17
      if (( $(vercmp "$_kernel" "5.17") >= 0 )); then
        _kernel517="1"
        _whitelist517=( 470.62.* 495*)
      fi

      # 6.0
      if (( $(vercmp "$_kernel" "6.0") >= 0 )); then
        _kernel60="1"
        _whitelist60=( 515.6* 470.4* 470.5* 470.6* 470.7* 470.8* 470.9* 470.10* 470.12* 470.14* )
      fi

      # 6.2
      if (( $(vercmp "$_kernel" "6.2") >= 0 )); then
        _kernel62="1"
        _whitelist62=( 525.5* 525.6* 525.7* )
      fi

      # 6.3
      if (( $(vercmp "$_kernel" "6.3") >= 0 )); then
        _kernel63="1"
        _whitelist63=( 470.16* 470.18* )
      fi

      # Loop patches (linux-4.15.patch, lol.patch, ...)
      for _p in $(printf -- '%s\n' ${source[@]} | grep .patch); do  # https://stackoverflow.com/a/21058239/1821548
        # Patch version (4.15, "", ...)
        _patch=$(echo $_p | grep -Po "\d+\.\d+")

        # Cd in place
        cd "$srcdir"/"$_pkg"/kernel-$_kernel

        if [ "$_patch" = "4.16" ]; then
          _whitelist=(${_whitelist416[@]})
        fi
        if [ "$_patch" = "4.19" ]; then
          _whitelist=(${_whitelist419[@]})
        fi
        if [ "$_patch" = "5.0" ]; then
          _whitelist=(${_whitelist50[@]})
        fi
        if [ "$_patch" = "5.1" ]; then
          _whitelist=(${_whitelist51[@]})
        fi
        if [ "$_patch" = "5.2" ]; then
          _whitelist=(${_whitelist52[@]})
        fi
        if [ "$_patch" = "5.3" ]; then
          _whitelist=(${_whitelist53[@]})
        fi
        if [ "$_patch" = "5.4" ]; then
          _whitelist=(${_whitelist54[@]})
        fi
        if [ "$_patch" = "5.5" ]; then
          _whitelist=(${_whitelist55[@]})
        fi
        if [ "$_patch" = "5.6" ]; then
          _whitelist=(${_whitelist56[@]})
        fi
        if [ "$_patch" = "5.7" ]; then
          _whitelist=(${_whitelist57[@]})
        fi
        if [ "$_patch" = "5.8" ]; then
          _whitelist=(${_whitelist58[@]})
        fi
        if [ "$_patch" = "5.9" ]; then
          _whitelist=(${_whitelist59[@]})
        fi
        if [ "$_patch" = "5.10" ]; then
          _whitelist=(${_whitelist510[@]})
        fi
        if [ "$_patch" = "5.11" ]; then
          _whitelist=(${_whitelist511[@]})
        fi
        if [ "$_patch" = "5.12" ]; then
          _whitelist=(${_whitelist512[@]})
        fi
        if [ "$_patch" = "5.14" ]; then
          _whitelist=(${_whitelist514[@]})
        fi
        if [ "$_patch" = "5.16" ]; then
          _whitelist=(${_whitelist516[@]})
        fi
        if [ "$_patch" = "5.17" ]; then
          _whitelist=(${_whitelist517[@]})
        fi
        if [ "$_patch" = "6.0" ]; then
          _whitelist=(${_whitelist60[@]})
        fi
        if [ "$_patch" = "6.2" ]; then
          _whitelist=(${_whitelist62[@]})
        fi
        if [ "$_patch" = "6.3" ]; then
          _whitelist=(${_whitelist63[@]})
        fi

        patchy=0
        if (( $(vercmp "$_kernel" "$_patch") >= 0 )); then
          for yup in "${_whitelist[@]}"; do
            [[ $pkgver = $yup ]] && patchy=1
          done

          if [ "$patchy" = "1" ]; then
            msg2 "Applying $_p for $_kernel..."
            patch -p2 -i "$srcdir"/$_p
          else
            msg2 "Skipping $_p as it doesn't apply to this driver version..."
          fi
        fi
      done

      cd ..

    done

    # dkms patches
    if [ "$_dkms" = "true" ]; then

      # https://bugs.archlinux.org/task/62142
      if [ "$_62142_fix" = "true" ]; then
        sed -i 's/return (ops->map_resource != NULL);/return (ops \&\& ops->map_resource);/' "$srcdir/$_pkg/kernel-dkms/nvidia/nv-dma.c" && msg2 "Applied fix for https://bugs.archlinux.org/task/62142"
      fi

      if (( ${pkgver%%.*} <= 455 )); then
        msg2 "Applying linux-version.diff for dkms..."
        patch -Np1 -i "$srcdir"/linux-version.diff
      fi

      # https://forums.developer.nvidia.com/t/455-23-04-page-allocation-failure-in-kernel-module-at-random-points/155250/77
      # Not sure if it actually affects 455.50.02 - let's skip the patch on that version for now
      if [[ $pkgver = 455.2* ]] || [[ $pkgver = 455.3* ]] || [[ $pkgver = 455.4* ]]; then
        msg2 "Applying 455 crashfix for dkms..."
        patch -Np1 -i "$srcdir"/455-crashfix.diff
      fi

      # 4.16
      if [ "$_kernel416" = "1" ]; then
        patchy=0
        for yup in "${_whitelist416[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-4.16.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-4.16.patch
        else
          msg2 "Skipping kernel-4.16.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 4.19
      if [ "$_kernel419" = "1" ]; then
        patchy=0
        for yup in "${_whitelist419[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-4.19.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-4.19.patch
        else
          msg2 "Skipping kernel-4.19.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.0
      if [ "$_kernel50" = "1" ]; then
        patchy=0
        for yup in "${_whitelist50[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.0.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.0.patch
        else
          msg2 "Skipping kernel-5.0.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.1
      if [ "$_kernel51" = "1" ]; then
        patchy=0
        for yup in "${_whitelist51[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.1.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.1.patch
          sed -i "s/static int nv_drm_vma_fault(struct vm_fault \*vmf)/#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 1, 0)\nstatic int nv_drm_vma_fault(struct vm_fault \*vmf)\n#else\nstatic vm_fault_t nv_drm_vma_fault(struct vm_fault \*vmf)\n#endif/g" "$srcdir/$_pkg/kernel-dkms/nvidia-drm/nvidia-drm-gem-nvkms-memory.c"
        else
          msg2 "Skipping kernel-5.1.patch as it doesn't apply to this driver version..."
        fi
        if [ "$_low418" = "1" ]; then
          msg2 "Applying list_is_first.patch for dkms..."
          # Use sed for the moving parts of the patch - Fix for "redefinition of ‘list_is_first’" (required for older than 418.56 drivers when used on 5.1+)
          sed -i "s/static inline int list_is_first(const struct list_head \*list,/#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 1, 0)\nstatic inline int list_is_first(const struct list_head \*list,/g" "$srcdir/$_pkg/kernel-dkms/common/inc/nv-list-helpers.h"
          sed -i "s/                                const struct list_head \*head)/                                const struct list_head \*head)\n#else\nstatic inline int nv_list_is_first(const struct list_head \*list,\n                                   const struct list_head \*head)\n#endif/g" "$srcdir/$_pkg/kernel-dkms/common/inc/nv-list-helpers.h"
          patch -Np1 -i "$srcdir"/list_is_first.diff
        fi
      fi

      # 5.2
      if [ "$_kernel52" = "1" ]; then
        patchy=0
        for yup in "${_whitelist52[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.2.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.2.patch
        else
          msg2 "Skipping kernel-5.2.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.3
      if [ "$_kernel53" = "1" ]; then
        patchy=0
        for yup in "${_whitelist53[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.3.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.3.patch
        else
          msg2 "Skipping kernel-5.3.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.4
      if [ "$_kernel54" = "1" ]; then
        patchy=0
        for yup in "${_whitelist54[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.4.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.4.patch
        else
          msg2 "Skipping kernel-5.4.patch as it doesn't apply to this driver version..."
        fi
        if [[ $pkgver = 435.27.02 ]] || [[ $pkgver = 435.27.03 ]] || [[ $pkgver = 435.27.06 ]] || [[ $pkgver = 435.27.07 ]] || [[ $pkgver = 435.27.08 ]] || [[ $pkgver = 440.26 ]]; then
          patch -Np1 -i "$srcdir"/kernel-5.4-symver.diff
        fi
      fi

      # 5.5
      if [ "$_kernel55" = "1" ]; then
        patchy=0
        for yup in "${_whitelist55[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.5.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.5.patch
        else
          msg2 "Skipping kernel-5.5.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.6
      if [ "$_kernel56" = "1" ]; then
        patchy=0
        for yup in "${_whitelist56[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.6.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.6.patch
        else
          msg2 "Skipping kernel-5.6.patch as it doesn't apply to this driver version..."
        fi
        if [[ $pkgver = 410* ]] || [[ $pkgver = 415* ]] || [[ $pkgver = 418.* ]] || [[ $pkgver = 430.0* ]] || [[ $pkgver = 435.* ]] || [[ $pkgver = 440.2* ]] || [[ $pkgver = 440.3* ]] || [[ $pkgver = 440.4* ]]; then
          msg2 "Applying 5.6-legacy-includes.diff for dkms..."
          patch -Np1 -i "$srcdir"/5.6-legacy-includes.diff
          msg2 "Applying 5.6-ioremap.diff for dkms..."
          patch -Np1 -i "$srcdir"/5.6-ioremap.diff
        elif [[ $pkgver = 440.5* ]]; then
          msg2 "Applying 5.6-ioremap.diff for dkms..."
          patch -Np1 -i "$srcdir"/5.6-ioremap.diff
        fi
      fi

      # 5.7
      if [ "$_kernel57" = "1" ]; then
        patchy=0
        for yup in "${_whitelist57[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.7.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.7.patch
        else
          msg2 "Skipping kernel-5.7.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.8
      if [ "$_kernel58" = "1" ]; then
        patchy=0
        for yup in "${_whitelist58[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.8.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.8.patch
        else
          msg2 "Skipping kernel-5.8.patch as it doesn't apply to this driver version..."
        fi
        if [[ $pkgver = 41* ]] || [[ $pkgver = 43* ]] || [[ $pkgver = 44* ]] || [[ $pkgver = 450.3* ]] || [[ $pkgver = 450.51 ]]; then
          msg2 "Applying 5.8-legacy.diff for dkms..."
          patch -Np1 -i "$srcdir"/5.8-legacy.diff
        fi
      fi

      # 5.9
      if [ "$_kernel59" = "1" ]; then
        patchy=0
        for yup in "${_whitelist59[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.9.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.9.patch
        else
          msg2 "Skipping kernel-5.9.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.10
      if [ "$_kernel510" = "1" ]; then
        patchy=0
        for yup in "${_whitelist510[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.10.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.10.patch
        else
          msg2 "Skipping kernel-5.10.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.11
      if [ "$_kernel511" = "1" ]; then
        patchy=0
        for yup in "${_whitelist511[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.11.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.11.patch
        else
          msg2 "Skipping kernel-5.11.patch as it doesn't apply to this driver version..."
        fi
        if [[ $pkgver = 455.45* ]] || [[ $pkgver = 455.50* ]] || [[ $pkgver = 460.27* ]] && [[ $pkgver != 455.50.19 ]]; then
          msg2 "Applying 5.11-legacy.diff for $_kernel..."
          patch -Np1 -i "$srcdir"/5.11-legacy.diff
        fi
      fi

      # 5.9 - 5.10 quirk
      if [ "$_kernel59" = "1" ] || [ "$_kernel510" = "1" ]; then
        if [[ $pkgver = 450* ]] || [[ $pkgver = 455.2* ]] || [[ $pkgver = 455.3* ]]; then
          msg2 "Applying 5.9-gpl.diff for dkms..."
          patch -Np1 -i "$srcdir"/5.9-gpl.diff
        fi
      fi

      # 5.12
      if [ "$_kernel512" = "1" ]; then
        patchy=0
        for yup in "${_whitelist512[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.12.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.12.patch
        else
          msg2 "Skipping kernel-5.12.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.14
      if [ "$_kernel514" = "1" ]; then
        patchy=0
        for yup in "${_whitelist514[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.14.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.14.patch
        else
          msg2 "Skipping kernel-5.14.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 5.16
      if [ "$_kernel516" = "1" ]; then
        patchy=0
        for yup in "${_whitelist516[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.16.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.16.patch
        else
          msg2 "Skipping kernel-5.16.patch as it doesn't apply to this driver version..."
        fi
        if [[ $pkgver = 470.62.* ]]; then
          msg2 "Applying kernel-5.16-std.diff for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.16-std.diff
        else
          msg2 "Skipping kernel-5.16-std.diff as it doesn't apply to this driver version..."
        fi
      fi

      # 5.17
      if [ "$_kernel517" = "1" ]; then
        patchy=0
        for yup in "${_whitelist517[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-5.17.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-5.17.patch
        else
          msg2 "Skipping kernel-5.17.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 6.0
      if [ "$_kernel60" = "1" ]; then
        patchy=0
        for yup in "${_whitelist60[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          if [[ "$yup" =~ ^470\..* ]]; then
            msg2 "Applying kernel-6.0-470.patch for dkms ..."
            patch -Np1 -i "$srcdir"/kernel-6.0-470.patch
          fi
          msg2 "Applying kernel-6.0.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-6.0.patch
        else
          msg2 "Skipping kernel-6.0.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 6.2
      if [ "$_kernel62" = "1" ]; then
        patchy=0
        for yup in "${_whitelist62[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-6.2.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-6.2.patch
        else
          msg2 "Skipping kernel-6.2.patch as it doesn't apply to this driver version..."
        fi
      fi

      # 6.3
      if [ "$_kernel63" = "1" ]; then
        patchy=0
        for yup in "${_whitelist63[@]}"; do
          [[ $pkgver = $yup ]] && patchy=1
        done
        if [ "$patchy" = "1" ]; then
          msg2 "Applying kernel-6.3.patch for dkms..."
          patch -Np1 -i "$srcdir"/kernel-6.3.patch
        else
          msg2 "Skipping kernel-6.3.patch as it doesn't apply to this driver version..."
        fi
      fi

      # Legacy quirks
      if [ "$_oldstuff" = "1" ]; then
        msg2 "Applying 01-ipmi-vm.diff for dkms..."
        patch -Np1 -i "$srcdir"/01-ipmi-vm.diff
      fi
      if [ "$_youngeryetoldstuff" = "1" ]; then
        msg2 "Applying 02-ipmi-vm.diff for dkms..."
        patch -Np1 -i "$srcdir"/02-ipmi-vm.diff
      fi
      if [[ $pkgver = 396* ]] || [[ $pkgver = 410* ]] || [[ $pkgver = 415* ]] || [[ $pkgver = 418.* ]] || [[ $pkgver = 430.0* ]] || [[ $pkgver = 435.* ]] || [[ $pkgver = 440.2* ]] || [[ $pkgver = 440.3* ]] || [[ $pkgver = 440.43.* ]] || [[ $pkgver = 440.44 ]] && [ "$_54_prime" = "true" ]; then
        msg2 "Applying kernel-5.4-prime.diff for dkms..."
        patch -Np1 -i "$srcdir"/kernel-5.4-prime.diff
      fi
    fi
  fi
}

build() {
  if [ "$_open_source" != "y" ]; then
    if [ "$_dkms" != "true" ]; then
      # Build for all kernels
      local _kernel
      local -a _kernels
      mapfile -t _kernels < <(find /usr/lib/modules/*/build/version -exec cat {} + || find /usr/lib/modules/*/extramodules/version -exec cat {} +)

      for _kernel in "${_kernels[@]}"; do
        cd "$srcdir"/$_pkg/kernel-$_kernel

        # Build module
        msg2 "Building Nvidia module for $_kernel..."
        make SYSSRC=/usr/lib/modules/$_kernel/build modules
      done
    fi
  else
    cd open-gpu-kernel-modules-${pkgver}
    make SYSSRC="/usr/src/linux"
  fi
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

#egl-wayland version
if (( ${pkgver%%.*} >= 530 )); then
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

#egl-gbm  version
if (( ${pkgver%%.*} >= 495 )); then
  _eglgver="1.1.0"
fi

nvidia-egl-wayland-tkg() {
  pkgdesc="NVIDIA EGL Wayland library (libnvidia-egl-wayland.so.$_eglwver) for 'nvidia-utils-tkg'"
  depends=('nvidia-utils-tkg' 'eglexternalplatform')
  provides=("egl-wayland" "nvidia-egl-wayland-tkg")
  conflicts=('egl-wayland')
  cd $_pkg

    install -Dm755 libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so."${_eglwver}"
    ln -s libnvidia-egl-wayland.so."${_eglwver}" "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so.1
    ln -s libnvidia-egl-wayland.so.1 "${pkgdir}"/usr/lib/libnvidia-egl-wayland.so

    install -Dm755 10_nvidia_wayland.json "${pkgdir}"/usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json
    install -Dm755 "$where"/egl-wayland/licenses/egl-wayland/COPYING "${pkgdir}"/usr/share/licenses/egl-wayland/COPYING
    install -Dm755 "$where"/egl-wayland/pkgconfig/wayland-eglstream-protocols.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
    install -Dm755 "$where"/egl-wayland/pkgconfig/wayland-eglstream.pc "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc
    install -Dm755 "$where"/egl-wayland/wayland-eglstream/wayland-eglstream-controller.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream-controller.xml
    install -Dm755 "$where"/egl-wayland/wayland-eglstream/wayland-eglstream.xml "${pkgdir}"/usr/share/wayland-eglstream/wayland-eglstream.xml

    sed -i "s/Version:.*/Version: $_eglwver/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream-protocols.pc
    sed -i "s/Version:.*/Version: $_eglwver/g" "${pkgdir}"/usr/share/pkgconfig/wayland-eglstream.pc
}
source /dev/stdin <<EOF
package_$_branchname-egl-wayland-tkg() {
  nvidia-egl-wayland-tkg
}
EOF

nvidia-utils-tkg() {
  pkgdesc="NVIDIA driver utilities and libraries for 'nvidia-tkg'"
  depends=('libglvnd' 'mesa' 'vulkan-icd-loader')
  optdepends=('gtk2: nvidia-settings (GTK+ v2)'
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

    # egl-gbm
    if [ -n "${_eglgver:-}" ]; then
        install -Dm755 libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so."${_eglgver}"
        ln -s libnvidia-egl-gbm.so."${_eglgver}" "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so.1
        ln -s libnvidia-egl-gbm.so.1 "${pkgdir}"/usr/lib/libnvidia-egl-gbm.so
    fi
    if [[ -e 15_nvidia_gbm.json ]]; then
        install -Dm755 15_nvidia_gbm.json "${pkgdir}"/usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json
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

    # nvidia-persistenced
    install -D -m755 nvidia-persistenced "${pkgdir}/usr/bin/nvidia-persistenced"
    install -D -m644 nvidia-persistenced.1.gz "${pkgdir}/usr/share/man/man1/nvidia-persistenced.1.gz"
    if [ -e nvidia-persistenced-init/systemd/nvidia-persistenced.service.template ]; then
      install -D -m644 nvidia-persistenced-init/systemd/nvidia-persistenced.service.template "${pkgdir}/usr/lib/systemd/system/nvidia-persistenced.service"
      sed -i 's/__USER__/nvidia-persistenced/' "${pkgdir}/usr/lib/systemd/system/nvidia-persistenced.service"
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
      install -D -m644 ${_path_addon1}nvidia-suspend.service "${pkgdir}/usr/lib/systemd/system/nvidia-suspend.service"
      install -D -m644 ${_path_addon1}nvidia-hibernate.service "${pkgdir}/usr/lib/systemd/system/nvidia-hibernate.service"
      install -D -m644 ${_path_addon1}nvidia-resume.service "${pkgdir}/usr/lib/systemd/system/nvidia-resume.service"
      install -D -m755 ${_path_addon2}nvidia "${pkgdir}/usr/lib/systemd/system-sleep/nvidia"
      install -D -m755 ${_path_addon3}nvidia-sleep.sh "${pkgdir}/usr/bin/nvidia-sleep.sh"
      # nvidia-powerd
      if [ -e nvidia-powerd ]; then
        install -D -m755 nvidia-powerd "${pkgdir}/usr/bin/nvidia-powerd"
        install -D -m644 nvidia-dbus.conf "${pkgdir}/usr/share/dbus-1/system.d/nvidia-dbus.conf"
        install -D -m644 ${_path_addon1}nvidia-powerd.service "${pkgdir}/usr/lib/systemd/system/nvidia-powerd.service"
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
    install -Dm644 "$srcdir"/10-nvidia-drm-outputclass.conf "$pkgdir"/usr/share/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf

    install -Dm644 "$srcdir"/nvidia-utils-tkg.sysusers "$pkgdir"/usr/lib/sysusers.d/$pkgname.conf

    install -Dm644 "$srcdir"/60-nvidia.rules "$pkgdir"/usr/lib/udev/rules.d/60-nvidia.rules

    _create_links
}
source /dev/stdin <<EOF
package_$_branchname-utils-tkg() {
  nvidia-utils-tkg
}
EOF

nvidia-settings-tkg() {
    pkgdesc='Tool for configuring the NVIDIA graphics driver'
    depends=("nvidia-utils-tkg>=${pkgver}" 'gtk3')
    provides=("nvidia-settings=${pkgver}" "nvidia-settings-tkg=${pkgver}")
    conflicts=('nvidia-settings')

    cd "$_pkg"

    install -D -m755 nvidia-settings         -t "${pkgdir}/usr/bin"
    install -D -m644 nvidia-settings.1.gz    -t "${pkgdir}/usr/share/man/man1"
    install -D -m644 nvidia-settings.png     -t "${pkgdir}/usr/share/pixmaps"
    install -D -m644 nvidia-settings.desktop -t "${pkgdir}/usr/share/applications"
    sed -e 's:__UTILS_PATH__:/usr/bin:' -e 's:__PIXMAP_PATH__/nvidia-settings.png:nvidia-settings:' -i "${pkgdir}/usr/share/applications/nvidia-settings.desktop"

    install -D -m755 "libnvidia-gtk3.so.${pkgver}" -t "${pkgdir}/usr/lib"

    # license
    install -D -m644 LICENSE -t "${pkgdir}/usr/share/licenses/${pkgname}"
}
source /dev/stdin <<EOF
package_$_branchname-settings-tkg() {
  nvidia-settings-tkg
}
EOF

if [ "$_dkms" = "false" ] || [ "$_dkms" = "full" ]; then
  nvidia-tkg() {
  if [ "$_open_source_modules" = "true" ]; then
      depends+=('linux')
      conflicts=('NVIDIA-MODULE')
      provides=('NVIDIA-MODULE')

      cd open-gpu-kernel-modules-${pkgver}
      _extradir="/usr/lib/modules/$(</usr/src/linux/version)/extramodules"
      install -Dt "${pkgdir}${_extradir}" -m644 kernel-open/*.ko
      find "${pkgdir}" -name '*.ko' -exec strip --strip-debug {} +
      find "${pkgdir}" -name '*.ko' -exec xz {} +

      # Force module to load even on unsupported GPUs
      mkdir -p "$pkgdir"/usr/lib/modprobe.d
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "$pkgdir"/usr/lib/modprobe.d/nvidia-open.conf

      install -Dm644 COPYING "$pkgdir"/usr/share/licenses/$pkgname

      if [ "$_blacklist_nouveau" = false ]; then
          echo "skip blacklist nouveau\n"
        else
            echo -e "blacklist nouveau\nblacklist lbm-nouveau" |
                install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/${pkgname}.conf"
      fi

      install -Dm644 "${srcdir}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
  else
      pkgdesc="Full NVIDIA drivers' package for all kernels on the system (drivers and shared utilities and libraries)"
      depends=("nvidia-utils-tkg>=$pkgver" 'libglvnd')
      provides=("nvidia=$pkgver" "nvidia-tkg>=$pkgver")
      conflicts=('nvidia-96xx' 'nvidia-173xx' 'nvidia')
      install=nvidia-tkg.install

      # Install for all kernels
      local _kernel
      local -a _kernels
      mapfile -t _kernels < <(find /usr/lib/modules/*/build/version -exec cat {} + || find /usr/lib/modules/*/extramodules/version -exec cat {} +)

      for _kernel in "${_kernels[@]}"; do
        install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia{,-drm,-modeset,-uvm}.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
        if [[ ${pkgver%%.*} = 465 ]]; then
          install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia-peermem.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
          install -D -m644 "${_pkg}/kernel-${_kernel}/"nvidia-ib-peermem-stub.ko -t "${pkgdir}/usr/lib/modules/${_kernel}/extramodules"
        fi
        find "$pkgdir" -name '*.ko' -exec gzip -n {} +
      done

      if [ "$_blacklist_nouveau" = false ]; then
          echo "skip blacklist nouveau\n"   
        else
            echo -e "blacklist nouveau\nblacklist lbm-nouveau" |
                install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/${pkgname}.conf"
            echo "nvidia-uvm" |
                install -Dm644 /dev/stdin "${pkgdir}/etc/modules-load.d/${pkgname}.conf"
      fi

      install -Dm644 "${srcdir}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"
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
    fi

    if [[ -e libnvidia-ifr.so.${pkgver} ]]; then
      install -D -m755 "libnvidia-ifr.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ifr.so.${pkgver}"
    fi
    install -D -m755 "libnvidia-fbc.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-fbc.so.${pkgver}"
    install -D -m755 "libnvidia-encode.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-encode.so.${pkgver}"
    install -D -m755 "libnvidia-ml.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-ml.so.${pkgver}"
    install -D -m755 "libnvidia-glvkspirv.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-glvkspirv.so.${pkgver}"

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

    # Fat (multiarchitecture) binary loader
    if [[ $pkgver = 396* ]] || [[ $pkgver = 41* ]] || [[ $pkgver = 43* ]] || [[ $pkgver = 44* ]]; then
      install -D -m755 "libnvidia-fatbinaryloader.so.${pkgver}" "${pkgdir}/usr/lib32/libnvidia-fatbinaryloader.so.${pkgver}"
    fi

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
      depends+=('dkms')
      conflicts=('nvidia-open' 'NVIDIA-MODULE')
      provides=('nvidia-open' 'NVIDIA-MODULE')

      install -dm 755 "${pkgdir}"/usr/src
      # cp -dr --no-preserve='ownership' kernel-open "${pkgdir}/usr/src/nvidia-$pkgver"
      cp -dr --no-preserve='ownership' open-gpu-kernel-modules-dkms "${pkgdir}/usr/src/nvidia-$pkgver"
      mv "${pkgdir}/usr/src/nvidia-$pkgver/kernel-open/dkms.conf" "${pkgdir}/usr/src/nvidia-$pkgver/dkms.conf"

      # Force module to load even on unsupported GPUs
      mkdir -p "$pkgdir"/usr/lib/modprobe.d
      echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > "$pkgdir"/usr/lib/modprobe.d/nvidia-open.conf

      install -Dm644 open-gpu-kernel-modules-${pkgver}/COPYING "$pkgdir"/usr/share/licenses/$pkgname
  else

      pkgdesc="NVIDIA kernel module sources (DKMS)"
      depends=('dkms' "nvidia-utils-tkg>=${pkgver}" 'nvidia-libgl' 'pahole')
      provides=("nvidia=${pkgver}" 'nvidia-dkms' "nvidia-dkms-tkg=${pkgver}" 'NVIDIA-MODULE')
      conflicts=('nvidia' 'nvidia-dkms')

      cd ${_pkg}
      install -dm 755 "${pkgdir}"/usr/{lib/modprobe.d,src}
      cp -dr --no-preserve='ownership' kernel-dkms "${pkgdir}/usr/src/nvidia-${pkgver}"

      if [ "$_blacklist_nouveau" = false ]; then
          echo "skip blacklist nouveau\n"    
        else
            echo -e "blacklist nouveau\nblacklist lbm-nouveau" |
                install -Dm644 /dev/stdin "${pkgdir}/usr/lib/modprobe.d/${pkgname}.conf"
            echo "nvidia-uvm" |
                install -Dm644 /dev/stdin "${pkgdir}/etc/modules-load.d/${pkgname}.conf"
      fi

      install -Dm644 "${srcdir}/nvidia-tkg.hook" "${pkgdir}/usr/share/libalpm/hooks/nvidia-tkg.hook"

      install -Dt "${pkgdir}/usr/share/licenses/${pkgname}" -m644 "${srcdir}/${_pkg}/LICENSE"
  fi
  }
source /dev/stdin <<EOF
  package_$__branchname-dkms-tkg() {
    nvidia-dkms-tkg
  }
EOF
fi

function exit_cleanup {
  # Sanitization
  rm -f "${where}"/options
  rm -f "${where}"/*.conf
  rm -f "${where}"/*.install
  rm -f "${where}"/*.patch
  rm -f "${where}"/*.diff
  rm -f "${where}"/*.hook
  rm -f "${where}"/nvidia-utils-tkg.sysusers
  rm -rf "${where}"/egl-wayland
  rm -rf "${where}"/src/*

  # Put the built packages in a versioned dir - overwrite if needed
  if [ "$_local_package_storing" = "true" ]; then
    rm -rf "${where}/${pkgver}-packages" && mkdir -p "${where}/${pkgver}-packages" && mv "${where}/"*.pkg.* "${where}/${pkgver}-packages"/ >/dev/null 2>&1
  fi

  remove_deps

  msg2 'exit cleanup done'
}

trap exit_cleanup EXIT
