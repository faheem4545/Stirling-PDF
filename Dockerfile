# Stage 1: Build the JAR using Gradle
FROM gradle:7.6.2-jdk17 AS builder

WORKDIR /app
COPY . .
RUN gradle clean build --no-daemon

# Stage 2: Create final image
FROM alpine:3.22.0

# Set environment variables
ENV DISABLE_ADDITIONAL_FEATURES=true \
    PORT=8080 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    PATH=$PATH:/usr/lib/jvm/java-17-openjdk/bin

# Install JRE and other dependencies
RUN echo "@main https://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories && \
    apk add --no-cache \
    openjdk17-jre \
    ttf-freefont \
    bash \
    tini \
    curl \
    python3 \
    py3-pip \
    poppler-utils \
    libreoffice \
    tesseract-ocr \
    && adduser -S stirlingpdfuser

# Create folders and fonts
RUN mkdir -p /usr/share/fonts/opentype/noto && \
    mkdir -p /home/stirlingpdfuser /configs /logs /customFiles

# Copy the built JAR from the builder stage
COPY --from=builder /app/build/libs/*.jar /app.jar

# Optionally copy additional assets (scripts, fonts, etc.)
COPY scripts /scripts
COPY pipeline /pipeline

# Set permissions
RUN chmod +x /scripts/* && \
    chown -R stirlingpdfuser /scripts /pipeline /app.jar

USER stirlingpdfuser

EXPOSE 8080

ENTRYPOINT ["tini", "--"]
CMD ["sh", "-c", "java -Dfile.encoding=UTF-8 -jar /app.jar & /opt/venv/bin/unoserver --port 2003 --interface 127.0.0.1"]
