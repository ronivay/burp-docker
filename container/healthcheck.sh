#!/bin/bash

/usr/bin/curl -s -I -m 3 http://127.0.0.1:5000 >/dev/null

if [[ "$?" == "0" ]]; then
	webcheck_retval="0"
else
	webcheck_retval="1"
fi

/usr/bin/pgrep burp >/dev/null

if [[ "$?" == "0" ]]; then
        burp_retval="0"
else
        burp_retval="1"
fi


if [[ "$webcheck_retval" == "1" ]] || [[ "$burp_retval" == "1" ]]; then
	exit 1
fi
