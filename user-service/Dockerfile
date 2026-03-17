FROM eclipse-temurin:21-jdk-alpine
LABEL author="emreunaldi <emree.unaldi@gmail.com>"
WORKDIR /user-service
ADD target/user-service-0.0.1-SNAPSHOT.jar .
ENTRYPOINT ["java", "-jar", "user-service-0.0.1-SNAPSHOT.jar"]
