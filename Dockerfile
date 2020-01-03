FROM openjdk:8-jre-alpine
MAINTAINER Quentin Dusser


ARG SQUASH_TM_LATEST_VERSION='1.21.0'
ENV SQUASH_TM_VERSION=$SQUASH_TM_LATEST_VERSION
ENV SQUASH_TM_URL="http://repo.squashtest.org/distribution/squash-tm-${SQUASH_TM_LATEST_VERSION}.RELEASE.tar.gz"

EXPOSE 8080

RUN echo $SQUASH_TM_VERSION

RUN apk add --update \
	mysql-client \
	postgresql-client \
	ttf-dejavu \
	curl && \
	rm -f /var/cache/apk/*

WORKDIR /opt
RUN curl -L ${SQUASH_TM_URL} | gunzip -c | tar x

COPY install-script.sh ./install-script.sh

RUN chmod +x ./install-script.sh 

RUN chmod +rwx squash-tm/bin/startup.sh

# Modifying data in squash-tm/bin/startup.sh & executing startup.sh
CMD cd /opt && ./install-script.sh
