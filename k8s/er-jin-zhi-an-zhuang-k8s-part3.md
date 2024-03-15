# 二进制安装K8s - part3

## 部署 master 节点

### 下载二进制组件

```bash
cd /server/tools

# 下载 server 安装包
wget https://dl.k8s.io/v1.18.14/kubernetes-server-linux-amd64.tar.gz

# 下载 client 安装包
wget https://dl.k8s.io/v1.18.14/kubernetes-client-linux-amd64.tar.gz

# 下载 node 安装包
wget https://dl.k8s.io/v1.18.14/kubernetes-node-linux-amd64.tar.gz

```

### 分发组件

```bash
tar -xf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/

for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster kube-apiserver kube-controller-manager kube-scheduler kubectl kubelet kube-proxy root@$ip:/usr/local/bin/
done

```

####

### 创建集群配置文件

> 在 kubernetes 中，我们需要创建一个配置文件，用来配置集群、用户、命名空间及身份认证等信息。

```bash
cd /opt/cert/k8s/

```

#### 创建 kube-controller-manager.kubeconfig 文件

```bash
export KUBE_APISERVER="https://172.16.0.96:8443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials "kube-controller-manager" \
  --client-certificate=/etc/kubernetes/ssl/kube-controller-manager.pem \
  --client-key=/etc/kubernetes/ssl/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

# 设置上下文参数(在上下文参数中将集群参数和用户参数关联起来)
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kube-controller-manager" \
  --kubeconfig=kube-controller-manager.kubeconfig

# 配置默认上下文
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig


# 参数详解
# 1. --certificate-authority:验证 kube-apiserver 证书的根证书。
# 2. --client-certificate、--client-key:刚生成的 kube-controller-manager 证书和私钥，连接 kube-apiserver 时使用。
# 3. --embed-certs=true:将 ca.pem 和 kube-controller-manager 证书内容嵌入到生成的 kubectl.kubeconfig 文件中(不加时，写入的是证书文件路径)。

```

#### 创建 kube-scheduler.kubeconfig 文件

```bash
export KUBE_APISERVER="https://172.16.0.96:8443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials "kube-scheduler" \
  --client-certificate=/etc/kubernetes/ssl/kube-scheduler.pem \
  --client-key=/etc/kubernetes/ssl/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

# 设置上下文参数(在上下文参数中将集群参数和用户参数关联起来)
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kube-scheduler" \
  --kubeconfig=kube-scheduler.kubeconfig
  
# 配置默认上下文
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

```

#### 创建 kube-proxy.kubeconfig 文件

```bash
export KUBE_APISERVER="https://172.16.0.96:8443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
  
# 设置客户端认证参数
kubectl config set-credentials "kube-proxy" \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
  
# 设置上下文参数(在上下文参数中将集群参数和用户参数关联起来)
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kube-proxy" \
  --kubeconfig=kube-proxy.kubeconfig
  
# 配置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

```

#### 创建 admin.kubeconfig 文件

```bash
export KUBE_APISERVER="https://172.16.0.96:8443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=admin.kubeconfig
  
# 设置客户端认证参数
kubectl config set-credentials "admin" \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --client-key=/etc/kubernetes/ssl/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig
  
# 设置上下文参数(在上下文参数中将集群参数和用户参数关联起来)
kubectl config set-context default \
  --cluster=kubernetes \
  --user="admin" \
  --kubeconfig=admin.kubeconfig

# 配置默认上下文
kubectl config use-context default --kubeconfig=admin.kubeconfig

```



### 配置 TLS bootstrapping

#### 生成 TLSbootstrapping 所需 token

```bash
# 必须要用自己机器创建的 Token
TLS_BOOTSTRAPPING_TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`

cat > token.csv << EOF
${TLS_BOOTSTRAPPING_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

cat token.csv

```

#### 创建 TLSBootstrapping 集群配置文件

{% hint style="danger" %}
设置客户端认证参数,此处 token 必须用上叙 token.csv 中的 token
{% endhint %}

```bash
export KUBE_APISERVER="https://172.16.0.96:8443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kubelet-bootstrap.kubeconfig

# 设置客户端认证参数,此处 token 必须用上叙 token.csv 中的 token
kubectl config set-credentials "kubelet-bootstrap" \
  --token=2f6f1baddb93966a4b851a5dea8e1438 \
  --kubeconfig=kubelet-bootstrap.kubeconfig
  
# 设置上下文参数(在上下文参数中将集群参数和用户参数关联起来)
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kubelet-bootstrap" \
  --kubeconfig=kubelet-bootstrap.kubeconfig
  
# 配置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig

```

#### 创建 TLS 匿名用户

```bash
# 此步放在kubelet启动之前做，只在master-01上执行
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap

```



### 分发集群配置文件

```bash
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "mkdir -p /etc/kubernetes/cfg"
  scp -i ~/.ssh/id_k8s_cluster kube-scheduler.kubeconfig kube-controller-manager.kubeconfig admin.kubeconfig kube-proxy.kubeconfig kubelet-bootstrap.kubeconfig token.csv root@$ip:/etc/kubernetes/cfg
done

```



### 部署 api-server

#### 创建 kube-apiserver 服务配置文件

> 三个节点都要执行，不能复制，注意 api server IP

```bash
KUBE_APISERVER_IP=`hostname -i`

cat > /etc/kubernetes/cfg/kube-apiserver.conf << EOF
KUBE_APISERVER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--advertise-address=${KUBE_APISERVER_IP} \\
--default-not-ready-toleration-seconds=360 \\
--default-unreachable-toleration-seconds=360 \\
--max-mutating-requests-inflight=2000 \\
--max-requests-inflight=4000 \\
--default-watch-cache-size=200 \\
--delete-collection-workers=2 \\
--bind-address=0.0.0.0 \\
--secure-port=6443 \\
--allow-privileged=true \\
--service-cluster-ip-range=10.96.0.0/16 \\
--service-node-port-range=10-52767 \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--enable-bootstrap-token-auth=true \\
--token-auth-file=/etc/kubernetes/cfg/token.csv \\
--kubelet-client-certificate=/etc/kubernetes/ssl/server.pem \\
--kubelet-client-key=/etc/kubernetes/ssl/server-key.pem \\
--tls-cert-file=/etc/kubernetes/ssl/server.pem \\
--tls-private-key-file=/etc/kubernetes/ssl/server-key.pem \\
--client-ca-file=/etc/kubernetes/ssl/ca.pem \\
--service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=3 \\
--audit-log-maxsize=100 \\
--audit-log-path=/var/log/kubernetes/k8s-audit.log \\
--etcd-servers=https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379 \\
--etcd-cafile=/etc/etcd/ssl/ca.pem \\
--etcd-certfile=/etc/etcd/ssl/etcd.pem \\
--etcd-keyfile=/etc/etcd/ssl/etcd-key.pem"
EOF

```

#### **参数详解**

| 配置选项                                     | 选项说明                                                      |
| ---------------------------------------- | --------------------------------------------------------- |
| --logtostderr=false                      | 输出日志到文件中，不输出到标准错误控制台                                      |
| --v=2                                    | 指定输出日志的级别                                                 |
| --advertise-address                      | 向集群成员通知 apiserver 消息的 IP 地址                               |
| --etcd-servers                           | 连接的 etcd 服务器列表                                            |
| --etcd-cafile                            | 用于 etcd 通信的 SSL CA 文件                                     |
| --etcd-certfile                          | 用于 etcd 通信的的 SSL 证书文件                                     |
| --etcd-keyfile                           | 用于 etcd 通信的 SSL 密钥文件                                      |
| --service-cluster-ip-range               | Service 网络地址分配                                            |
| --bind-address                           | 监听 --seure-port 的 IP 地址，如果为空，则将使用所有接口 (0.0.0.0)           |
| --secure-port=6443                       | 用于监听具有认证授权功能的 HTTPS 协议的端口，默认值是 6443                       |
| --allow-privileged                       | 是否启用授权功能                                                  |
| --service-node-port-range                | Service 使用的端口范围                                           |
| --default-not-ready-toleration-seconds   | 表示 notReady 状态的容忍度秒数                                      |
| --default-unreachable-toleration-seconds | 表示 unreachable 状态的容忍度秒数                                   |
| --max-mutating-requests-inflight=2000    | 在给定时间内进行中可变请求的最大数量，0 值表示没有限制(默 认值 200)                    |
| --default-watch-cache-size=200           | 默认监视缓存大小，0 表示对于没有设置默认监视大小的资源，将 禁用监视缓存                     |
| --delete-collection-workers=2            | 用于 DeleteCollection 调用的工作者数量，这被用于加速 namespace 的清理( 默认值 1) |
| --enable-admission-plugins               | 资源限制的相关配置                                                 |
| --authorization-mode                     | 在安全端口上进行权限验证的插件的顺序列表，以逗号分隔的列 表                            |

#### **注册 kube-apiserver 服务**

```bash
cat > /usr/lib/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/cfg/kube-apiserver.conf
ExecStart=/usr/local/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure
RestartSec=10
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

```

#### **分发 kube-apiserver 服务脚本**

```bash
for ip in k8s-master-02 k8s-master-03;
do
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/kube-apiserver.service root@$ip:/usr/lib/systemd/system/kube-apiserver.service
done

```

#### **启动**

```bash
# 3个master节点都要执行
# 创建 kubernetes 日志目录
mkdir -p /var/log/kubernetes/

systemctl daemon-reload
systemctl enable --now kube-apiserver
systemctl status kube-apiserver

```



### 高可用部署 api-server

负载均衡器有很多种，只要能实现 api-server 高可用都行，这里我们采用官方推荐的 haproxy + keepalived

#### 安装高可用软件

```bash
# 在三个 master 节点执行
yum install -y keepalived haproxy

mv -f /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_bak

```

#### 配置haproxy服务

```bash
cat > /etc/haproxy/haproxy.cfg <<EOF
global
  maxconn 2000
  ulimit-n 16384
  log 127.0.0.1 local0 err
  stats timeout 30s

defaults
  log global
  mode http
  option httplog
  timeout connect 5000
  timeout client 50000
  timeout server 50000
  timeout http-request 15s
  timeout http-keep-alive 15s

frontend monitor-in
  bind *:33305
  mode http
  option httplog
  monitor-uri /monitor

listen stats
  bind *:8006
  mode http
  stats enable
  stats hide-version
  stats uri /stats
  stats refresh 30s
  stats realm Haproxy\ Statistics
  stats auth admin:admin

frontend k8s-master
  bind 0.0.0.0:8443
  bind 127.0.0.1:8443
  mode tcp
  option tcplog
  tcp-request inspect-delay 5s
  default_backend k8s-master

backend k8s-master
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server k8s-master-01 172.16.0.91:6443 check inter 2000 fall 2 rise 2 weight 100
  server k8s-master-02 172.16.0.92:6443 check inter 2000 fall 2 rise 2 weight 100
  server k8s-master-03 172.16.0.93:6443 check inter 2000 fall 2 rise 2 weight 100
EOF

```

#### 分发至其他节点

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /etc/haproxy/haproxy.cfg root@$ip:/etc/haproxy/haproxy.cfg
done

```

#### 启动 haproxy 服务

```bash
# 在3个master节点都要执行
# 打开链接策略
# setsebool -P haproxy_connect_any=1

# 若启动不成功则执行上方打开链接策略命令
systemctl enable --now haproxy
systemctl status haproxy

```

#### 配置 keepalived 服务

```bash
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf_bak

cd /etc/keepalived

cat > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script chk_kubernetes {
    script "/etc/keepalived/check_kubernetes.sh"
    interval 2
    weight -5
    fall 3
    rise 2
}
vrrp_instance VI_1 {
    state MASTER
    interface eth1
    mcast_src_ip 172.16.0.91
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass K8SHA_KA_AUTH
    }
    virtual_ipaddress {
        172.16.0.96
    }
#    track_script{
#        chk_kubernetes
#    }
}
EOF

# 注意上方的 interface 网卡需要与对应的IP保持一致

```

#### 设置监控检查脚本

```bash
cat > /etc/keepalived/check_kubernetes.sh <<EOF
#!/bin/bash

function chech_kubernetes() {
  for ((i=0;i<5;i++))
  do
    apiserver_pid_id=$(pgrep kube-apiserver)
    if [[ ! -z $apiserver_pid_id ]];then
      return
    else
      sleep 2
    fi
    apiserver_pid_id=0
  done
}

# 1:running 0:stopped
check_kubernetes
if [[ $apiserver_pid_id -eq 0 ]];then
  /usr/bin/systemctl stop keepalived
  exit 1
else
  exit 0
fi
EOF

chmod +x /etc/keepalived/check_kubernetes.sh

```

#### 分发 keepalived 配置文件

```bash
for ip in k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "mv -f /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf_bak"
  scp -i ~/.ssh/id_k8s_cluster /etc/keepalived/keepalived.conf /etc/keepalived/check_kubernetes.sh root@$ip:/etc/keepalived/
done

```

#### 配置 k8s-master-02 节点

```bash
sed -i 's#state MASTER#state BACKUP#g' /etc/keepalived/keepalived.conf
sed -i 's#172.16.0.91#172.16.0.92#g' /etc/keepalived/keepalived.conf
sed -i 's#priority 100#priority 90#g' /etc/keepalived/keepalived.conf

```

#### 配置 k8s-master-03 节点

```bash
sed -i 's#state MASTER#state BACKUP#g' /etc/keepalived/keepalived.conf
sed -i 's#172.16.0.91#172.16.0.93#g' /etc/keepalived/keepalived.conf
sed -i 's#priority 100#priority 80#g' /etc/keepalived/keepalived.conf

```

#### 启动 keeplived 服务

```bash
# 在3个master节点都要执行
systemctl enable --now keepalived
systemctl status keepalived

```



### 部署 kube-controller-manager

#### 创建 kube-controller-manager 配置文件

```bash
cat > /etc/kubernetes/cfg/kube-controller-manager.conf << EOF
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--leader-elect=true \\
--cluster-name=kubernetes \\
--bind-address=127.0.0.1 \\
--allocate-node-cidrs=true \\
--cluster-cidr=10.244.0.0/12 \\
--service-cluster-ip-range=10.96.0.0/16 \\
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--root-ca-file=/etc/kubernetes/ssl/ca.pem \\
--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--kubeconfig=/etc/kubernetes/cfg/kube-controller-manager.kubeconfig \\
--tls-cert-file=/etc/kubernetes/ssl/kube-controller-manager.pem \\
--tls-private-key-file=/etc/kubernetes/ssl/kube-controller-manager-key.pem \\
--experimental-cluster-signing-duration=87600h0m0s \\
--controllers=*,bootstrapsigner,tokencleaner \\
--use-service-account-credentials=true \\
--node-monitor-grace-period=10s \\
--horizontal-pod-autoscaler-use-rest-clients=true"
EOF

```

#### 配置文件详解

| 配置选项                                    | 选项说明                                                                |
| --------------------------------------- | ------------------------------------------------------------------- |
| --leader-elect                          | 高可用时启用选举功能                                                          |
| --master                                | 通过本地非安全本地端口 8080 连接 apiserver                                       |
| --bind-address                          | 监控地址                                                                |
| --allocate-node-cidrs                   | 是否应在 node 节点上分配和设置 Pod 的 CIDR                                       |
| --cluster-cidr                          | Controller Manager 在启动时如果设置了--cluster-cidr 参 数，防止不同的节点的 CIDR 地址发生冲突 |
| --service-cluster-ip-range              | 集群 Services 的 CIDR 范围                                               |
| --cluster-signing-cert-file             | 指定用于集群签发的所有集群范围内证书文件(根证书 文件)                                        |
| --cluster-signing-key-file              | 指定集群签发证书的 key                                                       |
| --root-ca-file                          | 如果设置，该根证书权限将包含 service acount 的 toker secret，这必须是一个有效的 PEM 编码 CA 包  |
| --service-account-private-key-file      | 包含用于签署 service account token 的 PEM 编码 RSA 或 者 ECDSA 私钥的文件名          |
| --experimental-cluster-signing-duration | 证书签发时间                                                              |

#### 注册 kube-controller-manager 服务

```bash
cat > /usr/lib/systemd/system/kube-controller-manager.service << EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/cfg/kube-controller-manager.conf
ExecStart=/usr/local/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

```

#### 分发脚本

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /etc/kubernetes/cfg/kube-controller-manager.conf root@$ip:/etc/kubernetes/cfg
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/kube-controller-manager.service root@$ip:/usr/lib/systemd/system/kube-controller-manager.service
done

```

#### 启动

```bash
# 分别在三个 master 节点上启动
systemctl daemon-reload
systemctl enable --now kube-controller-manager
systemctl status kube-controller-manager

```



### 部署 kube-scheduler 服务

#### 创建kube-scheduler配置文件

```bash
cat > /etc/kubernetes/cfg/kube-scheduler.conf << EOF
KUBE_SCHEDULER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--kubeconfig=/etc/kubernetes/cfg/kube-scheduler.kubeconfig \\
--leader-elect=true \\
--master=http://127.0.0.1:8080 \\
--bind-address=127.0.0.1 "
EOF

```

#### 创建启动脚本

```bash
cat > /usr/lib/systemd/system/kube-scheduler.service << EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/cfg/kube-scheduler.conf
ExecStart=/usr/local/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

```

#### 分发配置文件

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/kube-scheduler.service root@${ip}:/usr/lib/systemd/system
  scp -i ~/.ssh/id_k8s_cluster /etc/kubernetes/cfg/kube-scheduler.conf root@${ip}:/etc/kubernetes/cfg
done

```

#### 启动

```bash
# 分别在三台 master 节点上启动
systemctl daemon-reload
systemctl enable --now kube-scheduler
systemctl status kube-scheduler

```

#### 查看集群状态

```bash
kubectl get cs

```



### 部署 kubelet 服务

#### 创建kubelet配置

```bash
# 分别在3台master节点执行
KUBE_HOSTNAME=`hostname`

cat > /etc/kubernetes/cfg/kubelet.conf << EOF
KUBELET_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--hostname-override=${KUBE_HOSTNAME} \\
--container-runtime=docker \\
--kubeconfig=/etc/kubernetes/cfg/kubelet.kubeconfig \\
--bootstrap-kubeconfig=/etc/kubernetes/cfg/kubelet-bootstrap.kubeconfig \\
--config=/etc/kubernetes/cfg/kubelet-config.yml \\
--cert-dir=/etc/kubernetes/ssl \\
--image-pull-progress-deadline=15m \\
--pod-infra-container-image=registry.cn-chengdu.aliyuncs.com/willsk8s/pause:3.2"
EOF

```

**配置详解**

| 配置选项                           | 选项意义                                                                                      |
| ------------------------------ | ----------------------------------------------------------------------------------------- |
| --hostname-override            | 用来配置该节点在集群中显示的主机名，kubelet 设置了 -–hostname-override 参数后，kube-proxy 也需要设置，否则会出现找 不到 Node 的情况 |
| --container-runtime            | 指定容器运行时引擎                                                                                 |
| --kubeconfig                   | kubelet 作为客户端使用的 kubeconfig 认证文件，此文件是由 kube-controller-mananger 自动生成的                     |
| --bootstrap-kubeconfig         | 指定令牌认证文件                                                                                  |
| --config                       | 指定 kubelet 配置文件                                                                           |
| --cert-dir                     | 设置 kube-controller-manager 生成证书和私钥的目录                                                     |
| --image-pull-progress-deadline | 镜像拉取进度最大时间，如果在这段时间拉取镜像没有任何进展，将 取消拉取，默认:1m0s                                               |
| --pod-infra-container-image    | 每个 pod 中的 network/ipc 名称空间容器将使用的镜像                                                        |

#### 创建 kubelet-config 配置文件

```bash
cat > /etc/kubernetes/cfg/kubelet-config.yml << EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 172.16.0.91
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS:
- 10.96.0.2
clusterDomain: cluster.local
failSwapOn: false
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/ssl/ca.pem
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
maxOpenFiles: 1000000
maxPods: 110
EOF

```

#### 配置详解

| 配置选项          | 选项意义                                         |
| ------------- | -------------------------------------------- |
| address       | kubelet 服务监听的地址                              |
| port          | kubelet 服务的端口，默认 10250                       |
| readOnlyPort  | 没有认证/授权的只读 kubelet 服务端口 ，设置为 0 表示禁用，默认 10255 |
| clusterDNS    | DNS 服务器的 IP 地址列表                             |
| clusterDomain | 集群域名, kubelet 将配置所有容器除了主机搜索域还将搜索当前域          |

#### 创建 kubelet 启动脚本

```bash
cat > /usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service

[Service]
EnvironmentFile=/etc/kubernetes/cfg/kubelet.conf
ExecStart=/usr/local/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

```

#### 分发配置文件

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /etc/kubernetes/cfg/{kubelet-config.yml,kubelet.conf} root@${ip}:/etc/kubernetes/cfg
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/kubelet.service root@${ip}:/usr/lib/systemd/system
done

```

#### 配置文件处理

```bash
# 修改 k8s-master-02 配置
sed -i 's#master-01#master-02#g' /etc/kubernetes/cfg/kubelet.conf
sed -i 's#172.16.0.91#172.16.0.92#g' /etc/kubernetes/cfg/kubelet-config.yml

```

```bash
# 修改 k8s-master-03 配置
sed -i 's#master-01#master-03#g' /etc/kubernetes/cfg/kubelet.conf
sed -i 's#172.16.0.91#172.16.0.93#g' /etc/kubernetes/cfg/kubelet-config.yml

```

#### 开启 kubelet 服务

```bash
# 分别在三台 master 节点上启动
systemctl daemon-reload
systemctl enable --now kubelet
systemctl status kubelet.service

```



### 配置 kube-proxy 服务

#### 创建kube-proxy配置文件

```bash
cat > /etc/kubernetes/cfg/kube-proxy.conf << EOF
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/var/log/kubernetes \\
--config=/etc/kubernetes/cfg/kube-proxy-config.yml"
EOF

```

#### 创建 kube-proxy-config 配置文件

```bash
cat > /etc/kubernetes/cfg/kube-proxy-config.yml << EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 172.16.0.91
healthzBindAddress: 172.16.0.91:10256
metricsBindAddress: 172.16.0.91:10249
clientConnection:
  burst: 200
  kubeconfig: /etc/kubernetes/cfg/kube-proxy.kubeconfig
  qps: 100
hostnameOverride: k8s-master-01
clusterCIDR: 10.96.0.0/16
enableProfiling: true
mode: "ipvs"
kubeProxyIPTablesConfiguration:
  masqueradeAll: false
kubeProxyIPVSConfiguration:
  scheduler: rr
  excludeCIDRs: []
EOF

```

**配置文件详解**

| 选项配置               | 选项意义                                                                                                                    |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| clientConnection   | 与 kube-apiserver 交互时的参数设置                                                                                               |
| burst: 200         | 临时允许该事件记录值超过 qps 设定值                                                                                                    |
| kubeconfig         | kube-proxy 客户端连接 kube-apiserver 的 kubeconfig 文件路径设置                                                                     |
| qps: 100           | 与 kube-apiserver 交互时的 QPS，默认值 5                                                                                         |
| bindAddress        | kube-proxy 监听地址                                                                                                         |
| healthzBindAddress | 用于检查服务的 IP 地址和端口                                                                                                        |
| metricsBindAddress | metrics 服务的 ip 地址和端口。默认:127.0.0.1:10249                                                                                 |
| clusterCIDR        | kube-proxy 根据 --cluster-cidr 判断集群内部和外部流量，指定 --cluster-cidr 或 --masquerade-all 选项后 kube-proxy 才会对访问 Service IP 的请求做 SNAT |
| hostnameOverride   | 参数值必须与 kubelet 的值一致，否则 kube-proxy 启动后会找不到该 Node， 从而不会创建任何 ipvs 规则                                                       |
| masqueradeAll      | 如果使用纯 iptables 代理，SNAT 所有通过服务集群 ip 发送的通信                                                                                |
| mode               | 使用 ipvs 模式                                                                                                              |
| scheduler          | 当 proxy 为 ipvs 模式时，ipvs 调度类型                                                                                            |

#### 创建 kube-proxy 启动脚本

```bash
cat > /usr/lib/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/cfg/kube-proxy.conf
ExecStart=/usr/local/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

```

#### 分发配置文件

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /etc/kubernetes/cfg/{kube-proxy-config.yml,kube-proxy.conf} root@${ip}:/etc/kubernetes/cfg/
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/kube-proxy.service root@${ip}:/usr/lib/systemd/system/
done

```

#### 修改 k8s-master-02 配置文件

```bash
 sed -i 's#172.16.0.91#172.16.0.92#g' /etc/kubernetes/cfg/kube-proxy-config.yml
 sed -i 's#master-01#master-02#g' /etc/kubernetes/cfg/kube-proxy-config.yml
 
```

#### 修改 k8s-master-03 配置文件

```bash
 sed -i 's#172.16.0.91#172.16.0.93#g' /etc/kubernetes/cfg/kube-proxy-config.yml
 sed -i 's#master-01#master-03#g' /etc/kubernetes/cfg/kube-proxy-config.yml
 
```

#### 查看配置文件

```bash
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  echo ''; echo $ip; echo '';
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "cat /etc/kubernetes/cfg/kube-proxy-config.yml";
done

```

#### 启动

```bash
# 分别在三台 master 节点上启动
systemctl daemon-reload
systemctl enable --now kube-proxy
systemctl status kube-proxy

```

#### 查看 kubelet 加入集群请求

```bash
kubectl get csr

```

#### 批准加入

```bash
kubectl certificate approve `kubectl get csr | grep "Pending" | awk '{print $1}'`

```

#### 查看加入集群的新节点

```bash
kubectl get node

```

#### 设置集群角色

```bash
kubectl label nodes k8s-master-01 node-role.kubernetes.io/master=k8s-master-01

kubectl label nodes k8s-master-02 node-role.kubernetes.io/master=k8s-master-02

kubectl label nodes k8s-master-03 node-role.kubernetes.io/master=k8s-master-03

kubectl get nodes

```

#### 为 master 节点打污点

{% hint style="info" %}
master 节点一般情况下不运行 pod，因此我们需要给 master 节点添加污点使其不被调度
{% endhint %}

```bash
kubectl taint nodes k8s-master-01 node-role.kubernetes.io/master=k8s-master-01:NoSchedule --overwrite

kubectl taint nodes k8s-master-02 node-role.kubernetes.io/master=k8s-master-02:NoSchedule --overwrite

kubectl taint nodes k8s-master-03 node-role.kubernetes.io/master=k8s-master-03:NoSchedule --overwrite

```

####

### 部署集群网络插件

> kubernetes 设计了网络模型，但却将它的实现交给了网络插件，CNI 网络插件最主要的功能就是实现 POD 资 源能够跨主机进行通讯。常见的 CNI 网络插件：
>
> * Flannel
> * Calico
> * Canal
> * Contiv
> * OpenContrail
> * NSX-T
> * Kube-router

#### 下载 Fannel 二进制组件

```bash
wget https://github.com/coreos/flannel/releases/download/v0.13.1-rc1/flannel-v0.13.1-rc1-linux-amd64.tar.gz

tar -xvf flannel-v0.13.1-rc1-linux-amd64.tar.gz

```

#### 分发网络组件

```bash
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster flanneld mk-docker-opts.sh root@$ip:/usr/local/bin
done

```

#### 将 flanneld 配置写入集群数据库

```bash
etcdctl \
--ca-file=/etc/etcd/ssl/ca.pem \
--cert-file=/etc/etcd/ssl/etcd.pem \
--key-file=/etc/etcd/ssl/etcd-key.pem \
--endpoints="https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379" \
mk /coreos.com/network/config '{"Network":"10.244.0.0/12", "SubnetLen": 21, "Backend": {"Type": "vxlan", "DirectRouting": true}}'

# 使用 get 查看信息
etcdctl \
--ca-file=/etc/etcd/ssl/ca.pem \
--cert-file=/etc/etcd/ssl/etcd.pem \
--key-file=/etc/etcd/ssl/etcd-key.pem \
--endpoints="https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379" \
get /coreos.com/network/config

```

#### 注册 Flanneld 服务

```bash
cat > /usr/lib/systemd/system/flanneld.service << EOF
[Unit]
Description=Flanneld address
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/usr/local/bin/flanneld \\
  -etcd-cafile=/etc/etcd/ssl/ca.pem \\
  -etcd-certfile=/etc/etcd/ssl/etcd.pem \\
  -etcd-keyfile=/etc/etcd/ssl/etcd-key.pem \\
  -etcd-endpoints=https://172.16.0.91:2379,https://172.16.0.92:2379,https://172.16.0.93:2379 \\
  -etcd-prefix=/coreos.com/network \\
  -ip-masq
ExecStartPost=/usr/local/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

```

**配置详解**

| 配置选项            | 选项说明                                                                                                                                                                         |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -etcd-cafile    | 用于 etcd 通信的 SSL CA 文件                                                                                                                                                        |
| -etcd-certfile  | 用于 etcd 通信的的 SSL 证书文件                                                                                                                                                        |
| -etcd-keyfile   | 用于 etcd 通信的 SSL 密钥文件                                                                                                                                                         |
| -etcd-endpoints | 所有 etcd 的 endpoints                                                                                                                                                          |
| -etcd-prefix    | etcd 中存储的前缀                                                                                                                                                                  |
| -ip-masq        | -ip-masq=true 如果设置为 true，这个参数的目的是让 flannel 进行 ip 伪装，而不让 docker 进行 ip 伪装。这么做的原因是如果 docker 进行 ip 伪装，流量再从 flannel 出去，其他 host 上看到的 source ip 就是 flannel 的网关 ip，而不是 docker 容器的 ip |

#### 分发配置文件

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/flanneld.service root@$ip:/usr/lib/systemd/system
done

```

#### 修改 Docker 启动模式

> 此举是将 docker 的网络交给 flanneld 来管理，形成集群统一管理的网络

```bash
sed -i '/ExecStart/s/\(.*\)/#\1/' /usr/lib/systemd/system/docker.service

sed -i '/ExecReload/a ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS -H fd:// --containerd=/run/containerd/containerd.sock' /usr/lib/systemd/system/docker.service

sed -i '/ExecReload/a EnvironmentFile=-/run/flannel/subnet.env' /usr/lib/systemd/system/docker.service

```

#### 分发 Docker 启动脚本

```bash
for ip in k8s-master-02 k8s-master-03
do
  scp -i ~/.ssh/id_k8s_cluster /usr/lib/systemd/system/docker.service root@${ip}:/usr/lib/systemd/system
done

```

#### 启动 Flanneld 服务

```bash
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  echo ">>> $ip"
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "systemctl daemon-reload"
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "systemctl start flanneld"
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "systemctl enable flanneld"
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "systemctl restart docker"
done

```



### 部署 CoreDNS

> CoreDNS 用于集群中 Pod 解析 Service 的名字，Kubernetes 基于 CoreDNS 用于服务发现功能

#### 下载配置文件

```bash
cd /opt

git clone https://github.com/coredns/deployment.git

```

#### 绑定集群匿名用户权限

```bash
kubectl create clusterrolebinding cluster-system-anonymous --clusterrole=cluster-admin --user=kubernetes

```

#### 修改 CoreDNS 并运行

```bash
cd /opt/deployment/kubernetes

# 替换 coreDNS 镜像为:registry.cn-chengdu.aliyuncs.com/willsk8s/coredns:1.7.0
sed -i 's#coredns/coredns:1.8.0#registry.cn-chengdu.aliyuncs.com/willsk8s/coredns:1.7.0#g' coredns.yaml.sed

./deploy.sh -i 10.96.0.2 -s | kubectl apply -f -

kubectl get pods -n kube-system

```

#### 测试集群 DNS

```bash
kubectl run test -it --rm --image=busybox:1.28.3

```
