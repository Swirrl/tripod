#!/bin/bash

FUSEKI_HOME=/opt/fuseki/jena-fuseki1-1.5.0
cd /opt/fuseki/jena-fuseki1-1.5.0
env JAVA_HOME=/usr/lib/jvm/java-8-oracle/bin/java JVM_ARGS=-Xmx4096M ./fuseki-server --config="/opt/fuseki/config/config.ttl" &