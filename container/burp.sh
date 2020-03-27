#!/bin/bash

if [ $# != "2" ]; then
	echo "usage: $(basename $0) burp/burp-ui start/stop"
	exit
fi

function Burp {
	if [ "$1" == "start" ]; then
		/usr/bin/bash -c '2>&1 1>>/var/log/burp.log burp -F -v -c /etc/burp/burp-server.conf &'
	elif [ "$1" == "stop" ]; then
		kill $(cat /run/burp-server.pid)
	else
		echo "unknown command $1"
	fi
}

function BurpUI {
	if [ "$1" == "start" ]; then
		gunicorn -c /etc/burp/burpui_gunicorn.py 'burpui:create_app(conf="/etc/burp/burpui.cfg",logfile="/var/log/burp-ui/burp-ui.log")'
	elif [ "$1" == "stop" ]; then
		kill $(cat /var/run/burp-ui.pid)
	else
		echo "unknown command $1"
	fi
}

case "$1" in

	burp)
	Burp $2
	exit 0;
	;;
	burp-ui)
	BurpUI $2
	exit 0
	;;
	*)
	exit 0
	;;
esac

