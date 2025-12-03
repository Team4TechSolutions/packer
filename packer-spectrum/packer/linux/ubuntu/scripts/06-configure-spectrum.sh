#!/bin/bash
set -e

echo "Configuring Spectrum..."

# Variables
DB_TYPE="${DB_TYPE:-mysql}"
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-spectrum}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-kioskmgr}"
SERVER_IP="${SERVER_IP:-localhost}"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Step 1: Install JDBC Driver
echo "Installing JDBC driver for $DB_TYPE..."

cd /tmp

if [ "$DB_TYPE" = "sqlserver" ]; then
    echo "Downloading Microsoft SQL Server JDBC driver..."
    wget -q --no-check-certificate "https://go.microsoft.com/fwlink/?linkid=2222954" -O mssql-jdbc.tar.gz
    tar xzf mssql-jdbc.tar.gz
    sudo cp sqljdbc_*/enu/jars/mssql-jdbc-*.jre17.jar $TOMCAT_HOME/lib/ 2>/dev/null || \
    sudo cp sqljdbc_*/enu/jars/mssql-jdbc-*.jar $TOMCAT_HOME/lib/
    sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/lib/mssql-jdbc-*.jar
    rm -rf sqljdbc_* mssql-jdbc.tar.gz
    echo "SQL Server JDBC driver installed"
elif [ "$DB_TYPE" = "mysql" ]; then
    echo "Downloading MySQL Connector..."
    MYSQL_CONNECTOR_VERSION="8.0.33"
    wget -q "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.tar.gz" -O mysql-connector.tar.gz || \
    wget -q "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar" -O $TOMCAT_HOME/lib/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
    
    if [ -f "mysql-connector.tar.gz" ]; then
        tar xzf mysql-connector.tar.gz
        sudo cp mysql-connector-j-*/mysql-connector-j-*.jar $TOMCAT_HOME/lib/
        rm -rf mysql-connector-j-* mysql-connector.tar.gz
    fi
    
    sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/lib/mysql-connector-java-*.jar 2>/dev/null || true
    echo "MySQL Connector installed"
fi

# Step 2: Configure Database Connection using template
echo "Configuring database connection in context.xml..."

if [ "$DB_TYPE" = "sqlserver" ]; then
    DB_URL="jdbc:sqlserver://${DB_HOST}:1433;databaseName=${DB_NAME};encrypt=false"
    DB_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
elif [ "$DB_TYPE" = "mysql" ]; then
    # Escape & for XML - use &amp; instead of &
    DB_URL="jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&amp;serverTimezone=UTC"
    DB_DRIVER="com.mysql.cj.jdbc.Driver"
fi

# Use template if available, otherwise use sed
if [ -f "/tmp/context.xml.tpl" ]; then
    echo "Using context.xml template..."
    # Backup original
    sudo cp $TOMCAT_HOME/conf/context.xml $TOMCAT_HOME/conf/context.xml.backup
    
    # Replace entire context.xml with template (simpler approach)
    # Use perl for better handling of special characters in URLs
    # Escape & to &amp; for XML compatibility
    DB_URL_ESCAPED=$(echo "$DB_URL" | perl -pe 's/&/&amp;/g')
    sudo perl -pe "s|{{DB_USER}}|${DB_USER}|g; s|{{DB_PASSWORD}}|${DB_PASSWORD}|g; s|{{DB_DRIVER}}|${DB_DRIVER}|g; s|{{DB_URL}}|${DB_URL_ESCAPED}|g" \
        /tmp/context.xml.tpl | sudo tee $TOMCAT_HOME/conf/context.xml > /dev/null
else
    # Fallback to sed method
    sudo cp $TOMCAT_HOME/conf/context.xml $TOMCAT_HOME/conf/context.xml.backup
    sudo sed -i '/<\/Context>/i\
    <!-- Spectrum Database Connection -->\
    <Resource name="jdbc/kilobase"\
              auth="Container"\
              type="javax.sql.DataSource"\
              maxTotal="100"\
              maxIdle="30"\
              maxWaitMillis="10000"\
              username="'${DB_USER}'"\
              password="'${DB_PASSWORD}'"\
              driverClassName="'${DB_DRIVER}'"\
              url="'${DB_URL}'"/>\
' $TOMCAT_HOME/conf/context.xml
fi

sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/conf/context.xml
echo "Database connection configured"

# Step 3: Configure Frontend appConfig.js using template
if [ -f "$TOMCAT_HOME/webapps/spectrum/appConfig.js" ]; then
    echo "Configuring frontend appConfig.js..."
    
    if [ -f "/tmp/appConfig.js.tpl" ]; then
        echo "Using appConfig.js template..."
        sudo sed -e "s|{{SERVER_IP}}|${SERVER_IP}|g" \
                /tmp/appConfig.js.tpl > /tmp/appConfig.js.new
        sudo mv /tmp/appConfig.js.new $TOMCAT_HOME/webapps/spectrum/appConfig.js
    else
        # Fallback to sed method
        sudo sed -i "s|http://YOUR-SERVER-IP:8080/spectrum-server|http://${SERVER_IP}:8080/spectrum-server|g" \
            $TOMCAT_HOME/webapps/spectrum/appConfig.js
    fi
    
    sudo chown $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_HOME/webapps/spectrum/appConfig.js
    echo "Frontend configuration updated"
fi

echo "Spectrum configuration completed!"

