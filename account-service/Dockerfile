FROM eclipse-temurin:21-jdk-alpine
LABEL author="emreunaldi <emree.unaldi@gmail.com>"
WORKDIR /account-service
ADD target/account-service-0.0.1-SNAPSHOT.jar .
ENTRYPOINT ["java", "-jar", "account-service-0.0.1-SNAPSHOT.jar"]
