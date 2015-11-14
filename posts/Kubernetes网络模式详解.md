Kubernetes网络详解
==

Kubernetes是Google开源的容器集群管理系统，其提供应用部署、维护、 扩展机制等功能，利用Kubernetes能方便地管理跨机器运行容器化的应用。本质上可看作是基于容器技术的PaaS平台.在Kubernetes框架中有4种不同的网络问题要解决：

- Highly-coupled container-to-container communications
- Pod-to-Pod communications
- Pod-to-Service communications
- External-to-internal communications

#1. container-to-container

Pod是容器的集合,Pod包含的容器都运行在同一个Host上，Pod会额外运行一个叫google_containers/pause的docker容器,它是Netowrk Container，它不做任何事情，只是用来接管Pod的网络。其他的容器使用—net=container的方式使其它容器拥用同样的网络空间。

#2. Pod-to-Pod

其网络模式实现了每一个pod有一个独立的IP地址，使用这个IP地址可以直接与其他机器上的容器通信。

#3. Pod-to-Service


#4. External-to-internal


#5. 总结


一
