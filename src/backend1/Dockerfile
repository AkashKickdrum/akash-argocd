# ---------- build ----------
FROM gradle:8.7-jdk17 AS build
WORKDIR /home/app
COPY . .
RUN gradle bootJar --no-daemon

# ---------- runtime ----------
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /home/app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
