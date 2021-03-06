FROM adoptopenjdk:15-jre-hotspot
ARG APP_VER
ENV JAVA_OPTS "-Xmx1024m"
EXPOSE 8880

RUN mkdir -p /opt/app
WORKDIR /opt/app
ADD https://downloads.mariadb.com/Connectors/java/connector-java-2.7.1/mariadb-java-client-2.7.1.jar /opt/app/mariadb-java-client.jar
COPY ./jsserver.properties /opt/app
COPY ./jsettlers-${APP_VER}/JSettlersServer-${APP_VER}.jar /opt/app/JSettlersServer.jar
# Params can be given on command line or jsserver.properties
ENTRYPOINT exec java $JAVA_OPTS -jar JSettlersServer.jar \
  -Djsettlers.db.user=$DB_USER \
  -Djsettlers.db.pass=$DB_PASS \
  -Djsettlers.db.url="jdbc:mariadb://${DB_HOST}:${DB_PORT}/${DB_NAME}" \
  -Djsettlers.db.jar=mariadb-java-client.jar

