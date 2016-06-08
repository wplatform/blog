#### OpenDDAL的JDBC Statement的QueryTimeout处理过程 
statement timeout用来限制statement的执行时长，单位为秒，timeout的值通过调用JDBC的java.sql.Statement.setQueryTimeout(int timeout) API进行设置。

1. 调用JdbcStatement.setQueryTimeout时,oppenddal设置session的queryTimeout
2. 调用Statement的executeQuery()方法，oppenddal记录Statement执行的开始时间为now,结速时间为now + queryTimeout
3. session处理数据将queryTimeout代理给物理的jdbc Statement，并检查是否处理时间超过Statement执行结速时间
4. 达到超时时间 
5. session终止数据处理，调用所有处理数据所打开的底层Statement的cancel()方法取消执行
6. session抛出query timeout异常
7. 调用JdbcStatement.close方法，session关闭所有处理数据所打开的底层Statement
