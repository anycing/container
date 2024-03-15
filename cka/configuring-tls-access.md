# Configuring TLS Access

### 在 kubectl 的配置文件中找到证书和 API server 的地址

#### 查找证书的信息

```bash
cat $HOME/.kube/config

```

```bash
# client-certificate-data key
export client=$(grep client-cert $HOME/.kube/config | cut -d " " -f 6)

echo $client


# client-key-data key
export key=$(grep client-key-data $HOME/.kube/config | cut -d " " -f 6)

echo $key


# certificate-authority-data key
export auth=$(grep certificate-authority-data $HOME/.kube/config | cut -d " " -f 6)

echo $auth

```

#### 编码用于 curl 命令的密钥

```bash
echo $client | base64 -d - > ./client.pem

echo $key | base64 -d - > ./client-key.pem

echo $auth | base64 -d - > ./ca.pem

```

#### 查找 API server 的地址

```bash
kubectl config view | grep server

```



### 使用 curl 命令和编码的密钥连接到 API 服务器

#### 使用 curl 命令测试

```bash
curl --cert ./client.pem \
--key ./client-key.pem \
--cacert ./ca.pem \
https://k8scp:6443

```

#### 创建一个 JSON 文件来创建一个新的 pod

```bash
cat > curlpod.json << EOF
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "labels": {
            "name": "examplepod"
        },
        "name": "curlpod",
        "namespace": "default"
    },
    "spec": {
        "containers": [
            {
                "name": "nginx",
                "image": "nginx",
                "ports": [{"containerPort": 80}]
            }
        ]
    }
}
EOF

```

#### 使用上一步创建的 JSON 文件构建 XPOST API 调用

```bash
curl --cert ./client.pem \
--key ./client-key.pem \
--cacert ./ca.pem \
https://k8scp:6443/api/v1/namespaces/default/pods \
-XPOST -H'Content-Type: application/json' \
-d@curlpod.json

```

#### 验证新 pod 是否存在并显示 Running 状态

```bash
kubectl get pod

```

