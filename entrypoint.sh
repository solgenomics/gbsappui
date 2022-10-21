#!/bin/bash
cp /gbsappui/slurm.conf  /etc/slurm/
sed -i s/localhost/$HOSTNAME/g /etc/slurm/slurm.conf
cp /gbsappui/config.sh  /GBSapp/examples/proj/
chown 106 /etc/munge/munge.key
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
touch /var/log/gbsappui/error.log
sleep 5
/gbsappui/script/gbsappui_server.pl -r -p 8080 2> /var/log/gbsappui/error.log
tail -f /var/log/gbsappui/error.log
