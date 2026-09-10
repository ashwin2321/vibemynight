#!/bin/sh
cd vibemynight/backend/spring_boot
if [ ! -f target/vibemynight-backend-0.1.0.jar ]; then
  mvn clean package -DskipTests
fi
java -Dserver.port=${PORT:-8080} -jar target/vibemynight-backend-0.1.0.jar
