# Burp docker container

This repository contains files to build burp container which includes burp-ui and email sending capability.

Burp is an open source backup and restore software for Unix and Windows clients.
https://burp.grke.org/

Burp-UI is a great project wich applies a graphical user interface to interact with the server, edit settings and manage clients.
https://github.com/ziirish/burp-ui

#### Installation

- Clone this repository
```
git clone https://github.com/ronivay/burp-docker
```

- build docker container manually

```
cd container
docker build -t burp-server .
```

- or pull from dockerhub

```
docker pull ronivay/burp-docker
```

- run it with defaults values for testing purposes. 

```
docker run -itd -p 5000:5000 burp-docker
```

Burp-UI is now accessible at `http://your-server-ip:5000`. Default username and password admin/admin

- Suggested method is to use the provided docker-compose file. Edit the variables to your preference and start up the environment

```
docker-compose up -d
```
Burp-UI is now accessible at `http://your-server-ip:5000`. Password for admin user is the one you defined in `BUI_USER_PASSWORD` variable.

#### Variables

`NOTIFY_SUCCESS` 

Boolean value true/false for receiving notifications on successfull backups via email. 

`NOTIFY_FAILURE`

Boolean value true/false for receiving notification on failed backups via email.

`NOTIFY_EMAIL`

Email address where notifications are sent to

`REDIS`

Boolean value true/false for using redis or not. Mainly designed to work with docker-compose

`MYSQL`

Boolean value true/false for using mysql or not. Mainly designed to work with docker-compose

`MYSQL_USER`

Username for connecting to mysql server

`MYSQL_DATABASE`

Mysql database to use

`MYSQL_PASSWORD`

Mysql password to use

`RESTOREPATH`

Path where restored files via burp-ui are stored. Slashes need to be escaped in this, example: `\/tmp\/bui`

`BUI_USER`

Username which burp-ui uses to interact with the server

`BUI_USER_PASSWORD`

BUI_USER password for burp-ui to interact with the server

`WEBUI_ADMIN_PASSWORD`

burp-ui admin user password. 

#### Volumes

There are few important mountpoints you should note if preserving data is important.

`/etc/burp` - configuration path
`/var/spool/burp` - path for backup store
`/tmp/bui` - default path for restored files when done from burp-ui

You should mount a path from host machine to these for best outcome.

#### Tips

- Each restart copies /etc/burp/burp-server.conf.template as /etc/burp/burp-server.conf and edits it according to variables set. If you wish to add or edit some configuration which is not supported by my build, you can edit the template file to preserve things in the future. 

- /etc/burp/burp.conf is generated only if /etc/clientconfdir/${BUI_USER} file doesn't exist, so you can also edit that if you wish.

- /etc/burp/burpui.cfg is copied from the package provided template on every restart, so it's currently not possible to edit it outside what variables provide.



