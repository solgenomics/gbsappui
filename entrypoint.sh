#!/bin/bash
cp /gbsappui/slurm.conf /etc/slurm/
chmod 777 /etc/slurm/slurm.conf
sed -i "s/localhost/$HOSTNAME/g" /etc/slurm/slurm.conf
chown munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
#setup postfix email
#replace placeholders with variables
username=$(sed -n 's/^smtp_login \(.*\)/\1/p' < /gbsappui/gbsappui_local.conf)
#remove trailing blank space
username=$(echo $username | sed -e 's/\ *$//g')
password=$(sed -n 's/^smtp_pass \(.*\)/\1/p' < /gbsappui/gbsappui_local.conf)
#remove trailing blank space
password=$(echo $password | sed -e 's/\ *$//g')
sed -i "s/username/$username/g" /etc/postfix/sasl_passwd
sed -i "s/password/$password/g" /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd

/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
/etc/init.d/postfix start
touch /var/log/gbsappui/error.log
#chmod 777 /var/log/gbsappui/error.log
sleep 5
/gbsappui/script/gbsappui_server.pl -r -p 8090 2> /var/log/gbsappui/error.log
tail -f /var/log/gbsappui/error.log
