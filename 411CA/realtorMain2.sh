#/bin/bash
JAVA_HOME=/usr/lib/java/jdk1.8.0_91
JRE_HOME=/usr/lib/java/jdk1.8.0_91/jre
CLASSPATH=/usr/lib/java/jdk1.8.0_91/lib:/usr/lib/java/jdk1.8.0_91/jre/lib
# 写日志函数
function write_log()
{
  now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'
  echo ${now_time} $1 | tee -a ${log_file}
}


log_file='/realtor/RealtorAutoMain/logs/realtor_main_'$(date +"%Y-%m-%d")'.log'
today=$(date +"%Y-%m-%d")
write_log '####################################################'
write_log 'Run started' 'The log is writed to '${log_file}
write_log '####################################################'
INTEVAL_TIME=30s

# 0.如果当日出现错误，删除当日未完成数据
# 终止抓取进程
ps -ef | grep getRealtorData | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep condoClient | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep commercialClient | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep residentialClient | grep -v grep | awk '{print $2}' | xargs kill -9

# 删除数据库记录
DeleteRealtorCaListJSONCmd=`psql -h localhost -d saninco_realtor_db -c "delete from realtor_list"`
DeleteRealtorCaListJSONCmdResult=`echo $DeleteRealtorCaListJSONCmd | awk -F' ' '{print $3}'`

DeleteRealtorItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from realtor_item where \"versionDate\"='$(date +"%Y-%m-%d")'"`
DeleteRealtorItemDataCmdResult=`echo $DeleteRealtorItemDataCmd | awk -F' ' '{print $3}'`

DeleteTrebItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from treb_data where \"versionDate\"='$(date +"%Y-%m-%d")'"`
DeleteTrebItemDataCmdCmdResult=`echo $DeleteRealtorItemDataCmd | awk -F' ' '{print $3}'`

DeleteSanincoRealtorItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from saninco_realtor_item where \"versionDate\"='$(date +"%Y-%m-%d")'"`
DeleteSanincoRealtorItemDataCmdResult=`echo $DeleteSanincoRealtorItemDataCmd | awk -F' ' '{print $3}'`
# 删除日志记录
rm /realtor/RealtorClient/RealtorClient1/logs/log_$(date +"%Y_%m_%d").txt
rm /realtor/RealtorClient/RealtorClient2/logs/log_$(date +"%Y_%m_%d").txt
rm /realtor/RealtorClient/RealtorClient3/logs/log_$(date +"%Y_%m_%d").txt



#1.更新Realtor.ca价格范围未抓取状态
write_log '开始更新价格范围未抓取状态'
UpdateRealtorPriceRangeCmd=`psql -h localhost -d saninco_realtor_db -c "update realtor_price_range set \"finishFlag\"='N',\"occupyFlag\"='N'"`
UpdateRealtorPriceRangeCmdResult=`echo $UpdateRealtorPriceRangeCmd | awk -F' ' '{print $3}'`

#2.验证更新状态是否成功
SelectRealtorPriceRangeCmd=`psql -h localhost -d saninco_realtor_db -c "select count(1) from realtor_price_range where \"finishFlag\"='Y' or \"occupyFlag\"='Y'"`
SelectRealtorPriceRangeResult=`echo $SelectRealtorPriceRangeCmd | awk -F' ' '{print $3}'`
if [ "${SelectRealtorPriceRangeResult}" = "0" ]; then
   write_log '更新realtor价格范围未抓取状态成功'
else 
   write_log '更新realtor价格范围未抓取状态失败'
   (echo 'Update realtor price error';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
   exit
fi 
write_log '####################################################'

#3.运行Realtor.ca抓取程序
write_log '开始运行Realtor.ca抓取程序'
cd "/realtor/RealtorClient/RealtorClient1"
nohup ${JAVA_HOME}/bin/java -jar getRealtorData1.jar &
cd "/realtor/RealtorClient/RealtorClient2"
nohup ${JAVA_HOME}/bin/java -jar getRealtorData2.jar &
cd "/realtor/RealtorClient/RealtorClient3"
nohup ${JAVA_HOME}/bin/java -jar getRealtorData3.jar &
GetgetRealtorDataProcessCount=`ps -ef | grep getRealtorData | grep -v grep | wc -l`
if [ "${GetgetRealtorDataProcessCount}" = "3" ]; then
   write_log '启动Realtor抓取程序成功'
else 
   write_log '启动Realtor抓取程序失败'
   (echo 'Start Realtor Catch Error';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
   exit
fi 
write_log '####################################################'

#4.运行TREB抓取程序
write_log '开始运行TREB抓取程序'
cd "/realtor/TREBClient/condoClient"
${JAVA_HOME}/bin/java -jar condoClient.jar
write_log 'TREB Condo抓取完成'
cd "/realtor/TREBClient/commercialClient"
${JAVA_HOME}/bin/java -jar commercialClient.jar
write_log 'TREB Commercial抓取完成'
cd "/realtor/TREBClient/residentialClient"
${JAVA_HOME}/bin/java -jar residentialClient.jar
write_log 'TREB Residential抓取完成'
write_log '开始验证TREB抓取数量'
SelectTREBCountCmd=`psql -h localhost -d saninco_realtor_db -c "select count(1) from treb_data where \"versionDate\"='$(date +"%Y-%m-%d")'"`
SelectTREBCountResult=`echo $SelectTREBCountCmd | awk -F' ' '{print $3}'`
if [ "${SelectTREBCountResult}" -gt 4000 ]; then
   write_log 'TREB抓取数量['"${SelectTREBCountResult}"']范围正常'
else 
   write_log 'TREB抓取数量['"${SelectTREBCountResult}"']数量过少'
   (echo 'TREB catch number ['"${SelectTREBCountResult}"'] too low';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
   exit
fi 
write_log '####################################################'

#5.等待Realtor.ca数据抓取完成
write_log '等待Realtor.ca数据抓取完成'
while true
do 
        getRealtorDataProcessCount=`ps -ef|grep getRealtorData | grep -v grep | wc -l`
        if [ "${getRealtorDataProcessCount}" = "0" ]
        then
		
		#6.Realtor.ca数据抓取完成验证完整性
		write_log 'Realtor.ca抓取进程执行完毕，验证日志大小'
		RealtorClient1LogPath="/realtor/RealtorClient/RealtorClient1/logs/log_$(date +"%Y_%m_%d").txt"
		RealtorClient1LogSize=`du -sb $RealtorClient1LogPath | awk '{print $1}'`
		if [ "${RealtorClient1LogSize}" -gt 204800 ]; then
		   write_log 'RealtorClient1日志文件['"`expr $RealtorClient1LogSize / 1024`"'kb]文件过大'
		   (echo 'RealtorClient1 log file ['"`expr $RealtorClient1LogSize / 1024`"'kb] size too large';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
		   exit
		else 
		   write_log 'RealtorClient1日志文件['"`expr $RealtorClient1LogSize / 1024`"'kb]文件大小正常'
		fi 
		RealtorClient2LogPath="/realtor/RealtorClient/RealtorClient2/logs/log_$(date +"%Y_%m_%d").txt"
		RealtorClient2LogSize=`du -sb $RealtorClient2LogPath | awk '{print $1}'`
		if [ "${RealtorClient2LogSize}" -gt 204800 ]; then
		   write_log 'RealtorClient2日志文件['"`expr $RealtorClient2LogSize / 1024`"'kb]文件过大'
		   (echo 'RealtorClient2 log file ['"`expr $RealtorClient2LogSize / 1024`"'kb] size too large';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
		   exit
		else 
		   write_log 'RealtorClient2日志文件['"`expr $RealtorClient2LogSize / 1024`"'kb]文件大小正常'
		fi 
		RealtorClient3LogPath="/realtor/RealtorClient/RealtorClient3/logs/log_$(date +"%Y_%m_%d").txt"
		RealtorClient3LogSize=`du -sb $RealtorClient3LogPath | awk '{print $1}'`
		if [ "${RealtorClient3LogSize}" -gt 204800 ]; then
		   write_log 'RealtorClient3日志文件['"`expr $RealtorClient3LogSize / 1024`"'kb]文件过大'
		   (echo 'RealtorClient3 log file ['"`expr $RealtorClient3LogSize / 1024`"'kb] size too large';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
		   exit
		else 
		   write_log 'RealtorClient3日志文件['"`expr $RealtorClient3LogSize / 1024`"'kb]文件大小正常'
		fi 
		break;
        fi

    sleep ${INTEVAL_TIME}
done
write_log '####################################################'

#7.开始执行loader程序
write_log '开始执行Realtor.ca Loader程序'
write_log '开始分解列表JSON数据Load到RealtorItem'
LoadRealtorCaListJSONCmd=`psql -h localhost -d saninco_realtor_db -c "select realtor_item_loader('${today}')"`
LoadRealtorCaListJSONCmdResult=`echo $LoadRealtorCaListJSONCmd | awk -F' ' '{print $3}'`
write_log '验证分解列表JSON数据数量'
SelectLoadRealtorCaListJSONCountCmd=`psql -h localhost -d saninco_realtor_db -c "select count(1) from realtor_item where \"versionDate\"='${today}'"`
SelectLoadRealtorCaListJSONCountCmdResult=`echo $SelectLoadRealtorCaListJSONCountCmd | awk -F' ' '{print $3}'`
if [ "${SelectLoadRealtorCaListJSONCountCmdResult}" -gt 170000 ]; then
   write_log 'Realtor.ca分解列表JSON数据数量['"${SelectLoadRealtorCaListJSONCountCmdResult}"']范围正常'
else 
   write_log 'Realtor.ca分解列表JSON数据数量['"${SelectLoadRealtorCaListJSONCountCmdResult}"']数量过少'
   (echo 'Realtor.ca split list JSON number ['"${SelectLoadRealtorCaListJSONCountCmdResult}"'] too less';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'Error Log'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com
   exit
fi 
write_log '删除Realtor.ca的JSON列表数据'
DeleteRealtorCaListJSONCmd=`psql -h localhost -d saninco_realtor_db -c "delete from realtor_list"`
DeleteRealtorCaListJSONCmdResult=`echo $DeleteRealtorCaListJSONCmd | awk -F' ' '{print $3}'`
write_log '开始分解单条JSON数据Load到SanincoRealtorItem'
LoadRealtorCaItemJSONCmd=`psql -h localhost -d saninco_realtor_db -c "select saninco_realtor_item_loader('${today}')"`
LoadRealtorCaItemJSONCmdResult=`echo $LoadRealtorCaItemJSONCmd | awk -F' ' '{print $3}'`
write_log '开始执行TREB Loader程序'
write_log '开始将TREB数据Load到TrebItem'
LoadTREBItemJSONCmd=`psql -h localhost -d saninco_realtor_db -c "select treb_item_loader('${today}')"`
LoadTREBItemJSONCmdResult=`echo $LoadTREBItemJSONCmd | awk -F' ' '{print $3}'`
write_log '####################################################'

#8.开始执行loader到主列表
write_log '开始执行load到主列表'
write_log '开始load Realtor.ca到主列表'
LoadRealtorCaToMainCmd=`psql -h localhost -d saninco_realtor_db -c "select insert_realtor_data_from_realtor_loader('${today}')"`
LoadRealtorCaToMainCmdResult=`echo $LoadRealtorCaToMainCmd | awk -F' ' '{print $3}'`
write_log '开始load TREB到主列表'
LoadTREBToMainCmd=`psql -h localhost -d saninco_realtor_db -c "select insert_realtor_data_from_treb_loader('${today}')"`
LoadTREBToMainCmdResult=`echo $LoadTREBToMainCmd | awk -F' ' '{print $3}'`
write_log '####################################################'

#9.开始进行更新数据操作
write_log '开始进行更新数据操作'
write_log '开始更新Realtor History'
UpdateRealtorHistoryCmd=`psql -h localhost -d saninco_realtor_db -c "select sp_realtor_history('${today}')"`
UpdateRealtorHistoryCmdResult=`echo $UpdateRealtorHistoryCmd | awk -F' ' '{print $3}'`
write_log '开始更新Delisling Data'
UpdateDelislingDataCmd=`psql -h localhost -d saninco_realtor_db -c "select update_realtor_data_delisling_loader('${today}')"`
UpdateDelislingDataCmdResult=`echo $UpdateDelislingDataCmd | awk -F' ' '{print $3}'`
write_log '开始更新Toronto Expected Data'
UpdateTorontoExpectedDataCmd=`psql -h localhost -d saninco_realtor_db -c "select update_realtor_data_expected_toronto_data_loader()"`
UpdateTorontoExpectedDataCmdResult=`echo $UpdateTorontoExpectedDataCmd | awk -F' ' '{print $3}'`
write_log '开始更新All Expected Data'
UpdateAllExpectedDataCmd=`psql -h localhost -d saninco_realtor_db -c "select update_realtor_data_expected_all_data_loader()"`
UpdateAllExpectedDataCmdResult=`echo $UpdateAllExpectedDataCmd | awk -F' ' '{print $3}'`
write_log '开始更新Expected Deal Date'
UpdateExpectedDealDateCmd=`psql -h localhost -d saninco_realtor_db -c "update realtor_data set \"expectedDealDate\"=\"delislingDate\" where \"delislingDate\" is not null"`
UpdateExpectedDealDateCmdResult=`echo $UpdateExpectedDealDateCmd | awk -F' ' '{print $3}'`
write_log '开始更新Expected Closing Data'
UpdateExpectedClosingDataCmd=`psql -h localhost -d saninco_realtor_db -c "select update_realtor_data_expected_closing_data_loader()"`
UpdateExpectedClosingDataCmdResult=`echo $UpdateExpectedClosingDataCmd | awk -F' ' '{print $3}'`
write_log '####################################################'


#13.开始抓取Canada411
#write_log '开始抓取Canada411'
#cd "/realtor/Canada411Client/client1"
#nohup ${JAVA_HOME}/bin/java -jar Canada411Client1.jar &

#14.等待Canada411数据抓取完成
#write_log '等待Canada411数据抓取完成'
#while true
#do 
#		getCanada411ProcessCount=`ps -ef|grep Canada411Client1 | grep -v grep | wc -l`
#		if [ "${getCanada411ProcessCount}" -eq 0 ]; then
#		   write_log 'Canada411数据抓取完成'
#		   break;
#		fi 
#    sleep ${INTEVAL_TIME}
#done
#write_log '####################################################'

#15.执行expected_closing_date_add_days_loader  （废弃）
#write_log '执行expected_closing_date_add_days_loader'
#ExpectedClosingDateAddDaysCmd=`psql -h localhost -d saninco_realtor_db -c "select #update_realtor_data_expected_closing_date_add_days_loader()"`
#ExpectedClosingDateAddDaysCmdResult=`echo $ExpectedClosingDateAddDaysCmd | awk -F' ' '{print $3}'`
#write_log '####################################################'

#16.执行expected_delisting_date_add_days_loader
write_log '执行expected_delisting_date_add_days_loader'
ExpectedClosingDateAddDaysCmd=`psql -h localhost -d saninco_realtor_db -c "select update_realtor_data_expected_delisting_date_add_days_loader()"`
ExpectedClosingDateAddDaysCmdResult=`echo $ExpectedClosingDateAddDaysCmd | awk -F' ' '{print $3}'`
write_log '####################################################'

#17.更新do not mail数据
#write_log '更新do not mail数据'
#UpdateDoNotMailDataCmd=`psql -h localhost -d saninco_realtor_db -c "UPDATE \"realtor_data\" AS mf SET \"isDoNotMailFlag\"= 'Y' from (select * FROM #\"do_not_mail_data\" ) as tb where btrim(tb.\"addr1\",' ')!='' and upper(mf.\"postalCode\")=upper(replace(tb.\"postal\",' ','')) and case when #mf.\"addressStreetName\"='' then replace(upper(mf.\"address\"),' ','') else #replace(upper(mf.\"addressUnit\"||mf.\"addressStreetNumber\"||mf.\"addressStreetName\"),' ','') end=replace(upper(replace(tb.\"addr1\",',','')),' ','')"`
#UpdateDoNotMailDataCmdResult=`echo $UpdateDoNotMailDataCmd | awk -F' ' '{print $3}'`
#write_log '####################################################'

#18.更新do not call数据
#write_log '更新do not call数据'
#UpdateDoNotCallDataCmd=`psql -h localhost -d saninco_realtor_db -c "update realtor_data set \"isDoNotCallFlag\"='Y' where \"isDoNotCallFlag\"='N' and #\"contactNumber\" is not null and replace(replace(replace(replace(\"contactNumber\",'(',''),')',''),'-',''),' ','') in (select \"areaCode\"||\"number\" from do_not_call_data)"`
#UpdateDoNotCallDataCmdResult=`echo $UpdateDoNotCallDataCmd | awk -F' ' '{print $3}'`
#write_log '####################################################'

#19.更新已过期数据
write_log '更新已过期数据'
UpdateExpiredDataCmd=`psql -h localhost -d saninco_realtor_db -c "update realtor_data set \"recActiveFlag\"='N' where \"delislingDate\" is not null and  \"expectedClosingDate\" is not null and \"recActiveFlag\"='Y' and \"expectedClosingDate\"<(now() - interval '7 month')::DATE"`
UpdateExpiredDataCmdResult=`echo $UpdateExpiredDataCmd | awk -F' ' '{print $3}'`
write_log '####################################################'


#20.更新whitePages的contact info
#write_log '更新whitePages的contact info'
#UpdateWhitepagesContactInfoDataCmd=`psql -h localhost -d saninco_realtor_db -c "update realtor_data as rd set #\"contactFirstName\"=wpd.\"firstName\",\"contactLastName\"=wpd.\"lastName\",\"contactNumber\"=wpd.\"phone\",\"contactInfoFrom\"=1 from (select * from#white_pages_data) as wpd where \"contactFirstName\" is null and \"contactLastName\" is null and \"contactNumber\" is null and rd.\"mlsNumber\"=wpd.\"mlsNumber\" "`
#UpdateWhitepagesContactInfoDataCmdResult=`echo $UpdateWhitepagesContactInfoDataCmd | awk -F' ' '{print $3}'`
#write_log '####################################################'

#21.realtor_search_loader
write_log '执行realtor_search_loader'
RealtorSearchLoadCmd=`psql -h localhost -d saninco_realtor_db -c "select realtor_search_loader()"`
RealtorSearchLoadCmdResult=`echo $RealtorSearchLoadCmd | awk -F' ' '{print $3}'`
write_log '####################################################'

#22.删除旧数据
write_log '删除旧数据'
write_log '开始删除realtor_item'
DeleteRealtorItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from realtor_item where \"versionDate\"<'$(date --date='4 day ago' +"%Y-%m-%d")'"`
DeleteRealtorItemDataCmdResult=`echo $DeleteRealtorItemDataCmd | awk -F' ' '{print $3}'`
write_log '开始删除saninco_realtor_item'
DeleteSanincoRealtorItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from saninco_realtor_item where \"versionDate\"<'$(date --date='4 day ago' +"%Y-%m-%d")'"`
DeleteSanincoRealtorItemDataCmdResult=`echo $DeleteSanincoRealtorItemDataCmd | awk -F' ' '{print $3}'`
write_log '开始删除treb_data'
DeleteTREBDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from treb_data where \"versionDate\"<'$(date --date='4 day ago' +"%Y-%m-%d")'"`
DeleteTREBDataCmdResult=`echo $DeleteTREBDataCmd | awk -F' ' '{print $3}'`
write_log '开始删除treb_item'
DeleteTREBItemDataCmd=`psql -h localhost -d saninco_realtor_db -c "delete from treb_item where \"versionDate\"<'$(date --date='4 day ago' +"%Y-%m-%d")'"`
DeleteTREBItemDataCmdResult=`echo $DeleteTREBItemDataCmd | awk -F' ' '{print $3}'`
write_log '####################################################'
write_log '程序执行完毕'
(echo 'finish log';uuencode /realtor/RealtorAutoMain/logs/realtor_main_$(date +"%Y-%m-%d").log log_$(date +"%Y-%m-%d").txt) | mail -s 'AutoJob Finished'  huibin.guan@xinketechnology.com peiwei.xiang@xinketechnology.com












