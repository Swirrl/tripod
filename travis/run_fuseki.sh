#!/bin/bash

FUSEKI_HOME=/opt/fuseki/jena-fuseki1-1.5.0
cd /opt/fuseki/jena-fuseki1-1.5.0
env JVM_ARGS=-Xmx4096M ./fuseki-server --config="/opt/fuseki/config/config.ttl"