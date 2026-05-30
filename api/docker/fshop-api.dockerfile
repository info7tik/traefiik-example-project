# ============================================================
# Build Stage
# ============================================================
FROM maven:3.9.11-eclipse-temurin-21 AS builder

WORKDIR /build

# Copy Maven files first for dependency caching
COPY pom.xml .

# Download dependencies
RUN mkdir -p /root/.m2 && \
    mvn dependency:go-offline -B || true

# Copy source code
COPY src ./src

# Build application
RUN mvn clean package -DskipTests

# ============================================================
# Runtime Stage
# ============================================================
FROM eclipse-temurin:21-jre

# Create non-root user
RUN groupadd -r spring && \
    useradd -r -g spring -d /app -s /sbin/nologin spring

WORKDIR /app

# Copy generated jar
COPY --from=builder /build/target/*.jar app.jar

RUN chown -R spring:spring /app

USER spring

ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+ExitOnOutOfMemoryError \
               -Djava.security.egd=file:/dev/urandom"

EXPOSE 8888

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
