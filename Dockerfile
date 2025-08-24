# Build aşaması
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter build web --release

# Serve aşaması
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
# İsteğe göre gzip/brotli ve cache header için custom nginx.conf ekleyebilirsin.
