#!/usr/bin/env bash
ME="$(dirname $0)"
set RANDFILE=.rnd
export BDD_PWD="$(openssl rand -base64 32)"
export PATH=~/.composer/vendor/bin/:$PATH
set -x
set -e

if [[ "$TRAVIS_OS_NAME" = "osx" ]]; then
    mysql -u root -ptoor -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$BDD_PWD'); FLUSH PRIVILEGES;"
else
    sudo /etc/init.d/mysql stop
    sudo mysqld_safe --skip-grant-tables --user=root &
    sleep 4
    mysql -u root -e "update mysql.user set authentication_string=PASSWORD('$BDD_PWD') where User='root' and host='%'; update mysql.user set plugin='mysql_native_password'; delete from mysql.user where User != 'root' OR host != '%'; FLUSH PRIVILEGES;"
    sudo kill -9 $(sudo cat /var/lib/mysql/mysqld_safe.pid)
    sudo kill -9 $(sudo cat /var/run/mysqld/mysqld.pid)
    sudo /etc/init.d/mysql start
    sleep 4
fi;

mysql -uroot -p"$BDD_PWD" -e "CREATE DATABASE IF NOT EXISTS accountmanager CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -uroot -p"$BDD_PWD" accountmanager < $ME/../../sql/structure.sql
mysql -uroot -p"$BDD_PWD" accountmanager < $ME/../../sql/routines.sql
mysql -uroot -p"$BDD_PWD" accountmanager < $ME/../../sql/views.sql
mysql -uroot -p"$BDD_PWD" accountmanager < $ME/../../sql/events.sql
mysql -uroot -p"$BDD_PWD" accountmanager < $ME/../../sql/triggers.sql
mysql -uroot -p"$BDD_PWD" -e "SELECT User,host FROM mysql.user;"

echo -e "DB_HOST=localhost\r\nDB_USER=root\r\nDB_NAME=accountmanager\r\nDB_PASS=\"$BDD_PWD\"\r\n" > $ME/../../.env
cp $ME/../../.env $ME/../../tests/.env
echo "Database password: $BDD_PWD"
cat $ME/../../tests/.env
# TEMP fix
wget https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/master/libraries/classes/Twig/I18nExtension.php -O $ME/../../src/Twig/I18nExtension.php
mkdir -p $ME/../../src/Twig/I18n
wget https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/master/libraries/classes/Twig/I18n/NodeTrans.php -O $ME/../../src/Twig/I18n/NodeTrans.php
wget https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/master/libraries/classes/Twig/I18n/TokenParserTrans.php -O $ME/../../src/Twig/I18n/TokenParserTrans.php

PMALICENSEURL="https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/master/LICENSE"

if [[ "$TRAVIS_OS_NAME" = "osx" ]]; then
    find "$ME/../../src/Twig" -type f -name '*.php' -exec sed -i '' -e 's,PhpMyAdmin,AccountManager,g' {} \;
    # Who care about vim :)
    find "$ME/../../src/Twig" -type f -name '*.php' -exec sed -i '' -e "s,vim: set expandtab sw=4 ts=4 sts=4:,LICENSE : $PMALICENSEURL,g" {} \;
else
    find "$ME/../../src/Twig" -type f -name '*.php' -exec sed -i 's,PhpMyAdmin,AccountManager,g' {} +
    # Who care about vim :)
    find "$ME/../../src/Twig" -type f -name '*.php' -exec sed -i "s,vim: set expandtab sw=4 ts=4 sts=4:,LICENSE : $PMALICENSEURL,g" {} +
fi;


