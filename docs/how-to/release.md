---
diataxis_type: how-to
---
# Cut a release

A release is the module tarball `{name}-{version}.tar.gz`, built once and
promoted by digest, with SLSA build provenance, a CycloneDX SBOM, and signed
gate verdicts — all re-verified fail-closed before the GitHub Release exists.

The pipeline lives in `.github/workflows/release.yml`. Its flow:

```
build tarball → attest provenance → generate + attest SBOM
  → seam-attest each gate verdict (sast / sca / iac-license / iac-policy)
  → self-attest VEX → fail-closed verify → tag-gated publish
```

## Before you start

- Ensure CI is green on the commit you intend to tag.

## 1. Dry-run with `workflow_dispatch`

A manual run from any branch exercises the full
`build → attest → verify` chain. `publish` is tag-gated, so the dry-run produces
no GitHub Release:

```bash
gh workflow run release.yml
gh run watch
```

Use this to confirm the pipeline is healthy before committing to a tag.

## 2. Tag and push

```bash
git tag v1.0.0
git push origin v1.0.0
```

The push of a `v*` tag triggers `release.yml`. Watch it:

```bash
gh run watch
# or: https://github.com/<owner>/<repo>/actions
```

`publish` runs only when `verify` passes **and** the ref is a tag. There is no
path from build to release that skips verification.

## 3. Verify the published artifact

Re-verify independently from a clean workstation — in-pipeline green is not the
acceptance test:

```bash
gh release download v1.0.0 --pattern '*.tar.gz'

ARTIFACT="<name>-1.0.0.tar.gz"
REPO="<owner>/<repo>"
SEAM="attested-delivery/.github/.github/workflows/reusable-attest-scan.yml"

gh attestation verify "$ARTIFACT" --repo "$REPO" \
  --predicate-type https://slsa.dev/provenance/v1
gh attestation verify "$ARTIFACT" --repo "$REPO" \
  --predicate-type https://cyclonedx.org/bom

for pt in sast sca iac-license iac-policy; do
  gh attestation verify "$ARTIFACT" --owner attested-delivery \
    --signer-workflow "$SEAM" \
    --predicate-type "https://attested-delivery.github.io/attestations/${pt}/v1"
done

gh attestation verify "$ARTIFACT" --owner attested-delivery \
  --signer-workflow attested-delivery/.github/.github/workflows/reusable-vex.yml \
  --predicate-type https://openvex.dev/ns/v0.2.0
```

> Verify: each command exits `0` and prints `✓ Verification succeeded!`. A
> non-zero exit is a supply-chain integrity failure — do not use the artifact.

See [SECURITY.md](../../SECURITY.md) for the full verification reference.

## Promotion

To move a verified digest between registry hops or environments, **re-verify the
existing digest — never re-archive**. A rebuild is a new artifact and orphans
every attestation made about the old one.
