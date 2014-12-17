#!/bin/bash
#
# Ablock.sh version 0.98
# Author Bodhi.zazen https://wiki.ubuntu.com/BodhiZazen
#
# This script is released under The GNU General Public License version 3
# http://www.gnu.org/licenses/gpl-3.0-standalone.html
# You may modify and distribute this script as you wish, but please give credit
#
# This script maintains a /etc/hosts file for adblocking.
# Please see the README for configuration information.
# You will need to run this script as root with gksu (kdesu on Kubuntu).
#
# ****************************


# ****************************
#
#
# This script checks and installs tofrodos and unzip if needed.
#
# You may use this script without X if you use sudo
# In that event you will want to use the options s, d, or z.

# Test bash and display
uid=$(/usr/bin/id -u)
if [ ! "$uid" = "0" ];then
if [ -z $DISPLAY ]; then
sudo bash $0 $@
exit 0
else
gksu "$0 $@"
exit 0
fi
fi

if [ -z $BASH ]; then
if [ -z $DISPLAY ]; then
sudo bash $0 $@
exit 0
else
gksu "$0 $@"
exit 0
fi
fi

# Declair variables
HFSERVER="http://hostsfile.mine.nu.nyud.net:8080"
HFILE="hosts.zip"
ORIGFILE="/etc/hosts.original"
HOSTS="/etc/hosts"
ADBLOCK="/etc/hosts.adblock"
CP="/bin/cp -f"
APTY="/usr/bin/apt-get -y install"
APTR="yes | /usr/bin/apt-get remove"
ZEN="/usr/bin/zenity"
ZENTXT='$ZEN --title "adblock "${VER}"" --info --text'
ZENWARN='$ZEN --title "adblock "${VER}"" --warning --text'
VER="0.97"
UNZIP="/usr/bin/unzip"
WGET="/usr/bin/wget"
GREP="/bin/grep"
DOS="/usr/bin/fromdos"
RM="/bin/rm -f"
SED="/bin/sed"
ZENMSG='"$TXT"'

# OPT = script options
# TERM = test if the -t option is set
# TXT= message


#Color
RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
NC='\e[0m' # No Color

###############
## Functions ##
##############

usage ()
{
MSG="This script is to enable Adblocking while browsing the web by modifying your hosts file.
The script will BACKUP and then MODIFY your hosts file (/etc/hosts).

*******************************************

THIS SCRIPT MYST BE RUN WITH gksu or sudo:

gksu /path/to/adblock-"${VER}".sh
sudo bash /path/to/adblock-"${VER}".sh

*******************************************

Backup location = /etc/hosts.original

The format of /etc/hosts is : 'IP_Address Host_name'

To block the ad server 'bad_ads' we will use
127.0.0.1 bad_ads
Or
0.0.0.0 bad_ads

127.0.0.1 is the default (select this if you are not sure).
0.0.0.0 may be faster , but may break some clients (Opera).

Options:
a | --activate => Activate adblocking
cp -f $ADBLOCK $HOSTS
d | --default => Run the script with 127.0.0.1 for adblocking
h | --help => Help
i | --inactive => Inactivate adblocking
r | --remove => Removes adblock.sh and all config files.
s | --store => Stores the hosts list in /root/hosts.adblock for review
t | --terminal => Run in a terminal
v | --version information
z | --zero => Runs the script with 0.0.0.0 for adblocking


Additional information :

See the "README" file

http://www.mvps.org/winhelp2002/hosts.htm
http://pgl.yoyo.org/adservers/"

# Print
case "$D" in
e)
more < $MSG
EOF
;;
z)
eval $ZEN --title "adblock "${VER}"" --width=500 --height=500 --text-info < $MSG
EOF
;;
esac
}

opts ()
{
case $OPT in
a | -a | --activate) # Active
activate
;;
d | -d | --default) # Default = 127.0.0.1
IP="127.0.0.1"
;;
h | -h | --help) # Help
usage
;;
i | -i | --inactivate) # Inactive
inactivate
;;
r | -r | --remove) #Removes adblock.
if [ ! -x "/usr/bin/zenity" ]; then
remove
exit 0
else
$ZEN --title "adblock "${VER}"" --question --text "This will remove adblock.sh and the configuration files from your computer. Are your sure you want to do this?"
return_value=$?
case $return_value in
1)
exit 1
;;
0)
remove
exit 0
;;
esac
fi
;;
s | -s | --store) #Store
download
$UNZIP -p /tmp/$HFILE | $DOS | $GREP -v pop3.*norton | $GREP -v localhost | $GREP -v pastebin.com > $ADBLOCK
$RM /tmp/$HFILE
TXT="The Hosts file was downladed and extracted to /root/hosts.adblock"
zeninfo
if [ "$D" = "e" ];then echo;fi
exit 0
;;
v | -v | --version)
case "$D" in
e)
echo
echo -e "$GREEN""adblock.sh version "${VER}"\nauthor = bodhi.zazen\nHome Page = https://wiki.ubuntu.com/BodhiZazen""$NC"
echo
;;
z)
$ZEN --title "About adblock.sh" --info --text "adblock.sh version "${VER}"
author = bodhi.zazen
Home Page = https://wiki.ubuntu.com/BodhiZazen"
;;
esac
;;
z | -z | --zero) # Use zero 0.0.0.0
IP="0.0.0.0"
;;
*)
usage
exit 1
;;
esac
}

default ()
{
# The default is to use 127.0.0.1
$CP $ORIGFILE $HOSTS
echo "" >>/etc/hosts # make sure the original file ends in a new-line
$UNZIP -p /tmp/$HFILE | $DOS | $GREP -v pop3.*norton | $GREP -v localhost | $GREP -v pastebin.com >> $HOSTS
}

zero ()
{
# This option uses 0.0.0.0
$CP $ORIGFILE $HOSTS
echo "" >>/etc/hosts # make sure the original file ends in a new-line
$UNZIP -p /tmp/$HFILE | $DOS | $GREP -v pop3.*norton | $GREP -v localhost | $GREP -v pastebin.com | $SED 's_127.0.0.1_0.0.0.0_g' >> $HOSTS
}

download ()
{
case "$D" in
e)
$WGET -O /tmp/$HFILE $HFSERVER/$HFILE 2>&1
;;
z)
RUN="1"
$WGET -O /tmp/$HFILE $HFSERVER/$HFILE 2>&1 | sed -u 's/.*\ \([0-9]\+%\)\ \+\([0-9.]\+\ [KMB\/s]\+\)$/\1\n# Downloading \2/' | $ZEN --title "adblock "${VER}"" --progress --text "Downloading hosts file Please wait ..." --auto-close &
while [ "$RUN" -eq "1" ];do
if [ -z "$(pidof wget)" ] ; then
RUN="0"
else
if [ -z "$(pidof zenity)" ] ; then
pkill wget
TXT="wget killed"
zenwarn
$RM /tmp/$HFILE
$ZEN --title "adblock "${VER}"" --warning --text "Canceled without updating hosts file"
exit 1
else
sleep 2
fi
fi
done
;;
esac
if [ ! -e /tmp/$HFILE ]; then
TXT="Hosts file failed to download"
zenwarn
exit 1
fi
}

zeninfo ()
{
case "$D" in
e)
echo -e $RED"$TXT" $NC;
;;
z)
eval $ZENTXT $ZENMSG;
;;
esac
}

zenwarn ()
{
case "$D" in
e)
echo -e $RED"${TXT}" $NC;
;;

z)
eval $ZENWARN $ZENMSG;
;;
esac
}

activate ()
{
$CP $ADBLOCK $HOSTS
TXT="Adblock activated"
zeninfo
exit 0
}

inactivate ()
{
$CP $ORIGFILE $HOSTS
TXT="Adblock inactivated"
zeninfo
exit 0
}

remove ()
{
$CP $ORIGFILE $HOSTS
$RM $ORIGFILE
$APTR tofrodos
$RM /root/hosts.adblock
$RM /tmp/hosts*
$RM $0
}

###################
## Sanity checks ##
###################

# Runing in X ?
## Test X
if [ -z "$D" ] && [ -z $DISPLAY ];then
D="e"
else
D="z"
fi

# Check for zenity
# This section needs work yet.
if [ ! -x "/usr/bin/zenity" ]; then
R=0
while [ "$R" -lt "4" ];do
echo "zenity must be installed to use this script with X ... "
read -sp "Would you like to install zenity now ? [Yn]" -n 1 N;ANS="${N:=Y}"
case $ANS in
y | Y)
echo
$APT zenity
R=5
;;
n | N)
echo
D="e"
R=5
;;
*)
if [ "$R" -lt "3" ];then
let R=R+1
else
echo -e $RED "\n\nPlease select Y or N\n" $NC
R=0
fi
;;
esac
done
fi

# Check for unzip
if [ ! -x /usr/bin/unzip ]; then
TXT="Installing unzip"
zeninfo
$APTY unzip
if ps -C zenity
then pkill zenity
fi
fi

# Check for dos2unix
if [ ! -x /usr/bin/dos2unix ]; then
TXT="Installing tofrodos aka dos2unix"
zeninfo
$APTY tofrodos
if ps -C zenity
then pkill zenity
fi
fi

# Check for /etc/hosts.original
if [ ! -f "$ORIGFILE" ]; then
TXT="Backing up /etc/hosts to $ORIGFILE"
zeninfo
$CP $HOSTS $ORIGFILE
fi

# Check length ORIGFILE
HOSTS_LENGTH=$((wc -l $ORIGFILE) | awk '{ print $1}')
if [ "$HOSTS_LENGTH" -gt "100" ]; then
TXT="The file /etc/hosts.original is used to generate /etc/hosts and is too large ~ max 100 lines."
zenwarn
exit 1
fi



############
## Script ##
############

IP=""
while [ "$#" -gt "0" ]
do
if [ "${1:0:2}" = "--" ] ; then
OPT="$1"
opts
else
while getopts "adhirstvz" OPT; do
opts
done
fi
shift
done

if [ -z "$IP" ]; then
case "$D" in
e)
R=0
while [ "$R" -lt "4" ]; do
echo "what IP address would you prefer to use?"
echo 'Enter 0 for 0.0.0.0'
echo 'Enter 1 or 172.0.0.1'
read -sp "Preferred IP [0]" -n 1 RIP; IP="${RIP:=0}"
case "$IP" in
0)
echo
IP='0.0.0.0'
R=5
;;
1)
echo
IP='127.0.0.1'
R=5
;;
*)
if [ "$R" -lt "3" ];then
let R=R+1
else
echo
echo -e $RED "\n\nPlease select 0 or 1\n" $NC
echo
R=0
fi
;;
esac
done
;;
z)
IP=$($ZEN --title "adblock "${VER}"" --list --height=250 --text "What format do you want for your hosts file?" --radiolist --column "Format" --column "IP for blocking" TRUE "127.0.0.1" FALSE "0.0.0.0" FALSE "Activate" False "Inactivate" FALSE "Help")
return_value=$?
case "$return_value" in
1)
$ZEN --title "adblock "${VER}"" --warning --text "Canceled without updating hosts file"
exit 1
;;
0)
case $IP in
"Activate")
activate
;;
"Inactivate")
inactivate
;;
"Help")
usage
exit 1
;;
esac
;;
esac
;;
esac
fi

#Download hosts
download

#Set /etc/hosts

case "$IP" in
"127.0.0.1")
default
$CP $HOSTS $ADBLOCK
;;
"0.0.0.0")
zero
$CP $HOSTS $ADBLOCK
;;
esac

# Cleanup
$RM /tmp/hosts*
case "$D" in
e)
echo -e "$GREEN""Host file successfully updated !!""$NC"
echo
;;
z)
$ZEN --title "adblock "${VER}"" --info --text "Host file successfully updated"
esac
