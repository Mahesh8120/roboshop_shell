#!/bin/bash
userid=$(id -u)
r="\e[31m"  
g="\e[32m"
y="\e[33m"
n="\e[0m"

logs_folder="/var/log/roboshop_shell"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"
catalogue_host="catalogue.sitaram.icu"
user_host="user.sitaram.icu"
cart_host="cart.sitaram.icu"
shipping_host="shipping.sitaram.icu"
payment_host="payment.sitaram.icu"
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

dnf module disable nginx -y &>>$log_file
dnf module enable nginx:1.24 -y &>>$log_file
dnf install nginx -y &>>$log_file
validate $? "Installing Nginx"

systemctl enable nginx  &>>$log_file
systemctl start nginx 
validate $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* 
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$log_file
validate $? "Downloading frontend"

rm -rf /etc/nginx/nginx.conf
cp $script_dir/nginx.conf /etc/nginx/nginx.conf
validate $? "Copying nginx.conf"

systemctl restart nginx 
validate $? "Restarting Nginx"