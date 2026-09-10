FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

COPY vibemynight/backend/spring_boot/pom.xml .
COPY vibemynight/backend/spring_boot/src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN mkdir -p /app/uploads

COPY --from=build /app/target/vibemynight-backend-0.1.0.jar app.jar

EXPOSE 8080
ENV PORT=8080
ENV IMAGE_STORAGE_LOCAL_PATH=/app/uploads

ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar app.jar"]
