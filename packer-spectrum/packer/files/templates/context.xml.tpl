<?xml version="1.0" encoding="UTF-8"?>
<Context>
    <!-- Spectrum Database Connection -->
    <Resource name="jdbc/kilobase"
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

