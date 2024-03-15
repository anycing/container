# 使用Secret拉取私有仓库镜像

#### 创建 Secret

```bash
# 此处secret的类型为 docker-registry
kubectl create secret docker-registry aliyun-registry-secret \
  --docker-server=registry.cn-chengdu.aliyuncs.com \
  --docker-username=anycing@gmail.com \
  --docker-password=92willsrepo. \
  --docker-email=anycing@gmail.com

```

#### 准备 Deployment 的 yaml 文件

```
cat > dp-secret.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dp-secret
  name: dp-secret
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dp-secret
  template:
    metadata:
      labels:
        app: dp-secret
    spec:
      imagePullSecrets:
      - name: aliyun-registry-secret
      containers:
      - image: registry.cn-chengdu.aliyuncs.com/willsk8s/nginx:latest
        name: nginx
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-secret --image=nginx --dry-run=client -o yaml > dp-secret.yaml


# 删除不必要的项后在 container 同级添加如下信息
imagePullSecrets:
- name: aliyun-registry-secret
```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-secret.yaml

```

#### 验证

```bash
kubectl get deployment
kubectl get pod

```

