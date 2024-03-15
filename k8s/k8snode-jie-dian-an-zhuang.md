# K8s-node节点安装

### 修改Hostname和hosts文件

```
hostnamectl set-hostname k8s-node-1

echo '10.0.0.10    k8s-Harbor
10.0.0.11    k8s-master-1
10.0.0.12    k8s-master-2
10.0.0.13    k8s-node-1
10.0.0.14    k8s-node-2' >> /etc/hosts

```



### node节点安装kubernetes

```bash
yum install kubernetes-node -y

vim /etc/kubernetes/config
KUBE_MASTER="--master=http://10.0.0.11:8080"

vim /etc/kubernetes/kubelet
KUBELET_ADDRESS="--address=0.0.0.0"
KUBELET_PORT="--port=10250"
KUBELET_HOSTNAME="--hostname-override=10.0.0.12"
KUBELET_API_SERVER="--api-servers=http://10.0.0.11:8080"


systemctl enable kubelet
systemctl start kubelet

systemctl enable kube-proxy
systemctl start kube-proxy

# 解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem
```



### 一键安装脚本

#### k8s-node-1 一键安装脚本（10.0.0.13）

```bash
hostnamectl set-hostname k8s-node-1

echo '10.0.0.10    k8s-Harbor
10.0.0.11    k8s-master-1
10.0.0.12    k8s-master-2
10.0.0.13    k8s-node-1
10.0.0.14    k8s-node-2' >> /etc/hosts


yum install kubernetes-node -y

sed -i 's#KUBE_MASTER="--master=http://127.0.0.1:8080"#KUBE_MASTER="--master=http://10.0.0.11:8080"#g' /etc/kubernetes/config

sed -i 's#KUBELET_ADDRESS="--address=127.0.0.1"#KUBELET_ADDRESS="--address=0.0.0.0"#g' /etc/kubernetes/kubelet
sed -i 's/# KUBELET_PORT="--port=10250"/KUBELET_PORT="--port=10250"/g' /etc/kubernetes/kubelet
# 下方hostname的ip为node节点的ip
sed -i 's/KUBELET_HOSTNAME="--hostname-override=127.0.0.1"/KUBELET_HOSTNAME="--hostname-override=10.0.0.13"/g' /etc/kubernetes/kubelet
sed -i 's#KUBELET_API_SERVER="--api-servers=http://127.0.0.1:8080"#KUBELET_API_SERVER="--api-servers=http://10.0.0.11:8080"#g' /etc/kubernetes/kubelet

systemctl enable kubelet
systemctl start kubelet

systemctl enable kube-proxy
systemctl start kube-proxy

# 解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem

```

#### k8s-node-2 一键安装脚本（10.0.0.14）

```bash
hostnamectl set-hostname k8s-node-2

echo '10.0.0.10    k8s-Harbor
10.0.0.11    k8s-master-1
10.0.0.12    k8s-master-2
10.0.0.13    k8s-node-1
10.0.0.14    k8s-node-2' >> /etc/hosts


yum install kubernetes-node -y

sed -i 's#KUBE_MASTER="--master=http://127.0.0.1:8080"#KUBE_MASTER="--master=http://10.0.0.11:8080"#g' /etc/kubernetes/config

sed -i 's#KUBELET_ADDRESS="--address=127.0.0.1"#KUBELET_ADDRESS="--address=0.0.0.0"#g' /etc/kubernetes/kubelet
sed -i 's/# KUBELET_PORT="--port=10250"/KUBELET_PORT="--port=10250"/g' /etc/kubernetes/kubelet
# 下方hostname的ip为node节点的ip
sed -i 's/KUBELET_HOSTNAME="--hostname-override=127.0.0.1"/KUBELET_HOSTNAME="--hostname-override=10.0.0.14"/g' /etc/kubernetes/kubelet
sed -i 's#KUBELET_API_SERVER="--api-servers=http://127.0.0.1:8080"#KUBELET_API_SERVER="--api-servers=http://10.0.0.11:8080"#g' /etc/kubernetes/kubelet

systemctl enable kubelet
systemctl start kubelet

systemctl enable kube-proxy
systemctl start kube-proxy

# 解决启动pod拉取registry.access.redhat.com/rhel7/pod-infrastructure:latest镜像时证书问题
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem

```
