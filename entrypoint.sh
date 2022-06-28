#!/bin/bash
devel/run_docker.sh
mv ./gbsappui/slurm.conf  /etc/slurm/
/etc/init.d/gbsappui start
touch /var/log/gbsappui/error.log
chmod 777 /var/log/gbpsappui/error.log
/gbsappui/script/gbsappui_server.pl --fork -r -p 8080 2> /var/log/gbsappui/error.log
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
tail -f /var/log/gbsappui/error.log
