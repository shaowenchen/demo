#!/bin/sh

for line in $(cat tag)
do
    echo $line
    docker buildx build --push --platform=linux/arm64,linux/amd64 -t shaowenchen/builder-maven:3.9-openjdk-$line - << EOF
FROM shaowenchen/runtime-openjdk:$line AS builder
ADD https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.4/apache-maven-3.9.4-bin.tar.gz /temp/apache-maven-3.9.4-bin.tar.gz
RUN cd /temp/ && tar -zxvf apache-maven-3.9.4-bin.tar.gz

FROM shaowenchen/runtime-openjdk:$line
RUN mkdir -p /builder && \
    mkdir -p /usr/local/maven/repository
COPY --from=builder /temp/apache-maven-3.9.4 /usr/local/maven/apache-maven-3.9.4
ADD https://raw.githubusercontent.com/shaowenchen/demo/main/builder/maven/settings.xml /usr/local/maven/apache-maven-3.9.4/conf/
ENV MAVEN_HOME /usr/local/maven/apache-maven-3.9.4
ENV CLASSPATH ${MAVEN_HOME}/lib:$CLASSPATH
ENV PATH ${MAVEN_HOME}/bin:$PATH
WORKDIR /builder
EOF
done