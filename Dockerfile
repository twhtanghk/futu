FROM node

ENV APP=/usr/src/app \
    SRC=https://softwarefile.futunn.com/FutuOpenD_7.0.3218_NN_Ubuntu16.04.tar.gz
ADD . $APP

WORKDIR $APP

RUN  apt-get update \
&&  (cd /tmp && wget -q $SRC && tar -C /opt -xf $(basename $SRC)) \
&&  apt-get install -y telnet git-core vim \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* /tmp/$(basename $SRC) \
&&  (cd frontend && yarn install && yarn build) \
&&  (cd backend && yarn install)

CMD /opt/FutuOpenD_7.0.3218_NN_Ubuntu16.04/FutuOpenD_7.0.3218_NN_Ubuntu16.04/FutuOpenD
