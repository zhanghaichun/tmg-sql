#!/bin/sh

# 1, image load into original table
/root/imgsh/z.sh |mail -s "imgsh.sh--cronjob from `hostname`" ccm.ops@saninco.com >>/var/log/cronlog/imgsh.log 2>&1
sleep 300

# 2, mysql restart
service mysqld restart
sleep 300

# 3, stop Tomcat
tomcat_base=/source/apache-tomcat-5.5.28-uat
echo "stopping tomcat(port 9080) ..."
su - root -c ${tomcat_base}/bin/shutdown.sh

echo "waiting grace time..."
sleep 20

echo "checking if tomcat still alive"
#TOMCAT_PID=`ps -ef | grep java | grep -v grep | awk '{print $2}'`
TOMCAT_PID=`netstat -lanp |grep 9080 |grep LISTEN|awk '{print $7}'|awk -F'/' '{print $1}'`

if [ -n "${TOMCAT_PID}" ]
then
  echo "tomcat still alive ... going to kill it (${TOMCAT_PID})"
  kill -n 9 ${TOMCAT_PID}
  sleep 2
fi

if [ ! -f "${tomcat_base}/logs/catalina.out.`date  +%Y%m%d`" ]; then
/bin/mv ${tomcat_base}/logs/catalina.out  ${tomcat_base}/logs/catalina.out.`date  +%Y%m%d`
fi
# restart tomcat
#echo "starting tomcat(port 9080) again ..."
#${tomcat_base}/bin/startup.sh


tomcat_base=/source/apache-tomcat-5.5.28-uat2
echo "stopping tomcat(port 9180) ..."
su - root -c ${tomcat_base}/bin/shutdown.sh

echo "waiting grace time..."
sleep 20

echo "checking if tomcat still alive"
TOMCAT_PID=`netstat -lanp |grep 9180 |grep LISTEN|awk '{print $7}'|awk -F'/' '{print $1}'`

if [ -n "${TOMCAT_PID}" ]
then
  echo "tomcat still alive ... going to kill it(${TOMCAT_PID})"
  kill -n 9 ${TOMCAT_PID}
  sleep 2
fi
if [ ! -f "${tomcat_base}/logs/catalina.out.`date  +%Y%m%d`" ]; then
/bin/mv ${tomcat_base}/logs/catalina.out  ${tomcat_base}/logs/catalina.out.`date  +%Y%m%d`
fi
# restart tomcat
#echo "starting tomcat(port 9180) again ..."
#${tomcat_base}/bin/startup.sh
sleep 300

# 4, Mysql database dump, log backup and ftp to backup,1.20,.1.7,.4.192
/var/scripts/MyBackup.sh |mail -s "MyBackup--cronjob from `hostname`" ccm.ops@saninco.com >>/var/log/cronlog/mybackup.log 2>&1
sleep 300

# 5, restart tomcat
tomcat_base=/source/apache-tomcat-5.5.28-uat
echo "start tomcat(port 9080) ..."
su - root -c ${tomcat_base}/bin/startup.sh

tomcat_base=/source/apache-tomcat-5.5.28-uat2
echo "start tomcat(port 9180) ..."
su - root -c ${tomcat_base}/bin/startup.sh
sleep 300

# 5.1 lftp to .1.7 and .1.20
DATE=`date +%Y%m%d`

GZDumpFile=$DATE.ccm_db.sql.tgz

HOST=192.168.1.7
USER=root
PASS=111111

echo "Starting to ccm_db Sftp."
cd /var/backup/mysql
lftp -u ${USER},${PASS} sftp://${HOST} <<EOF
cd /var/recover_db
put $GZDumpFile
cd /var/rsync_db
put /var/backup/history_db.gz
bye
EOF


HOST=192.168.1.20
USER=root
PASS=111111

#echo "Starting to sftp."
cd /var/backup/mysql
lftp -u ${USER},${PASS} sftp://${HOST} <<EOF
cd /var/recover_db
put $GZDumpFile
cd /var/rsync_db
put /var/backup/history_db.gz
bye
EOF

echo "backup sftp done"


# 6, Report schedule
/source/report_script/scripts/report_scheduler.sh |mail -s "report scheduler--cronjob from `hostname`" ccm.ops@saninco.com  >>/var/log/cronlog/report_scheduler.log 2>&1

# 7, delete report attachement, daily dwdb 
/var/scripts/daily_maintenance.sh |mail -s "daily maintenance--cronjob from `hostname`" ccm.ops@saninco.com >>/var/log/cronlog/dailyMaintenance.log 2>&1

# 8, image sync to 1.20
/var/scripts/rsyncPicture.sh |mail -s "Rsync Picture to 20--cronjob from `hostname`" ccm.ops@saninco.com >>/var/log/cronlog/rsyncPicture.log 2>&1

# 9, Auto data loader
/var/scripts/loader/invoices_load.sh
sleep 300

# 10, mysql restart
service mysqld restart
