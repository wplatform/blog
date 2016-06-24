#### 1.千里之行始于足下,规划好数据表的切分规模，建立你的数据库集群
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ddal-config PUBLIC "-//openddal.com//DTD ddal-config//EN" "http://openddal.com/dtd/ddal-config.dtd">
<ddal-config>
	
	<settings>
		<property name="sqlMode" value="MySQL" />
		<property name="defaultQueryTimeout" value="3000" />
		<property name="validationQuery" value="select 1" />
		<property name="validationQueryTimeout" value="1000" />
	</settings>

	<schema name="SCHEMA_MAIN" force="false">
		<tableGroup>
			<tables>
				<table name="orders" />
				<table name="order_items" />
				<table name="order_status" />
			</tables>
			<nodes>
				<node shard="shard0" suffix="_01,_02,_03,_04" />
				<node shard="shard1" suffix="_01,_02,_03,_04" />
				<node shard="shard2" suffix="_01,_02,_03,_04" />
				<node shard="shard3" suffix="_01,_02,_03,_04" />
			</nodes>
			<tableRule>
				<columns>order_id</columns>
				<algorithm>order_partitioner</algorithm>
			</tableRule>

		</tableGroup>

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

		<table name="product_category">
			<broadcast>shard0,shard1,shard2,shard3</broadcast>
		</table>
		
		<table name="customer_login_log">
			<node shard="shard0" name="t_customer_login_log"/>
		</table>
		
		<sequence name="customer_seq" strategy="hilo">
			<property name="shard" value="shard0" />
			<property name="cacheSize" value="50" />
		</sequence>

	</schema>

	<cluster>
		<shard name="shard0">
			<member ref="master01" rWeight="5"/>
			<member ref="slave01" rWeight="10"/>
		</shard>
		<shard name="shard1">
			<member ref="master02" rWeight="5"/>
			<member ref="slave02" rWeight="10"/>
		</shard>
		<shard name="shard2">
			<member ref="master03" rWeight="5"/>
			<member ref="slave03" rWeight="10"/>
		</shard>
		<shard name="shard3">
			<member ref="master04" rWeight="5"/>
			<member ref="slave04" rWeight="10"/>
		</shard>
	</cluster>


	<dataNodes>
		<datasource id="master01" class="org.apache.commons.dbcp.BasicDataSource">
			<property name="driverClassName" value="com.mysql.jdbc.Driver" />
			<property name="url"
				value="jdbc:mysql://10.199.188.136:3306/ddal_db1?connectTimeout=1000&amp;rewriteBatchedStatements=true" />
			<property name="username" value="root" />
			<property name="password" value="!Passw0rd01" />
			<property name="maxWait" value="0" />
			<property name="poolPreparedStatements" value="true" />
		</datasource>
		.....
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
应用可以返问的表需要在schema中定义，OpendDDAL中定义的表分为三种类型：sharding table,broadcast table, fixnode table, tableGroup，broadcast特别的为OpendDDAL JoinFree做优化，比较同一个tableGroup的比按ruleColumns进行inner jone ,right/left out join可应用JoinFree进行优化，避免夸库。

#### 2.OpendDDAL支持ddl语句，在OpendDDAL执行上面的SQL，OpendDDAL会在数据库集群上创建对应的数据库对象。 无需人工参与。OpendDDAL提供了ScriptRunner工作，可以将语句放至到文件中，批量运行脚本。
mysql_script.sql
```sql
DROP TABLE IF EXISTS customers,address,order_items,order_status,orders,product,product_category,customer_logs;

CREATE TABLE IF NOT EXISTS `customers` (
  `id` int(11) NOT NULL,
  `rand_id` int(11) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `customer_info` varchar(100) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY (`birthdate`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `address` (
  `address_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `address_info` varchar(512) DEFAULT NULL,
  `zip_code` varchar(16) DEFAULT NULL,
  `phone_num` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`address_id`),
  KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `orders` (
  `order_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `order_info` varchar(218) DEFAULT NULL,
  `create_date` datetime NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `order_items` (
  `item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `item_info` varchar(218) DEFAULT NULL,
  `create_date` datetime NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY (`create_date`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `order_status` (
  `status_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `order_status` int(2) DEFAULT NULL,
  `create_date` datetime NOT NULL,
  PRIMARY KEY (`order_id`),
  KEY (`create_date`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `product_category` (
  `product_category_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `category_info` int(2) DEFAULT NULL,
  `create_date` datetime NOT NULL,
  PRIMARY KEY (`product_category_id`),
  KEY (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `product` (
  `product_id` int(11) NOT NULL,
  `product_category_id` int(11) NOT NULL,
  `product_name` int(2) DEFAULT NULL,
  `create_date` datetime NOT NULL,
  PRIMARY KEY (`product_id`),
  KEY (`create_date`),
  FOREIGN KEY (`product_category_id`) REFERENCES `product_category` (`product_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `customer_logs` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `logintime` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

```
#### 3.OpendDDAL实现了一套完整的jdbc规范，易于基于jdbc开发的应用迁移至OpendDDAL实现分库分表。OpendDDAL提供了JdbcDriver。用户可以选用任意的数据源品产品。下面的应用使用dbcp进行演示。
```java
    //创建dbcp数据源
    BasicDataSource ds = new BasicDataSource();
    ds.setDriverClassName("com.openddal.jdbc.JdbcDriver");
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
#### 4.SQL怎样执行的，看看执行计划
````java
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        try {
            conn = ds.getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("EXPLAIN PLAN FOR CREATE TABLE IF NOT EXISTS `order_items`(`item_id` int(11) NOT NULL,`order_id` int(11) NOT NULL,`item_info` varchar(218) DEFAULT NULL,`create_date` datetime NOT NULL, PRIMARY KEY (`order_id`),  KEY (`create_date`), FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1");
            printResultSet(rs);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            JdbcUtils.closeSilently(rs);
            JdbcUtils.closeSilently(stmt);
            JdbcUtils.closeSilently(conn);
        }
````
执行结果
````sql
PLAN 
-------------------
MULTIPLE_EXECUTION
    execute on shard0: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_01(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_01(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard0: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_02(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_02(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard0: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_03(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_03(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard0: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_04(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_04(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard1: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_01(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_01(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard1: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_02(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_02(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard1: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_03(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_03(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard1: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_04(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_04(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard2: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_01(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_01(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard2: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_02(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_02(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard2: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_03(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_03(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard2: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_04(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_04(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard3: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_01(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_01(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard3: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_02(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_02(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard3: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_03(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_03(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1
    execute on shard3: CREATE TABLE IF NOT EXISTS ORDER_ITEMS_04(ITEM_ID INT NOT NULL, ORDER_ID INT NOT NULL, ITEM_INFO VARCHAR(218) DEFAULT NULL, CREATE_DATE DATETIME NOT NULL,  CONSTRAINT PRIMARY KEY(ORDER_ID),  INDEX(CREATE_DATE),  CONSTRAINT FOREIGN KEY(ORDER_ID) REFERENCES ORDERS_04(ORDER_ID)) ENGINE = InnoDb DEFAULT CHARACTER SET = latin1 

````
#### 5.需求总是变化的，表增减字段，SQL执行变量了要加index,在OpendDDAL上也是分分钟搞定的事情
````java
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("EXPLAIN PLAN FOR ALTER TABLE  CUSTOMERS ADD IF NOT EXISTS GMT_TIME TIME");
            printResultSet(rs);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            JdbcUtils.closeSilently(rs);
            JdbcUtils.closeSilently(stmt);
            JdbcUtils.closeSilently(conn);
        }
````
执行结果
````sql
PLAN 
-------------------
MULTIPLE_EXECUTION
    execute on shard0: ALTER TABLECUSTOMERS_01 ADD COLUMN GMT_TIME TIME
    execute on shard0: ALTER TABLECUSTOMERS_02 ADD COLUMN GMT_TIME TIME
    execute on shard1: ALTER TABLECUSTOMERS_01 ADD COLUMN GMT_TIME TIME
    execute on shard1: ALTER TABLECUSTOMERS_02 ADD COLUMN GMT_TIME TIME
    execute on shard2: ALTER TABLECUSTOMERS_01 ADD COLUMN GMT_TIME TIME
    execute on shard2: ALTER TABLECUSTOMERS_02 ADD COLUMN GMT_TIME TIME
    execute on shard3: ALTER TABLECUSTOMERS_01 ADD COLUMN GMT_TIME TIME
    execute on shard3: ALTER TABLECUSTOMERS_02 ADD COLUMN GMT_TIME TIME 
````
#### 6.分布式唯一Sequence支持
````java
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.createStatement();
            int rows = stmt.executeUpdate(
                    "insert into CUSTOMERS values(customer_seq.nextval, 1000, '马云', '大老', '1965-01-20')");
            System.out.println(rows);
            rs = stmt.executeQuery("select last_insert_id()");
            rs.next();
            System.out.println("LAST_INSERT_ID: " + rs.getLong(1));
        } catch (Exception e) {
            Assert.fail();
        } finally {
            JdbcUtils.closeSilently(rs);
            JdbcUtils.closeSilently(stmt);
            JdbcUtils.closeSilently(conn);
        }
    
````
打印结果
````bash
1 
LAST_INSERT_ID: 1708
````
获取Sequence的方式可以通过：
````sql
select customer_seq.nextval dual
select customer_seq.currval dual
select nextval('customer_seq') dual
select currval('customer_seq') dual
select last_insert_id() dual
select last_insert_id() dual
````
