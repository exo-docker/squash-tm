# What is Squash TM ?

Squash TM is one of the best open source management test tools for test repository management.
It has been designed for sharing test projects between stakeholders.

**Squash TM offers the following features:**

- Requirements, Test cases, Campaigns management
- Report management: custom reports (charts, dashboards) for requirements
- Connection with Bugtrackers and Agile project management tool: Jira
- Automation workspace for developers and testers introducing a Gherkin editor

**Squash TM also offers specific features designed for collaborative work:**

- Multi- and inter- project possibilities
- "Full web" tool, which does not need to be set up on the client workstation
- Intuitive and ergonomic design, RIA (Rich Internet Application) technology
- Light administration & user management

All documentation is available here: [https://sites.google.com/a/henix.fr/wiki-squash-tm/](https://sites.google.com/a/henix.fr/wiki-squash-tm/)

# Supported tags and Dockerfile links

The Dockerfile builds from "openjdk:8-jre-alpine" see [https://hub.docker.com/_/openjdk](https://hub.docker.com/_/openjdk)

The container taged `latest` will always refer to the last stable version of Squash TM. It means that each release of Squash TM corresponds to a docker image, starting from the version 1.19.1. 

 - [1.19.2, latest](https://bitbucket.org/squashtest/docker-squash-tm/src/master/Dockerfile) (Dockerfile)

 - [1.19.1](https://bitbucket.org/squashtest/docker-squash-tm/src/1.19.1/Dockerfile) (Dockerfile)

# Quick Start

Run the Squash-TM image with an embedded h2 database (for demo purpose only !)
```
docker run --name='squash-tm' -it -p 8090:8080 squashtest/squash-tm
```
*NOTE*: To run the container in daemon mode, use the -d option :

```
docker run --name='squash-tm' -d -it -p 8090:8080 squashtest/squash-tm
```
Please allow a few minutes for the applicaton to start, especially if populating the database for the first time. If you want to make sure that everything went fine, watch the log:
```
docker exec -it squash-tm sh

tail -f squash-tm/logs/squash-tm.log
```
Go to http://localhost:8090/squash or point to the IP of your docker host. 

The default username and password are:

-   username: **admin**
-   password: **admin**


# Configuration

*The following sections show how to deploy Squash TM using an external **PostgreSQL DB** container or an external **MariaDB** container. Exemples of yml file also show how to deploy this solution using **docker-compose**.*

## Backing up data with persistent volumes

As you may already know, in Docker you would generally keep data in volumes.

So, in order to use Squash TM image properly, it is highly recommended to set up an external database (MariaDB or PostgreSQL).

Each of these configurations povide the creation of a persistant volume for data.
```
/var/lib/postgresql/data     # Data location using PostgreSQL
/var/lib/mysql               # Data location using MariaDB
```
Moreover, if your purpose is to use squash TM image in production, you'll probably want to persist the following location in a volume in order to keep traces of logs.
```
/opt/squash-tm/logs          # Log directory
```
For more info check Docker docs section on [Managing data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/)

## Deployment using PostgreSQL

The database is created by the database container and automatically populated by the application container on first run.

All data from the database will be saved within the local volume named ‘squash-tm-db-pg’. So the db container (called ‘squash-tm-pg’) can be stop and restart with no risk of losing them.
```
docker run -it -d --name='squash-tm-pg' \
-e POSTGRES_USER=squashtm \
-e POSTGRES_PASSWORD=MustB3Ch4ng3d \
-e POSTGRES_DB=squashtm \
-v squash-tm-db-pg:/var/lib/postgresql/data \
postgres:9.6.12 \

sleep 10

docker run -it -d --name=squash-tm \
--link squash-tm-pg:postgres \
-v squash-tm-logs:/opt/squash-tm/logs -v squash-tm-plugins:/opt/squash-tm/plugins \
-p 8090:8080 \
squashtest/squash-tm
```
Wait 3-4 minutes the time for Squash-TM to initialize. then log in to *http://localhost:8090/squash* (admin  /  admin)

## Deployment using MariaDB

Database is created by the database container and automatically populated by the application container on first run.

All data from the database will be saved within the local volume named ‘squash-tm-db-mdb’. So the db container (called ‘squash-tm-mdb’) can be stop and restart with no risk of losing them.
```
docker run -it -d --name='squash-tm-mdb' \
-e MYSQL_ROOT_PASSWORD=MustB3Ch4ng3d \
-e MYSQL_USER=squashtm \
-e MYSQL_PASSWORD=MustB3Ch4ng3d \
-e MYSQL_DATABASE=squashtm \
-v squash-tm-db-mdb:/var/lib/mysql \
mariadb:10.2.22-bionic --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci \

sleep 10

docker run -it -d --name=squash-tm \
--link squash-tm-mdb:mysql \
-v squash-tm-logs:/opt/squash-tm/logs -v squash-tm-plugins:/opt/squash-tm/plugins \
-p 8090:8080 \
squashtest/squash-tm
```
Wait about 10 minutes, the time for Squash-TM to initialize (yes, mysql initialisation is a bit longer than postres…). then log in to *http://localhost:8090/squash* (admin  /  admin)

## Docker-Compose

### `docker-compose.yml file`

The following example of a docker-compose.yml link squash-tm to a MariaDB database. The environment variables should be set in a .env file (saved in the same repositority as the docker-compose.yml)

```
version: '3.7'
services:
  squash-tm-md:
    image: mariadb:10.2.22-bionic
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_DATABASE: ${DB_DATABASE}
    volumes:
      - "/var/lib/mysql-db:/var/lib/mysql"

  squash-tm:
    image: squashtest/squash-tm
    depends_on:
      - squash-tm-md
    environment:
      MYSQL_ENV_MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_ENV_MYSQL_USER: ${DB_USER}
      MYSQL_ENV_MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ENV_MYSQL_DATABASE: ${DB_DATABASE}
    ports:
      - 8090:8080/tcp
    links:
      - squash-tm-md:mysql
    volumes:
      - squash-tm-logs:/opt/squash-tm/logs
      - squash-tm-plugins:/opt/squash-tm/plugins

volumes:
  squash-tm-logs:
  squash-tm-plugins:
```

### `.env file`

Here is an example of a .env file :
```
DB_ROOT_PASSWORD=MustB3Ch4ng3d
DB_USER=squashtm
DB_PASSWORD=MustB3Ch4ng3d
DB_DATABASE=squashtm
```
### Run a docker-compose

1. Copy the **docker-compose.yml** that correspond to your need.
You’ll find several docker-compose repository on our [Bitbucket](https://bitbucket.org/squashtest/docker-squash-tm/src/master/)  :
 - [Squash-tm deployment using MariaDB database](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-mariadb/)
 - [Squash-tm deployment using Postgres database](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-postgres/)
 - [Squash-tm deployment using Postgres database and Reverse-Proxy](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-reverseproxy/docker-compose-nginx-postgres/)
 - [Squash-tm deployment using MariaDB database and Reverse-Proxy](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-reverseproxy/docker-compose-nginx-mariadb/)

2. Don’t forget to create a **.env** file (or set the value of environment variables directly in the docker-compose.yml file).

3. In the docker-compose.yml directory, run ``` docker-compose up ``` or ``` docker-compose up -d ``` for daemon mode.

4. Log in to *http://localhost:8090/squash* or  *http://**{host_ip}**:8090/squash*

For more information about docker-compose here is the [documentation](https://docs.docker.com/compose/)

## Environment variables

As we are using images of existing DB container, we also use their environment variables.

These variables are used by Squash TM image script to connect to the database.

Here are some info about them and links leading to their documentation.


### Postgres image environment variables

#### `POSTGRES_PASSWORD`

This environment variable is recommended for you to use the PostgreSQL image. This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the `POSTGRES_USER` environment variable.

#### `POSTGRES_USER`

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.

#### `POSTGRES_DB`

This optional environment variable can be used to define a different name for the default database that is created when the image is first started. If it is not specified, then the value of `POSTGRES_USER` will be used.

For further information and optional environment variables, please check out the [Posgres image documentation](https://hub.docker.com/_/postgres)


### MariaDB image environment variables

#### `MYSQL_ROOT_PASSWORD`
This variable is mandatory and specifies the password that will be set for the MariaDB `root` superuser account.

#### `MYSQL_DATABASE`
This variable is optional and allows you to specify the name of a database to be created on image startup. If a user/password was supplied then that user will be granted superuser access ([corresponding to `GRANT ALL`](http://dev.mysql.com/doc/en/adding-users.html)) to this database.

#### `MYSQL_USER`, `MYSQL_PASSWORD`

These variables are optional, used in conjunction to create a new user and to set that user's password. This user will be granted superuser permissions (see above) for the database specified by the `MYSQL_DATABASE` variable. Both variables are required for a user to be created.

Do note that there is no need to use this mechanism to create the root superuser, that user gets created by default with the password specified by the `MYSQL_ROOT_PASSWORD` variable.

For further information and optional environment variables, please check out the [MariaDB image documentation](https://hub.docker.com/_/mariadb)

## Using Squash TM container with a reverse proxy

Two examples of docker-compose.yml deploying Squash TM behind a reverse proxy are available on our ** [Bitbucket](https://bitbucket.org/squashtest/docker-squash-tm/src/master/) ** :

 - [Squash-tm deployment using Postgres database and Reverse-Proxy](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-reverseproxy/docker-compose-nginx-postgres/)
 - [Squash-tm deployment using MariaDB database and Reverse-Proxy](https://bitbucket.org/squashtest/docker-squash-tm/src/master/docker-compose-reverseproxy/docker-compose-nginx-mariadb/)

These solutions use a [docker image from jwilder based on nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy).

Here is an example of Squash TM deployed behind a reverse-proxy using Postres database:
```
version: '3.7'
services:
  squash-tm-pg:
    container_name: squash-tm-pg
    environment:
      POSTGRES_DB: ${DB_DATABASE}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USER}
    image: postgres:9.6.12
    volumes:
      - /var/lib/db-postgresql:/var/lib/postgresql/data
    networks:
      - db-network

  squash-tm:
    depends_on:
      - squash-tm-pg
    environment:
      POSTGRES_ENV_POSTGRES_USER: ${DB_USER}
      POSTGRES_ENV_POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_ENV_POSTGRES_DB: ${DB_DATABASE}
      VIRTUAL_HOST: mysquash.example.com
    ports:
      - 8090:8080/tcp
    image: squashtest/squash-tm
    links:
      - squash-tm-pg:postgres
    volumes:
      - squash-tm-logs:/opt/squash-tm/logs
      - squash-tm-plugins:/opt/squash-tm/plugins
    networks:
      - nginx-proxy
      - db-network

  nginx-proxy:
    container_name: nginx
    image: jwilder/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - nginx-proxy

volumes:
  squash-tm-logs:
  squash-tm-plugins:

networks:
  nginx-proxy:
  db-network:

```


**References**

-  [Squash-TM documentation](https://sites.google.com/a/henix.fr/wiki-squash-tm/)
-  [Bitbucket repository of Squash TM docker sources](https://bitbucket.org/squashtest/docker-squash-tm/src/)
-  [Posgres image documentation](https://hub.docker.com/_/postgres)
-  [MariaDB image documentation](https://hub.docker.com/_/mariadb)
-  [jwilder/nginx-proxy documentation](https://hub.docker.com/r/jwilder/nginx-proxy)

