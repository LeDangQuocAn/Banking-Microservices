FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom first so dependency download can be cached.
COPY pom.xml .
RUN mvn -B -ntp dependency:go-offline

# Copy source and build the Spring Boot jar.
COPY src ./src
RUN mvn -B -ntp clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app

# Run with an unprivileged user for better container security.
RUN useradd --create-home appuser && \
    apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /app/target/*.jar /app/app.jar
RUN chown appuser:appuser /app/app.jar

USER appuser
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
