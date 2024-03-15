# dockerfile

### dockerfile常用参数

| 参数         | 说明                              |
| ---------- | ------------------------------- |
| FROM       | 指定基础镜像                          |
| MAINTAINER | 指定维护者信息                         |
| LABEL      | 描述、标签                           |
| RUN        | 在命令前面添加                         |
| ADD        | 添加文件，会自动解压tar                   |
| WORKDIR    | 设置当前工作目录                        |
| VOLUME     | 设置卷，挂载主机目录（无法指定主机上对应的目录，是自动生成的） |
| EXPOSE     | 指定对外开放的端口                       |
| CMD        | 指定容器启动后要执行的命令（容易被替换）            |
| COPY       | 复制文件，不解压                        |
| ENV        | 环境变量                            |
| ENTRYPOINT | 容器启动后执行的命令（无法被替换，会被当成参数）        |

{% hint style="info" %}
ADD 与 COPY 的文件需放在当前目录下，否则会提示找不到文件
{% endhint %}

{% hint style="info" %}
VOLUME \<DIR> 跟 -v \<DIR> 效果一样

\-v 的标记只设置了容器的挂载点，并没有指定关联的主机目录。这时docker会自动绑定主机上的一个目录，可 通过 docker inspect  命令查看
{% endhint %}

#### 容器共享卷

```bash
docker run --name test2 -it --volumes-from test1 centos:6.9 /bin/bash

# 此命令将会使容器test2和test1共享卷
```



### 案例演示

> 使用dockerfile构建基于centos6.9的镜像，要求部署nginx环境，外部通过80端口可访问，部署SSH服务，通过22端口可访问（用户使用root账户访问，密码为docker run最后一个参数，如果未指定则使用123456）

#### dockerfile内容

```
FROM centos:6.9

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
RUN curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
RUN yum install nginx -y
RUN yum install openssh-server -y

EXPOSE 80 22
ENV SSH_PASS=123456
ADD init.sh /
ENTRYPOINT ["/bin/bash","/init.sh"]
```

#### init.sh内容

```bash
#!/bin/bash

if [ ! -z $1 ]; then
    SSH_PASS=$1
fi
echo "$SSH_PASS" | passwd --stdin root
service sshd start
nginx -g 'daemon off;'
```



### 优化dockerfile减小镜像体积

* 选择体积小的linux
* 合并RUN指令，清理无用文件（YUM缓存，源码包）
* 修改dockerfile，把变化的内容尽可能放在dockerfile结尾
* 使用.dockerignore 减少不必要的ADD指令



### 构建命令 docker build

```bash
docker build -t will/ubuntu_test:v1 -f /path/to/a/Dockerfile .

# -t 指定构建镜像的名称和版本号
# -f /path/to/a/Dockerfile 指定Dockerfile文件的位置
```

