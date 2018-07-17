#!/bin/bash

cp /etc/asterisk/aws/credentials /root/.aws
/usr/sbin/asterisk -c
