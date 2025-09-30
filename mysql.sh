#!/bin/bash
userid=$(id -u)
r="\e[31m"  
g="\e[32m"
y="\e[33m"
n="\e[0m"

logs_folder="/var/log/roboshop_shell"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"
START_TIME=$(date +%s)
echo "Script started executed at: $(date)" | tee -a $log_file
mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e "$r run the script with root access $n" 
  exit 1
else
  echo -e "$g you ar root user $n"
fi

validate() {
  if [ $1 -ne 0  ]; then
     echo -e "$2 ....$r failed $n" | tee -a $LOG_FILE
     exit 1
  else  
     echo -e "$2 .... $g success $n" | tee -a $LOG_FILE
  fi
}

dnf install mysql-server -y &>>$log_file
validate $? "installing mysql" 

systemctl enable mysqld &>>$log_file
validate $? "enabling mysql" 

systemctl start mysqld

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting up Root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"