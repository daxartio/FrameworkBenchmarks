FROM gradle:8.0.2-jdk17 as gradle
USER root
WORKDIR /http4k
COPY build.gradle.kts build.gradle.kts
COPY settings.gradle.kts settings.gradle.kts
COPY core core
COPY core-jdbc core-jdbc
COPY core-pgclient core-pgclient
COPY graalvm graalvm
COPY sunhttp sunhttp

RUN gradle --quiet --no-daemon graalvm:shadowJar

FROM ghcr.io/graalvm/graalvm-ce:ol7-java17-22.3.0 as graalvm
RUN gu install native-image

COPY --from=gradle /http4k/core/src/main/resources/* /home/app/http4k-graalvm/
COPY --from=gradle /http4k/graalvm/build/libs/http4k-benchmark.jar /home/app/http4k-graalvm/
COPY --from=gradle /http4k/graalvm/config/*.json /home/app/http4k-graalvm/

WORKDIR /home/app/http4k-graalvm

RUN native-image \
    -H:ReflectionConfigurationFiles=reflect-config.json \
    -H:ResourceConfigurationFiles=resource-config.json \
    --initialize-at-build-time="org.slf4j.LoggerFactory,org.slf4j.simple.SimpleLogger,org.slf4j.impl.StaticLoggerBinder" \
    --no-fallback -cp http4k-benchmark.jar Http4kGraalVMBenchmarkServerKt

FROM frolvlad/alpine-glibc:glibc-2.34
RUN apk update && apk add libstdc++
EXPOSE 9000
COPY --from=graalvm /home/app/http4k-graalvm/http4kgraalvmbenchmarkserverkt /app/http4k-graalvm
ENTRYPOINT ["/app/http4k-graalvm"]
