FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install mosquitto mosquitto-clients python curl uuid-runtime
RUN mkdir /test /test/scripts /test/data /test/conf /test/logs /test/templates
WORKDIR /test/scripts
COPY scripts/*.sh /test/scripts/
COPY templates/* /test/templates/
RUN chmod +x /test/scripts/*.sh
CMD /test/scripts/startup.sh