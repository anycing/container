# 二进制安装K8s  - part4

## 部署 node 节点

### 分发二进制组件

```bash
tar -xf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin/

for ip in k8s-node-01 k8s-node-02
do
  scp -i ~/.ssh/id_k8s_cluster kubelet kube-proxy root@$ip:/usr/local/bin/
done

# 查看分发结果
for ip in k8s-node-01 k8s-node-02
do
  echo $ip
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "ls -lh /usr/local/bin"
done

```

### 颁发 node 节点证书

```bash
cd /opt/cert/k8s

for ip in k8s-node-01 k8s-node-02
do
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "mkdir -pv /etc/kubernetes/ssl"
  scp -i ~/.ssh/id_k8s_cluster -pr ./{ca*.pem,admin*pem,kube-proxy*pem} root@$ip:/etc/kubernetes/ssl
done

```

### 配置 TLS bootstrapping

