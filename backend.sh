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

mkdir -p /app
VALIDATE $? "creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading backend application"

cd /app
rm -rf /app/* # remove the existing code 
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "unzipping/extracting backend application"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# load the data before running backend 

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Install mysql"

mysql -h mysql.daws81s.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "loading schema"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload daemon"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enable backend service"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restart backend service"
