FROM centos:centos6

MAINTAINER Shigure Onishi <shigure.onishi@gmail.com>

RUN rpm --rebuilddb && yum install -y wget tar openssl logrotate redis

RUN \
  cd /tmp && \
  wget http://sensuapp.org/docs/0.16/tools/ssl_certs.tar && \
  tar xvf ssl_certs.tar && \
  cd ssl_certs && \
  ./ssl_certs.sh generate

# erlang Install
RUN \
  rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
  yum install -y erlang

# RabbitMQ Install
RUN \
  rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc && \
  rpm -Uvh http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.1/rabbitmq-server-3.2.1-1.noarch.rpm

# SSL Setting
RUN \
  cd /tmp/ssl_certs && \
  mkdir -p /etc/rabbitmq/ssl && \
  cp -a sensu_ca/cacert.pem /etc/rabbitmq/ssl/ && \
  cp -a server/cert.pem /etc/rabbitmq/ssl/ && \
  cp -a server/key.pem /etc/rabbitmq/ssl/

RUN \
  rabbitmq-plugins enable rabbitmq_management

RUN \
  cd /tmp && \
  wget http://peak.telecommunity.com/dist/ez_setup.py;python ez_setup.py;easy_install distribute; \
  wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py;python get-pip.py; \
  pip install supervisor

# Install Sensu
ADD ./files/sensu.repo /etc/yum.repos.d/
RUN rpm --rebuilddb && yum install -y sensu

RUN \ 
  mkdir -p /etc/sensu/ssl && \
  cd /tmp/ssl_certs/ && \
  cp -a client/cert.pem /etc/sensu/ssl/ && \
  cp -a client/key.pem /etc/sensu/ssl/

# uchiwa
RUN rpm --rebuilddb && yum install -y uchiwa

ADD ./files/uchiwa.json /etc/sensu/
ADD ./files/rabbitmq.config /etc/rabbitmq/
ADD ./files/config.json /etc/sensu/
ADD ./files/supervisord.conf /etc/supervisord.conf

RUn yum install -y redis 

CMD ["/usr/bin/supervisord"]
