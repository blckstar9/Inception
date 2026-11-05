
# Inception — Developer Guide

## Development environment

The project is developed in a minimal Debian 13 virtual
machine running Docker Engine and Docker Compose.

The mandatory application images use Debian 12 Bookworm
as their base image.

The project directory is:

`/home/aybelaou/Inception`

## Service architecture

### MariaDB

Source directory:

`srcs/requirements/mariadb/`

The Dockerfile installs MariaDB from Debian packages.

The initialization script reads database passwords from
Docker secrets, prepares the database and creates the
WordPress database user.

MariaDB listens internally on port 3306.

Its data directory is `/var/lib/mysql`.

### WordPress

Source directory:

`srcs/requirements/wordpress/`

The image installs PHP-FPM, PHP extensions and WP-CLI.

The entrypoint script:

1. Downloads WordPress if its files are missing.
2. Generates `wp-config.php` if necessary.
3. Waits for MariaDB.
4. Installs WordPress if it is not installed.
5. Creates the regular WordPress user if necessary.
6. Starts PHP-FPM.

PHP-FPM listens internally on port 9000.

WordPress files are stored in `/var/www/html`.

### NGINX

Source directory:

`srcs/requirements/nginx/`

NGINX listens on port 443 using TLS 1.2 and TLS 1.3.

It serves static WordPress files and forwards PHP requests
to the `wordpress` service on port 9000.

A self-signed development certificate is generated when
the container starts if no certificate is present.

## Docker networking

All services share the Docker Compose bridge network
named `inception`.

Service names are used for internal communication:

- `mariadb:3306`
- `wordpress:9000`

Only NGINX publishes port 443 to the VM.

Neither MariaDB nor WordPress publishes a host port.

## Persistent storage

Docker Compose defines two named volumes:

- `inception_mariadb_data`
- `inception_wordpress_data`

They use bind-backed local volume configurations.

VM storage paths:

```text
/home/aybelaou/data/
├── mariadb/
└── wordpress/
```

Container paths:

- MariaDB: `/var/lib/mysql`
- WordPress: `/var/www/html`

The NGINX container also mounts WordPress files,
but only in read-only mode.

## Automated environment setup

The script `srcs/tools/setup.sh` is executed by the Makefile.

It prepares the environment before Docker Compose starts.

For a fresh installation:

```bash
make setup
make
```

The setup script is idempotent: existing environment files
and non-empty secret files are preserved.

The persistent storage root is configured using `DATA_ROOT`
in `srcs/.env`. By default, it is set to `$HOME/data` for
the user running the setup script.

The two bind-backed Docker volumes use:

- `${DATA_ROOT}/mariadb`
- `${DATA_ROOT}/wordpress`

The four required secret files are generated with OpenSSL.
They are excluded from Git.

For an existing installation, do not replace database or
WordPress passwords by simply regenerating secret files.
Stored credentials must be updated consistently.

## Environment configuration

The file `srcs/.env` contains non-secret application
configuration such as the domain, database name,
database username and WordPress account names.

Use `srcs/.env.example` as a starting point.

The file `srcs/.env` is excluded from Git.

## Secrets

Compose reads passwords from files inside `srcs/secrets/`.

The required secret filenames are:

- `db_password`
- `db_root_password`
- `wp_admin_password`
- `wp_user_password`

To generate new random passwords before a fresh installation:

```bash
mkdir -p srcs/secrets
chmod 700 srcs/secrets
umask 077

openssl rand -hex 24 > srcs/secrets/db_password
openssl rand -hex 24 > srcs/secrets/db_root_password
openssl rand -hex 24 > srcs/secrets/wp_admin_password
openssl rand -hex 24 > srcs/secrets/wp_user_password
```

Changing these secret files after initialization does not
automatically change credentials already stored in MariaDB
or WordPress.

## Building and running

From the project root:

```bash
make
make ps
```

To rebuild the images:

```bash
make build
```

To recreate the infrastructure:

```bash
make re
```

To inspect logs:

```bash
make logs
```

## Validation

Check the Compose configuration:

```bash
sudo docker compose \
  --env-file srcs/.env \
  -f srcs/docker-compose.yml \
  config --quiet
```

Check the NGINX configuration:

```bash
sudo docker exec nginx nginx -t
```

Check the WordPress installation:

```bash
sudo docker exec -u www-data wordpress \
  wp core is-installed --path=/var/www/html
```

List WordPress users:

```bash
sudo docker exec -u www-data wordpress \
  wp user list --path=/var/www/html
```

Inspect the containers:

```bash
make ps
```

Inspect Docker resource usage:

```bash
sudo docker system df
df -h /
```

## Persistence testing

Publish a WordPress article and run:

```bash
make re
```

After the containers restart, verify that the article
is still available.

MariaDB persistence can also be tested by creating a
temporary SQL table, recreating the container and checking
that the table still exists.


## Local browser access

The WordPress website is served by NGINX on HTTPS port 443.

To access it from a browser running inside the VM, ensure
that `/etc/hosts` contains:

```text
127.0.0.1 aybelaou.42.fr
```

Verify the hostname resolution with:

```bash
getent ahostsv4 aybelaou.42.fr
```

The browser can then access `https://aybelaou.42.fr`
without an SSH tunnel or proxy.

A self-signed TLS certificate warning may appear.

The graphical browser is a VM administration tool and is
not part of the Docker Compose infrastructure.


## Git workflow

The main branch is `main`.

The personal GitHub remote is named `origin`.

Environment files, secrets and persistent data must not
be included in commits.

Before pushing, verify staged changes and confirm that
no credentials have been committed.
