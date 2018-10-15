FROM centos:latest

MAINTAINER Roni Väyrynen <roni@vayrynen.info>

RUN yum -y install epel-release
RUN yum install -y make gcc gcc-c++ bzip2 pkgconfig \
        librsync-devel libzip-devel openssl-devel uthash-devel \
        libacl-devel ncurses-devel openssl-perl python-devel \
        autoconf automake libtool python-pip libffi libffi-devel \
        git postfix mysql-devel monit

RUN mkdir /etc/burp-source
RUN git clone https://github.com/grke/burp /etc/burp-source

RUN cd /etc/burp-source && autoreconf -vif
RUN cd /etc/burp-source && ./configure --prefix=/usr --sysconfdir=/etc/burp --localstatedir=/var
RUN cd /etc/burp-source && make
RUN cd /etc/burp-source && make install
RUN cd /etc/burp-source && make install-configs

RUN pip install --upgrade burp-ui
RUN pip install "burp-ui[sql]"
RUN pip install mysqlclient
RUN pip install "burp-ui[gunicorn]"
RUN pip install "burp-ui[gunicorn-extra]"
RUN pip install "burp-ui[celery]"

RUN ln -sfn /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

RUN ln -s /proc/1/fd/1 /var/log/burp.log
RUN ln -s /proc/1/fd/1 /var/log/burp-ui.log
ADD monit-services /etc/monit.d/services
ADD burp.sh /root/burp.sh
RUN chmod +x /root/burp.sh

EXPOSE 4971
EXPOSE 4972
EXPOSE 5000

ADD entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]