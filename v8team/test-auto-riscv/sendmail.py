#!/usr/bin/python
# -*- coding: UTF-8 -*-
 
import smtplib
from email.mime.text import MIMEText
from email.header import Header
import sys
# 第三方 SMTP 服务
mail_host="xxx"  #设置服务器
mail_user="xxx"    #用户名
mail_pass="xxxx"   #口令 
 
 
sender = mail_user
receivers = ["xxxx"]  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱
 
msg = ""
for i in sys.argv[1:]:
    senmsg = open(i)
    msg += senmsg.read()
    msg += "\n"

message = MIMEText(msg, 'plain', 'utf-8')
message['From'] = Header("riscv-hifive-test", 'utf-8')
subject = 'riscv-hifive-test'
message['Subject'] = Header(subject, 'utf-8')
 

smtpObj = smtplib.SMTP()
smtpObj.connect(mail_host, 587)    # 25 为 SMTP 端口号
smtpObj.ehlo()
smtpObj.starttls() 
smtpObj.login(mail_user,mail_pass)  
smtpObj.sendmail(sender, receivers, message.as_string())
smtpObj.quit()
