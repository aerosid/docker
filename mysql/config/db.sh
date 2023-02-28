#!/bin/bash
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h 127.0.0.1 -e 'create database trident;'
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h 127.0.0.1 trident < /tmp/trident.sql
