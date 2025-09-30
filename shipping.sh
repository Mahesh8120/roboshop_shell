#!/bin/bash
userid=$(id -u)
r="\e[31m"  
g="\e[32m"
y="\e[33m"
n="\e[0m"

logs_folder="/var/log/roboshop_shell"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"
cart_host="cart.sitaram.icu"
mysql_host="mysql.sitaram.icu"
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

dnf install maven -y &>>$log_file

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating system user"
else
    echo -e "User already exist ... $y SKIPPING $n"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "Downloading shipping application"

cd /app 
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/shipping.zip &>>$log_file
validate $? "unzip shipping"

mvn clean package  &>>$log_file
mv target/shipping-1.0.jar shipping.jar 

cp $script_dir/shipping.service /etc/systemd/system/shipping.service
systemctl daemon-reload
systemctl enable shipping  &>>$log_file

dnf install mysql -y  &>>$log_file

mysql -h $mysql_host -uroot -pRoboShop@1 -e 'use cities' &>>$log_file
if [ $? -ne 0 ]; then
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$log_file
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
else
    echo -e "Shipping data is already loaded ... $y SKIPPING $n"
fi

systemctl restart shipping
validate $? "Restarting shipping service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"