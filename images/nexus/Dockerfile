FROM quay.io/travelaudience/docker-nexus:3.27.0

USER root
RUN apk update && apk upgrade --no-cache
RUN apk add jq curl

#Enabling scripting (normally in $(NEXUS_DATA)/etc/nexus.properties, required reboot)
RUN bash -c 'echo nexus.scripts.allowCreation=true' >> ${NEXUS_HOME}/etc/nexus-default.properties

COPY uploadGroovyScript.sh createUser.groovy runScript.sh run /etc/service/nexusconfig/
RUN chmod 755 /etc/service/nexusconfig/*

ENV NEXUS_CONFIG_SCRIPTS /etc/service/nexusconfig
