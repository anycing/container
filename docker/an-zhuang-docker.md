# 安装Docker

### 详细安装步骤

#### 配置阿里docker-ce源

> [https://mirrors.aliyun.com/docker-ce/](https://mirrors.aliyun.com/docker-ce/)

```bash
# 安装必要的一些系统工具
yum install yum-utils device-mapper-persistent-data lvm2 -y

# 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 更新yum
yum makecache fast
```

#### docker-ce 软件包安装

```bash
yum install docker-ce -y
```

#### 查看信息

```bash
# 启动服务端
systemctl start docker
systemctl enable docker


# 查看信息
docker version
```

#### 配置 docker 镜像加速

```bash
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://2cky5149.mirror.aliyuncs.com"]
}
EOF

# 添加非ssl仓库访问
# "insecure-registries": ["registry:5000"]

# 修改默认存储路径为 /usr/local/docker_data
# "storage-driver": "overlay2",
# "data-root": "/usr/local/docker_data"
```

#### 重启并启动测试容器

```bash
systemctl daemon-reload
systemctl restart docker

docker run -d -p 80:80 nginx

# run 创建并启动一个容器
# -d 放在后台
# -p 端口映射
# nginx 镜像的名称
```



### 一键安装脚本

```bash
#!/bin/bash

# 安装必要的一些系统工具
yum install yum-utils device-mapper-persistent-data lvm2 -y

# 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 更新yum
yum makecache fast


# 安装docker-ce软件包
yum install docker-ce -y


# 启动服务端
systemctl start docker
systemctl enable docker


# 查看信息
docker version


# 配置镜像加速
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://2cky5149.mirror.aliyuncs.com"]
}
EOF

# 重启服务端
systemctl restart docker

```

