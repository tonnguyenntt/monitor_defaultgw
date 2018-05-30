# monitor_defaultgw<br />
## Runbook:<br /><br />
### Copy monitor script to local sbin directory:
  cp script/monitor_defaultgw.sh /usr/local/sbin/<br />
  chmod 750 /usr/local/sbin/monitor_defaultgw.sh<br />
### Copy conf file to local etc directory && adjust variable to suit your env:<br />
  cp conf/monitor_defaultgw.conf /usr/local/etc/<br />
  (*) modify /usr/local/etc/monitor_defaultgw.conf with your own ENV<br />
### Create systemd template to daemonize the script:<br />
  cp systemd/monitor-defaultgw.service /usr/lib/systemd/system/<br />
  systemctl daemon-reload<br />
  systemctl start monitor-defaultgw.service<br />
  systemctl enable monitor-defaultgw.service<br />
