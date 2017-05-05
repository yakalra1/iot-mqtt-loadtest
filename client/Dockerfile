From ubuntu:latest
RUN apt-get update && apt-get install -y wget
#install docker
RUN wget -qO- https://get.docker.com/ | sed 's/lxc-docker/lxc-docker-1.6.2/' | sh
#install cf
RUN wget "https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.14.0&source=github-rel" --output-document=cf.tgz && tar -xvf cf.tgz  && mv cf /usr/bin/cf 
RUN cf install-plugin https://static-ice.ng.bluemix.net/ibm-containers-linux_x64 -f
RUN mkdir /test-client /test-client/scripts /test-client/logs /test-client/data
WORKDIR /test-client/scripts
#copy scripts
COPY scripts/*.sh /test-client/scripts/
RUN chmod +x /test-client/scripts/*.sh
#start the docker service
RUN service docker start