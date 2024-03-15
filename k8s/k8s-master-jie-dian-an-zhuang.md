# K8s-master节点安装

### 集群规划

| IP        | Hostname     |
| --------- | ------------ |
| 10.0.0.10 | k8s-Harbor   |
| 10.0.0.11 | k8s-master-1 |
| 10.0.0.12 | k8s-master-2 |
| 10.0.0.13 | k8s-node-1   |
| 10.0.0.14 | k8s-node-2   |

#### 修改Hostname和hosts文件

```bash
hostnamectl set-hostname k8s-master-1

echo '10.0.0.10    k8s-Harbor
10.0.0.11    k8s-master-1
10.0.0.12    k8s-master-2
10.0.0.13    k8s-node-1
10.0.0.14    k8s-node-2' >> /etc/hosts

```



### master节点安装etcd

```bash
yum install etcd -y


vim /etc/etcd/etcd.conf
# 第六行改为
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
# 第二十一行改为，10.0.0.11为master节点IP
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.11:2379"


systemctl enable etcd
systemctl start etcd
etcdctl -C http://10.0.0.11:2379 cluster-health

```



### master节点安装kubernetes

```bash
yum install kubernetes-master -y

vim /etc/kubernetes/apiserver

KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
KUBE_API_PORT="--port=8080"
KUBELET_PORT="--kubelet-port=10250"
KUBE_ETCD_SERVERS="--etcd-servers=http://10.0.0.11:2379"
#default admission control policies删掉ServiceAccount


vim /etc/kubernetes/config
KUBE_MASTER="--master=http://10.0.0.11:8080"


systemctl enable kube-apiserver
systemctl restart kube-apiserver

systemctl enable kube-controller-manager
systemctl restart kube-controller-manager

systemctl enable kube-scheduler
systemctl restart kube-scheduler


kubectl get componentstatus


# 解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem
```

{% hint style="warning" %}
解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题也可使用本地镜像，使用本地镜像需要修改配置文件，将配置文件修改为本地仓库地址

/etc/kubernetes/kubelet
{% endhint %}



### 一键安装脚本

```bash
hostnamectl set-hostname k8s-master-1

echo '10.0.0.10    k8s-Harbor
10.0.0.11    k8s-master-1
10.0.0.12    k8s-master-2
10.0.0.13    k8s-node-1
10.0.0.14    k8s-node-2' >> /etc/hosts


yum install etcd -y

sed -i 's#ETCD_LISTEN_CLIENT_URLS="http://localhost:2379"#ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"#g' /etc/etcd/etcd.conf
#注意下方IP为master节点IP
sed -i 's#ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"#ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.11:2379"#g' /etc/etcd/etcd.conf

systemctl enable etcd
systemctl start etcd
etcdctl -C http://10.0.0.11:2379 cluster-health

yum install kubernetes-master -y

sed -i 's#KUBE_API_ADDRESS="--insecure-bind-address=127.0.0.1"#KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"#g' /etc/kubernetes/apiserver
sed -i 's/# KUBE_API_PORT="--port=8080"/KUBE_API_PORT="--port=8080"/g' /etc/kubernetes/apiserver
sed -i 's/# KUBELET_PORT="--kubelet-port=10250"/KUBELET_PORT="--kubelet-port=10250"/g' /etc/kubernetes/apiserver
#注意下方IP为etcd server's IP
sed -i 's#KUBE_ETCD_SERVERS="--etcd-servers=http://127.0.0.1:2379"#KUBE_ETCD_SERVERS="--etcd-servers=http://10.0.0.11:2379"#g' /etc/kubernetes/apiserver
sed -i 's#KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"#KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"#g' /etc/kubernetes/apiserver

sed -i 's#KUBE_MASTER="--master=http://127.0.0.1:8080"#KUBE_MASTER="--master=http://10.0.0.11:8080"#g' /etc/kubernetes/config

systemctl enable kube-apiserver
systemctl restart kube-apiserver

systemctl enable kube-controller-manager
systemctl restart kube-controller-manager

systemctl enable kube-scheduler
systemctl restart kube-scheduler

kubectl get componentstatus


# 解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem

```

