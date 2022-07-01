#!/bin/bash
cp /gbsappui/slurm.conf  /etc/slurm/
cp /gbsappui/config.sh  /GBSapp/examples/proj/
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
touch /var/log/gbsappui/error.log
chmod 777 /var/log/gbpsappui/
chmod 777 /var/log/gbpsappui/error.log
/gbsappui/script/gbsappui_server.pl --fork -r -p 8080 2> /var/log/gbsappui/error.log
/etc/init.d/gbsappui start
sleep 5
tail -f /var/log/gbsappui/error.log
