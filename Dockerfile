FROM cirrusci/flutter:3.19.0
WORKDIR /app
COPY . .
RUN flutter pub get
EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "8080"]
