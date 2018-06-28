docker stop freepbx
docker rm freepbx
docker run -d --name=freepbx --net=host --volumes-from data  -v /etc/asterisk:/etc/asterisk freepbx
