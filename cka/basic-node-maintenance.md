# Basic Node Maintenance

### Backup The etcd Database

#### 查找 etcd 守护进程的数据目录

```bash
sudo grep data-dir /etc/kubernetes/manifests/etcd.yaml

# Pod 的所有设置都可以在 manifests 中找到

```

#### 进入容器查找 etcdctl 命令所需要的证书和密钥文件

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh
# 此处的容器名称为etcd-k8scp，若不是这个则可以使用 etcd-<Tab> 来补全容器名称


# 以下步骤在容器中进行
cd /etc/kubernetes/pki/etcd/

# 由于容器没有ls命令，则使用 echo 命令来查看文件，并记录下输出结果
echo *

# 退出容器
exit

```

{% hint style="danger" %}
注意接下来步骤的容器名称若不是 etcd-k8scp ，则可以使用 etcd-\<tab> 来补全容器名称
{% endhint %}

#### 使用环回 IP 和端口 2379 检查数据库的健康状况

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh \
-c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl endpoint health"

```

#### 查看集群状态，数据库数量等

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c \
"ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key  \
etcdctl --endpoints=https://127.0.0.1:2379 member list"

```

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c \
"ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key  \
etcdctl --endpoints=https://127.0.0.1:2379 member list -w table"

# 此命令相对上边的命令多了一个 -w table 参数，显示结果更友好

```

#### 使用快照参数保存 etcd 数据库的快照到 etcd 容器的本地数据目录 /var/lib/etcd/

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c \
"ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl --endpoints=https://127.0.0.1:2379 \
snapshot save /var/lib/etcd/snapshot.db"

```

#### 验证上一步的快照是否成功保存到本地目录

```bash
sudo ls -lh /var/lib/etcd/

```

#### 备份快照和一些创建集群的信息

```bash
mkdir $HOME/backup
sudo cp /var/lib/etcd/snapshot.db $HOME/backup/snapshot.db-$(date +%F)
sudo cp /root/kubeadm-config.yaml $HOME/backup/
sudo cp -r /etc/kubernetes/pki/etcd $HOME/backup/

```



### Upgrade the Cluster ( cp node )

#### 更新APT源的数据

```bash
sudo apt-get update

```

#### 查看可用的 kubeadm 软件包并安装

```bash
sudo apt-cache madison kubeadm | head -10

```

```bash
sudo apt-mark unhold kubeadm

```

```bash
sudo apt-get install kubeadm=1.21.3-00 -y

# 截止本文档书写日期，kubeadm 1.21.3-00 为最新版本

```

```bash
sudo apt-mark hold kubeadm

```

```bash
sudo kubeadm version

```

#### 驱逐除了守护进程外的所有 pod ，为更新 cp 节点做准备

```bash
kubectl drain k8scp --ignore-daemonsets

```

#### 检查现有集群

```bash
sudo kubeadm upgrade plan

```

#### 升级集群

```bash
sudo kubeadm upgrade apply v1.21.3

# 由于阿里云容器仓库的原因，此处需要手动下载新版本的coredns并打标签
# sudo docker pull coredns/coredns:1.8.0
# sudo docker tag docker.io/coredns/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns:v1.8.0

# 下载并打完标签后重新执行，然后中间会有一次交互输入，键入y即可

```

#### 检查节点状态

```bash
kubectl get node

# cp 节点应该显示调度已禁用。
# 此外，由于我们尚未更新所有软件并重新启动守护程序，因此它将显示以前的版本。

```

#### 安装新版 kubelet 和 kubectl

```bash
sudo apt-mark unhold kubelet kubectl

```

```bash
sudo apt-get install kubelet=1.21.3-00 kubectl=1.21.3-00 -y

```

```bash
sudo apt-mark hold kubelet kubectl

```

```bash
sudo systemctl daemon-reload

sudo systemctl restart kubelet

```

#### 验证节点更新的版本

```bash
kubectl get node

```

#### 设置 cp 节点可调度

```bash
kubectl uncordon k8scp

```

#### 验证 cp 现在显示就绪状态

```bash
kubectl get node

```



### Upgrade the Cluster ( worker node )

#### 安装 kubeadm 软件包

```bash
sudo apt-mark unhold kubeadm

```

```bash
sudo apt-get update && sudo apt-get install kubeadm=1.21.3-00 -y

# 更新 kubeadm 的版本和 cp 节点保持一致

```

```bash
sudo apt-mark hold kubeadm

```

#### 驱逐除了守护进程外的所有 pod ，为更新 worker 节点做准备（返回 cp 节点上执行）

```bash
# 在 cp 节点上执行命令，此处 worker 节点的主机名为 worker01
kubectl drain worker01 --ignore-daemonsets

```

#### 升级 worker 节点 （返回 worker 节点上执行）

```bash
sudo kubeadm upgrade node

```

#### 安装新版 kubelet 和 kubectl

```bash
sudo apt-mark unhold kubelet kubectl

```

```bash
sudo apt-get install kubelet=1.21.3-00 kubectl=1.21.3-00 -y

```

```bash
sudo apt-mark hold kubelet kubectl

```

```bash
sudo systemctl daemon-reload

sudo systemctl restart kubelet

```

#### 查看节点状态（返回 cp 节点执行）

```bash
kubectl get node

```

#### 设置 worker 节点为可调度

```bash
# 此处 worker 节点的主机名为 worker01
kubectl uncordon worker01

```

#### 再次查看节点状态

```bash
kubectl get node

```
