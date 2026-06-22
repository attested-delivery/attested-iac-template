## Summary

<!-- Brief description of the changes in this PR -->

## Related Issues

<!-- Link any related issues: Fixes #123, Relates to #456 -->

## Changes

<!-- List the key changes made in this PR -->

-
-
-

## Type of Change

<!-- Mark the relevant option with an [x] -->

- [ ] Bug fix (non-breaking)
- [ ] New feature / module change (non-breaking)
- [ ] Breaking change (alters existing module inputs/outputs or behavior)
- [ ] Documentation update
- [ ] CI / workflow change
- [ ] Refactoring (no functional change)

## Validation

### Commands run

```bash
# Substitute `terraform` for `tofu` if the project uses Terraform.
tofu fmt -check -recursive
tofu validate                       # in modules/labels and each examples/<cloud>
tflint                              # in modules/labels and each examples/<cloud>
```

> `validate` / `tflint` run with **zero cloud credentials** — no `init` against a
> real backend, no `plan`, no `apply`.

## Checklist

### Terraform / OpenTofu

- [ ] `tofu fmt` (or `terraform fmt`) is clean across the module and examples
- [ ] `tofu validate` passes for the module and every example root
- [ ] `tflint` passes for the module and every example root
- [ ] No `plan`/`apply` is run in CI; no cloud credentials are required by any gate

### Supply chain

- [ ] Every `uses:` I added/changed is pinned to a full 40-char commit SHA (`pin-check` passes)
- [ ] If I touched the Checkov caller, the pin matches the merged `reusable-checkov.yml` SHA (see SECURITY.md)
- [ ] No new third-party action is referenced without it being on the org allow-list

### Documentation

- [ ] I updated the relevant docs (README, SECURITY, or `docs/`) for any behavior change
- [ ] Module input/output changes are reflected in the example roots

### Commit hygiene

- [ ] My commits are scoped (one logical change each) and rebased on the latest default branch
- [ ] No AI attribution lines in commits
