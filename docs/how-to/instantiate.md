---
diataxis_type: how-to
---
# Instantiate this template with Copier

attested-iac-template is a **living, update-propagating template**. Stand up a
project three ways; they differ in one decisive way — whether you can later pull
template improvements with `copier update`.

| Path | Gets the files | `copier update` later? |
| --- | --- | --- |
| `copier copy` (recommended) | yes | **yes** — records `.copier-answers.yml` |
| GitHub "Use this template" | yes | no (until you adopt Copier) |
| `git clone` | yes | no |

## 1. Copier (recommended)

```bash
uvx copier copy gh:attested-delivery/attested-iac-template my-proj
# or: pipx install copier && copier copy gh:attested-delivery/attested-iac-template my-proj
cd my-proj
```

Copier prompts for:

| Answer | Meaning |
| --- | --- |
| `project_name` | Module / artifact name (used in `{name}-{version}.tar.gz`) |
| `owner` | GitHub org or user that owns the repo |
| `description` | One-line project description |
| `engine` | `opentofu` (default) or `terraform` |
| `engine_version` | Engine version CI installs (checksum-verified) |
| `clouds` | Subset of `aws` / `gcp` / `azure` to keep example roots for |

Copier writes `.copier-answers.yml` (your answers + the template version) and
renders the per-instance record at `docs/instance.md`. **Only those two files are
rendered** — every other file (the module, the example roots, the workflows, the
VEX disposition, the engine/TFLint setup scripts) is copied verbatim.

> Verify: `tofu fmt -check -recursive` (or `terraform fmt`) and
> `bin/setup-engine.sh` succeed locally before pushing.

## 2. Pull later template improvements

This is the differentiator over snapshot engines. When the template ships a fix
or addition, re-apply it:

```bash
cd my-proj
copier update   # re-applies template changes, preserving your answers
```

## Post-instantiation steps

Do these before relying on the gates and before your first release.

1. **Set `CODEOWNERS`.** Add a `CODEOWNERS` file (or fill the placeholder) so
   required reviews route to the right owners, and wire it into branch
   protection.

2. **Populate the VEX disposition.** Edit `.vex/openvex.json` so the OpenVEX gate
   signs a real disposition for your known/won't-fix advisories rather than an
   empty document.

3. **Enable required status checks.** In branch protection, mark these as
   required: `pin-check`, the `terraform-checks` jobs, and **"Code scanning
   results"** (the merge gate the SAST/SCA/Trivy/Checkov gates feed). The
   scanning gates soft-fail into the Security tab; "Code scanning results" is
   what blocks merge.

4. **Update self-references.** Replace `attested-delivery/attested-iac-template`
   with your org/repo in `README.md` and `SECURITY.md` (see `docs/instance.md`
   for the rendered list).

### Checkov gate pin

The Checkov gate calls the central `reusable-checkov.yml`, merged into
`attested-delivery/.github`
([#7](https://github.com/attested-delivery/.github/pull/7)). Its callers in
`.github/workflows/quality-gates.yml` and `.github/workflows/release.yml` are
pinned to that merged commit SHA (`8fa29c50d765cedd33a7ed37a82d7075f59b764f`),
which Dependabot's `github-actions` updater keeps fresh alongside the other
central reusables — no manual action needed.
