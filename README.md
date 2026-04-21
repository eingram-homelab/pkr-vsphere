# pkr-vsphere

Packer templates for building VM templates on a VMware vSphere homelab. Each directory corresponds to a single OS image. Templates are built as vSphere VMs using the `vsphere-iso` source and converted to vCenter templates upon completion.

Secrets (vCenter credentials, SSH passwords) are retrieved from HashiCorp Vault at build time via Packer's `vault()` function.

## Templates

| Directory | OS |
|---|---|
| `rocky9/` | Rocky Linux 9 |
| `rocky9_rke2/` | Rocky Linux 9 (RKE2 node) |
| `rocky10/` | Rocky Linux 10 |
| `rocky10_rke2/` | Rocky Linux 10 (RKE2 node) |
| `ubuntu24/` | Ubuntu 24.04 |
| `win10/` | Windows 10 |
| `win11/` | Windows 11 |
| `win2019/` | Windows Server 2019 |
| `win2022/` | Windows Server 2022 |
| `win2022-core/` | Windows Server 2022 Core |

## Directory Structure

Each template follows this layout:

```
<os>/
├── vsphere_<os>.pkr.hcl        # Main build and source block
├── variables.pkr.hcl           # Variable declarations
├── <os>.auto.pkrvars.hcl       # Variable values (vCenter targets, ISO paths, sizing)
├── data/
│   └── homelab_ca.crt          # CA certificate uploaded to each VM
└── scripts/
    ├── env_setup.sh             # Package install and VMware Tools config
    └── sysprep-op-*.sh          # Sysprep cleanup scripts
```

Windows templates additionally contain PowerShell scripts under `scripts/` for WinRM configuration, VMware Tools installation, and Windows customization.

The repository-level `scripts/publish_template.ps1` is called by CI after a successful build to delete the old vCenter template and rename the new timestamped one.

## Prerequisites

- [Packer](https://developer.hashicorp.com/downloads) ≥ 1.15
- HashiCorp Vault accessible at `http://vault.local.lan:8200` with a valid token
- vCenter/ESXi accessible at `vcsa-1.local.lan`
- ISO files pre-staged in the vCenter datastore

## Usage

### Initialize plugins

Always run `packer init` before first use or after changing plugin versions:

```bash
packer init <os>/
```

### Validate (syntax only — no Vault required)

```bash
packer validate -syntax-only <os>/
```

### Validate (full — requires Vault)

```bash
export VAULT_ADDR=http://vault.local.lan:8200
export VAULT_TOKEN=<token>
packer validate <os>/
```

### Build

```bash
export VAULT_ADDR=http://vault.local.lan:8200
export VAULT_TOKEN=<token>
packer build <os>/
```

After a successful build, `<os>/build-manifest.json` is written with the artifact ID and timestamped VM name (format: `<template_name>__YYYYMMDDHHmmss`).

### Format check

```bash
packer fmt -check <os>/
```

Run `packer fmt <os>/` (without `-check`) to auto-fix formatting.

## CI/CD

| Workflow | Trigger | Action |
|---|---|---|
| `push-workflow.yaml` | Push to non-`main` branch (`*.pkr.hcl` changed) | Validate all changed templates |
| `pr-workflow.yaml` | Pull request to `main` (`*.pkr.hcl` changed) | Validate all changed templates |
| `release-workflow.yaml` | Push to `main` (`*.pkr.hcl` changed) | Build templates, verify via Terraform, publish to vCenter |

Validation runs `packer fmt -check`, `packer init`, and `packer validate` against each changed template directory. The build pipeline additionally installs `xorriso` (required for Windows ISO builds) and calls `scripts/publish_template.ps1` to promote the new template in vCenter.

Workflows are self-hosted on `arc-runners` and call reusable workflows from [eingram-homelab/reusable_workflows](https://github.com/eingram-homelab/reusable_workflows).

Required secrets/variables:
- `VAULT_TOKEN` (secret)
- `VAULT_ADDR` (Actions variable)

## Triggering a New Build

To force a rebuild of a template without any functional changes, edit the trigger comment on line 1 of the relevant `.pkr.hcl` file:

```hcl
# Change this line to trigger new build
```
