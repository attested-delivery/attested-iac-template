---
diataxis_type: reference
---
# Documentation Index

Documentation for the attested-iac-template project, organized by
[Diátaxis](https://diataxis.fr/) mode.

## How-to

Task-oriented guides.

| Guide | Description |
| --- | --- |
| [Instantiate](how-to/instantiate.md) | `copier copy` / `copier update`, the answers, and post-instantiation steps |
| [Release](how-to/release.md) | Cut a release (tag `vX.Y.Z`), dry-run the pipeline, and verify the artifact |

## Reference

Precise, factual lookup.

| Document | Description |
| --- | --- |
| [Gates](reference/gates.md) | Every gate: what it scans, its reusable, soft/hard fail, and predicate |

## Explanation

Design rationale — the "why".

| Document | Description |
| --- | --- |
| [Attested IaC](explanation/attested-iac.md) | Why attest IaC, the module-supply-chain gap, Trivy+Checkov complementarity, why CodeQL can't read HCL |

See also [SECURITY.md](../SECURITY.md) for release-verification commands and
[README.md](../README.md) for the overview.
