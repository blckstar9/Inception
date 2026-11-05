
# Inception — User Guide

## Overview

Inception hosts a WordPress website using three Docker services:
NGINX, WordPress with PHP-FPM, and MariaDB.

The application runs inside a Linux virtual machine.

## First-time setup

From a fresh clone, run `make` in the project root.

The setup script automatically creates the environment file,
generates the required passwords, and prepares persistent
storage directories.

After installation, the WordPress administrator username is
configured through `WORDPRESS_ADMIN_USER` in `srcs/.env`.

The corresponding initial password is stored in
`srcs/secrets/wp_admin_password`.

Never publish or share the secret files.

Running `make` again does not replace existing passwords.

## Starting the application

Open a terminal inside the virtual machine and navigate
to the project directory:

```bash
cd ~/Inception
make
```

Check the status:

```bash
make ps
```

All three containers should be running.

## Accessing WordPress

Website:

https://aybelaou.42.fr

Administration dashboard:

https://aybelaou.42.fr/wp-admin/

For local access, open a web browser inside the virtual
machine and navigate to https://aybelaou.42.fr.

The domain must resolve to the VM's local HTTPS endpoint.
When using the browser inside the VM, it can resolve to
127.0.0.1.

A browser warning may appear because the development TLS
certificate is self-signed.

## User accounts

The initial WordPress configuration creates:

- `siteowner`: administrator account.
- `visitor`: regular subscriber account.

The actual passwords are stored in local secret files,
not in this document.

## Credentials and secrets

Secret files are located inside:

`srcs/secrets/`

They include:

- `db_password`
- `db_root_password`
- `wp_admin_password`
- `wp_user_password`

Only authorized users of the VM should access these files.
Never share or commit their contents.

## Managing the application

Start the infrastructure:

```bash
make
```

Stop the running containers:

```bash
make stop
```

Start previously stopped containers:

```bash
make start
```

Stop and remove containers and the Compose network:

```bash
make down
```

Recreate the infrastructure:

```bash
make re
```

Inspect container status:

```bash
make ps
```

Read logs:

```bash
make logs
```

## Data persistence

WordPress content and MariaDB data are stored in
persistent Docker volumes backed by directories on the VM.

Removing and recreating containers does not remove the
website data.

Do not manually delete `/home/aybelaou/data` unless
permanent data loss is intended.

## Basic troubleshooting

If the website is unavailable:

1. Confirm that the virtual machine is running.
2. Run `make ps`.
3. Inspect the output of `make logs`.
4. Verify that HTTPS access to the VM is available.
5. Check that the domain resolves to the correct destination.

If the browser shows a certificate warning, remember that
the local development certificate is self-signed.
