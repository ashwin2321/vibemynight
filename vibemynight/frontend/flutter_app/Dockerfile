# Multi-stage Flutter Web Dockerfile
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
ARG API_BASE_URL=https://vibemynight-production.up.railway.app/api/v1
COPY . .
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
RUN printf 'server {\n listen 80;\n location / {\n root /usr/share/nginx/html;\n try_files $uri $uri/ /index.html;\n }\n}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
