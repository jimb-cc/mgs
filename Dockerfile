FROM ruby:2.2.1
MAINTAINER Jim <jim@jimb.cc>

RUN apt-get update && apt-get install -y net-tools
RUN gem install mongo
RUN gem install sinatra
RUN gem install awesome_print
RUN gem install thin

EXPOSE 4567

ADD api_insert.rb /home/
#CMD ["ruby", "/home/api_insert.rb", "echo ${USER}", "echo ${PASS}", "echo {$DBHOST}"]

CMD ruby /home/api_insert.rb $USER $PASS $DBHOST $COLL