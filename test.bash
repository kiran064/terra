#!/bin/bash
yum update -y
yum install httpd -y
cd /var/www/html/
echo "<H1> Test Html file <H1>" > index.html
service httpd start
systemctl restart httpd