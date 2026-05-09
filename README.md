# nvidia-all

All-in-one NVIDIA Linux driver PKGBUILD with dynamic branch selection,
kernel compatibility patching, and optional component split packages.

## Contents

- [nvidia-all](#nvidia-all)
  - [Contents](#contents)
  - [What nvidia-all adds](#what-nvidia-all-adds)
  - [Hardware notes](#hardware-notes)
  - [Install](#install)
  - [Update](#update)
  - [Uninstall and revert](#uninstall-and-revert)
    - [1) Remove installed nvidia-all packages](#1-remove-installed-nvidia-all-packages)
    - [2) Reinstall distro packages](#2-reinstall-distro-packages)
  - [DKMS or regular modules](#dkms-or-regular-modules)
  - [Important customization.cfg options](#important-customizationcfg-options)
  - [Custom driver versions](#custom-driver-versions)
  - [Troubleshooting](#troubleshooting)
    - [DKMS build stopped working after a kernel update](#dkms-build-stopped-working-after-a-kernel-update)
    - [GCC mismatch warning](#gcc-mismatch-warning)
    - [Optimus/hybrid laptops](#optimushybrid-laptops)

## What nvidia-all adds

- Builds current and legacy NVIDIA Linux drivers.
- Supports proprietary kernel modules and NVIDIA open kernel modules.
- Detects installed kernels and applies compatibility patches where needed.
- Offers DKMS and regular package variants.
- Supports optional split packages.
- Exposes many build/runtime toggles through customization.cfg.
  
    Vulkan dev drivers : https://developer.nvidia.com/vulkan-driver

    Regular drivers : https://www.nvidia.com/object/unix.html

- Legacy selection path includes additional older series down to 396.
- Custom version input is supported for 396 and newer.

Notes:

- 390 and older series are not supported.
- 470 is treated as a legacy branch and may require extra caution on newer kernels.

## Hardware notes

- For 595 NVIDIA open kernel modules are intended for Turing and newer GPUs.
- For 470 users (Kepler legacy context): NVIDIA ended Kepler support updates
	in September 2024, so an LTS kernel is generally recommended.

## Install

```bash
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
makepkg -si
```

Then follow the prompts.

If your setup needs it, consider a pacman hook for DRM mode setting:
https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting

## Update

```bash
cd nvidia-all
git pull
makepkg -si
```

Then follow the prompts as before.

## Uninstall and revert

### 1) Remove installed nvidia-all packages

The exact package names can vary by branch and options (for example open/dev,
series suffixes, dkms vs regular, lib32, split components).

List installed nvidia-all packages first:

```bash
pacman -Qq \
  | grep -E \
    '^(lib32-)?(opencl-)?nvidia([0-9]+xx)?(-dev)?(-open)?(-dkms|-utils|-settings|-egl-wayland|-egl-x11|-libxnvctrl)?-tkg$'
```

If the list looks correct, remove the matched packages:

```bash
pacman -Qq \
  | grep -E \
    '^(lib32-)?(opencl-)?nvidia([0-9]+xx)?(-dev)?(-open)?(-dkms|-utils|-settings|-egl-wayland|-egl-x11|-libxnvctrl)?-tkg$' \
  | xargs -r sudo pacman -Rdd
```

### 2) Reinstall distro packages

For proprietary DKMS path:

```bash
sudo pacman -S \
  nvidia-dkms \
  egl-wayland \
  lib32-nvidia-utils \
  lib32-opencl-nvidia \
  nvidia-settings \
  opencl-nvidia \
  nvidia-utils
```

For open DKMS path (Turing or newer only):

```bash
sudo pacman -S \
  nvidia-open-dkms \
  egl-wayland \
  lib32-nvidia-utils \
  lib32-opencl-nvidia \
  nvidia-settings \
  opencl-nvidia \
  nvidia-utils
```

After installing the drivers provided by your distro everything should function as normal after a reboot.

## DKMS or regular modules

DKMS is usually recommended because it rebuilds modules automatically when
kernels update.

Choose regular packages only if you specifically want prebuilt non-DKMS modules
for your workflow.

## Important customization.cfg options

The main user-facing configuration lives in customization.cfg (external options can be placed at ~/.config/frogminer/nvidia-all.cfg).

Build logs and environment snapshots are written under logs/.

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

### GCC mismatch warning

NVIDIA modules should be built with the same major GCC version used for the
kernel. Align your toolchain or rebuild kernel/modules consistently.

### Optimus/hybrid laptops

Hardware and OEM implementations vary. If needed, use dedicated hybrid tooling
and consult NVIDIA PRIME render offload documentation.
