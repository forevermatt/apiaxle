#!/bin/sh

port=3000
app='api'

# app can be passed as first parameter
if [ $# -gt 0 ]; then
  app=$1
fi

# port can be passed as second parameter
if [ $# -gt 1 ]; then
  port=$2
fi

# Set default values if env vars are not present
if [ -z $REDIS_HOST ]; then
  REDIS_HOST=redis
fi
if [ -z $REDIS_PORT ]; then
  REDIS_PORT=6379
fi
if [ -z $DEBUG_MODE ]; then
  DEBUG_MODE=false
fi

# Update config file with env values
mkdir -p /etc/apiaxle
CONFIG_FILE=/etc/apiaxle/$NODE_ENV.json
cp /apiaxle-config.json $CONFIG_FILE
sed -i "s/REDIS_HOST/${REDIS_HOST}/" $CONFIG_FILE
sed -i "s/REDIS_PORT/${REDIS_PORT}/" $CONFIG_FILE
sed -i "s/DEBUG_MODE/${DEBUG_MODE}/" $CONFIG_FILE

if [ $app = 'repl' ]; then
  cd /app/apiaxle/repl
  if [ $NODE_ENV = 'test' ]; then
    # When NODE_ENV is 'test', run as coffee for watch and recompile
    coffee --watch /app/apiaxle/base/index.coffee /app/apiaxle/base &
    coffee /app/apiaxle/repl/apiaxle.coffee
  else
    node /app/apiaxle/repl/apiaxle.js
  fi

elif [ $app = 'test' ]; then
  apk add --update make

  cd /app/apiaxle/proxy
  npm install nock
  npm install -g twerp

  cd /app/apiaxle
  make
  make test

else
  if [ $NODE_ENV = 'test' ]; then
    # When NODE_ENV is 'test', run as coffee for watch and recompile
    coffee --watch /app/apiaxle/base/index.coffee /app/apiaxle/base &
    coffee --watch /app/apiaxle/$app/apiaxle-$app.coffee -- -h 0.0.0.0 -p $port -f 1
  else
    cd /app/apiaxle/$app
    node /app/apiaxle/$app/apiaxle-$app.js -h 0.0.0.0 -p $port -f 1
  fi
fi
