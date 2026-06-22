# Security Policy

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Report security issues using the
[GitHub private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
feature for this repository (Security → Advisories → "Report a vulnerability"),
or by emailing the maintainer directly.

We will respond within 72 hours and coordinate a fix and disclosure timeline.

---

## Verify a release

Every release is the module tarball `{name}-{version}.tar.gz`, signed with
GitHub's Sigstore-backed (keyless, OIDC) attestation infrastructure. Anyone can
re-verify from a clean workstation — there are no long-lived signing keys.

The examples below use this template's own slug,
`attested-delivery/attested-iac-template`. **Substitute your org/repo and the real
artifact filename** when verifying a downstream release.

### Prerequisites

- [GitHub CLI](https://cli.github.com/) `gh` ≥ 2.49.0
- Authenticated: `gh auth login`

Set the variables once:

```bash
ARTIFACT="attested-iac-template-1.0.0.tar.gz"   # the downloaded release tarball
REPO="attested-delivery/attested-iac-template"  # your org/repo
SEAM="attested-delivery/.github/.github/workflows/reusable-attest-scan.yml"
```

### 1. SLSA build provenance + CycloneDX SBOM

These are produced by the repo's own release workflow, so they verify with
`--repo`:

```bash
gh attestation verify "$ARTIFACT" --repo "$REPO" \
  --predicate-type https://slsa.dev/provenance/v1

gh attestation verify "$ARTIFACT" --repo "$REPO" \
  --predicate-type https://cyclonedx.org/bom
```

### 2. Seam-signed gate verdicts

The artifact-characterizing gates — **SAST** (CodeQL), **SCA** (OSV),
**IaC/license** (Trivy), and **IaC/policy** (Checkov) — are each signed by the
central attestation seam (`reusable-attest-scan.yml`). Under SLSA Build L3 the
Fulcio signer identity is that central workflow, so `--owner`/`--repo` alone is
**not** sufficient — pin `--signer-workflow`, one predicate per command:

```bash
for pt in sast sca iac-license iac-policy; do
  gh attestation verify "$ARTIFACT" --owner attested-delivery \
    --signer-workflow "$SEAM" \
    --predicate-type "https://attested-delivery.github.io/attestations/${pt}/v1"
done
```

### 3. OpenVEX disposition (self-signed)

VEX is signed by its own workflow, so it pins a different signer:

```bash
gh attestation verify "$ARTIFACT" --owner attested-delivery \
  --signer-workflow attested-delivery/.github/.github/workflows/reusable-vex.yml \
  --predicate-type https://openvex.dev/ns/v0.2.0
```

### What a passing verification looks like

```
Loaded digest sha256:abc123... for file://attested-iac-template-1.0.0.tar.gz
Loaded 1 attestation from GitHub API
✓ Verification succeeded!
```

A failed verification exits non-zero. **Treat any verification failure as a
supply-chain integrity breach — do not use the artifact.**

> **Signed ≠ passed.** A passing verification proves the gate *ran and recorded a
> verdict* bound to the subject digest. Read the predicate body for the verdict
> itself.

---

## What the attestations prove

| Attestation | Predicate type | Signer | What it proves |
| --- | --- | --- | --- |
| SLSA build provenance | `https://slsa.dev/provenance/v1` | this repo's `release.yml` | The tarball was built by this repo's workflow from a specific commit, untampered after signing |
| CycloneDX SBOM | `https://cyclonedx.org/bom` | this repo's `release.yml` | The tarball is bound to a CycloneDX bill of materials |
| SAST | `.../attestations/sast/v1` | seam (`reusable-attest-scan.yml`) | CodeQL ran over this repo's workflows and recorded a verdict |
| SCA | `.../attestations/sca/v1` | seam | OSV ran over dependencies and recorded a verdict |
| IaC/license | `.../attestations/iac-license/v1` | seam | Trivy ran (misconfig + license) and recorded a verdict |
| IaC/policy | `.../attestations/iac-policy/v1` | seam | Checkov ran (graph policy) and recorded a verdict |
| OpenVEX | `https://openvex.dev/ns/v0.2.0` | `reusable-vex.yml` | A signed vulnerability disposition is bound to the subject |

Attestations are stored in the GitHub Attestations API and signed via Sigstore's
keyless infrastructure (Fulcio CA + Rekor transparency log). They cannot be
forged without control of the repository's GitHub Actions OIDC token.

---

## Checkov gate pin

The `iac-policy/v1` attestation is produced by the **Checkov** gate, which calls
the central `reusable-checkov.yml`, merged into `attested-delivery/.github`
([#7](https://github.com/attested-delivery/.github/pull/7)). The callers in
`quality-gates.yml` and `release.yml` are pinned to that merged commit SHA,
`8fa29c50d765cedd33a7ed37a82d7075f59b764f`, and Dependabot's `github-actions`
updater keeps it fresh alongside the other central reusables.

---

## Supply-chain security posture

- Every GitHub Action is pinned to a full 40-character commit SHA — never a
  mutable tag or branch. The `pin-check` CI job enforces this on every push and
  PR and is a required status check.
- The CI engine (OpenTofu/Terraform) and TFLint are installed by
  checksum-verified download (`bin/setup-engine.sh`, `bin/setup-tflint.sh`), not
  a third-party setup action.
- The `terraform-checks` gate runs validate-only with **zero cloud
  credentials** — no `plan`, no `apply`.
- The release pipeline is fail-closed: `verify` must pass before `publish` can
  run. There is no path from build to release that bypasses attestation
  verification.
