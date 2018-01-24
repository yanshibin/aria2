#!/bin/bash

[ $# -eq '1' ] && vTHR="$1"
[ -z $vTHR ] && THR='64'
[ "$vTHR" == '64' ] && THR='64'
[ "$vTHR" == '128' ] && THR='128'
[ -z $THR ] && echo 'Error, Input invalid.' && exit 1
[ ! -f /etc/os-release ] && echo "Not Found Version! " && exit 1;
[ -f /etc/os-release ] && DEB_VER="$(awk -F'[= "]' '/VERSION_ID/{print $3}' /etc/os-release)"
[ -z $DEB_VER ] && echo "Error, Found Version! " && exit 1;
[ "$DEB_VER" == '7' ] && vName='wheezy' && vAria='1.15.1';
[ "$DEB_VER" == '8' ] && vName='jessie' && vAria='1.18.8';
[ -z $vName ] && echo 'Error,Get Debian version.' && exit 1;
Bit=$(getconf LONG_BIT)
[ "$Bit" == '32' ] && vBit='i386';
[ "$Bit" == '64' ] && vBit='amd64';
rm -rf /tmp/aria2_*.deb
wget --no-check-certificate -qO "/tmp/aria2_"$vBit"_thr"$THR".deb" "https://moeclub.org/attachment/DebianPackage/aria2/"$THR"Threads/aria2_"$vAria"-1_"$vBit".deb"
[ $? -ne '0' ] && echo 'Error, Download aria2.' && exit 1;
apt-get install -y -t "$vName" dpkg-dev vnstat nload quilt
apt-get build-dep -y -t "$vName" aria2
dpkg -i /tmp/aria2_*.deb

mkdir -p /etc/aria2
cat >/etc/aria2/aria2c.conf<<EOF
#Setting
dir=/home
dht-file-path=/etc/aria2/dht.dat
save-session-interval=15
force-save=false
log-level=error
 
# Advanced Options
disable-ipv6=true
file-allocation=none
max-download-result=35
max-download-limit=20M
 
# RPC Options
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-save-upload-metadata=true
rpc-secure=false
 
# see --split option
continue=true
max-concurrent-downloads=10
max-overall-download-limit=0
max-overall-upload-limit=5
max-upload-limit=1
 
# Http/FTP options
split=16
connect-timeout=120
max-connection-per-server=64
max-file-not-found=2
min-split-size=10M
check-certificate=false
http-no-cache=true
 
#BT options
bt-enable-lpd=true
bt-max-peers=80
bt-require-crypto=true
follow-torrent=true
listen-port=6881-6999
bt-request-peer-speed-limit=256K
bt-hash-check-seed=true
bt-seed-unverified=true
bt-save-metadata=true
enable-dht=true
enable-peer-exchange=true
seed-time=0

EOF

cat >/etc/aria2/aria2<<EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          aria2
# Required-Start:    \$all
# Required-Stop:     \$all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable aria2c by daemon.
### END INIT INFO
PATH=/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:/sbin:/bin
DAEMON=aria2c
CONF=/etc/aria2/aria2c.conf
DAEMONPID=\`ps -e |pgrep 'aria2c' |tail -n1\`

case "\$1" in
start)
[ -n "\$DAEMONPID" ] && echo "aria2c already in running [\$DAEMONPID]." && exit 1
ulimit -n 65530
iptables -N Aria2
iptables -A Aria2 -p tcp --dport 6800 -j ACCEPT
iptables -A Aria2 -p tcp --dport 6881:6999 -j ACCEPT
iptables -A Aria2 -p udp --dport 6881:6999 -j ACCEPT
sleep 1
[ -e \$CONF ] && \$DAEMON --conf-path=\$CONF -D
DAEMONPID=\`ps -e |pgrep 'aria2c' |tail -n1\`
[ -n "\$DAEMONPID" ] && echo "aria2c START Success [\$DAEMONPID]! "
[ -z "\$DAEMONPID" ] && echo "aria2c START Fail! "
;;
stop)
[ -z "\$DAEMONPID" ] && echo "aria2c not work ." && exit 1
kill -9 "\$DAEMONPID" >/dev/null 2>&1
sleep 1
iptables -F Aria2
iptables -X Aria2
DAEMONPID=\`ps -e |pgrep 'aria2c' |tail -n1\`
[ -z "\$DAEMONPID" ] && echo "aria2c STOP Success."
[ -n "\$DAEMONPID" ] && echo "aria2c STOP Fail."
;;
restart)
[ -n "\$DAEMONPID" ] && kill -9 "\$DAEMONPID" >/dev/null 2>&1
sleep 1
\$0 start;
;;
*)
echo "Usage: aria2c {start|stop|restart}"
exit 1
esac
exit 0

EOF

chown -R root:root /etc/aria2
chmod -R a+x /etc/aria2
ln -sf /etc/aria2/aria2 /etc/init.d/aria2
update-rc.d -f aria2 remove >/dev/null 2>&1
update-rc.d aria2 defaults
mkdir -p ~/.aria2
chmod -R a+x ~/.aria2

