FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B package

FROM eclipse-temurin:17-jre

WORKDIR /app
COPY --from=build /app/target/sgsst-0.0.1-SNAPSHOT.jar app.jar

# Keep the JVM within Render's free 512 MB memory limit.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60.0 -XX:+UseSerialGC"

EXPOSE 10000
ENTRYPOINT ["java", "-jar", "app.jar"]
