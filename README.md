# scripts

Setup scripts and reusable GitHub Actions for provisioning Ubuntu servers.

## Provision Ubuntu Server

Reusable workflow that SSHs into a server and installs:

- Node.js (LTS) and PM2
- MongoDB 8.0
- Nginx
- Certbot (`python3-certbot-nginx`)
- Redis

It runs [`install-ubuntu-libs.sh`](install-ubuntu-libs.sh) on the target machine. MongoDB is installed from the Ubuntu 24.04 (noble) repo.

### Use it from another repository

Because [this repo is public](https://github.com/kapilislive/scripts), any GitHub repo can call the workflow. You do not need to fork or copy the script.

1. On the target server, put the matching **public** key in `~/.ssh/authorized_keys`. The SSH user must be able to `sudo` without a password.
2. In the **caller** repo, add an Actions secret named `SSH_PRIVATE_KEY` with the full private key (including the `BEGIN` / `END` lines).
3. Add a workflow file, for example `.github/workflows/provision.yml`:

```yaml
name: Provision server

on:
  workflow_dispatch:
    inputs:
      ip:
        description: IP address of the Ubuntu server
        required: true
        type: string

jobs:
  provision:
    uses: kapilislive/scripts/.github/workflows/provision-ubuntu.yml@main
    with:
      ip: ${{ inputs.ip }}
    secrets:
      ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
```

Pin `@main` to always use the latest workflow, or pin a commit SHA if you want a fixed version:

```yaml
uses: kapilislive/scripts/.github/workflows/provision-ubuntu.yml@<commit-sha>
```

### Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `ip` | yes | — | Server IP address |
| `ssh_user` | no | `ubuntu` | SSH username |
| `ssh_port` | no | `22` | SSH port |

Example with a non-default user and port:

```yaml
jobs:
  provision:
    uses: kapilislive/scripts/.github/workflows/provision-ubuntu.yml@main
    with:
      ip: 203.0.113.10
      ssh_user: root
      ssh_port: "22"
    secrets:
      ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Secrets

| Secret | Required | Description |
| --- | --- | --- |
| `ssh_private_key` | yes | SSH private key used to log in to the server |

Pass it from the caller repo; do not commit the key.

```yaml
secrets:
  ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Requirements

- Ubuntu 24.04 (noble) on the server
- SSH reachable from GitHub-hosted runners
- Passwordless sudo for `ssh_user`

## Local install script

You can also run the script directly on a server:

```bash
chmod +x install-ubuntu-libs.sh
./install-ubuntu-libs.sh 1 2 3 9 13 14 17 18
```

That combination is what the workflow uses: system update, common tools, Node.js, Nginx, MongoDB, PM2, Certbot, and Redis. Run without arguments for an interactive menu.
