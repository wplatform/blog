```Bash
git clone git@github.com:mysql/mysql-server.git

cmake \
-DCMAKE_INSTALL_PREFIX=$HOME/mysql-bin/
-DMYSQL_DATADIR=$HOME/mysql-bin/data \
-DSYSCONFDIR=$HOME/mysql-bin/etc \
-DMYSQL_UNIX_ADDR=$HOME/mysql-bin/mysql.sock \
-DWITH_DEBUG=1  \
-DWITH_BOOST=$HOME/Downloads/boost_1_67_0

```
