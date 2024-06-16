#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter DB password:"
#read -s mysql_root_password
read mysql_root_password

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs"

# useradd expense
# VALIDATE $? "Creating expense user"

# # Output:

#     Please enter DB password:
#     You are super user.
#     Disabling default nodejs... SUCCESS 
#     Enabling nodejs:20 version... SUCCESS 
#     Installing nodejs... SUCCESS 
#     Creating expense user... SUCCESS 

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ sudo sh backed.sh
#     Please enter DB password:
#     You are super user.
#     Disabling default nodejs... SUCCESS 
#     Enabling nodejs:20 version... SUCCESS 
#     Installing nodejs... SUCCESS 
#     useradd: user 'expense' already exists (if we run the script again we are getting this)
#     Creating expense user... FAILURE 

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ id ec2-user
#     uid=1001(ec2-user) gid=1001(ec2-user) groups=1001(ec2-user)

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ echo $?
#     0

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ id expense
#     uid=1002(expense) gid=1002(expense) groups=1002(expense)

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ echo $?
#     0

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ id mohan
#     id: ‘mohan’: no such user

#     [ ec2-user@ip-172-31-16-86 ~/expense-project-with-shell-scripting ]$ echo $?
#     1

# The above can we be written in the based on the number

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "Creating expense user"
else
    echo -e "Expense user already created...$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading backend code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracted backend code"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

# #check your repo and path
cp /home/ec2-user/expense-project-with-shell-scripting/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "Copied backend service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend"

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Client"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling MySQL Client"

dnf systemctl start mysqld -y &>>$LOGFILE
VALIDATE $? "Starting MySQL Client"

mysql -h db.mohansaivenna.cloud -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"

# systemctl restart backend &>>$LOGFILE
# VALIDATE $? "Restarting Backend"