Docker技术入门和实践
==

现在Docker技术很火，从2013年初诞生到现在，短短两年时间内，迅速成为最受欢迎的云计算开源项目。Docker作为新兴的虚拟化方式，它几乎动摇了传统虚拟化技术的地位，与传统的虚拟化方式相比，Docker具备更好的性能，更轻松的迁移和扩展，更简单的管理。

![](https://raw.githubusercontent.com/wplatform/blog/master/assets/docker001/0001.png) 

Docker的Logo 就很形象的表明了Docker的意图，一个系统可能需要一系列的软件及服务，如MySQL,redis,nignx,tomcat 等等，那这些集装箱就是用来打包这些部件，而把包好的部件便可以方便的进行运输和迁移，还是感觉挺“Build, Ship, and Run Any App, Anywhere”的。Docker提供轻量的虚拟化，最大的好处是基于你的应用配置能够无缝运行在任何平台上。它能让你将环境和配置放入代码然后部署，这实际是将应用环境和底层host环境实现了解耦。并通过配置文件可以轻松实现应用程序的自动化安装、部署和升级，可以很方便的把生产环境和开发环境分开，互不影响，这是 docker 最普遍的一个玩法。


#Docker相关的学习资料

##入门教程：

[https://docs.docker.com/](https://docs.docker.com/)  
[http://dockerpool.com/static/books/docker_practice/](http://dockerpool.com/static/books/docker_practice/)
[http://dockone.io/article/101](http://dockone.io/article/101/)

###Docker源码分析

[http://blog.daocloud.io/docker-source-code-analysis-part1/](http://blog.daocloud.io/docker-source-code-analysis-part1/)

###Docker相关概念​

-Docker Client：用户和 Docker 守护进程进行通信的接口，也就是 docker 命令。
-Docker 守护进程：宿主机上用于用户应答用户请求的服务。
-Docker Index：用户进行用户的私有、公有 Docker 容器镜像托管，也就是 Docker 仓库。
-Docker 容器：用于运行应用程序的容器，包含操作系统、用户文件和元数据。
-Docker 镜像：只读的 Docker 容器模板，简言之就是系统镜像文件。
-Dockerfile：进行镜像创建的指令文件。

###还需要了解一些liunx内核的知识，它们是Docker实现容器化资源隔离的支柱。

-Namespaces ：充当隔离的第一级。确保一个容器中运行一个进程而且不能看到或影响容器外的其它进程。
-Control Groups：是LXC的重要组成部分，具有资源核算与限制的关键功能。
-UnionFS：（文件系统）作为容器的构建块。为了支持Docker的轻量级以及速度快的特性，它创建了用户层。

##Docker软件安装

Docker要求在64位的linux环境中运行，对于windows及Mac OS ,可以装个virtualbox或 vmware软件虚拟出来一个linux环境。 当前Docker的版本为1.8.1,此版本要求3.8以上的kernal版本，否则需要升级linux内核。Docker的版本为1.7.1可以在2.6以上的kernal版本运行，这意味着可以在CentOS6中安装1.7.1的版本。大部分Linux环境下，在网络正常的况情下，只需要执行下面的命定就能完成安装，

```Bash

curl-sSL https://get.daocloud.io/docker | sh

```
CentOS，Redhat下面也可以通过rpm包的方式进行安装，在http://rpmfind.net/linux/rpm2html/search.php通过搜索docker-engine能找到安装包。Docker服务默认是开机启动的，可以通过 service docker start|stop|restart|status进行管理

##Docker实践

要用dockered的程序是一个分布式的服务框架，四个部件结构如图所示：

![](https://raw.githubusercontent.com/wplatform/blog/master/assets/docker001/0002.jpeg)

soa服务容器：服务提供方，包含服务容器和服务本身。
服务注册中心：服务启动成功后，容器向服务注册中心进行注册，当代理层需要调用一个服务时，代理层查询服务注册中心，获取所需服务的全部服务实例。
proxy：通过服务注册中心发现服务实例，为服务的调用提供HA、负载均衡等特性
sdk：服务消费方(客户端)

这四个部分分别打成独立的镜像，每个部分运行一个docker容器，相互之存通过网络进行通信。soa服务容器把自己的ip及端口上报给服务注册中心，同时接收来自proxy的服务调用，proxy端查询服务注册中心的服务实现代理客户器的请求。这样的一种网络交互，若用Docker默认的网络模式bridge，如果使用bridge模式是Docker默认的网络设置，soa服务端上报给服务中心的ip和端口是要以参数的方式传给soa服务端的，不不能把本地的ip和端口直接上报给服务中心，因为应用程序在docker容器获取的是一个内部私有IP，外部是无法访问的。


###SOA服务端的Dockerfile

```Bash

FROM centos

# Install Java.

ADD jdk1.8.0_60 /usr/local/jdk1.8.0_60

# sayhello-service-engine

ADD sayhello-service-engine /usr/local/sayhello-service-engine

# Define commonly used JAVA_HOME variable

ENV JAVA_HOME /usr/local/jdk1.8.0_60

ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

ENV PATH $PATH:$JAVA_HOME/bin

ENV PATH $PATH:/usr/local/sayhello-service-engine/bin

EXPOSE 1080

# Define working directory.

WORKDIR /usr/local/sayhello-service-engine

VOLUME ["/usr/local/sayhello-service-engine/logs"]

#start ops-proxy

#ENTRYPOINT ["osp-default.sh start"]

# Define default command.

CMD ["osp-default.sh", "start"]

```


SOA服务端需要向外部提供服务，在Dockerfile通过EXPOSE 把1080端口映射了出去，运行时可以通过-p进行host端口映射，同时应用需要输出日志，VOLUME提供了host目录挂载到容器目录的功能，运行时可以通过-v提定

###Proxy端的Dockerfile

```Bash

# Pull base image.

FROM centos

# Install Java.

ADD jdk1.8.0_60 /usr/local/jdk1.8.0_60

# Install osp-proxy

ADD osp-proxy-2.4.9 /usr/local/osp-proxy-2.4.9

# Define commonly used JAVA_HOME variable

ENV JAVA_HOME /usr/local/jdk1.8.0_60

ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

ENV PATH $PATH:$JAVA_HOME/bin

ENV PATH $PATH:/usr/local/osp-proxy-2.4.9/bin

EXPOSE 2080

# Define working directory.

WORKDIR /usr/local/osp-proxy-2.4.9

VOLUME ["/usr/local/osp-proxy-2.4.9/logs"]

#START OPS-PROXY

#ENTRYPOINT ["OSP-PROXY-DEFAULT.SH START"]

# DEFINE DEFAULT COMMAND.

CMD ["osp-proxy-default.sh", "start"]

```

##运行docker容器

###运行SOA服务端​

```Bash

docker run -d \
> -e VIP_CFGCENTER_ZK_CONNECTION=10.101.18.110:2181,10.101.18.111:2181,10.101.18.112:2181 \
> –e EXPORT_IP=192.168.89.61 –e EXPORT_PROT=1080 –p1080:1080 \
> –v /apps/logs/osp-prox:usr/local/sayhello-service-engine/logs \
> sayhello-osp-engine 

```

 ##运行SOA Proxy

```Bash
docker run –d \
> -e VIP_CFGCENTER_ZK_CONNECTION=10.101.18.110:2181,10.101.18.111:2181,10.101.18.112:2181 \
> –p2080:2080 \
> –v /apps/logs/osp-prox:/usr/local/osp-proxy-2.4.9/logs \
>  osp-proxy

```