FROM mdnetdesign/base

RUN echo "[mariadb]" > /etc/yum.repos.d/mariadb.repo
RUN echo "name = MariaDB" >> /etc/yum.repos.d/mariadb.repo
RUN echo "baseurl = http://yum.mariadb.org/10.2/centos7-amd64" >> /etc/yum.repos.d/mariadb.repo
RUN echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/mariadb.repo
RUN echo "gpgcheck=0" >> /etc/yum.repos.d/mariadb.repo

RUN yum -y install MariaDB-server

RUN mkdir -p /var/www/database
RUN chmod 777 /var/www/database

RUN echo "TRUNCATE TABLE mysql.user;" > /mysql-init
RUN echo "FLUSH PRIVILEGES;" >> /mysql-init
RUN echo "CREATE USER 'root'@'%' IDENTIFIED BY 'PWD';" >> /mysql-init
RUN echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" >> /mysql-init
RUN echo "FLUSH PRIVILEGES;" >> /mysql-init
RUN chmod 444 /mysql-init

RUN echo "#!/bin/sh" > /container-init
RUN echo "rm -f /var/lib/mysql/mysql.sock 2> /dev/null" >> /container-init
RUN echo "mysql_install_db --datadir=/var/www/database" >> /container-init
RUN echo "if grep -q PWD \"/mysql-init\"; then" >> /container-init
RUN echo " echo Initial root user was not set, please wait..." >> /container-init
RUN echo " MYSQLPWD=\$(echo \$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1))" >> /container-init
RUN echo " chmod 777 /mysql-init" >> /container-init
RUN echo " sed -i \"s/PWD/\$MYSQLPWD/\" /mysql-init" >> /container-init
RUN echo " chmod 444 /mysql-init" >> /container-init
RUN echo " echo The mysql root password is: \$MYSQLPWD" >> /container-init
RUN echo "fi" >> /container-init
RUN echo "exec mysqld --user=root --init-file=/mysql-init --datadir=/var/www/database" >> /container-init
RUN chmod +x /container-init

RUN cat /container-init

EXPOSE 3306

VOLUME /var/www/database

CMD ["/container-init"]