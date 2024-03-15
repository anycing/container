# Install Kubernetes

## Use kubeadm on Ubuntu

### 环境准备

| 环境       | 说明                                 |
| -------- | ---------------------------------- |
| 操作系统     | Ubuntu 18.04.5 LTS (Bionic Beaver) |
| IP       | 10.0.0.31                          |
| Hostname | k8scp                              |
| Swap     | off                                |
| ufw      | stop、disable                       |
| 安装软件包    | vim、curl、net-tools                 |

```bash
# sudo执行命令
sudo -i

# 更新系统
apt-get update && apt-get upgrade -y

# 关闭swap分区
swapoff -a
#vim /etc/fstab
#注释掉/swapfile所在行

# 关闭并禁用防火墙
systemctl stop ufw
systemctl disable ufw

# 安装软件包
apt-get install curl net-tools vim -y

```

### K8s部署

#### 1. 安装 Docker

```bash
apt-get install docker.io -y

```

#### 2. 配置 K8s 源

```bash
cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# 由于网络原因，此处使用国内阿里云的源
# 官方源如下：
# deb  http://apt.kubernetes.io/  kubernetes-xenial  main
```

#### 3. 为软件包添加 GPG 密钥

```bash
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg \
| apt-key add -

# 此处使用阿里云的密钥
# 官方密钥地址如下：
# https://packages.cloud.google.com/apt/doc/apt-key.gpg

```

#### 4. 更新软件仓库

```bash
apt-get update

```

#### 5. 安装 kubeadm

```bash
apt-get install -y \
kubeadm=1.20.1-00 kubelet=1.20.1-00 kubectl=1.20.1-00

```

```bash
apt-mark hold kubelet kubeadm kubectl

```

#### 6. 下载网络插件 Calico 的配置文件

```bash
wget https://docs.projectcalico.org/manifests/calico.yaml


# less calico.yaml
# 预览 Calico 的配置文件

# 下面这两行是Clico网络的网段，分配给容器的IPV4池
# - name: CALICO_IPV4POOL_CIDR
#   value: "192.168.0.0/16"
```

#### 7. 为 CP 节点添加本地DNS别名

```bash
echo "10.0.0.31 k8scp" >> /etc/hosts

# 此处的 10.0.0.31 为本机IP

```

#### 8. 创建 kubeadm 的配置文件

```bash
cat > kubeadm-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: 1.20.1
controlPlaneEndpoint: "k8scp:6443"
networking:
  podSubnet: 192.168.0.0/16
imageRepository: registry.aliyuncs.com/google_containers
EOF

# 此处用国内阿里云的仓库安装
# 若是官方源安装，则省掉 imageRepository 这一项

```

#### 9. 初始化 CP 节点

```bash
kubeadm init --config=kubeadm-config.yaml --upload-certs \
| tee kubeadm-init.out

```

#### 10. 非 root 用户访问集群，查看配置文件

```bash
# 退出 root 用户
exit

# 根据步骤9的输出操作如下
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 查看配置文件
less .kube/config

```

#### 11. 应用 Calico 网络配置

```bash
sudo cp /root/calico.yaml .
kubectl apply -f calico.yaml

```

#### 12. 安装 bash-completion 软件包

```bash
sudo apt-get install bash-completion -y

exit
# 退出再登录
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# 由于kubectl命令太长，此处安装bash自动补全来简化输入

```

#### 13. 查看集群配置（创建时使用的kubeadm-config.yaml）

```bash
sudo kubeadm config print init-defaults

```



## Use kubeadm on CentOS
