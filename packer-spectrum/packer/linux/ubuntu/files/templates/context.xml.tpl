<?xml version="1.0" encoding="UTF-8"?>
<Context>
    <!-- Default set of monitored resources. If one of these changes, the    -->
    <!-- web application will be reloaded.                                   -->
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <WatchedResource>WEB-INF/tomcat-web.xml</WatchedResource>
    <WatchedResource>${catalina.base}/conf/web.xml</WatchedResource>
    
    <!-- Spectrum Database Connection -->
    <Resource name="jdbc/kioskmgr"
              auth="Container"
              type="javax.sql.DataSource"
              maxTotal="100"
              maxIdle="30"
              maxWaitMillis="10000"
              username="{{DB_USER}}"
              password="{{DB_PASSWORD}}"
              driverClassName="{{DB_DRIVER}}"
              url="{{DB_URL}}"/>
</Context>

