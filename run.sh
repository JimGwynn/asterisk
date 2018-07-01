#!/bin/bash 
image="asterisk:latest"
volume="/etc/asterisk"
voltftp="/var/data/tftpboot"

docker stop asterisk
docker rm asterisk

docker ps |grep -q $image || { 
	docker run -d --name asterisk --restart always -e "TZ=America/Phoenix" -v $volume:/etc/asterisk -v $voltftp:/tftpboot --log-driver=none --net=host $image
}
