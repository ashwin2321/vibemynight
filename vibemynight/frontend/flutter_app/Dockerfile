# Multi-stage Flutter Web Dockerfile for Railway
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
ARG API_BASE_URL=https://vibemynight.onrender.com/api/v1
COPY . .
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
