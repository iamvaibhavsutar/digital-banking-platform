# ---------- Stage 1: BUILD (heavy tools, thrown away later) ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
# Copy ONLY pom first so Docker caches dependency downloads between builds
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q clean package -DskipTests

# ---------- Stage 2: RUNTIME (small, no compiler, no Maven) ----------
FROM eclipse-temurin:21-jre-alpine
# Non-root numeric user: if the app is hacked, the attacker is not root
RUN addgroup -S -g 10001 bank && adduser -S -u 10001 -G bank bank
WORKDIR /app
COPY --from=build /build/target/notification-service-*.jar app.jar
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
USER 10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
