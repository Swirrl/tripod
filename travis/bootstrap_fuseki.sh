#!/bin/bash

mkdir -p /home/travis/tdb_data
mkdir -p /opt/fuseki
mkdir /opt/fuseki/config
sudo apt-get update
sudo apt-get -y install tar wget
wget http://apache.mirror.anlx.net/jena/binaries/jena-fuseki1-1.5.0-distribution.tar.gz -O /opt/fuseki/jena-fuseki-1.5.0.tar.gz
tar -xvzf /opt/fuseki/jena-fuseki-1.5.0.tar.gz -C /opt/fuseki
mv ./travis/config_tripod.ttl /opt/fuseki/config/config.ttl