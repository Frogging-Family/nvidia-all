# NVIDIA 610.57.04 Keylase Patch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the package-managed NVIDIA 610.57.04 userspace package with the exact upstream keylase NVENC and NvFBC patches, install only the patched userspace package, and verify rollback remains available.

**Architecture:** Add the two version-specific substitutions to the existing `nvidia-all` patch tables, validate the associative arrays before building, and use Arch `makepkg` to produce a reproducible `nvidia-utils-tkg` package. Preserve the existing unpatched package before rebuilding, install the patched package through interactive pacman, and leave kernel/DKMS packages untouched.

**Tech Stack:** Arch Linux, Bash, `nvidia-all`, `makepkg`, `pacman`, `bsdtar`, NVIDIA 610.57.04.

## Global Constraints

- Use the exact keylase 610.57.04 NVENC and NvFBC substitutions already present in upstream `patch.sh` and `patch-fbc.sh`.
- Keep `_nvidia_patch_enc_fbc="true"` in `/home/modernyogi/.config/frogminer/nvidia-all.cfg`.
- Do not edit installed libraries directly under `/usr/lib`.
- Do not change NVIDIA kernel modules, DKMS configuration, GPU switching configuration, Hyprland configuration, or unrelated working-tree files.
- Preserve the existing unpatched `nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst` artifact before rebuilding.
- Do not install or replace kernel packages solely to apply these userspace patches.
- Stop if the resolved package version is not `610.57.04`, either patch definition is absent, or build output reports an unsupported/zero-match patch.
- Installation uses the user's interactive `sudo` password; do not bypass or script credentials.

---

### Task 1: Adding and validating the 610.57.04 patch definitions

**Files:**
- Modify: `nvidia-all-config/system/nvidia-patch.sh: enc_patch_list and fbc_patch_list`
- Read: `/home/modernyogi/.config/frogminer/nvidia-all.cfg`
- Test: shell assertions against the sourced associative arrays

**Interfaces:**
- Consumes: Existing `enc_patch_list` and `fbc_patch_list` associative arrays.
- Produces: `enc_patch_list[610.57.04]` and `fbc_patch_list[610.57.04]` containing the exact upstream substitutions.

- [ ] **Step 1: Preserve the current unpatched userspace package**

```bash
backup_dir="$HOME/.cache/nvidia-all-backups/610.57.04-pre-keylase"
mkdir -p "$backup_dir"
cp -p /home/modernyogi/Projects/openSource/nvidia-all/nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst \
  "$backup_dir/"
sha256sum "$backup_dir/nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst" \
  | tee "$backup_dir/SHA256SUMS"
```

Expected: the unpatched package and its checksum exist outside the build output directory.

- [ ] **Step 2: Add the exact upstream entries**

Insert these entries immediately after the existing `610.43.03` entries in their respective arrays:

```bash
["610.57.04"]='s/\xe8\x71\x1f\xfe\xff\x41\x89\xc6\x85\xc0/\xe8\x71\x1f\xfe\xff\x29\xc0\x41\x89\xc6/g'
```

for `enc_patch_list`, and:

```bash
["610.57.04"]='s/\x85\xc0\x0f\x85\xd4\x00\x00\x00\x48/\x85\xc0\x90\x90\x90\x90\x90\x90\x48/g'
```

for `fbc_patch_list`.

- [ ] **Step 3: Run the pre-build validation**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
source ./nvidia-all-config/system/nvidia-patch.sh
test "${enc_patch_list[610.57.04]}" = \
  's/\xe8\x71\x1f\xfe\xff\x41\x89\xc6\x85\xc0/\xe8\x71\x1f\xfe\xff\x29\xc0\x41\x89\xc6/g'
test "${fbc_patch_list[610.57.04]}" = \
  's/\x85\xc0\x0f\x85\xd4\x00\x00\x00\x48/\x85\xc0\x90\x90\x90\x90\x90\x90\x48/g'
grep -q '^_nvidia_patch_enc_fbc="true"$' "$HOME/.config/frogminer/nvidia-all.cfg"
```

Expected: all assertions exit with status 0.

- [ ] **Step 4: Check the focused diff**

```bash
git diff --check
git diff -- nvidia-all-config/system/nvidia-patch.sh
```

Expected: only the two new 610.57.04 associative-array entries are changed.

- [ ] **Step 5: Commit the source change**

```bash
git add nvidia-all-config/system/nvidia-patch.sh
git commit -m "fix: add keylase patches for NVIDIA 610.57.04" \
  -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Expected: the patch definitions are committed without staging the existing untracked `docs/` content.

### Task 2: Building and inspecting the patched package

**Files:**
- Read: `PKGBUILD`
- Read: `nvidia-all-config/install-common:352-379`
- Create: `logs/keylase-610.57.04-build.log`
- Create/replace: `nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst`

**Interfaces:**
- Consumes: The committed patch definitions, the external configuration, and the existing 610.57.04 source cache.
- Produces: A package whose `libnvidia-encode.so.610.57.04` and `libnvidia-fbc.so.610.57.04` contain the patched byte sequences.

- [ ] **Step 1: Build without installing**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
set -o pipefail
makepkg -f 2>&1 | tee logs/keylase-610.57.04-build.log
```

Expected: `makepkg` completes successfully without asking to install packages, and the output package is rebuilt.

- [ ] **Step 2: Require both patch-success messages**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
grep -F 'Patched libnvidia-encode.so.610.57.04' logs/keylase-610.57.04-build.log
grep -F 'Patched libnvidia-fbc.so.610.57.04' logs/keylase-610.57.04-build.log
grep -F 'Version 610.57.04 detected and supported for NVENC patching' logs/keylase-610.57.04-build.log
grep -F 'Version 610.57.04 detected and supported for NVFBC patching' logs/keylase-610.57.04-build.log
```

Expected: each command finds one successful message; any warning or missing message stops the workflow.

- [ ] **Step 3: Confirm the package version and payload**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
pacman -Qp ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst
bsdtar -tf ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst \
  | grep -Fx 'usr/lib/libnvidia-encode.so.610.57.04'
bsdtar -tf ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst \
  | grep -Fx 'usr/lib/libnvidia-fbc.so.610.57.04'
```

Expected: package metadata reports `nvidia-utils-tkg-610.57.04-300`; both library paths are present.

- [ ] **Step 4: Verify the patched byte sequences in the package**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
bsdtar -xOf ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst \
  usr/lib/libnvidia-encode.so.610.57.04 > "$tmpdir/encode.so"
bsdtar -xOf ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst \
  usr/lib/libnvidia-fbc.so.610.57.04 > "$tmpdir/fbc.so"
grep -aobF "$(printf '\x29\xc0\x41\x89\xc6')" "$tmpdir/encode.so"
grep -aobF "$(printf '\x85\xc0\x90\x90\x90\x90\x90\x90\x48')" "$tmpdir/fbc.so"
```

Expected: both searches return at least one byte offset. A missing match means the package must not be installed.

### Task 3: Installing only the patched userspace package

**Files:**
- Install: `nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst`
- Preserve: `$HOME/.cache/nvidia-all-backups/610.57.04-pre-keylase/nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst`

**Interfaces:**
- Consumes: The inspected patched package from Task 2.
- Produces: Installed patched `nvidia-utils-tkg` userspace libraries while leaving DKMS and kernel packages unchanged.

- [ ] **Step 1: Reconfirm installed package scope**

```bash
pacman -Q nvidia-utils-tkg
pacman -Qo /usr/lib/libnvidia-encode.so.610.57.04
pacman -Qo /usr/lib/libnvidia-fbc.so.610.57.04
```

Expected: both libraries are owned by `nvidia-utils-tkg`; no package replacement outside this userspace package is planned.

- [ ] **Step 2: Install through interactive pacman**

```bash
cd /home/modernyogi/Projects/openSource/nvidia-all
sudo pacman -U ./nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst
```

Expected: pacman requests the user's normal password if needed and replaces the same-version package successfully.

- [ ] **Step 3: Confirm the installed package and ownership**

```bash
pacman -Q nvidia-utils-tkg
pacman -Qo /usr/lib/libnvidia-encode.so.610.57.04
pacman -Qo /usr/lib/libnvidia-fbc.so.610.57.04
```

Expected: package version remains `610.57.04-300`, and both files are package-owned.

### Task 4: Verifying runtime behavior and rollback

**Files:**
- Read: `$HOME/.cache/nvidia-all-backups/610.57.04-pre-keylase/SHA256SUMS`
- Read: `logs/keylase-610.57.04-build.log`

**Interfaces:**
- Consumes: The installed patched userspace package and the preserved unpatched package.
- Produces: Evidence that the NVIDIA stack still works and a tested package-level rollback command.

- [ ] **Step 1: Verify the driver remains usable**

```bash
nvidia-smi
modinfo nvidia | grep -E '^(filename|version):'
dkms status | grep 'nvidia/610.57.04'
```

Expected: `nvidia-smi` works, `modinfo` reports 610.57.04, and DKMS still reports the existing installed module for the current kernel.

- [ ] **Step 2: Test NVENC if ffmpeg is available**

```bash
if command -v ffmpeg >/dev/null; then
  ffmpeg -hide_banner -loglevel error \
    -f lavfi -i color=c=black:s=128x128:d=1 \
    -c:v h264_nvenc -f null -
else
  printf '%s\n' 'ffmpeg is unavailable; NVENC runtime test not performed'
fi
```

Expected: the command exits successfully when ffmpeg and a working NVENC device are available.

- [ ] **Step 3: Verify installed library bytes**

```bash
grep -aobF "$(printf '\x29\xc0\x41\x89\xc6')" \
  /usr/lib/libnvidia-encode.so.610.57.04
grep -aobF "$(printf '\x85\xc0\x90\x90\x90\x90\x90\x90\x48')" \
  /usr/lib/libnvidia-fbc.so.610.57.04
```

Expected: both patched sequences are present in the installed files.

- [ ] **Step 4: Document the exact rollback command**

```bash
sudo pacman -U \
  "$HOME/.cache/nvidia-all-backups/610.57.04-pre-keylase/nvidia-utils-tkg-610.57.04-300-x86_64.pkg.tar.zst"
```

Expected: this command is sufficient to restore the preserved pre-keylase userspace package if the patched build causes a regression.
