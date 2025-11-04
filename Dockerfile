FROM ubuntu:22.04 as build
RUN apt-get update && apt-get install -y curl unzip xz-utils git
RUN curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz && tar xf flutter_linux_3.24.3-stable.tar.xz
ENV PATH="/flutter/bin:${PATH}"
WORKDIR /app
COPY . .
RUN flutter build web
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
