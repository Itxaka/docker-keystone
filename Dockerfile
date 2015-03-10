FROM ubuntu:14.04
MAINTAINER Itxaka Serrano Garcia <itxakaserrano@gmail.com>
RUN apt-get update && apt-get install ubuntu-cloud-keyring -y && echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list && apt-get update && apt-get install keystone python-keystoneclient -y
COPY keystone.conf /etc/keystone/keystone.conf
RUN keystone-manage db_sync
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 5000
EXPOSE 35357

ENTRYPOINT ["/run.sh"]
