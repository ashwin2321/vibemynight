FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

COPY vibemynight/backend/spring_boot/pom.xml .
COPY vibemynight/backend/spring_boot/src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN mkdir -p /app/uploads

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENV PORT=8080
ENV IMAGE_STORAGE_LOCAL_PATH=/app/uploads
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Xmx350m -Xms128m"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dserver.port=${PORT:-8080} -Dserver.address=0.0.0.0 -jar app.jar"]
