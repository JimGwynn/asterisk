docker stop freepbx
docker rm freepbx
docker run -d --name=freepbx --net=host --volumes-from data  -p 8003:8003 -p3303:3303 -p 50601:50601 freepbx
