
/usr/libexec/polkit-gnome-authentication-agent-1 &
if pgrep -u marcial nm-applet &> /dev/null;
then
echo alive &> /dev/null
else
nvidia-settings --load-config-only &
nm-applet &
parcellite &
sh composekey.sh &
xrdb .Xdefaults &
xrandr -s 1600x1200 &
xkbset -a &
fi
if pgrep -u marcial trayer &> /dev/null;
then
echo alive &> /dev/null
else
trayer --edge top --align left --SetDockType true --SetPartialStrut true --widthtype percent --width 4 --height 14
# stalonetray
fi
