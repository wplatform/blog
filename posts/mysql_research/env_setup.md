

```Bash

git clone git@github.com:mysql/mysql-server.git

cd mysql-server

cmake . -DCMAKE_INSTALL_PREFIX=$HOME/mysql-bin \
-DMYSQL_DATADIR=$HOME/mysql-bin/data \
-DSYSCONFDIR=$HOME/mysql-bin/etc \
-DWITH_DEBUG=1 \
-DWITH_BOOST=$HOME/Downloads/boost_1_67_0

make -j 4

make install -j 4

cd $HOME/mysql-bin/bin

#使用--initialize-insecure参数执行初始化后，默认root@localhost的密码为空密码
./mysqld --basedir=/$HOME/mysql-bin --datadir=/$HOME/mysql-bin/data --initialize-insecure --user=jorgie


```



