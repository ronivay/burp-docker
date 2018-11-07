#!/bin/bash

SSL_KEY_RANDOM_PASS=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
APPSECRET_RANDOM_PASS=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
BUI_USER=${BUI_USER:-bui}
BUI_USER_PASSWORD=${BUI_USER_PASSWORD:-password}
WEBUI_ADMIN_PASSWORD=${WEBUI_ADMIN_PASSWORD:-admin}
RESTOREPATH=${RESTOREPATH:-\/tmp\/bui}
NOTIFY_EMAIL=${NOTIFY_EMAIL:-youremail@example.com}

# fix postfix configuration
sed -i 's/^inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf
sed -i 's/^inet_interfaces = localhost/#inet_interfaces = localhost/' /etc/postfix/main.cf

if [[ -z $(ls -A /etc/burp) ]]; then
	cd /etc/burp-source && make install-configs
	cp /etc/burp/burp-server.conf /etc/burp/burp-server.conf.template
fi

# start with clean config files
cp -f /etc/burp/burp-server.conf.template /etc/burp/burp-server.conf
cp -f /usr/share/burpui/etc/burpui.sample.cfg /etc/burp/burpui.cfg
cp -f /usr/share/burpui/contrib/gunicorn/burpui_gunicorn.py /etc/burp/burpui_gunicorn.py

## fix for clients not showing in the UI. Will be fixed in burp-ui v0.7
sed -i "s/self.burpbin, '-v'/self.burpbin, '-V'/" /usr/lib/python2.7/site-packages/burpui/misc/backend/burp2.py

# enable listen_status port in burp server
sed -i 's/^#listen_status = 127.0.0.1:4972/listen_status = 0.0.0.0:4972/' /etc/burp/burp-server.conf
sed -i 's/^#max_status_children = 5/max_status_children = 15/' /etc/burp/burp-server.conf

# set timer to 23h instead of 20h
sed -i 's/^timer_arg = 20h/timer_arg = 23h/' /etc/burp/burp-server.conf

# enable bui user to act as restore client
echo "restore_client = ${BUI_USER}" >> /etc/burp/burp-server.conf

# performance enhancement
echo "monitor_browse_cache = 1" >> /etc/burp/burp-server.conf

# if burp-ui client configuration doesn't exist, add
if [ ! -f /etc/burp/clientconfdir/${BUI_USER} ]; then
cat >/etc/burp/burp.conf<<EOF
mode = client
port = 4971
status_port = 4972
server = 127.0.0.1
password = ${BUI_USER_PASSWORD}
cname = ${BUI_USER}
pidfile = /var/run/burp.bui.pid
syslog = 0
stdout = 1
progress_counter = 1
network_timeout = 72000
ca_burp_ca = /usr/sbin/burp_ca
ca_csr_dir = /etc/burp/CA-client
# SSL certificate authority - same file on both server and client
ssl_cert_ca = /etc/burp/ssl_cert_ca-client.pem
# Client SSL certificate
ssl_cert = /etc/burp/ssl_cert-client.pem
# Client SSL key
ssl_key = /etc/burp/ssl_cert-client.key
# SSL key password
ssl_key_password = ${SSL_KEY_RANDOM_PASS}
# Common name in the certificate that the server gives us
ssl_peer_cn = burpserver
# The following options specify exactly what to backup.
include = /home
EOF
fi

# if burp-ui client configuration doesn't exist, add
if [[ ! -f /etc/burp/clientconfdir/${BUI_USER} ]]; then
cat > /etc/burp/clientconfdir/${BUI_USER}<<EOF
password = ${BUI_USER_PASSWORD}
EOF
fi

## fix burp-ui configuration parameters

# enable burp-ui to query the server
sed -i 's/^#\[Burp\]/\[Burp\]/' /etc/burp/burpui.cfg
sed -i 's/^#bhost = ::1/bhost = 127.0.0.1/' /etc/burp/burpui.cfg
sed -i 's/^#bport = 4972/bport = 4972/' /etc/burp/burpui.cfg
sed -i 's/^#burpbin = \/usr\/sbin\/burp/burpbin = \/usr\/bin\/burp/' /etc/burp/burpui.cfg
sed -i 's/^#stripbin = \/usr\/sbin\/vss_strip/stripbin = \/usr\/bin\/vss_strip/' /etc/burp/burpui.cfg
sed -i 's/^#bconfcli = \/etc\/burp\/burp.conf/bconfcli = \/etc\/burp\/burp.conf/' /etc/burp/burpui.cfg
sed -i 's/^#bconfsrv = \/etc\/burp\/burp-server.conf/bconfsrv = \/etc\/burp\/burp-server.conf/' /etc/burp/burpui.cfg
sed -i "s/^#tmpdir = \/tmp\/bui/tmpdir = ${RESTOREPATH}/" /etc/burp/burpui.cfg
sed -i 's/^#timeout = 15/timeout = 15/' /etc/burp/burpui.cfg
sed -i "s/appsecret = random/appsecret = ${APPSECRET_RANDOM_PASS}/" /etc/burp/burpui.cfg

# set admin password to non-default
sed -i 's/^#\[BASIC\]/\[BASIC\]/' /etc/burp/burpui.cfg
sed -i "s/^#admin = password/admin = ${WEBUI_ADMIN_PASSWORD}/" /etc/burp/burpui.cfg

if [[ $NOTIFY_FAILURE == "true" ]]; then
	sed -i '/^#notify_failure/s/^#//g' /etc/burp/burp-server.conf
	sed -i "s/youremail@example.com/${NOTIFY_EMAIL}/g" /etc/burp/burp-server.conf
fi

if [[ $NOTIFY_SUCCESS == "true" ]]; then
	sed -i '/^#notify_success/s/^#//g' /etc/burp/burp-server.conf
	sed -i "s/youremail@example.com/${NOTIFY_EMAIL}/g" /etc/burp/burp-server.conf
fi

if [[ $REDIS == "true" ]]; then
	sed -i 's/^storage = default/storage = redis/' /etc/burp/burpui.cfg
	sed -i 's/^session = default/session = redis/' /etc/burp/burpui.cfg
	sed -i 's/^cache = default/cache = redis/' /etc/burp/burpui.cfg
	sed -i "s/^redis = localhost:6379/redis = ${REDIS_SERVER}/" /etc/burp/burpui.cfg
fi

if [[ $MYSQL == "true" ]]; then
	sed -i "s/^database = none/database = mysql:\/\/${MYSQL_USER}:${MYSQL_PASSWORD}@mysql-server\/${MYSQL_DATABASE}/" /etc/burp/burpui.cfg
fi

# fix gunicorn configuration

sed -i "s/^daemon = False/daemon = True/" /etc/burp/burpui_gunicorn.py
sed -i "s/^pidfile = None/pidfile = '\/var\/run\/burp-ui.pid'/" /etc/burp/burpui_gunicorn.py
sed -i "s/^umask = 0/umask = 0022/" /etc/burp/burpui_gunicorn.py
sed -i "s/^user = 'burpui'/user = 'root'/" /etc/burp/burpui_gunicorn.py
sed -i "s/^group = 'burpui'/group = 'root'/" /etc/burp/burpui_gunicorn.py
sed -i "s/^errorlog = '\/var\/log\/gunicorn\/burp-ui_error.log'/errorlor = '\/var\/log\/burp-ui.log'/" /etc/burp/burpui_gunicorn.py
sed -i "s/^accesslog = '\/var\/log\/gunicorn\/burp-ui_access.log'/accesslog = '\/var\/log\/burp-ui.log'/" /etc/burp/burpui_gunicorn.py

/usr/bin/monit
