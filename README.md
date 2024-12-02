# Nvidia driver latest to 396 series AIO installer

LIBGLVND compatible, with 32 bit libs and DKMS enabled out of the box (you will still be asked if you want to use the regular package). Installs for all currently installed kernels. Comes with custom patches to enhance kernel compatibility, dynamically applied when you're requesting a driver that's not compatible OOTB with your currently installed kernel(s).
Unwanted packages can be disabled with switches in the PKGBUILD. Defaults to complete installation.

Huge thanks to Isaak I. Aleksandrov who has been much faster at offering compat patches than myself for a good while now! https://gitlab.com/EULA

You may need/want to add a pacman hook for nvidia depending on your setup : https://wiki.archlinux.org/index.php/NVIDIA#DRM_kernel_mode_setting

Vulkan dev drivers : https://developer.nvidia.com/vulkan-driver

Regular drivers : https://www.nvidia.com/object/unix.html

## Note regarding 470 series

**Nvidia's support for Kepler GPUs ended on September 2024 ( see https://nvidia.custhelp.com/app/answers/detail/a_id/5202 ), so 470 series is unlikely to be updated going forward. As a result using a LTS kernel is recommended/needed to prevent issues (<=6.6.y).**

## How to run the installer
```
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
makepkg -si
```
Then follow the prompts.

### To update the installer
```
cd nvidia-all
git pull
makepkg -si
```
Then follow the prompts as before.

## How to uninstall and revert to distro provided packages
For arch and its derivatives you can uninstall using:
```
sudo pacman -Rdd lib32-nvidia-utils-tkg lib32-opencl-nvidia-tkg nvidia-dkms-tkg nvidia-egl-wayland-tkg nvidia-settings-tkg nvidia-utils-tkg opencl-nvidia-tkg
```
And install the distro dkms packages:

```
sudo pacman -S nvidia-dkms egl-wayland lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings opencl-nvidia nvidia-utils
```
Alternatively install the dkms open kernel modules (Turing or newer hardware only!!!) with:
```
sudo pacman -S nvidia-open-dkms egl-wayland lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings opencl-nvidia nvidia-utils
```
After installing the drivers provided by your distro everything should function as normal after a reboot.
# DKMS or regular?
DKMS is recommended as it allows for automatic module rebuilding on kernel updates. As long as you're on the same major version (5.8.x for example), you won't need to regenerate the packages on updates, which is a huge QoL feature. Regular modules can also be problematic on Manjaro due to differences in kernel hooking mechanisms compared to Arch. So if in doubt, go DKMS.


## My DKMS driver installed with kernel X.1 doesn't work/build anymore after I upgraded to kernel X.2! Help!
- Simply rebuild the packages so the script can detect your currently installed kernel(s) and patch your driver accordingly to fix compatibility issues.

# How to generate a package for a driver that isn't listed (390 and lower branches are not supported) :
- When you are prompted for driver version, select "custom" (choice 6).
- You'll then be asked the branch group. Select either "Vulkan dev" (choice 2) for Vulkan dev drivers or "stable or regular beta" (choice 1) for every other driver.
- Now you have to enter the version number of the desired driver. Vulkan dev drivers version is usually formatted as `mainbranch.version.subversion` (i.e.: 415.22.01) while the stable or regular beta drivers version is usually (but not always) `mainbranch.version` (i.e.: 415.25)
- To finish, you'll be asked if you want dkms(recommended) or regular modules, similarly to the usual drivers versions.

# Optimus users :
- A great tool exists for you and works with these nvidia-all packages: https://github.com/Askannz/optimus-manager
- 435.17 beta has introduced PRIME render offload support. You can learn more about the needed setup here: http://us.download.nvidia.com/XFree86/Linux-x86_64/435.17/README/primerenderoffload.html

# Mostlyportable-gcc users :
- For non-dkms nvidia-all packages, setting your `CUSTOM_GCC_PATH` in .cfg is enough.
- For dkms nvidia-all packages, you'll need to make DKMS aware of your mostlyportable-gcc build. See: https://github.com/Tk-Glitch/PKGBUILDS/issues/334#issuecomment-537197636
