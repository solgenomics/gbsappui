#!/bin/bash
chown 106 /etc/munge/munge.key
cp /gbsappui/slurm.conf  /etc/slurm/
sed -i s/localhost/$HOSTNAME/g /etc/slurm/slurm.conf
cp /gbsappui/config.sh  /GBSapp/examples/proj/
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
/etc/init.d/postfix start
touch /var/log/gbsappui/error.log
#chmod 777 /var/log/gbsappui/error.log
sleep 5
/gbsappui/script/gbsappui_server.pl -r -p 8090 2> /var/log/gbsappui/error.log
tail -f /var/log/gbsappui/error.log
