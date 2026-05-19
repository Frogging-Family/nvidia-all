## 📢 New: Multi-distro installer support

We've added installer support for multiple distributions, but it is still in an early stage. If you encounter any issues or have suggestions for improvement, please report them. If the driver misbehaves, make sure you know how to revert to your distro's packaged driver. See [Uninstall and revert](#uninstall-and-revert) below.

Tested:
- Fedora 44 - kernel 7.x, NVIDIA 610 series (DKMS)
- Ubuntu 26.04 - kernel 7.x, NVIDIA 610 series (DKMS, Secure Boot disabled)

Caveats:
- Secure Boot on Ubuntu: modules failed to load with SB enabled. This may be system-specific and is not yet confirmed broadly.
- Standard (non-DKMS) build path is currently untested.

KISS! 🐸 damachine

---

# nvidia-all

All-in-one NVIDIA Linux driver with dynamic branch selection,
kernel compatibility patching, optional component split packages
and other customization features.

## Contents

- [nvidia-all](#nvidia-all)
  - [Contents](#contents)
  - [What nvidia-all adds](#what-nvidia-all-adds)
  - [Notes](#notes)
  - [Install](#install)
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
    - [Secure Boot enabled](#secure-boot-enabled)
    - [Download fails](#download-fails)

## What nvidia-all adds
  
- Vulkan dev drivers : https://developer.nvidia.com/vulkan-driver
- Regular drivers : https://www.nvidia.com/object/unix.html
- Builds current and legacy NVIDIA Linux drivers.
- Supports proprietary kernel modules and NVIDIA open kernel modules.
- Detects installed kernels and applies compatibility patches where needed. 
- Offers DKMS and regular package variants.
- Supports optional split packages.
- Exposes many build/runtime toggles through customization.cfg.
- Legacy selection path includes additional older series down to 396.
- Custom version input is supported for 396 and newer.

## Notes

- As of 590, NVIDIA no longer develops proprietary (closed-source) kernel modules. https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/
- For older GPUs (pre-Turing), proprietary kernel modules remain available via driver 580 and below.
- For 470 users (Kepler legacy context) 470 is treated as a legacy branch and may require extra caution on newer kernels. NVIDIA ended Kepler support updates in September 2024, so an LTS kernel is generally recommended.
- 390 and older series are not supported.

---

## Install

Supported: Arch, Debian/Ubuntu, Fedora/SUSE.

```bash
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all

# Arch-based
makepkg -si

# All distributions 
./install.sh
```

Then follow the prompts to select your desired driver version, module type, optional split packages and other options.

If your setup needs it, consider a pacman hook for DRM mode setting:
https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting

## Update

```bash
cd nvidia-all
git pull
makepkg -si
# or
./install.sh 
```

Then follow the prompts as before.

---

## Uninstall and revert

### 1) Remove installed nvidia-all packages

The exact package names can vary by branch and options (for example open/dev,
series suffixes, dkms vs regular, lib32, split components).

List installed nvidia-all packages first:

```bash
pacman -Qq | grep -E 'nvidia*.*-tkg'
```

If the list looks correct, remove the matched packages:

```bash
pacman -Qq | grep -E 'nvidia*.*-tkg' | xargs -r sudo pacman -Rdd
```

### 2) Reinstall distro packages


For open DKMS path (Turing or newer only) see *[Notes](#notes)*:

```bash
sudo pacman -S \
  nvidia-open-dkms \
  opencl-nvidia \
  nvidia-utils \
  nvidia-settings \
  lib32-nvidia-utils \
  lib32-opencl-nvidia
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

---

## DKMS or regular modules

DKMS is usually recommended because it rebuilds modules automatically when
kernels update.

Choose regular packages only if you specifically want prebuilt non-DKMS modules
for your workflow.

---

## Important customization.cfg options and paths

The main user-facing configuration lives in [customization.cfg](https://github.com/Frogging-Family/nvidia-all/blob/master/customization.cfg).
External options can be placed at `~/.config/frogminer/nvidia-all.cfg` to automatically apply them.

Prebuilted distro packages are written to `nvidia-all/dist/` and can be installed from there.

Build logs and environment snapshots are written under `nvidia-all/logs/`.

---

## Custom driver versions

When prompted for driver version:

1. Select custom version entry(6).
2. Select branch group (stable/regular beta or Vulkan dev).
3. Enter desired version number.
4. Select DKMS or regular modules.

Version format examples:

- Vulkan dev style: 415.22.01
- Regular style: 415.25

---

## Troubleshooting

### DKMS build stopped working after a kernel update

Make sure you have the latest linux-headers package for your kernel installed.
Rebuild so the script re-detects currently installed kernels and reapplies
relevant compatibility logic.

### GCC/Clang mismatch warning

NVIDIA modules should be built with the same major GCC/Clang version used for the
kernel and not mixed between different compilers. Align your toolchain or rebuild kernel/modules consistently.

### Optimus/hybrid laptops

Hardware and OEM implementations vary. If needed, use dedicated hybrid tooling
and consult NVIDIA PRIME render offload documentation.

### Secure Boot enabled

If driver loading fails, test once with Secure Boot disabled.

### Download fails

If updates fail or downloads are corrupted/incomplete, start from a clean clone.
