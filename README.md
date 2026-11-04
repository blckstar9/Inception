*This project has been created as part of the 42 curriculum by aybelaou.*

# Inception

## Description

Inception is a system administration project developed as part of
the 42 curriculum.

The goal is to deploy a small web infrastructure using Docker
Compose, with each mandatory service running in its own container.

The project is developed and tested inside a Debian virtual machine.

## Architecture

The infrastructure contains three services:

- **NGINX**: HTTPS entry point, using TLS 1.2 and TLS 1.3.
- **WordPress + PHP-FPM**: web application and PHP execution.
- **MariaDB**: database used by WordPress.

Only NGINX publishes a port outside the Docker network.

```text
Browser
   |
   | HTTPS (443)
   v
NGINX
   |
   | FastCGI (9000)
   v
WordPress + PHP-FPM
   |
   | SQL (3306)
   v
MariaDB
```

## Project structure

- `Makefile`: infrastructure management commands.
- `srcs/docker-compose.yml`: Docker Compose configuration.
- `srcs/requirements/nginx/`: NGINX image and configuration.
- `srcs/requirements/wordpress/`: WordPress and PHP-FPM image.
- `srcs/requirements/mariadb/`: MariaDB image and initialization.
- `srcs/.env.example`: example environment configuration.
- `USER_DOC.md`: instructions for users and administrators.
- `DEV_DOC.md`: developer documentation.

## Requirements

- A Linux virtual machine
- Docker Engine
- Docker Compose plugin
- GNU Make
- Sufficient disk space for images and persistent data

The Docker images are built from Debian Bookworm rather than
using prebuilt application images.

## Instructions


### First-time setup

Clone the repository and enter the project directory.

```bash
git clone <repository-url> Inception
cd Inception
make
```

The Makefile automatically runs `srcs/tools/setup.sh`, which:

1. Creates `srcs/.env` from `srcs/.env.example` if missing.
2. Configures the domain using the current Linux username.
3. Creates the persistent data directories.
4. Generates four random secrets if missing.
5. Starts the infrastructure using Docker Compose.

Review `srcs/.env` to customize the domain, site title, and
WordPress usernames before the first installation.

Existing secrets and persistent data are preserved when
the setup script is run again.

Never commit environment files containing private information,
passwords, private keys, or secret files.


## Usage

```bash
make
make ps
make logs
make stop
make start
make down
make re
```

The WordPress website uses the domain configured by
`DOMAIN_NAME`. DNS or local name resolution must point to
the virtual machine, and the client must be able to reach
the VM's HTTPS port.

## Persistent data

The MariaDB and WordPress Docker volumes are bound to:

- `/home/aybelaou/data/mariadb`
- `/home/aybelaou/data/wordpress`

The data is preserved when the containers are recreated.

## Security

- TLS 1.2 and TLS 1.3 are enabled in NGINX.
- MariaDB and PHP-FPM do not publish host ports.
- Passwords are provided through local Docker Compose secrets.
- Sensitive files are excluded from Git.
- The WordPress administrator does not use `admin` or
  `administrator` as its username.

The current TLS certificate is self-signed and intended for
local development.

## Resources

Relevant technical references:

- Docker documentation: https://docs.docker.com/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI handbook: https://make.wordpress.org/cli/handbook/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/docs/

ChatGPT was used to help work on Docker configuration,
shell scripts and documentation, and to explain and debug
the infrastructure. The resulting services were tested
inside the virtual machine.
