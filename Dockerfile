FROM node:19

ENV APP=/usr/src/app
ADD . $APP

WORKDIR $APP

RUN  apt-get update \
&&  apt-get install -y telnet git-core vim \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* \
&&  (cd frontend; yarn install; npx update-browserslist-db@latest; yarn build) \
&&  (cd backend; npm i) \
&&  (cd backend/node_modules/binance/node_modules/binance/; npm i axios@0.27.2)

WORKDIR $APP/backend

CMD ["/usr/local/bin/npm", "start"]
