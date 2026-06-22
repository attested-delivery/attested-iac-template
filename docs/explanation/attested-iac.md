---
diataxis_type: explanation
---
# Why attested IaC

Infrastructure-as-code is code that grants itself privilege. A Terraform module
that runs unverified can stand up networks, IAM roles, and storage exactly as an
attacker who tampered with it intended. The same promise the org makes for
binaries — *the thing you verified is the thing that runs* — has to hold for the
module you `source` into your root configuration. This template makes the
released module byte-identical to what was validated, binds SLSA provenance, a
CycloneDX SBOM, and signed gate verdicts to its digest, and refuses to publish
unless they all re-verify.

## The module-supply-chain gap

Terraform/OpenTofu give you a strong integrity guarantee for **providers** and a
much weaker one for **modules**, and the difference is the whole reason to attest.

When you run `init`, the engine records each provider's exact checksum in
`.terraform.lock.hcl` and refuses a provider whose hash doesn't match. Modules
have no equivalent. A `module` block sourced from a registry or a Git ref is
fetched and trusted; there is no lockfile entry pinning the module's content
hash. This is the gap HashiCorp tracks as **HCSEC-2024-04**: modules lack the
provider lockfile's checksum guarantee, so a moved tag or a compromised source
can substitute code without the integrity check providers get for free.

Two consequences follow, and the template acts on both:

1. **Pin module and action sources to immutable references.** Inside the
   template, every `uses:` is pinned to a full 40-char commit SHA (enforced
   fail-closed by `pin-check`). Downstream, consumers of a *published* module
   should pin it by version/digest and verify the release attestation rather than
   tracking a mutable tag.

2. **Make the release itself verifiable.** Because the ecosystem won't checksum
   the module for the consumer, the producer signs it. The release tarball
   carries SLSA build provenance (it was built by this repo's workflow from a
   named commit) and a CycloneDX SBOM, both bound to the artifact digest and
   re-verifiable from a clean workstation with `gh attestation verify`. That is
   the checksum guarantee the module ecosystem lacks, supplied out-of-band and
   cryptographically.

## Trivy and Checkov are complementary, not redundant

The template scans the Terraform with **two** IaC scanners on purpose.

- **Trivy** covers misconfiguration and license. It is fast, broad, and its rule
  set overlaps with most "is this resource configured insecurely" checks.
- **Checkov** is graph-based. It builds a resource graph and evaluates policies
  that follow references *across* resources — for example, a security group that
  is permissive only because of how a separate variable or another resource wires
  into it. That cross-resource reasoning catches a class of finding a
  single-resource rule misses.

Running both is not belt-and-suspenders duplication; the two engines find
different things. The template keeps their outputs distinct end to end: separate
SARIF categories in the Security tab, and separate attestation predicates at
release — `iac-license/v1` for Trivy, `iac-policy/v1` for Checkov. A verifier can
assert *both* a misconfiguration/license verdict and a graph-policy verdict
travelled with the artifact, independently.

Because Checkov's gate calls a **new** central reusable
(`reusable-checkov.yml`) that is not yet merged upstream, its callers are pinned
to a bootstrap SHA that won't resolve on github.com until the org owner merges
it — until then the `iac-policy/v1` predicate is simply absent, and the
fail-closed release pipeline (which requires it) won't complete. That is by
design: a partially-attested release is not a release.

## Why CodeQL can't read the HCL

It would be natural to assume the SAST gate analyzes the Terraform. It does not —
and the reason is a hard limitation, not a configuration choice. **CodeQL has no
HCL extractor.** CodeQL works by extracting a queryable database from source in a
language it understands; with no HCL/Terraform extractor, there is nothing for it
to extract from `*.tf`.

So the SAST gate here is configured `languages: actions` — it scans this repo's
**own GitHub Actions workflow YAML**, which *is* a supported CodeQL target and is
itself a meaningful supply-chain attack surface. The Terraform is left to the
tools built for it: Trivy and Checkov. Keeping this explicit matters, because
"SAST is green" must not be misread as "the infrastructure code was statically
analyzed." It was not by CodeQL; it was by the IaC scanners. The `sast/v1`
predicate's subject is the workflows, the `iac-license/v1` and `iac-policy/v1`
predicates' subject is the Terraform — and the verifier can tell them apart.
