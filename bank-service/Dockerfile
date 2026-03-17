FROM eclipse-temurin:21-jdk-alpine
LABEL author="emreunaldi <emree.unaldi@gmail.com>"
WORKDIR /bank-service
ADD target/bank-service-0.0.1-SNAPSHOT.jar .
ENTRYPOINT ["java", "-jar", "bank-service-0.0.1-SNAPSHOT.jar"]
