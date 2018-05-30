# monitor_defaultgw
Runbook:
- Copy monitor script to local sbin directory
# cp script/monitor_defaultgw.sh /usr/local/sbin/
# chmod 750 /usr/local/sbin/monitor_defaultgw.sh

- Copy conf file to local etc directory && adjust variable to suit your env
# cp conf/monitor_defaultgw.conf /usr/local/etc/
# modify /usr/local/etc/monitor_defaultgw.conf with your own ENV

- Create systemd template to daemonize the script
# cp systemd/monitor-defaultgw.service /usr/lib/systemd/system/
# systemctl daemon-reload
# systemctl start monitor-defaultgw.service
# systemctl enable monitor-defaultgw.service
