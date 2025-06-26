FROM tabulario/spark-iceberg:3.5.1_1.5.0
RUN wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.769/aws-java-sdk-bundle-1.12.769.jar -O /opt/spark/jars/aws-java-sdk-bundle-1.12.769.jar
RUN wget https://repo1.maven.org/maven2/software/amazon/awssdk/aws-sdk-java/2.27.17/aws-sdk-java-2.27.17.jar -O /opt/spark/jars/aws-sdk-java-2.27.17.jar
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar -O /opt/spark/jars/hadoop-aws-3.3.4.jar
ENV HADOOP_CONF_DIR=/etc/hadoop/conf/
COPY spark-defaults.conf /opt/spark/conf
COPY core-site.xml /etc/hadoop/conf/core-site.xml
COPY hadoop-ks3-3.1.1-1.1.2.jar /opt/spark/jars/hadoop-ks3-3.1.1-1.1.2.jar
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
