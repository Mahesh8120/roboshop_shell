#!/bin/bash
userid=$(id -u)
r="\e[31m"  
g="\e[32m"
y="\e[33m"
n="\e[0m"

logs_folder="/var/log/roboshop_shell"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"
mongodb_host="mongodb.sitaram.icu"
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

dnf module disable nodejs -y &>>$log_file
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "enabling nodejs"

dnf install nodejs -y &>>$log_file
validate $? "installing nodejs"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating system user"
else
    echo -e "User already exist ... $y SKIPPING $n"
fi


mkdir -p /app &>>$log_file
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$log_file
validate $? "downloading catalogue component"

cd /app 
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$log_file
validate $? "unzipping catalogue component"

npm install &>>$log_file
validate $? "Install dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$log_file
validate $? "Enable catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$log_file
validate $? "Install MongoDB client"

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $mongodb_host </app/db/master-data.js &>>$log_file
    validate $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $y SKIPPING $n"
fi

systemctl restart catalogue &>>$log_file
validate $? "Restarted catalogue"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"