# attested-iac-template

A Copier template that scaffolds an **attested OpenTofu/Terraform project**:
infrastructure-as-code whose released module is byte-identical to what was
validated, carries SLSA build provenance plus a CycloneDX SBOM, and ships only
when every signed gate verdict re-verifies. A tag publishes nothing unattested.

The gates that characterize the artifact — SAST, SCA, IaC misconfiguration +
license (Trivy), and IaC policy (Checkov) — are turned into signed, digest-bound
attestations and re-checked **fail-closed** before the release exists.

## What it scaffolds

```
modules/labels/        # A reusable module — the published unit
examples/aws/          # Per-cloud example root (selected at instantiation)
examples/gcp/
examples/azure/
bin/setup-engine.sh    # Checksum-verified engine install (no third-party action)
bin/setup-tflint.sh    # Checksum-verified TFLint install
.github/workflows/
  ci.yml               # pin-check + actionlint (thin callers)
  quality-gates.yml    # SAST, SCA, Trivy, Checkov, Scorecard (+ terraform-checks)
  release.yml          # build → attest → fail-closed verify → tag-gated publish
```

The release artifact is a module tarball, `{name}-{version}.tar.gz`, built once
and promoted by digest: promotion re-verifies the digest, it never re-archives.

## Quick start

This is a **Copier** template — it records your answers so you can pull template
improvements later with `copier update`.

```bash
copier copy gh:attested-delivery/attested-iac-template my-proj
cd my-proj
```

Copier prompts for:

| Answer | Meaning |
| --- | --- |
| `project_name` | Module / artifact name |
| `owner` | GitHub org or user that owns the repo |
| `description` | One-line project description |
| `engine` | `opentofu` (default) or `terraform` |
| `engine_version` | Engine version CI installs (checksum-verified) |
| `clouds` | Subset of `aws` / `gcp` / `azure` to keep example roots for |

Only `.copier-answers.yml` and `docs/instance.md` are rendered; everything else
is copied verbatim. Pull later template fixes with `copier update`.

See [docs/how-to/instantiate.md](docs/how-to/instantiate.md) for the answers,
post-instantiation steps, and the Checkov re-pin.

## Engine and cloud choices

- **Engine.** OpenTofu (default — MPL-licensed, open source) or Terraform,
  selected at instantiation. CI installs the chosen engine via a
  checksum-verified download (`bin/setup-engine.sh`), not a third-party setup
  action, keeping the org's restrictive Actions allow-list satisfied.
- **Clouds.** Pick any subset of `aws`, `gcp`, `azure`. Each selected cloud gets
  an `examples/<cloud>` root that consumes `modules/labels`. The
  `terraform-checks` gate runs `fmt` / `validate` / `tflint` across the module
  and every example root **validate-only, with zero cloud credentials** — no
  `plan`, no `apply`, nothing reaches a provider API.

## Gates and attestations

Every gate is a **thin, SHA-pinned caller** of a central
`attested-delivery/.github` reusable workflow (CLAUDE.md §2/§3 — consume the
central reusables, never reinvent them). Findings normalize on SARIF and surface
in the repository **Security** tab; the "Code scanning results" check is the
merge gate, so the scanning gates soft-fail (report, don't block the job).

| Gate | Scans | Reusable | Release predicate |
| --- | --- | --- | --- |
| pin-check | Every `uses:` is a 40-char SHA | `pin-check.yml` | — (required check) |
| actionlint | This repo's workflow YAML | `reusable-actionlint.yml` | — |
| SAST (CodeQL) | This repo's **own workflows** (`languages: actions`) | `reusable-sast-codeql.yml` | `sast/v1` |
| SCA (OSV) | Dependency advisories | `reusable-sca-osv.yml` | `sca/v1` |
| Trivy | IaC misconfiguration + license | `reusable-trivy.yml` | `iac-license/v1` |
| Checkov | IaC policy (graph-based) | `reusable-checkov.yml` | `iac-policy/v1` |
| Scorecard | Supply-chain posture (repo-level) | `reusable-scorecard.yml` | — (not an artifact verdict) |
| OpenVEX | Vulnerability disposition | `reusable-vex.yml` | `openvex.dev/ns/v0.2.0` (self-signed) |

**CodeQL has no HCL extractor**, so SAST analyzes only this repo's own workflow
YAML — *not* the Terraform. The Terraform itself is scanned by **Trivy and
Checkov together**: they are complementary, not redundant. Trivy covers
misconfiguration and license; Checkov adds graph-based policy that follows
references across resources. They emit distinct SARIF categories and distinct
attestation predicates (`iac-license/v1` vs `iac-policy/v1`).

Predicate namespace (custom):
`https://attested-delivery.github.io/attestations/<gate>/v1`. Standard
predicates: SLSA provenance `https://slsa.dev/provenance/v1`, CycloneDX SBOM
`https://cyclonedx.org/bom`, OpenVEX `https://openvex.dev/ns/v0.2.0`.

> **Signed ≠ passed.** A verified attestation proves the gate *ran and recorded a
> verdict* bound to the artifact digest. Read the predicate body for the verdict.

## Checkov reusable bootstrap — read before you push

The Checkov gate calls a **new** central reusable, `reusable-checkov.yml`, that
is **not yet merged upstream** into `attested-delivery/.github`. Its callers (in
`quality-gates.yml` and `release.yml`) are pinned to a bootstrap commit SHA:

```
9bb91c6b49b68ffebcd8f6a9419391badc70e97c
```

This SHA **will not resolve on github.com** until the org owner merges the
reusable and the pin is updated to the real upstream SHA. `pin-check` validates
the SHA *format*, not its existence, so it passes — but until the re-pin:

- the `checkov` / `gate-checkov` jobs cannot run on github.com, and
- because `release.yml`'s fail-closed `verify` depends on `attest-iac-policy`,
  the **release pipeline cannot complete** until the reusable is merged and
  re-pinned.

After the owner merges `reusable-checkov.yml`, update both callers to the real
upstream SHA. See [docs/how-to/instantiate.md](docs/how-to/instantiate.md#re-pin-the-checkov-reusable)
and [SECURITY.md](SECURITY.md#checkov-bootstrap-caveat).

## Documentation

- [SECURITY.md](SECURITY.md) — reporting + the copy-pasteable release-verification commands
- [docs/](docs/README.md) — how-to, reference, and explanation guides
  - [How-to: instantiate](docs/how-to/instantiate.md)
  - [How-to: cut a release](docs/how-to/release.md)
  - [Reference: gates](docs/reference/gates.md)
  - [Explanation: why attested IaC](docs/explanation/attested-iac.md)
