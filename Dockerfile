FROM node:19

ENV APP=/usr/src/app \
    SRC=Futu_OpenD_8.8.4818_Ubuntu16.04.tar.gz
ADD . $APP

WORKDIR $APP

RUN (tar -C /opt -xf $APP/$SRC) \
&&  apt-get update \
&&  apt-get install -y telnet git-core vim \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* $APP/$SRC \
&&  (cd frontend; yarn install; yarn build) \
&&  (cd backend; npm i) \
&&  (cd backend/node_modules/binance/node_modules/binance/; npm i axios@0.27.2)

CMD /opt/Futu_OpenD_8.8.4818_Ubuntu16.04/Futu_OpenD_8.8.4818_Ubuntu16.04/FutuOpenD
