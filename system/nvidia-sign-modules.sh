#!/bin/bash

set -euo pipefail

# Uses the module signing key shipped in the linux-tkg headers package.
# This requires linux-tkg to be built with _install_signing_keys="true" so the
# key and certificate are present in /usr/lib/modules/<kernel>/build/.


_signed_any=0

while IFS= read -r -d '' _kbuild; do
  _kernel="${_kbuild%/build}"
  _kernel="${_kernel##*/}"
  _sign_file="${_kbuild}/scripts/sign-file"
  _config="${_kbuild}/.config"

  if [ ! -x "$_sign_file" ] || [ ! -r "$_config" ]; then
    echo ":: nvidia-tkg module signing skipped for ${_kernel}: build metadata missing"
    continue
  fi

  _sign_key="$(grep -Po 'CONFIG_MODULE_SIG_KEY="\K[^"]*' "$_config" 2>/dev/null || true)"
  [ -n "$_sign_key" ] || _sign_key="certs/signing_key.pem"
  [[ "$_sign_key" =~ ^/ ]] || _sign_key="${_kbuild}/${_sign_key}"
  _sign_cert="${_kbuild}/certs/signing_key.x509"
  _hash_algo="$(grep -Po 'CONFIG_MODULE_SIG_HASH="\K[^"]*' "$_config" 2>/dev/null || echo sha256)"

  if [ ! -r "$_sign_key" ] || [ ! -r "$_sign_cert" ]; then
    echo ":: nvidia-tkg module signing skipped for ${_kernel}: linux-tkg signing key not readable in headers"
    continue
  fi

  _changed=0

  while IFS= read -r -d '' _mod; do
    _plain_mod="$_mod"
    _compression=""

    case "$_mod" in
      *.ko.xz)
        xz -d -f "$_mod"
        _plain_mod="${_mod%.xz}"
        _compression="xz"
        ;;
      *.ko.gz)
        gzip -d -f "$_mod"
        _plain_mod="${_mod%.gz}"
        _compression="gz"
        ;;
    esac

    "$_sign_file" "$_hash_algo" "$_sign_key" "$_sign_cert" "$_plain_mod"

    case "$_compression" in
      xz)
        xz -f "$_plain_mod"
        ;;
      gz)
        gzip -n -f "$_plain_mod"
        ;;
    esac

    _changed=1
    _signed_any=1
  done < <(find "/usr/lib/modules/${_kernel}" -type f \( -name 'nvidia*.ko' -o -name 'nvidia*.ko.xz' -o -name 'nvidia*.ko.gz' \) -print0)

  if [ "$_changed" -eq 1 ]; then
    depmod "$_kernel"
  fi
done < <(find /usr/lib/modules -mindepth 2 -maxdepth 2 -type d -name build -print0)

if [ "$_signed_any" -eq 0 ]; then
  echo ":: nvidia-tkg module signing skipped: no installed nvidia modules found"
fi
