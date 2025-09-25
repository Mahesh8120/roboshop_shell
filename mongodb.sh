#!/bin/bash

userid=$(id -u)
date=$(date +%s)

r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"

if [ $userid -ne 0]; then
  echo "$r run the script with root access $n"
  exit 1
else
  echo "$g you ar root user $n"
fi

validate() {
  if [ $1 -ne 0  ]; then
     echo "$2 ....$r failed $n"
     exit 1
  else  
     echo "$2 .... $g success $n"
  fi
}

echo script started executing at $date

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "copying mongo repo file"

dnf install mongodb-org -y
validate $? "installing mongodb" 

systemctl enable mongod 
validate $? "enabling mongodb"

systemctl start mongod 
validate $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "allowing remote connections"

systemctl restart mongod
validate $? "restarting mongodb"

