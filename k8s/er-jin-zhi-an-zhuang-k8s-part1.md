# 二进制安装K8s - part1

### 环境初始化

#### 节点规划

| Hostname             | 外网IP      | 内网IP        |
| -------------------- | --------- | ----------- |
| k8s-master-01        | 10.0.0.91 | 172.16.0.91 |
| k8s-master-02        | 10.0.0.92 | 172.16.0.92 |
| k8s-master-03        | 10.0.0.93 | 172.16.0.93 |
| k8s-node-01          | 10.0.0.94 | 172.16.0.94 |
| k8s-node-02          | 10.0.0.95 | 172.16.0.95 |
| k8s-master-vip（虚拟节点） | 10.0.0.96 | 172.16.0.96 |

#### 修改hosts

```bash
cat >> /etc/hosts <<EOF
172.16.0.91    k8s-master-01
172.16.0.92    k8s-master-02
172.16.0.93    k8s-master-03
172.16.0.94    k8s-node-01
172.16.0.95    k8s-node-02
172.16.0.96    k8s-master-vip
EOF

```

#### 集群各节点免密登录

```bash
yum install sshpass -y

ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_k8s_cluster -q

for ip_k8s_cluster in k8s-master-01 k8s-master-02 k8s-master-03 k8s-node-01 k8s-node-02
do
  sshpass -p "CentOS7.." ssh-copy-id -i ~/.ssh/id_k8s_cluster.pub -o StrictHostKeyChecking=no root@$ip_k8s_cluster
done

```

#### 关闭SeLinux

```bash
# 永久关闭
sed -i 's#enforcing#disabled#g' /etc/sysconfig/selinux

# 零时关闭
setenforce 0

```

#### 关闭 swap 分区

```bash
swapoff -a

sed -i.bak 's/^.*centos-swap/#&/g' /etc/fstab

echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet

```

#### 配置国内 YUM 源

```bash
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

yum makecache

# 更新系统（不更新内核）
yum update -y --exclud=kernel*

```

#### 升级系统内核版本

```bash
curl -o ./kernel-lt.el7.elrepo.x86_64.rpm https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-5.4.87-1.el7.elrepo.x86_64.rpm

curl -o ./kernel-lt-devel.el7.elrepo.x86_64.rpm https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-devel-5.4.87-1.el7.elrepo.x86_64.rpm

yum localinstall -y /kernel/kernel-lt*

grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --default-kernel

reboot

```

#### 安装 ipvs

```bash
yum install -y conntrack-tools ipvsadm ipset conntrack libseccomp

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
    /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /sbin/modprobe \${kernel_module}
        fi
    done
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs

```

#### 内核参数优化

```bash
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
fs.inotify.max_user_watches = 89100
fs.file-max = 52706963
fs.nr_open = 52706963
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp.keepaliv.probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp.max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp.max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.top_timestamps = 0
net.core.somaxconn = 16384
EOF

sysctl --system

```

#### 安装基础软件

```bash
yum install wget expect vim net-tools ntp bash-completion ipvsadm ipset jq iptables conntrack sysstat libseccomp -y

```

#### 关闭防火墙

```bash
systemctl disable --now firewalld

```



### 安装 Docker

{% content-ref url="../docker/an-zhuang-docker.md" %}
[an-zhuang-docker.md](../docker/an-zhuang-docker.md)
{% endcontent-ref %}



### 同步集群时间

```bash
yum install ntp -y

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' > /etc/timezone

ntpdate time2.aliyun.com

# 写入定时任务
*/1 * * * * ntpdate time2.aliyun.com > /dev/null 2>&1

```



### 集群证书

#### 安装 cfssl 证书生成工具

```bash
# 下载，可能会出现网站无法连接的情况
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

cd /server/tools/cfssl
# 设置执行权限
chmod +x cfssljson_linux-amd64
chmod +x cfssl_linux-amd64

# 移动到/usr/local/bin
mv cfssljson_linux-amd64 cfssljson
mv cfssl_linux-amd64 cfssl
mv cfssljson cfssl /usr/local/bin

```

#### 创建集群根证书

```bash
mkdir -p /opt/cert/ca

cat > /opt/cert/ca/ca-config.json <<EOF
{
  "signing":{
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "8760h"
      }
    }
  }
}
EOF

# 证书参数详解
# 1. default 是默认策略，指定证书默认有效期是 1 年
# 2. profiles 是定义使用场景，这里只是 kubernetes，其实可以定义多个场景，分别指定不同的过期时间,使用场 景等参数,后续签名证书时使用某个 profile;
# 3. signing: 表示该证书可用于签名其它证书,生成的 ca.pem 证书
# 4. server auth: 表示 client 可以用该 CA 对 server 提供的证书进行校验;
# 5. client auth: 表示 server 可以用该 CA 对 client 提供的证书进行验证。

```

#### 创建根 CA 证书签名请求文件

```bash
cat > /opt/cert/ca/ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "CN",
    "ST": "ShangHai",
    "L": "ShangHai"
  }]
}
EOF

# 证书详解
# C    国家
# ST   省
# L    城市
# O    组织
# OU   组织别名

```

#### 生成证书

```bash
cd /opt/cert/ca/

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# 参数详解
# gencert    生成新的 key(密钥)和签名证书
# --initca   初始化一个新 CA 证书

```



### 部署 Etcd 集群

#### Etcd 集群规划

| Etcd 节点 | IP          |
| ------- | ----------- |
| Etcd-01 | 172.16.0.91 |
| Etcd-02 | 172.16.0.92 |
| Etcd-03 | 172.16.0.93 |

#### 创建 Etcd 证书

```bash
mkdir -p /opt/cert/etcd
cd /opt/cert/etcd

cat > etcd-csr.json << EOF
{
  "CN": "etcd",
  "hosts": [
      "127.0.0.1",
      "172.16.0.91",
      "172.16.0.92",
      "172.16.0.93",
      "172.16.0.94",
      "172.16.0.95"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai"
    }
  ]
}
EOF

```

#### 生成证书

```bash
cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

# 参数详解
# gencert    生成新的 key(密钥)和签名证书
# -initca    初始化一个新 ca
# -ca-key    指明 ca 的证书
# -config    指明 ca 的私钥文件
# -profile   指明请求证书的 json 文件
# -ca        与 config 中的 profile 对应，是指根据 config 中的 profile 段来生成证书的相关信息

```

#### 分发证书

```bash
# 分发证书（此处分发到3个主节点上）
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@${ip} "mkdir -pv /etc/etcd/ssl"
  scp -i ~/.ssh/id_k8s_cluster ../ca/ca*.pem root@${ip}:/etc/etcd/ssl
  scp -i ~/.ssh/id_k8s_cluster ./etcd*.pem root@${ip}:/etc/etcd/ssl
done

```

```bash
# 查看分发结果
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@${ip} "hostname;ls -l /etc/etcd/ssl;echo"
done

```

#### 部署Etcd

```bash
# 下载 Etcd 安装包
mkdir -p /server/tools
cd /server/tools
# wget https://mirrors.huaweicloud.com/etcd/v3.4.14/etcd-v3.4.14-linux-amd64.tar.gz
wget https://mirrors.huaweicloud.com/etcd/v3.3.24/etcd-v3.3.24-linux-amd64.tar.gz

# 解压
tar xf etcd-v3.3.24-linux-amd64.tar.gz

# 分发至其他节点
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster ./etcd-v3.3.24-linux-amd64/etcd* root@$ip:/usr/local/bin/
done

```

#### 查看 Etcd 安装是否成功

```bash
# 查看 Etcd 安装结果
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@${ip} "hostname;/usr/local/bin/etcd --version;echo"
done

```

#### 注册 Etcd 服务

```bash
# 在三台节点上执行
mkdir -pv /etc/kubernetes/conf/etcd

ETCD_NAME=`hostname`
INTERNAL_IP=`hostname -i`
INITIAL_CLUSTER=k8s-master-01=https://172.16.0.91:2380,k8s-master-02=https://172.16.0.92:2380,k8s-master-03=https://172.16.0.93:2380

cat << EOF | sudo tee /usr/lib/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/ssl/etcd.pem \\
  --key-file=/etc/etcd/ssl/etcd-key.pem \\
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster \\
  --initial-cluster ${INITIAL_CLUSTER} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

```

配置项详解

| 配置选项                        | 选项说明                               |
| --------------------------- | ---------------------------------- |
| name                        | 节点名称                               |
| data-dir                    | 指定节点的数据存储目录                        |
| listen-peer-urls            | 与集群其它成员之间的通信地址                     |
| listen-client-urls          | 监听本地端口，对外提供服务的地址                   |
| initial-advertise-peer-urls | 通告给集群其它节点，本地的对等 URL 地址             |
| advertise-client-urls       | 客户端 URL，用于通告集群的其余部分信息              |
| initial-cluster             | 集群中的所有信息节点                         |
| initial-cluster-token       | 集群的 token，整个集群中保持一致                |
| initial-cluster-state       | 初始化集群状态，默认为 new                    |
| --cert-file                 | 客户端与服务器之间 TLS 证书文件的路径              |
| --key-file                  | 客户端与服务器之间 TLS 密钥文件的路径              |
| --peer-cert-file            | 对等服务器 TLS 证书文件的路径                  |
| --peer-key-file             | 对等服务器 TLS 密钥文件的路径                  |
| --trusted-ca-file           | 签名 client 证书的 CA 证书，用于验证 client 证书 |
| --peer-trusted-ca-file      | 签名对等服务器证书的 CA 证书                   |
| --trusted-ca-file           | 签名 client 证书的 CA 证书，用于验证 client 证书 |
| --peer-trusted-ca-file      | 签名对等服务器证书的 CA 证书                   |

#### 启动 Etcd

```bash
# 在三台节点上执行
systemctl enable --now etcd
systemctl status etcd

```

#### 测试 Etcd 集群

```bash
# 方式1
ETCDCTL_API=3 etcdctl \
--cacert=/etc/etcd/ssl/etcd.pem \
--cert=/etc/etcd/ssl/etcd.pem \
--key=/etc/etcd/ssl/etcd-key.pem \
--endpoints="https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379" \
endpoint status --write-out='table'

```

```bash
# 方式2
ETCDCTL_API=3 etcdctl \
--cacert=/etc/etcd/ssl/etcd.pem \
--cert=/etc/etcd/ssl/etcd.pem \
--key=/etc/etcd/ssl/etcd-key.pem \
--endpoints="https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379" \
member list --write-out='table'

```

