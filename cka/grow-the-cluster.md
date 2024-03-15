# Grow the Cluster

## Grow the Cluster on Ubuntu

### 环境准备

| 环境       | 说明                                 |
| -------- | ---------------------------------- |
| 操作系统     | Ubuntu 18.04.5 LTS (Bionic Beaver) |
| IP       | 10.0.0.32                          |
| Hostname | worker01                           |
| Swap     | off                                |
| ufw      | stop、disable                       |
| 安装软件     | vim、curl、net-tools                 |

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

###

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

#### 6. 查看 token ，生成 token（cp节点）

```bash
sudo kubeadm token list

# 在 cp 节点上执行此命令，默认情况下 token 的有效期为两小时，若过期则需要重新生成
```

```bash
sudo kubeadm token create

```

#### 7. 创建 Discovery Token CA Cert Hash（cp节点）

```bash
openssl x509 -pubkey \
-in /etc/kubernetes/pki/ca.crt | openssl rsa \
-pubin -outform der 2>/dev/null | openssl dgst \
-sha256 -hex | sed 's/ˆ.* //'

```

#### 8. 在 worker01 节点上添加 cp 节点的本地DNS别名

```bash
echo "10.0.0.31 k8scp" >> /etc/hosts

# 此处的 10.0.0.31 为本机IP

```

#### 9. 在 worker01 节点上使用6、7步骤生成的 token 和 hash 加入集群

```bash
kubeadm join \
--token 2whe18.jhey74xlprijyesa \
k8scp:6443 \
--discovery-token-ca-cert-hash \
sha256:625dff507aa413d63425ba42030866a8cd4441d959aa431b51cf7824938df0e8

```

#### 10. cp 节点上查看节点

```bash
kubectl get nodes

```

