---
diataxis_type: reference
---
# Gates reference

Every gate is a **thin, SHA-pinned caller** of a central
`attested-delivery/.github` reusable workflow. The scanning gates normalize on
SARIF and surface in the repository **Security** tab; the "Code scanning results"
check is the actual merge gate, so those gates **soft-fail** (report findings,
do not fail their own job).

## CI gates (`.github/workflows/ci.yml`)

| Gate | Scans | Reusable | Fail mode | Predicate |
| --- | --- | --- | --- | --- |
| pin-check | Every `uses:` is a full 40-char commit SHA | `pin-check.yml` | **hard** (required check) | — |
| actionlint | This repo's workflow YAML | `reusable-actionlint.yml` | **hard** | — |

## Quality gates (`.github/workflows/quality-gates.yml`)

| Gate | Scans | Reusable | Fail mode | Release predicate |
| --- | --- | --- | --- | --- |
| SAST (CodeQL) | This repo's **own workflows** (`languages: actions`) | `reusable-sast-codeql.yml` | soft (Security tab) | `sast/v1` |
| SCA (OSV) | Dependency advisories + dependency review | `reusable-sca-osv.yml` | soft (Security tab) | `sca/v1` |
| Trivy | IaC misconfiguration + license | `reusable-trivy.yml` | soft (Security tab) | `iac-license/v1` |
| Checkov | IaC policy (graph-based) | `reusable-checkov.yml` | soft (Security tab) | `iac-policy/v1` |
| Scorecard | Supply-chain posture (push + schedule) | `reusable-scorecard.yml` | soft (Security tab) | — (repo-level signal, not an artifact verdict) |
| terraform-checks | `fmt` / `validate` / `tflint` across module + examples, validate-only, **zero cloud credentials** | inline (engine via `bin/setup-engine.sh`) | **hard** | — |

> **CodeQL has no HCL extractor.** SAST therefore analyzes only this repo's own
> workflow YAML — *not* the Terraform. The Terraform is scanned by Trivy and
> Checkov; see [attested-iac.md](../explanation/attested-iac.md).

## Release gates (`.github/workflows/release.yml`)

At release, the artifact-characterizing gates are re-run and each verdict is
turned into a signed, digest-bound attestation, then re-checked **fail-closed**
before publish.

| Job | Produces | Signer | Predicate |
| --- | --- | --- | --- |
| `build` → attest provenance | SLSA build provenance | this repo's `release.yml` | `https://slsa.dev/provenance/v1` |
| `sbom` | CycloneDX SBOM | this repo's `release.yml` | `https://cyclonedx.org/bom` |
| `gate-sast` → `attest-sast` | SAST verdict | seam (`reusable-attest-scan.yml`) | `.../attestations/sast/v1` |
| `gate-sca` → `attest-sca` | SCA verdict | seam | `.../attestations/sca/v1` |
| `gate-trivy` → `attest-iac-license` | IaC misconfig + license verdict | seam | `.../attestations/iac-license/v1` |
| `gate-checkov` → `attest-iac-policy` | IaC policy verdict | seam | `.../attestations/iac-policy/v1` |
| `vex` | OpenVEX disposition | `reusable-vex.yml` (self-signed) | `https://openvex.dev/ns/v0.2.0` |
| `verify` | Fail-closed re-verification of all of the above | — | — |
| `publish` | GitHub Release with checksums | — | gated on `verify` + tag ref |

The custom-predicate namespace is
`https://attested-delivery.github.io/attestations/<gate>/v1`.

> **Signed ≠ passed.** A verified attestation proves a gate *ran and recorded a
> verdict* bound to the artifact digest. The verdict itself is in the predicate
> body.

## Checkov gate pin

The `gate-checkov` / `checkov` jobs call `reusable-checkov.yml`, merged into
`attested-delivery/.github`
([#7](https://github.com/attested-delivery/.github/pull/7)). Both callers are
pinned to that merged commit SHA `8fa29c50d765cedd33a7ed37a82d7075f59b764f`,
kept fresh by Dependabot's `github-actions` updater.
