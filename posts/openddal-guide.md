#### Getting started

#### Configuration

#### JDBC-API

#### Server

#### 路由规则

#### SQL优化器

#### 分布式SQL引擎
OpenDDAL SQL引擎把SQL类为4类

1. 无数据表访问的SQL，如：select 1+1, select seq.nextval等，此类SQL直接于OpenDDAL SQL引擎直接处理。
2. JoinFree SQL,SQL无需按表进行折分，通过路由规则计算的结果只一个结点上执行，OpenDDAL无需作任何的处理，直接发到db上执行。
3. JoinFree SQL,SQL无需按表进行折分，通过路由规则计算的结果在多个结点上执行，分组查询需要改写SQL Select字段，OpenDDAL负责查询结果集的合并、排序、分组汇总操作。
4. 跨库Join SQL


#### 读写分离及HA

#### 事务支持

#### 分布式Sequence之hilo算法实现
hilo主键生成策略的就是为了提高序列生成的效率问题，它改善了每次生成一个顺列都必须查询一遍数据库的模式，取而代之的是向数据库申请一段范围的序列号，生成这范围内的顺列无需访问数据库。hilo需要数据库的辅助表或sequence记录范围号，并控制多个顺列实列申请的范围不能重复，保证集群的唯一性。

OpenDDAL维护如下的表结构用于存放sequence序列状态

| sequence_name | next_val |
|:---|:---:|
| test_sequence | 2 |

hilo 辅助表中的next_val数值是范围的序号。其含义就是一段连续可分配的整数，如：1-10，50-100 等。桶的容量即是 cacheSize 的值，假定 cacheSize 的值为 100，那么范围的序号和每个范围容纳的整数可参看下表：

| 序号 | 1 | 2 | 3 | 4 | 5 | ... |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| 范围 | 1-100 | 101-200 | 201-300 | 301-400 | 401-500 | ... |

#### OpenDDAL的JDBC Statement的QueryTimeout处理过程 
Statement queryTimeout用来限制statement的执行时长，单位为秒，timeout的值通过调用JDBC的java.sql.Statement.setQueryTimeout(int timeout) API进行设置。OpenDDAL完成一次statement执行可能会访问多个结节的数据,会创建多个数据处理的handler,HandlerHolderProxy的职责就是记录这些handler，方便session对运行的statement执行资源控制。

1. 调用JdbcStatement.setQueryTimeout时,oppenddal设置session的queryTimeout
2. 调用Statement的executeQuery()方法，oppenddal记录Statement执行的开始时间为now,结速时间为now + queryTimeout
3. session处理数据将queryTimeout代理给物理的jdbc Statement，并检查是否处理时间超过Statement执行结速时间
4. 达到超时时间 
5. session终止数据处理，调用所有处理数据所打开的底层Statement的cancel()方法取消执行
6. session抛出query timeout异常
7. 调用close方法，session关闭所有处理数据所打开的底层Statement

#### 使用限制
1. 为保证数据的正确性, update语句不支持修改表的切分字段值，切分字段值确定数据存放的位置。
2. 跨库的分页操作，会在内存中进行，支持limit中的offset在 10000 以内。
