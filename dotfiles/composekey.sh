#!/bin/bash

if [ "$1" = "post" ] ; then
    typeset -x DISPLAY=:0.0
    # sleep 1
    su -c "/usr/bin/xmodmap ~/.Xmodmap" marcial
fi
