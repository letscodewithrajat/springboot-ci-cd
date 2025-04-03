# Build stage
FROM maven:3.8.6-jdk-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package

# Run stage
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/target/demo-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]