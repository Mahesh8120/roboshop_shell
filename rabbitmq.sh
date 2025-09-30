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
script_dir=$PWD
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
     echo -e "$2 ....$r failed $n" | tee -a $log_file
     exit 1
  else  
     echo -e "$2 .... $g success $n" | tee -a $log_file
  fi
}

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y  &>>$log_file
validate $? "Installing RabbitMQ" 

systemctl enable rabbitmq-server  &>>$log_file
validate $? "Enabling RabbitMQ" 

systemctl start rabbitmq-server
validate $? "Starting RabbitMQ" 

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "Creating application user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"