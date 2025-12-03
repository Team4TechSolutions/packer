# JDBC Drivers Directory

This directory is **optional** and can be used to pre-bundle JDBC driver JAR files.

## Usage

If you have JDBC drivers locally and want to include them in the AMI build instead of downloading during the build:

1. Place your JDBC driver JAR files here:
   ```
   jdbc/
   ├── mssql-jdbc-11.2.3.jre17.jar  (for SQL Server)
   ├── mysql-connector-java-8.0.33.jar  (for MySQL)
   └── README.md
   ```

2. Update `ubuntu.pkr.hcl` to use a file provisioner:
   ```hcl
   provisioner "file" {
     source      = "./files/jdbc/mssql-jdbc-11.2.3.jre17.jar"
     destination = "/opt/tomcat/lib/mssql-jdbc-11.2.3.jre17.jar"
   }
   ```

3. Modify `05-configure-spectrum.sh` to skip downloading if files already exist:
   ```bash
   if [ -f "/opt/tomcat/lib/mssql-jdbc-*.jar" ]; then
     echo "JDBC driver already installed"
   else
     # Download logic here
   fi
   ```

## Alternative

The default behavior is to download JDBC drivers automatically during the build process based on the `DB_TYPE` variable.

## Supported Drivers

- **SQL Server**: Microsoft JDBC Driver for SQL Server
- **MySQL**: MySQL Connector/J

## Note

If this directory is empty, the build will automatically download the appropriate JDBC driver based on your `DB_TYPE` configuration.

