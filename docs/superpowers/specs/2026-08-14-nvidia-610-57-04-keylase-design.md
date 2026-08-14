# NVIDIA 610.57.04 NVENC/NvFBC Patch Design

## Goal

Build the installed Frogging-Family `nvidia-all` 610.57.04 userspace packages
with the exact upstream keylase `nvidia-patch` definitions for:

- removing the consumer NVENC session limit;
- enabling NvFBC on consumer GPUs.

The patch must remain package-managed and must not modify NVIDIA kernel modules
or unrelated packages.

## Chosen approach

Update the local `nvidia-all-config/system/nvidia-patch.sh` patch tables with the
upstream 610.57.04 definitions already present in keylase's current `patch.sh`
and `patch-fbc.sh`. Keep `_nvidia_patch_enc_fbc="true"` in the existing external
configuration, then use the repository's normal preparation and package-build
flow.

Directly editing `/usr/lib/libnvidia-encode.so.610.57.04` or
`/usr/lib/libnvidia-fbc.so.610.57.04` is explicitly out of scope because those
files are owned by `nvidia-utils-tkg` and direct edits would be overwritten by
package operations.

## Implementation flow

1. Record the repository state and installed NVIDIA package/library metadata.
2. Add only the two exact 610.57.04 patch definitions.
3. Run the existing build flow with the current external configuration.
4. Require build output to report successful NVENC and NvFBC patch application.
5. Inspect generated package contents and verify the expected byte substitutions
   before installation.
6. Install the generated packages through the user's interactive `sudo` and
   pacman workflow. Do not bypass password prompts.
7. Verify package ownership/version, driver loading, and patch results.

The build must stop if the resolved driver version is not 610.57.04, either
patch definition is missing, or a substitution applies zero times.

## Safety and rollback

The patch changes only two userspace shared libraries. DKMS sources, kernel
modules, firmware, display configuration, and GPU switching configuration are
not changed.

Before installation, preserve the generated unpatched 610.57.04 package
artifacts if available. Rollback options are:

- reinstalling the unpatched package artifacts;
- rebuilding with `_nvidia_patch_enc_fbc="false"` and reinstalling;
- allowing a later package upgrade to replace the patched libraries.

Package upgrades may overwrite the patch, so the external configuration and
patch-table change must remain available for reproducible rebuilds.

## Verification

The verification pass will confirm:

- both patch messages appear in the build log;
- generated package payloads contain the expected patched libraries;
- installed package versions remain 610.57.04;
- NVIDIA modules and `nvidia-smi` continue to work;
- NVENC is exposed to an available encoder test;
- NvFBC availability is checked where a local diagnostic is available.

No claim of runtime functionality will be made if the system lacks a suitable
NVENC or NvFBC test utility.
