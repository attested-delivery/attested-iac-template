#!/usr/bin/env bash
# setup-engine.sh — install the IaC engine (OpenTofu or Terraform) at a pinned
# version, verifying the download against its published SHA256SUMS before use.
#
# Identity-free + runtime-resolved (org philosophy): the engine and version are
# resolved at run time, not baked into the workflow. Resolution order:
#   1. ENGINE / ENGINE_VERSION environment variables (caller override), else
#   2. the `engine:` / `engine_version:` keys in .copier-answers.yml (an
#      instantiated repo records its Copier answers there), else
#   3. defaults (opentofu / DEFAULT_TOFU_VERSION).
#
# The template repo itself has no .copier-answers.yml (only the .jinja source),
# so its own CI falls through to the OpenTofu default — which is the intended
# self-test engine.
#
# Fail-closed: a checksum mismatch aborts; nothing unverified is placed on PATH.
set -euo pipefail

DEFAULT_TOFU_VERSION="1.12.3"
DEFAULT_TF_VERSION="1.5.7" # last MPL-licensed Terraform; override for newer/BUSL.
ANSWERS_FILE="${ANSWERS_FILE:-.copier-answers.yml}"

answer() {
  # answer <key> — echo the value of `<key>: value` from the answers file (if any).
  [ -f "${ANSWERS_FILE}" ] || return 0
  sed -n -E "s/^${1}:[[:space:]]*[\"']?([^\"'#]+)[\"']?[[:space:]]*$/\1/p" \
    "${ANSWERS_FILE}" | head -n1 | tr -d '[:space:]'
}

ENGINE="${ENGINE:-$(answer engine)}"
ENGINE="${ENGINE:-opentofu}"

case "${ENGINE}" in
  opentofu)
    VERSION="${ENGINE_VERSION:-$(answer engine_version)}"
    VERSION="${VERSION:-${DEFAULT_TOFU_VERSION}}"
    bin="tofu"
    zip="tofu_${VERSION}_linux_amd64.zip"
    sums="tofu_${VERSION}_SHA256SUMS"
    base="https://github.com/opentofu/opentofu/releases/download/v${VERSION}"
    ;;
  terraform)
    VERSION="${ENGINE_VERSION:-$(answer engine_version)}"
    VERSION="${VERSION:-${DEFAULT_TF_VERSION}}"
    bin="terraform"
    zip="terraform_${VERSION}_linux_amd64.zip"
    sums="terraform_${VERSION}_SHA256SUMS"
    base="https://releases.hashicorp.com/terraform/${VERSION}"
    ;;
  *)
    echo "::error::Unknown engine '${ENGINE}' (expected opentofu|terraform)" >&2
    exit 1
    ;;
esac

dest="${ENGINE_BIN_DIR:-${RUNNER_TEMP:-/tmp}/iac-engine}"
mkdir -p "${dest}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

echo "Installing ${ENGINE} ${VERSION} (${bin})..."
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  -o "${work}/${zip}" "${base}/${zip}"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  -o "${work}/${sums}" "${base}/${sums}"

# Fail-closed checksum verification: the SHA256SUMS file lists every artifact;
# verify only our zip and abort on any mismatch.
( cd "${work}" && grep " ${zip}\$" "${sums}" | sha256sum --check --strict - )

unzip -q -o "${work}/${zip}" "${bin}" -d "${dest}"
chmod +x "${dest}/${bin}"

# Expose on PATH for subsequent steps (GitHub Actions) or the current shell.
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "${dest}" >> "${GITHUB_PATH}"
fi
echo "Installed: $("${dest}/${bin}" version | head -n1) -> ${dest}/${bin}"
