FROM eclipse-temurin:21-jdk-alpine
LABEL author="emreunaldi <emree.unaldi@gmail.com>"
WORKDIR /log-service
ADD target/log-service-0.0.1-SNAPSHOT.jar .
ENTRYPOINT ["java", "-jar", "log-service-0.0.1-SNAPSHOT.jar"]
