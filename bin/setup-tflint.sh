#!/usr/bin/env bash
# setup-tflint.sh — install TFLint at a pinned version, verifying the download
# against its published checksums.txt before use. No third-party action, so the
# org Actions allow-list is untouched. Fail-closed on checksum mismatch.
set -euo pipefail

VERSION="${TFLINT_VERSION:-0.63.1}"
dest="${TFLINT_BIN_DIR:-${RUNNER_TEMP:-/tmp}/tflint-bin}"
base="https://github.com/terraform-linters/tflint/releases/download/v${VERSION}"
zip="tflint_linux_amd64.zip"

mkdir -p "${dest}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

echo "Installing TFLint ${VERSION}..."
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  -o "${work}/${zip}" "${base}/${zip}"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  -o "${work}/checksums.txt" "${base}/checksums.txt"

( cd "${work}" && grep " ${zip}\$" checksums.txt | sha256sum --check --strict - )

unzip -q -o "${work}/${zip}" tflint -d "${dest}"
chmod +x "${dest}/tflint"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "${dest}" >> "${GITHUB_PATH}"
fi
echo "Installed: $("${dest}/tflint" --version | head -n1) -> ${dest}/tflint"
