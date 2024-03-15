# K8s参数配置

### 修改nodePort范围

```bash
vim /etc/kubernetes/apiserver

KUBE_API_ARGS="--service-node-port-range=3000-50000"

systemctl restart kube-apiserver

```



### 修改DNS

```bash
vim /etc/kubernetes/kubelet

KUBELET_ARGS="--cluster_dns=10.254.230.254 --cluster_domain=cluster.local"

systemctl restart kubelet

```

