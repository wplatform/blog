#### JDBC-API的JDBC Statement的QueryTimeout处理过程 
statement timeout用来限制statement的执行时长，timeout的值通过调用JDBC的java.sql.Statement.setQueryTimeout(int timeout) API进行设置。
1. 通过调用Connection的createStatement()方法创建statement 
2. 调用Statement的executeQuery()方法 
3. statement通过自身connection将query发送给MySQL数据库 
4. statement创建一个新的timeout-execution线程用于超时处理 
5. 5.1版本后改为每个connection分配一个timeout-execution线程 
6. 向timeout-execution线程进行注册 
7. 达到超时时间 
6. TimerThread调用JtdsStatement实例中的TsdCore.cancel()方法 
7. timeout-execution线程创建一个和statement配置相同的connection 
8. 使用新创建的connection向超时query发送cancel query（KILL QUERY “connectionId”） 
