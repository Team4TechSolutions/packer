#!/bin/bash
export JAVA_OPTS="-Xmx{{JVM_XMX}} -Xms{{JVM_XMS}} -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"
export CATALINA_OPTS="-Dfile.encoding=UTF-8"

