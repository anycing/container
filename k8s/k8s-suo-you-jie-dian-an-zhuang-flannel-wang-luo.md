# K8s所有节点安装flannel网络

### 安装flannel

```bash
# 所有节点都需执行
yum install flannel -y

sed -i 's#FLANNEL_ETCD_ENDPOINTS="http://127.0.0.1:2379"#FLANNEL_ETCD_ENDPOINTS="http://10.0.0.21:2379"#g' /etc/sysconfig/flanneld

```

### master节点配置key

```bash
etcdctl mk /atomic.io/network/config '{ "Network": "172.16.0.0/16" }'
```

### master节点安装docker

```bash
yum install docker -y
#为了安装Harbor，如果有更多服务器则单独一台用来安装Harbor
```

### master节点重启服务

```bash
systemctl enable flanneld
systemctl restart flanneld

systemctl enable docker
systemctl daemon-reload
systemctl restart docker

systemctl restart kube-apiserver
systemctl restart kube-controller-manager
systemctl restart kube-scheduler

```

### node节点重启服务

```bash
systemctl enable flanneld
systemctl restart flanneld
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet
systemctl restart kube-proxy

```

{% hint style="danger" %}
某些版本的docker安装后会修改IPTABLES的FORWARD链为DROP，导致docker间网络不通无法通信（进容器后相互PING Docker分配的虚拟IP），需要修改宿主机的IPTABLES的FORWARD链规则为ACCEPT（每个机器都要修改）

iptables -P FORWARD ACCEPT

一劳永逸修改方案：

vim /usr/lib/systemd/system/docker.service

ExecStart上方添加 ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT

systemctl daemon-reload

systemctl restart docker
{% endhint %}



### 一键安装脚本

#### master

```bash
yum install flannel -y

#下方IP为etcd主节点IP（master节点IP）
sed -i 's#FLANNEL_ETCD_ENDPOINTS="http://127.0.0.1:2379"#FLANNEL_ETCD_ENDPOINTS="http://10.0.0.11:2379"#g' /etc/sysconfig/flanneld

etcdctl mk /atomic.io/network/config '{ "Network": "172.16.0.0/16" }'

yum install docker -y
#为了安装Harbor，如果有更多服务器则单独一台用来安装Harbor

systemctl enable flanneld
systemctl restart flanneld

systemctl enable docker
systemctl daemon-reload
systemctl restart docker

systemctl restart kube-apiserver
systemctl restart kube-controller-manager
systemctl restart kube-scheduler

```

#### node

```bash
# 所有节点都需执行
yum install flannel -y

sed -i 's#FLANNEL_ETCD_ENDPOINTS="http://127.0.0.1:2379"#FLANNEL_ETCD_ENDPOINTS="http://10.0.0.11:2379"#g' /etc/sysconfig/flanneld

systemctl enable flanneld
systemctl restart flanneld

systemctl daemon-reload
systemctl restart docker

systemctl restart kubelet
systemctl restart kube-proxy

```

