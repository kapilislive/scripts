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

#### 1. Generate an SSH key pair

On your local machine:

```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/ubuntu_gha -N ""
```

`-N ""` means no passphrase (GitHub Actions cannot type one). That creates:

- `~/.ssh/ubuntu_gha` — **private** key (goes in GitHub Secrets)
- `~/.ssh/ubuntu_gha.pub` — **public** key (goes on the Ubuntu server)

Never put the private key on the server.

#### 2. Put the public key on Ubuntu

If you can already SSH with a password:

```bash
ssh-copy-id -i ~/.ssh/ubuntu_gha.pub ubuntu@YOUR_SERVER_IP
```

Or on the server manually:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Paste the one line from `~/.ssh/ubuntu_gha.pub` (starts with `ssh-ed25519`). Cloud VMs often already have a key from the provider — you can reuse that instead.

#### 3. Confirm login works

```bash
ssh -i ~/.ssh/ubuntu_gha ubuntu@YOUR_SERVER_IP
```

You should get a shell with no password prompt.

#### 4. Add the private key as a GitHub secret

```bash
cat ~/.ssh/ubuntu_gha
```

Copy everything, including:

```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

In the **caller** repo: **Settings → Secrets and variables → Actions → New repository secret**

- Name: `SSH_PRIVATE_KEY`
- Value: the full private key

Do not commit the private key or paste it into workflow YAML.

#### 5. Enable passwordless sudo

On the server (as a user who already has sudo):

```bash
sudo visudo
```

Add a line for your SSH user (example for `ubuntu`):

```
ubuntu ALL=(ALL) NOPASSWD:ALL
```

Without this, the workflow hangs on `sudo` because nobody can type a password.

#### 6. Call the workflow from another repo

Add a workflow file, for example `.github/workflows/provision.yml`:

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
