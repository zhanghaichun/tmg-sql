#!/bin/bash

# 脚本中共做了 5 件事情
# 1. 访问接口， 查询 411.ca 中当天的任务列表是否抓取完毕，抓取任务列表的函数是
#   loading_411_ca_query_reference_info。
# 2. 杀掉所有客户端进程
# 3. 将数据库中 estate_master_411_ca_data 表中 "finishFlag" = 'N' 的数据的 "occFlag"
#   设置为 "N"
# 4. 开启所有客户端
# 5. 心跳监测， 监测所有客户端是否都已经抓取完毕，如果是， 访问接口， 更新工作流程，
#   目的是告知程序 "抓取任务已经完毕" 

JAVA_HOME=/usr/local/jdk1.8.0_151
SERVICE_URL=http://138.197.138.231:8080/data.do

listingDate=`date -d '-3 day' +%Y-%m-%d`

# @step 1
# The value is 0 or 1.
taskListFinishedCountFlag=`curl "${SERVICE_URL}?method=selectEstate411ContactStepWorkflow&stepId=1&versionDate=${listingDate}"`

if [ "${taskListFinishedCountFlag}" != "0" ]; then

  # 如果有待抓取的 task item， 才能执行一下逻辑

  # @step 2
  # 监测 client 抓取进程是否存在
  ps -ef | grep 411CaClient | grep -v grep | awk '{print $2}' | xargs kill -9

  # @step 3
  # 将 estate_master_411_ca_data 数据库中未完成状态的记录改成
  # "occFlag" = 'N'
  curl "${SERVICE_URL}?method=update411CaTaskListOccFlag"

  # @step 4
  # 启动客户端进程
  nohup ${JAVA_HOME}/bin/java -jar 411CaClient1.jar &
  nohup ${JAVA_HOME}/bin/java -jar 411CaClient2.jar &
  nohup ${JAVA_HOME}/bin/java -jar 411CaClient3.jar & 
  nohup ${JAVA_HOME}/bin/java -jar 411CaClient4.jar & 
  nohup ${JAVA_HOME}/bin/java -jar 411CaClient5.jar & 

  # @step 5
  # 心跳监测， 监测客户端进程是否存在
  while true
  do 
    client=`ps -ef|grep 411CaClient1 | grep -v grep | wc -l`

    if [[ "${client}" = "0" ]]; then
      
      # 如果进程都已经抓取完毕， 访问这个链接更新步骤
      curl "${SERVICE_URL}?method=updateEstate411ContactStepWorkflow&stepId=2&versionDate=${listingDate}"

      exit
    fi
    
    sleep 120
    
  done;

fi

