#!/bin/bash -ex

# ref: https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker

# ensure we have sql server 2017 or pull it
docker images microsoft/mssql-server-linux:2017-latest >/dev/null || \
    docker pull microsoft/mssql-server-linux:2017-latest

# ensure image running or run it
docker ps --filter name=sql1 | grep sql1 >/dev/null || \
    docker run \
        --name sql1 \
        -e ACCEPT_EULA=Y \
        -e MSSQL_SA_PASSWORD='<YourStrong!Passw0rd>' \
        -p 1401:1433 \
        -d microsoft/mssql-server-linux:2017-latest

# run query
docker exec -t sql1 /bin/bash -c '/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "<YourStrong!Passw0rd>" -Q "select 1"'

# from example, unimplemented
<<'EOS'
CREATE DATABASE TestDB
SELECT Name from sys.Databases
GO

USE TestDB
CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
INSERT INTO Inventory VALUES (1, 'banana', 150);
INSERT INTO Inventory VALUES (2, 'orange', 154);
GO

SELECT * FROM Inventory WHERE quantity > 152;
GO

QUIT
EOS

