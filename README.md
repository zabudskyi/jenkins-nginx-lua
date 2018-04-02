## jenkins-nginx-lua
This repository builds CD pipeline that starts by push event to the git repository master branch. It compiles Nginx server with a lua-nginx-module with custom nginx.conf and index.html files and deploys it on EC2 instance using docker-machine. 
## Pipeline consists of 3 stages
### Stage1. Build and Dockerize
Multi-stage Dockerfile is used.
First stage builds Nginx deb with dynamic lua module. Second stage dockerize Nginx app.

### Stage2. Push image to dockerhub
It pushes Dockerized app to docker hub.

### Stage3. Deploy
It deploys Nginx container on EC2 instance using docker-machine.

Modify `nginx/conf/nginx.conf` and `nginx/html/index.html` for your need.
