## 1.配置数据库集群

规划好数据表的切分规模，建立数据库集群。OpenDDAL中的ddal-config.xml用于描述这些信息，下面显示功能演示中使用的配置，些配置文件可能在[openddal-quickstart-server](https://github.com/openddal/openddal-quickstart-server/blob/master/conf/engine.xml)中找到。
```xml

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ddal-config PUBLIC "-//openddal.com//DTD ddal-config//EN" "http://openddal.com/dtd/ddal-config.dtd">
<ddal-config>

	<settings>
		<property name="sqlMode" value="MySQL" />
		<property name="transactionMode" value="BESTEFFORTS_1PC" />
		<property name="defaultQueryTimeout" value="3000" />
		<property name="validationQuery" value="select 1" />
		<property name="validationQueryTimeout" value="1000" />
	</settings>

	<schema name="SCHEMA_MAIN" force="false">

		<tableGroup>
			<tables>
				<table name="customers" ruleColumns="id" />
				<table name="address" ruleColumns="customer_id" />
			</tables>
			<nodes>
				<node shard="shard0" suffix="_01,_02" />
				<node shard="shard1" suffix="_01,_02" />
				<node shard="shard2" suffix="_01,_02" />
				<node shard="shard3" suffix="_01,_02" />
			</nodes>
			<tableRule>
				<columns>${table.ruleColumns}</columns>
				<algorithm>customer_partitioner</algorithm>
			</tableRule>
		</tableGroup>

		<table name="product">
			<broadcast>shard0,shard1,shard2,shard3</broadcast>
		</table>
		
		<table name="customer_login_log">
			<node shard="shard0" name="t_customer_login_log"/>
		</table>
		
		<sequence name="customer_seq" strategy="hilo">
			<property name="shard" value="shard0" />
			<property name="cacheSize" value="1" />
		</sequence>
		....
	</schema>

	<cluster>
		<shard name="shard0">
			<member ref="db1m" />
		</shard>
		<shard name="shard1">
			<member ref="db2m" />
		</shard>
		<shard name="shard2">
			<member ref="db3m" />
		</shard>
		<shard name="shard3">
			<member ref="db4m" />
		</shard>
	</cluster>


	<dataNodes>
		<datasource id="db1m" class="org.apache.commons.dbcp.BasicDataSource">
			<property name="driverClassName" value="com.mysql.jdbc.Driver" />
			<property name="url"
				value="jdbc:mysql://10.199.188.136:3306/ddal_db1?connectTimeout=1000&amp;rewriteBatchedStatements=true" />
			<property name="username" value="root" />
			<property name="password" value="!Passw0rd01" />
			<property name="maxWait" value="0" />
			<property name="poolPreparedStatements" value="true" />
		</datasource>
		....
	</dataNodes>

	<algorithms>
		<ruleAlgorithm name="customer_partitioner"
			class="com.openddal.route.algorithm.HashBucketPartitioner">
			<property name="partitionCount" value="8" />
			<property name="partitionLength" value="128" />
		</ruleAlgorithm>
		<ruleAlgorithm name="order_partitioner"
			class="com.openddal.route.algorithm.HashBucketPartitioner">
			<property name="partitionCount" value="16" />
			<property name="partitionLength" value="64" />
		</ruleAlgorithm>
	</algorithms>

</ddal-config>

```
此文档定义了数据库集群信息，表的分切方式和切分规模及局的序列信息，在OpenDDAL中，应用能访问的表需要在schema中定义，OpendDDAL中定义的表分为三种类型：sharding table,broadcast table, fixnode table, tableGroup的做用是让有着关联关系的表对象可以做用于相同的切分方式，以使用SQL的关联查询上获得好的性能，比如同一个tableGroup的比按ruleColumns进行inner jone ,right/left out join的查询无需夸库。

## 2. embedded模式 VS c/s模式

在OpendDDAL三层的体系架构中，API层和repository层是可以自由让用户进行选择。在API层，OpendDDAL实现了一套完整的jdbc规范，可以让openddal-engine以embedded模式方试运行在应用中。
也可能通过openddal-server以c/s模式运行OpendDDAL，openddal-server是一款基于MySQL协议的数据库中间件,使用应用开发不用受制于开发语言。对java应用而言，两种模式可以相互切换而无兼容问题。


## 3. 使用JDBC-API
OpendDDAL实现了一套完整的jdbc规范，易于基于jdbc开发的应用迁移至OpendDDAL实现分库分表。OpendDDAL提供了Driver。其用使方式与数据库的jdbc driver无差别。
```java
    //创建dbcp数据源
    BasicDataSource ds = new BasicDataSource();
    ds.setDriverClassName("com.openddal.jdbc.Driver");
    ds.setUrl("jdbc:openddal:");
    ds.setDefaultAutoCommit(false);
    ds.setDefaultTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);

    //运行mysql_script.sql脚本
    ScriptRunner runner = new ScriptRunner(ds.getConnection());
    runner.setAutoCommit(true);
    runner.setStopOnError(true);

    String resource = "script/mysql_script.sql";
    Reader reader = new InputStreamReader(Utils.getResourceAsStream(resource));
    try {
        runner.runScript(reader);
    } catch (Exception e) {
        Assert.fail(e.getMessage());
    }
```

## 3. 使用openddal-server

本文档使用的openddal-quickstart-server以上传到github上，欢迎[下载](https://github.com/openddal/openddal-quickstart-server)试玩。

#### 3.1启动server进程
```bash
[root@***** bin]# ./openddal.sh start
openddal starting, port is 6100, JMX port is 8050..
openddal start successfully, running as process:125564.

```

#### 3.2连接server
openddal-server默认的tcp端口为6100，可以使用mysql client端连接到server，本文档使用的server配置了两个户用，root/root, mysql/mysql

```bash
E:\downloads\mysql-5.7.13-win32\bin>mysql -h 10.199.135.33 -P6100 -uroot -proot
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.6.31OpenDDAL MySQL Protocol Server-1.2.1 (2016-07-19) OpenDDAL MySQL Protocol Server

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| SCHEMA_NAME        |
+--------------------+
| schema_main        |
| information_schema |
+--------------------+
2 rows in set (0.00 sec)

mysql> show engines;
+-----------------+---------+------------------------+--------------+------+------------+
| Engine          | Support | Comment                | Transactions | XA   | Savepoints |
+-----------------+---------+------------------------+--------------+------+------------+
| OPENDDAL_ENGINE | DEFAULT | Distributed SQL Engine | YES          | NO   | YES        |
+-----------------+---------+------------------------+--------------+------+------------+
1 row in set (0.00 sec)

```

## 4. ddl语句支持

在第一节中ddal-config.xml配置文件已经定义好了数据库集群信息，表的分切方式，虽然还没有在物理数据库上创建对应的物理表结点，但在openddal上可以通过show tables,show partitions table_name查看。

```bash

mysql> show tables;
+--------------------+--------------+
| TABLE_NAME         | TABLE_SCHEMA |
+--------------------+--------------+
| address            | schema_main  |
| customer_login_log | schema_main  |
| customers          | schema_main  |
| order_items        | schema_main  |
| order_status       | schema_main  |
| orders             | schema_main  |
| product            | schema_main  |
| product_category   | schema_main  |
+--------------------+--------------+
8 rows in set (0.01 sec)

mysql> show partitions customers;
+------------+-----------+--------------+-----------+----------------------------------------------------+
| TABLE_NAME | DATA_NODE | NODE_NAME    | NODE_TYPE | PARTITIONER                                        |
+------------+-----------+--------------+-----------+----------------------------------------------------+
| customers  | shard0    | customers_01 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard0    | customers_02 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard1    | customers_01 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard1    | customers_02 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard2    | customers_01 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard2    | customers_02 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard3    | customers_01 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
| customers  | shard3    | customers_02 | sharded   | com.openddal.route.algorithm.HashBucketPartitioner |
+------------+-----------+--------------+-----------+----------------------------------------------------+
8 rows in set (0.01 sec)

```

OpendDDAL支持ddl语句，以上的表并未创建物理表结点，可以在OpendDDAL执行上执行创建，OpendDDAL会在数据库集群上创建对应的数据库对象。 可以将语句放至到文件中[mysql_script.sql](https://github.com/openddal/openddal-quickstart-server/blob/master/mysql_script.sql)，批量运行脚本。

```bash
mysql> source D:\product_code\openddal\openddal-tests\src\main\resources\script\mysql_script.sql
Query OK, 0 rows affected (0.17 sec)

Query OK, 0 rows affected (0.23 sec)

Query OK, 0 rows affected (0.20 sec)

Query OK, 0 rows affected (0.41 sec)

Query OK, 0 rows affected (0.38 sec)

Query OK, 0 rows affected (0.40 sec)

Query OK, 0 rows affected (0.11 sec)

Query OK, 0 rows affected (0.14 sec)

Query OK, 0 rows affected (0.03 sec)
```
mysql_script.sql完成物理表结点的创建
```bash
mysql> show columns from customers;
+---------------+--------------+------+------+---------+
| FIELD         | TYPE         | NULL | KEY  | DEFAULT |
+---------------+--------------+------+------+---------+
| id            | integer(10)  | YES  | UNI  | NULL    |
| rand_id       | integer(10)  | YES  |      | NULL    |
| name          | varchar(20)  | YES  |      | NULL    |
| customer_info | varchar(100) | YES  |      | NULL    |
| birthdate     | date(10)     | YES  |      | NULL    |
+---------------+--------------+------+------+---------+
5 rows in set (0.10 sec)
```
## 5.增删改查

完成物理表结点的创建就可以访问表的的数据

#### 5.1 看看SQL在那个结点上执行

````sql
mysql> explain plan for insert into customers(id,rand_id,name,customer_info,birthdate) values (customer_seq.nextval, customer_seq.currval,'zhangshang','zhangshang','1985-01-01');
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| PLAN                                                                                                                                                                                                                |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| SINGLE_EXECUTION
    execute on shard0: INSERT INTO CUSTOMERS_01(ID, RAND_ID, NAME, CUSTOMER_INFO, BIRTHDATE) VALUES (?, ?, ?, ?, ?) params: {1: 47, 2: 47, 3: 'zhangshang', 4: 'zhangshang', 5: DATE '1985-01-01'} |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.01 sec)

mysql> insert into customers(id,rand_id,name,customer_info,birthdate) values (customer_seq.nextval, customer_seq.currval,'zhangshang','zhangshang','1985-01-01');
Query OK, 1 row affected (0.01 sec)

````

#### 5.2 合并查询

````sql

mysql> select * from customers order by name;
+----+---------+------------+---------------+------------+
| ID | RAND_ID | NAME       | CUSTOMER_INFO | BIRTHDATE  |
+----+---------+------------+---------------+------------+
| 48 |      48 | zhangshang | zhangshang    | 1985-01-01 |
| 45 |      45 | 公孙胜     | 银牌会员      | 1980-07-01 |
| 46 |      46 | 关胜       | 铜牌会员      | 1932-03-01 |
| 43 |      43 | 卢俊义     | 金牌会员      | 1987-05-01 |
| 44 |      44 | 吴用       | 银牌会员      | 1970-06-01 |
| 42 |      42 | 宋江       | 金牌会员      | 1985-01-01 |
+----+---------+------------+---------------+------------+
6 rows in set (0.01 sec)

````


#### 5.2 JoinFree查询

````sql

mysql> select  * from customers a, address b where id=customer_id order by name;
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
| ID | RAND_ID | NAME      | CUSTOMER_INFO | BIRTHDATE  | ADDRESS_ID      | CUSTOMER_ID | ADDRESS_INFO            | ZIP_CODE | PHONE_NUM   |
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
| 45 |      45 | 公孙胜    | 银牌会员      | 1980-07-01 | 606051175108608 |          45 | 浙江·磐安               | 54475    | 6332474     |
| 46 |      46 | 关胜      | 铜牌会员      | 1932-03-01 | 606051217051648 |          46 | 福建·霞浦               | 54245    | 654148      |
| 43 |      43 | 卢俊义    | 金牌会员      | 1987-05-01 | 606050877313024 |          43 | 山东·烟墩角             | 6542     | 326654654   |
| 43 |      43 | 卢俊义    | 金牌会员      | 1987-05-01 | 606050957004800 |          43 | 新疆·果子沟             | 5454     | 12654654654 |
| 43 |      43 | 卢俊义    | 金牌会员      | 1987-05-01 | 606051045085184 |          43 | 云南·坝美               | 5429     | 54654285    |
| 44 |      44 | 吴用      | 银牌会员      | 1970-06-01 | 606051045085185 |          44 | 甘孜州·丹巴             | 5422     | 69355356    |
| 42 |      42 | 宋江      | 金牌会员      | 1985-01-01 | 606050579517440 |          42 | 西藏·然乌湖             | 545254   | 65463546    |
| 42 |      42 | 宋江      | 金牌会员      | 1985-01-01 | 606050789232640 |          42 | 阿坝州·四姑娘山         | 455475   | 65465465    |
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
8 rows in set (0.00 sec)

mysql> select  * from customers a, address b where id=customer_id order by name limit 3,10;
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
| ID | RAND_ID | NAME      | CUSTOMER_INFO | BIRTHDATE  | ADDRESS_ID      | CUSTOMER_ID | ADDRESS_INFO            | ZIP_CODE | PHONE_NUM   |
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
| 43 |      43 | 卢俊义    | 金牌会员      | 1987-05-01 | 606050877313024 |          43 | 山东·烟墩角             | 6542     | 326654654   |
| 43 |      43 | 卢俊义    | 金牌会员      | 1987-05-01 | 606050957004800 |          43 | 新疆·果子沟             | 5454     | 12654654654 |
| 44 |      44 | 吴用      | 银牌会员      | 1970-06-01 | 606051045085185 |          44 | 甘孜州·丹巴             | 5422     | 69355356    |
| 42 |      42 | 宋江      | 金牌会员      | 1985-01-01 | 606050789232640 |          42 | 阿坝州·四姑娘山         | 455475   | 65465465    |
| 42 |      42 | 宋江      | 金牌会员      | 1985-01-01 | 606050579517440 |          42 | 西藏·然乌湖             | 545254   | 65463546    |
+----+---------+-----------+---------------+------------+-----------------+-------------+-------------------------+----------+-------------+
5 rows in set (0.01 sec)

````
#### 5.2 group by having查询

````sql

mysql> select name, count(ADDRESS_ID),sum(ADDRESS_ID),max(ADDRESS_ID),min(ADDRESS_ID),avg(ADDRESS_ID)  from customers a, address b where id=customer_id group by name order by name;
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
| NAME      | COUNT(ADDRESS_ID) | SUM(ADDRESS_ID)  | MAX(ADDRESS_ID) | MIN(ADDRESS_ID) | AVG(ADDRESS_ID) |
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
| 公孙胜    |                 1 |  606051175108608 | 606051175108608 | 606051175108608 | 606051175108608 |
| 关胜      |                 1 |  606051217051648 | 606051217051648 | 606051217051648 | 606051217051648 |
| 卢俊义    |                 3 | 1818152879403008 | 606051045085184 | 606050877313024 | 606050959801003 |
| 吴用      |                 1 |  606051045085185 | 606051045085185 | 606051045085185 | 606051045085185 |
| 宋江      |                 2 | 1212101368750080 | 606050789232640 | 606050579517440 | 606050684375040 |
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
5 rows in set (0.01 sec)

mysql> select name, count(ADDRESS_ID),sum(ADDRESS_ID),max(ADDRESS_ID),min(ADDRESS_ID),avg(ADDRESS_ID)  from customers a, address b where id=customer_id group by name having COUNT(ADDRESS_ID) > 1 order by name;
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
| NAME      | COUNT(ADDRESS_ID) | SUM(ADDRESS_ID)  | MAX(ADDRESS_ID) | MIN(ADDRESS_ID) | AVG(ADDRESS_ID) |
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
| 卢俊义    |                 3 | 1818152879403008 | 606051045085184 | 606050877313024 | 606050959801003 |
| 宋江      |                 2 | 1212101368750080 | 606050789232640 | 606050579517440 | 606050684375040 |
+-----------+-------------------+------------------+-----------------+-----------------+-----------------+
2 rows in set (0.01 sec)

````

## 6.分布式Sequence支持

````sql
mysql> select address_seq.nextval snowflake, customer_seq.nextval hilo;
+-----------------+------+
| SNOWFLAKE       | HILO |
+-----------------+------+
| 624026556960768 |   51 |
+-----------------+------+
1 row in set (0.01 sec)

mysql> select address_seq.currval snowflake, customer_seq.currval hilo;
+-----------------+------+
| SNOWFLAKE       | HILO |
+-----------------+------+
| 624026556960768 |   51 |
+-----------------+------+
1 row in set (0.01 sec)

mysql> select LAST_INSERT_ID(), IDENTITY(), SCOPE_IDENTITY();
+------------------+------------+------------------+
| LAST_INSERT_ID() | IDENTITY() | SCOPE_IDENTITY() |
+------------------+------------+------------------+
|               51 |         51 |               51 |
+------------------+------------+------------------+
1 row in set (0.02 sec)

````
