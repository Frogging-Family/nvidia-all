## 📢 Announcement for nvidia-all!!

We've put some effort into adding installer support for other distros, and it is still in an initial phase. Please note that this is a work in progress, and it could contain errors and rough edges, so we would greatly appreciate your help in testing it out and providing feedback. If you encounter any issues or have suggestions for improvement, please don't hesitate to report them.

The original Arch-only PKGBUILD is preserved in the [`legacy`](https://github.com/Frogging-Family/nvidia-all/tree/legacy) branch. If you notice anything that was overlooked or lost during the refactor, please open an issue or PR — feedback is very welcome!

Thanks in advance for your support. KISS! 🐸

# nvidia-all

All-in-one NVIDIA Linux driver with dynamic branch selection,
kernel compatibility patching, and optional component split packages.

## Contents

- [nvidia-all](#nvidia-all)
  - [Contents](#contents)
  - [What nvidia-all adds](#what-nvidia-all-adds)
  - [Notes\*](#notes)
  - [Install](#install)
  - [Legacy branch (Arch PKGBUILD)](#legacy-branch-arch-pkgbuild)
  - [Update](#update)
  - [Uninstall and revert](#uninstall-and-revert)
    - [1) Remove installed nvidia-all packages](#1-remove-installed-nvidia-all-packages)
    - [2) Reinstall distro packages](#2-reinstall-distro-packages)
    - [Non-Arch (install.sh)](#non-arch-installsh)
  - [DKMS or regular modules](#dkms-or-regular-modules)
  - [Important customization.cfg options and paths](#important-customizationcfg-options-and-paths)
  - [Custom driver versions](#custom-driver-versions)
  - [Troubleshooting](#troubleshooting)
    - [DKMS build stopped working after a kernel update](#dkms-build-stopped-working-after-a-kernel-update)
    - [GCC/Clang mismatch warning](#gccclang-mismatch-warning)
    - [Optimus/hybrid laptops](#optimushybrid-laptops)

## What nvidia-all adds
  
- Vulkan dev drivers : https://developer.nvidia.com/vulkan-driver
- Regular drivers : https://www.nvidia.com/object/unix.html
- Builds current and legacy NVIDIA Linux drivers.*
- Supports proprietary kernel modules and NVIDIA open kernel modules.*
- Detects installed kernels and applies compatibility patches where needed. 
- Offers DKMS and regular package variants.
- Supports optional split packages.
- Exposes many build/runtime toggles through customization.cfg.
- Legacy selection path includes additional older series down to 396.
- Custom version input is supported for 396 and newer.

## Notes*

- As of 590, NVIDIA no longer develops proprietary (closed-source) kernel modules. https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/
- For older GPUs (pre-Turing), proprietary kernel modules remain available via driver 580 and below.
- For 470 users (Kepler legacy context) 470 is treated as a legacy branch and may require extra caution on newer kernels. NVIDIA ended Kepler support updates in September 2024, so an LTS kernel is generally recommended.
- 390 and older series are not supported.

## Install

**Arch-based (makepkg):**

```bash
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
makepkg -si
```

**All distributions (install.sh):**

Supported: Debian, Ubuntu, Fedora, SUSE/openSUSE — and Arch-based via direct install.

```bash
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
bash install.sh
```

The script auto-detects your distribution and offers two install modes:

- **Direct install** - installs driver files directly onto the system.
- **Package build** - builds a native package to `dist/<distro>/`.

After a package build, install the generated packages:

```bash
# Debian/Ubuntu
sudo dpkg -i dist/ubuntu/*.deb

# Fedora
sudo rpm -i dist/fedora/*.rpm

# SUSE
sudo zypper install dist/suse/*.rpm
```

If your setup needs it, consider a pacman hook for DRM mode setting:
https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting

## Legacy branch (Arch PKGBUILD)

The [`legacy`](https://github.com/Frogging-Family/nvidia-all/tree/legacy) branch preserves the original Arch-only PKGBUILD-based workflow for users who prefer it or rely on it.

> **Note:** The current `master` branch may have missed some fixes or improvements that existed in the original `legacy` PKGBUILD. If you notice anything that was overlooked during the refactor, please open an issue or PR — feedback is very welcome!

```bash
git clone -b legacy https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
makepkg -si
```

## Update

```bash
cd nvidia-all
git pull
bash install.sh
# or 
makepkg -si
```

Then follow the prompts as before.

## Uninstall and revert

### 1) Remove installed nvidia-all packages

The exact package names can vary by branch and options (for example open/dev,
series suffixes, dkms vs regular, lib32, split components).

List installed nvidia-all packages first:

```bash
pacman -Qq | grep -E 'nvidia.*-tkg'
```

If the list looks correct, remove the matched packages:

```bash
pacman -Qq | grep -E 'nvidia.*-tkg' | xargs -r sudo pacman -Rdd
```

### 2) Reinstall distro packages


For open DKMS path (Turing or newer only):

```bash
sudo pacman -S \
  nvidia-open-dkms \
  lib32-nvidia-utils \
  lib32-opencl-nvidia \
  nvidia-settings \
  opencl-nvidia \
  nvidia-utils
```

For proprietary DKMS path:

```bash
sudo pacman -S nvidia-580xx-dkms
```

After installing the drivers provided by your distro everything should function as normal after a reboot.

### Non-Arch (install.sh)

List installed nvidia-all packages:

```bash
# Debian/Ubuntu
dpkg -l | grep nvidia-tkg

# Fedora/SUSE
rpm -qa | grep nvidia-tkg
```

Remove them:

```bash
# Debian/Ubuntu
sudo dpkg -r <package-name>...

# Fedora
sudo rpm -e <package-name>...

# SUSE
sudo zypper remove <package-name>...
```

Then reinstall the NVIDIA driver provided by your distro.

## DKMS or regular modules

DKMS is usually recommended because it rebuilds modules automatically when
kernels update.

Choose regular packages only if you specifically want prebuilt non-DKMS modules
for your workflow.

## Important customization.cfg options and paths

The main user-facing configuration lives in [customization.cfg](https://github.com/Frogging-Family/nvidia-all/blob/master/customization.cfg).
External options can be placed at `~/.config/frogminer/nvidia-all.cfg` to automatically apply them.

Prebuilted distro packages are written to `/nvidia-all/` and can be installed from there.

Build logs and environment snapshots are written under `logs/`.

## Custom driver versions

When prompted for driver version:

1. Select custom version entry(6).
2. Select branch group (stable/regular beta or Vulkan dev).
3. Enter desired version number.
4. Select DKMS or regular modules.

Version format examples:

- Vulkan dev style: 415.22.01
- Regular style: 415.25

## Troubleshooting

### DKMS build stopped working after a kernel update

Rebuild so the script re-detects currently installed kernels and reapplies
relevant compatibility logic.

### GCC/Clang mismatch warning

NVIDIA modules should be built with the same major GCC/Clang version used for the
kernel and not mixed between different compilers. Align your toolchain or rebuild kernel/modules consistently.

### Optimus/hybrid laptops

Hardware and OEM implementations vary. If needed, use dedicated hybrid tooling
and consult NVIDIA PRIME render offload documentation.
