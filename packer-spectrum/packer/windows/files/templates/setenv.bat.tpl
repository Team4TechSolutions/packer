@echo off
REM Tomcat Environment Configuration for Windows
REM This file sets JVM options for Tomcat

set "JAVA_OPTS=-Xmx{{JVM_XMX}} -Xms{{JVM_XMS}} -XX:+UseG1GC -Dfile.encoding=UTF-8"
set "CATALINA_OPTS=-Dfile.encoding=UTF-8"

