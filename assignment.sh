#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
#echo "user ID is: $USERID"
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then    
        echo -e "$R Please run this script with root privileges $N" | tee -a $LOG_FILE
        exit 1
    fi 
}
VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is $R failed $N" | tee -a $LOG_FILE
        exit 1 
    else 
        echo -e "$2 is $G success $N" | tee -a $LOG_FILE
    fi
}

echo "script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

LOG_FILE=/var/log/mysql_installation.log

# Function to validate the exit status of commands
VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2... $R FAILED $N" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "$2... $G SUCCESS $N" | tee -a $LOG_FILE
  fi
}


echo "Checking if MySQL is installed or not..." | tee -a $LOG_FILE
mysql --version &>>$LOG_FILE
if [ $? -ne 0 ]; 
then
  echo "MySQL is not installed. Installing now..." | tee -a $LOG_FILE
  dnf install mysql-server -y &>>$LOG_FILE
  VALIDATE $? "MySQL Server installation"
else
  echo -e "MySQL is already installed.... $Y SKIPPING $N" | tee -a $LOG_FILE
fi


echo "Checking if MySQL server is enabled or not..." | tee -a $LOG_FILE
systemctl is-enabled mysqld &>>$LOG_FILE
if [ $? -ne 0 ]; then
  echo "MySQL service is not enabled. Enabling now..." | tee -a $LOG_FILE
  systemctl enable mysqld &>>$LOG_FILE
  VALIDATE $? "Enable MySQL Server"
else
  echo -e "MySQL service is already enabled.... $Y SKIPPING $N" | tee -a $LOG_FILE
fi


echo "Checking if MySQL server is started or not..." | tee -a $LOG_FILE
systemctl is-active mysqld &>>$LOG_FILE
if [ $? -ne 0 ]; then
  echo "MySQL service is not yet started. Starting now..." | tee -a $LOG_FILE
  systemctl start mysqld &>>$LOG_FILE
  VALIDATE $? "Start MySQL Server"
else
  echo -e "MySQL service is already started.... $Y SKIPPING $N" | tee -a $LOG_FILE
fi
