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
validate $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "enabling nginx"

dnf install nginx -y &>>$log_file
validate $? "installing nginx"

systemctl enable nginx &>>$log_file
systemctl start nginx
validate $? "starting nginx"

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "Downloading frontend component"

cd /usr/share/nginx/html &>>$log_file
validate $? "Changing to nginx html directory"

unzip /tmp/frontend.zip &>>$log_file
validate $? "unzipping frontend component"

rm -rf /etc/nginx/nginx.conf &>>$log_file
cp $script_dir/nginx.conf /etc/nginx/nginx.conf
validate $? "Copying nginx configuration file"

systemctl restart nginx &>>$log_file
validate $? "restarting nginx"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $y $TOTAL_TIME Seconds $n"