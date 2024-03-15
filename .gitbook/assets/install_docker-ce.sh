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
