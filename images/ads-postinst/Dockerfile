FROM adoptopenjdk:11-jre-hotspot-bionic

RUN apt-get update \
    && apt-get install -y jq \
    && apt-get clean

RUN mkdir -p /downloads \
    && cd /downloads \
    && curl -O 'https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz' \
    && ( echo "d941423d115cd021514bfd06c453658b1b3e39e6240969caf4315ab7119a77299713f14b620fb2571a264f8dff2473d8af3cb47b05acf0036fc2553199a5c1ee  apache-maven-3.6.2-bin.tar.gz" | sha512sum -c ) \
    && tar xz -C / -f apache-maven-3.6.2-bin.tar.gz \
    && cd / \
    && rm -rf downloads

ENV PATH="/apache-maven-3.6.2/bin:${PATH}"

RUN  mkdir -p /app
COPY ads_devops_postinstall.sh settings.xml.tpl /app/
RUN  chmod +x /app/ads_devops_postinstall.sh

# pre-download of maven plugins
RUN  mvn deploy:deploy-file || true
RUN  mvn clean:clean || true

ENTRYPOINT [ "/app/ads_devops_postinstall.sh" ]  # expects parameters <ADS_DESIGNER_URL>, <NEXUS_BASE_URL> and <ACCESS_TOKEN>
                                                 # env variables NEXUS_USER and NEXUS_PASSWORD can be overriden also
                                                 