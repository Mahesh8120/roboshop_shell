#!/bin/bash
userid=$(id -u)
r="\e[31m"  
g="\e[32m"
y="\e[33m"
n="\e[0m"

logs_folder="/var/log/roboshop_shell"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"
rabbitmq_host="rabbitmq.sitaram.icu"    
script_dir=$PWD
START_TIME=$(date +%s)

mkdir -p $logs_folder
echo "Script started executed at: $(date)" | tee -a $log_file

if [ $userid -ne 0 ]; then
  echo -e "$r run the script with root access $n" 
  exit 1
else
  echo -e "$g you ar root user $n"
fi

validate() {
  if [ $1 -ne 0  ]; then
     echo -e "$2 ....$r failed $n" | tee -a $log_file
     exit 1
  else  
     echo -e "$2 .... $g success $n" | tee -a $log_file
  fi
}

dnf install golang -y &>>$log_file
validate $? "installing golang"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating system user"
else
    echo -e "User already exist ... $y SKIPPING $n"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$log_file
validate $? "Downloading dispatch application"

cd /app 
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/dispatch.zip &>>$log_file
validate $? "unzip dispatch"

cd /app 
go mod init dispatch &>>$log_file

go get &>>$log_file
go build &>>$log_file

cp $script_dir/dispatch.service /etc/systemd/system/dispatch.service

systemctl daemon-reload &>>$log_file

systemctl enable dispatch
validate $? "Enabling dispatch service"

systemctl start dispatch &>>$log_file
validate $? "Starting dispatch service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"