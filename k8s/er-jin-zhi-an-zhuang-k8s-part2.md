# 二进制安装K8s - part2

## 证书签发

{% hint style="info" %}
part1 也有一部分证书签发内容
{% endhint %}

### master节点规划

| Hostname      | 外网IP      | 内网IP        |
| ------------- | --------- | ----------- |
| k8s-master-01 | 10.0.0.91 | 172.16.0.91 |
| k8s-master-02 | 10.0.0.92 | 172.16.0.92 |
| k8s-master-03 | 10.0.0.93 | 172.16.0.93 |

####

### 创建集群证书

```bash
mkdir /opt/cert/k8s
cd /opt/cert/k8s

cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "expiry": "87600h",
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ]
      }
    }
  }
}
EOF

```

####

### 创建根证书签名

```bash
cat > ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "ShangHai",
      "ST": "ShangHai"
    }
  ]
}
EOF

```

####

### 生成根证书

```bash
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

```

####

### 签发 kube-apiserver 证书

#### 创建 kube-apiserver 证书签名配置

```bash
cat > server-csr.json << EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "172.16.0.91",
    "172.16.0.92",
    "172.16.0.93",
    "172.16.0.96",
    "10.96.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "ShangHai",
      "ST": "ShangHai"
    }
  ]
}
EOF

# host:localhost 地址 + master 部署节点的 ip 地址 + etcd 节点的部署地址 + 负载均衡指定的 VIP(172.16.0.96) + service ip 段的第一个合法地址(10.96.0.1) + k8s 默认指定的一些地址。

```

#### 生成证书

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

```



### 签发 kube-controller-manager 证书

#### 创建 kube-controller-manager 证书签名配置

```bash
cat > kube-controller-manager-csr.json << EOF
{
  "CN": "system:kube-controller-manager",
  "hosts": [
    "127.0.0.1",
    "172.16.0.91",
    "172.16.0.92",
    "172.16.0.93",
    "172.16.0.96"
  ], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "system:kube-controller-manager",
      "OU": "System"
    }
  ]
}
EOF

```

#### 生成证书

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

```



### 签发 kube-scheduler 证书

#### 创建 kube-scheduler 签名配置

```bash
cat > kube-scheduler-csr.json << EOF
{
  "CN": "system:kube-scheduler",
  "hosts": [
    "127.0.0.1",
    "172.16.0.91",
    "172.16.0.92",
    "172.16.0.93",
    "172.16.0.96"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "system:kube-scheduler",
      "OU": "System"
    }
  ]
}
EOF

```

#### 创建证书

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

```



### 签发 kube-proxy 证书

#### 创建 kube-proxy 证书签名配置

```bash
cat > kube-proxy-csr.json << EOF
{
  "CN":"system:kube-proxy",
  "hosts":[],
  "key":{
    "algo":"rsa",
    "size":2048
  },
  "names":[
    {
      "C":"CN",
      "L":"BeiJing",
      "ST":"BeiJing",
      "O":"system:kube-proxy",
      "OU":"System"
    }
  ]
}
EOF

```

#### 生成证书

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

```



### 签发管理员用户证书

> 为了能让集群客户端工具安全的访问集群，所以要为集群客户端创建证书，使其具有所有的集群权限

#### 创建证书签名配置

```bash
cat > admin-csr.json << EOF
{
  "CN":"admin",
  "key":{
    "algo":"rsa",
    "size":2048
  },
  "names":[
    {
      "C":"CN",
      "L":"BeiJing",
      "ST":"BeiJing",
      "O":"system:masters",
      "OU":"System"
    }
  ]
}
EOF

```

#### 生成证书

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

```



### 颁发证书

> Master 节点所需证书:ca、kube-apiservver、kube-controller-manager、kube-scheduler、用户证书、Etcd 证书。

#### 颁发 Master 节点证书

```bash
mkdir -pv /etc/kubernetes/ssl

cp -p ./{ca*pem,server*pem,kube-controller-manager*pem,kube-scheduler*.pem,kube-proxy*pem,admin*.pem} /etc/kubernetes/ssl

for ip in k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "mkdir -pv /etc/kubernetes/ssl"
  scp -i ~/.ssh/id_k8s_cluster /etc/kubernetes/ssl/* root@$ip:/etc/kubernetes/ssl
done

```

#### 查看分发结果

```bash
for ip in k8s-master-01 k8s-master-02 k8s-master-03
do
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "hostname"
  ssh -i ~/.ssh/id_k8s_cluster root@$ip "ls /etc/kubernetes/ssl"
  echo
done

```
