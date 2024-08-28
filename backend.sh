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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "dnf module disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "dnf module enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo -e "User expense does not exist $G creating $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user"
else 
    echo -e "User expense already exists $Y skipping $N"
fi
