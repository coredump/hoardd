
FROM dockerfile/nodejs
MAINTAINER Teemu Heikkilä <teemu.heikkila@pistoke.org>

ADD . /data
RUN npm install
CMD /usr/local/bin/node start.js -c config.json