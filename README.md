# defectdojo-ansible

Ansible project that deploys [DefectDojo](https://github.com/DefectDojo/django-DefectDojo)
(OWASP vulnerability management / ASPM) on an Ubuntu or Debian server using the
upstream Docker Compose stack (`git clone ... && docker compose up`, automated).

What it does:

1. Installs Docker Engine + Compose plugin (official Docker apt repo)
2. Clones `DefectDojo/django-DefectDojo` to `/opt/django-DefectDojo`
3. Writes a `.env` (image tag, ports, optional admin password)
4. Runs `docker compose up -d`
5. Waits for the `initializer` to finish and the UI to answer
6. Saves the generated admin password to `credentials/<host>.txt` on your control machine

## Layout

```
.
├── ansible.cfg
├── site.yml                 # main playbook
├── uninstall.yml
├── requirements.yml         # community.docker
├── Makefile
├── inventory/hosts.ini
├── group_vars/all.yml       # all settings live here
├── credentials/             # generated, git-ignored
└── roles/
    ├── docker/              # Docker Engine + Compose
    └── defectdojo/          # clone, .env, compose up, credentials
```

## Requirements

- Control machine: Ansible 2.15+ and `make`
- Target: Ubuntu 22.04/24.04 (or Debian 12), 2 vCPU / 4 GB RAM minimum (4 vCPU / 8 GB recommended), SSH + sudo
- Open port `8080` (HTTP UI) on the firewall / security group, optionally `8443`

## Usage

```bash
# 1. Put your server in inventory/hosts.ini
make deps      # install community.docker collection
make ping      # test SSH
make deploy    # first init takes ~3 minutes
make creds     # show admin login
```

Open `http://<server-ip>:8080` and log in as `admin`.

To run on the current machine, set `ansible_connection=local` in the inventory.

## Configuration (`group_vars/all.yml`)

| Variable | Default | Notes |
|---|---|---|
| `defectdojo_version` | `master` | Git branch/tag to clone. Pin a release tag for production. |
| `defectdojo_image_tag` | `latest` | Image tag for django + nginx. Match it to the pinned release. |
| `defectdojo_http_port` | `8080` | nginx HTTP port |
| `defectdojo_https_port` | `8443` | nginx HTTPS port |
| `defectdojo_admin_password` | `""` | Empty = random password from the initializer |
| `defectdojo_dir` | `/opt/django-DefectDojo` | Clone location |

Set your own admin password with Ansible Vault:

```bash
ansible-vault encrypt_string 'MyStr0ngPass!' --name defectdojo_admin_password
# paste the output into group_vars/all.yml, then:
ansible-playbook site.yml --ask-vault-pass
```

## Operations

```bash
# on the server
cd /opt/django-DefectDojo
docker compose ps
docker compose logs -f uwsgi
docker compose logs initializer | grep "Admin password:"

# update (from control machine)
make update TAG=2.xx.x   # after setting defectdojo_version to the same release

# remove
make uninstall
```

## Notes

- The initializer prints the admin password only on the **first** run. If the volumes already exist, the credentials file will say so; reset with
  `docker compose exec uwsgi ./manage.py changepassword admin`.
- For production, put a TLS-terminating reverse proxy (Nginx/Caddy/ALB) in front, or use the upstream `docker-compose.override.https.yml`.
- `master` is the development branch; pin a tag for stable deployments.
