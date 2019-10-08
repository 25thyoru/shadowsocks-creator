#!/usr/bin/python3

##
#Mail Component of Shadowsocks Proxy Create Script
#@Github https://github.com/wangyc/shadowsocks-creator
#END

from email.mime.text import MIMEText
import os 
import smtplib
import sys

#Varibles below are defined in System environment. 
mail_host = os.getenv('SS_MAIL_HOST')
mail_user = os.getenv('SS_MAIL_USER')
mail_pass = os.getenv('SS_MAIL_PASS')
mail_dest = os.getenv('SS_MAIL_DEST')
mail_subject = os.getenv('SS_MAIL_SUBJECT')

content_prefix='''Hello!
Your client configuration is HERE--------
'''
content = sys.stdin.read()
message = MIMEText(content_prefix + content)
message['From'] = mail_user
message['To'] = mail_dest
message['Subject'] = mail_subject

smtp = smtplib.SMTP_SSL(mail_host)
smtp.login(mail_user, mail_pass)
smtp.sendmail(mail_user, mail_dest, message.as_string())
smtp.quit()