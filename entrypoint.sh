#!/bin/bash
cp /gbsappui/slurm.conf  /etc/slurm/
cp /gbsappui/config.sh  /GBSapp/examples/proj/
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
touch /var/log/gbsappui/error.log
sleep 5
/gbsappui/script/gbsappui_server.pl -r -p 8080 2> /var/log/gbsappui/error.log
tail -f /var/log/gbsappui/error.log
