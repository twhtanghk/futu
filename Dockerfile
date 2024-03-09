FROM node:19

ENV APP=/usr/src/app \
    SRC=Futu_OpenD_8.1.4108_Ubuntu16.04.tar.gz
ADD . $APP

WORKDIR $APP

RUN (tar -C /opt -xf $APP/$SRC) \
&&  apt-get update \
&&  apt-get install -y telnet git-core vim \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* $APP/$SRC

CMD /opt/Futu_OpenD_8.1.4108_Ubuntu16.04/Futu_OpenD_8.1.4108_Ubuntu16.04/FutuOpenD
