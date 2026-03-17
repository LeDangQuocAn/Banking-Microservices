FROM eclipse-temurin:21-jdk-alpine
LABEL author="emreunaldi <emree.unaldi@gmail.com>"
WORKDIR /credit-card-service
ADD target/credit-card-service-0.0.1-SNAPSHOT.jar .
ENTRYPOINT ["java", "-jar", "credit-card-service-0.0.1-SNAPSHOT.jar"]
