# pkr-vsphere – Copilot Agent Instructions

## Repository Summary
This is a **HashiCorp Packer** repository that builds VM templates for a VMware vSphere homelab environment. Each top-level directory corresponds to one OS image. Templates are built as vSphere VMs and converted to templates in vCenter. Secrets (vCenter credentials, SSH passwords) are always retrieved from **HashiCorp Vault** at build time using Packer's `vault()` function.

## Repository Size and Languages
- ~11 template directories, ~50 HCL files, a handful of Shell and PowerShell scripts
- **Languages/Formats:** HCL (Packer), Bash, PowerShell
- **Tool versions in use:** Packer ≥ 1.15 (local: v1.15.0), hashicorp/vsphere plugin `~> 1`, rgl/windows-update plugin `0.14.1`–`0.15.0`
- **Runtime:** GitHub Actions on self-hosted `arc-runners`; Vault at `http://vault.local.lan:8200`

---

## Repository Layout

```
<os-name>/packer/             # One directory per OS template
    vsphere_<os>.pkr.hcl      # Main Packer build + source block
    variables.pkr.hcl         # Variable declarations
    <os>.auto.pkrvars.hcl     # Variable values (vCenter targets, ISO paths, sizing)
    data/                     # homelab_ca.crt (CA cert uploaded to VM)
    scripts/                  # Provisioner shell scripts (env_setup.sh + sysprep-op-*.sh)
scripts/
    publish_template.ps1      # Post-build: delete old template, rename new one in vCenter
.github/workflows/
    pr-workflow.yaml          # Runs packer-validate on PRs to main
    push-workflow.yaml        # Runs packer-validate on pushes to non-main branches
    release-workflow.yaml     # Runs packer-build (full build + publish) on push to main
```

**Template directories:** `rhel85/`, `rocky9/`, `rocky9_rke2/`, `rocky10/`, `rocky10_rke2/`, `ubuntu24/`, `win10/`, `win11/`, `win2019/`, `win2022/`, `win2022-core/`

**Key architectural facts:**
- All secrets come from Vault. `VAULT_ADDR` and `VAULT_TOKEN` must be set as environment variables before any `packer validate` or `packer build` that resolves `vault()` locals.
- Linux templates use `vsphere-iso` source with SSH communicator; Windows templates use WinRM.
- `rhel85/` is a legacy template: it has **no `packer {}` required_plugins block** and **no `scripts/` subdir inside `packer/`** (scripts are at `rhel85/scripts/`). It will also fail `packer fmt -check` — do not attempt to fix the formatting unless specifically asked.
- `win11/packer/vsphere_win11.pkr.hcl` also currently fails `packer fmt -check`. Do not auto-fix formatting unless asked.
- The CI workflow only triggers on files matching `**.pkr.hcl`. Changes to shell scripts or `.pkrvars.hcl` files alone do not trigger CI.

---

## Build & Validation Commands

Always run commands from the **repo root** (`/path/to/pkr-vsphere/`).

### 1. Format Check (lint)
```bash
packer fmt -check <os>/packer/
```
- Exit 0 = formatted correctly. Exit 1 = file needs formatting; the filename is printed.
- Run `packer fmt <os>/packer/` (without `-check`) to auto-fix formatting.
- **Known pre-existing failures:** `rhel85/packer/` and `win11/packer/` currently fail fmt check. Do not fix these unless explicitly asked.

### 2. Initialize plugins
```bash
packer init <os>/packer/
```
- Downloads required plugins into `~/.config/packer/plugins/`.
- `rhel85/packer/` prints a warning ("No plugins requirement found") but exits 0 — this is expected.
- Always run `packer init` before `packer validate` or `packer build` on a freshly cloned repo or after plugin version changes.

### 3. Syntax-only validation (no Vault required)
```bash
packer validate -syntax-only <os>/packer/
```
- Validates HCL syntax without resolving `vault()` locals. Safe to run without Vault access.
- All 11 template directories pass syntax-only validation.

### 4. Full validation (requires Vault)
```bash
export VAULT_ADDR=http://vault.local.lan:8200
export VAULT_TOKEN=<token>
packer validate <os>/packer/
```
- Resolves Vault secrets and performs full semantic validation.
- Will fail with "permission denied / invalid token" if `VAULT_TOKEN` is wrong or Vault is unreachable.

### 5. Build (requires Vault + vSphere access)
```bash
export VAULT_ADDR=http://vault.local.lan:8200
export VAULT_TOKEN=<token>
packer build <os>/packer/
```
- Builds the VM template in vSphere and converts it to a template.
- Windows builds additionally require `xorriso` installed on the runner: `sudo apt-get install -y xorriso`
- After a successful build, `<os>/packer/build-manifest.json` is written with the artifact ID and timestamped VM name.

### Validate all templates (CI-equivalent loop)
```bash
for dir in */packer; do
  echo "=== $dir ==="
  packer fmt -check "$dir"
  packer init "$dir"
  packer validate "$dir"   # requires VAULT_ADDR + VAULT_TOKEN
done
```

---

## CI/CD Pipelines

All three workflows call reusable workflows from `eingram-homelab/reusable_workflows`:

| Workflow | Trigger | Action |
|----------|---------|--------|
| `push-workflow.yaml` | Push to non-main branch (`.pkr.hcl` changed) | `packer-validate`: fmt check → init → validate |
| `pr-workflow.yaml` | PR to `main` (`.pkr.hcl` changed) | Same validate workflow |
| `release-workflow.yaml` | Push to `main` (`.pkr.hcl` changed) | `packer-build`: init → build → Terraform verify → publish template |

**The validate workflow (PR/push) runs these steps on each changed `.pkr.hcl` directory:**
1. `packer fmt -check <dir>` — **must pass or the CI fails**
2. `packer init <dir>`
3. `packer validate <dir>` (full, with `VAULT_TOKEN` secret)

**The build workflow additionally:**
- Installs `xorriso` for Windows ISO builds
- Reads `build-manifest.json` to extract the new template artifact ID
- Runs a Terraform workflow to spin up a test VM from the new template
- Runs `scripts/publish_template.ps1` via PowerShell to rename the new template and delete the old one

**Required secrets/vars:**
- `VAULT_TOKEN` (secret) — Vault token
- `VAULT_ADDR` (Actions variable) — e.g. `http://vault.local.lan:8200`

---

## Key Conventions

- **Triggering a new build:** Add or edit the comment on line 1 of the `.pkr.hcl` file (e.g., `# Change this line to trigger new build`). This is the intentional pattern used throughout the repo.
- **Variable values** are in `*.auto.pkrvars.hcl` files and are automatically loaded by Packer. Do not hard-code values in the main `.pkr.hcl`.
- **Vault secret paths** for Linux templates: `/secret/vsphere/vcsa` (username/password), `/secret/ssh/eingram` (ssh_password, encrypted_password). Legacy `rhel85` uses KV v2 path prefix: `/secret/data/...`.
- **VM naming convention:** `<vsphere_template_name>__<YYYYMMDDHHmmss>` (double underscore). The publish script strips the timestamp suffix to derive the canonical template name.
- **No test suite exists.** Validation is `packer fmt -check` + `packer validate`. Post-build verification is done via Terraform (managed in a separate repo).
- **`.gitignore`** excludes `packerlog.txt`, `.ansible/`, `.vscode/`, and all OS junk files.

---

## Guidance for This Agent

Trust these instructions. Only search the codebase if information here is incomplete or appears incorrect. When making changes:
1. Always run `packer fmt -check <os>/packer/` after editing any `.pkr.hcl` file to confirm formatting.
2. Always run `packer validate -syntax-only <os>/packer/` after edits to catch HCL errors without needing Vault.
3. Do not modify `rhel85/` formatting or add a `packer {}` block unless explicitly asked — it is intentionally legacy.
4. When adding a new OS template, follow the structure of `rocky9/packer/` as the reference pattern.
