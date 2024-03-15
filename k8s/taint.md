# Taint

### Taint

#### 污点的类型

* NoSchedule
* PreferNoSchedule
* NoExecute

#### 打污点

```bash
kubectl taint node worker01 bubba=value:NoSchedule

```

#### 删除污点

```bash
kubectl taint node worker01 bubba-

```

####

### Demo

#### 准备 yaml 文件

```bash
cat > taint-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: taint-deployment
spec:
  replicas: 8
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
EOF

```

#### 给节点 worker01 打上 taint

```bash
kubectl taint node worker01 bubba=value:NoSchedule

```

#### 使用上方的 yaml 文件创建 Deployment

```bash
kubectl apply -f taint-deployment.yaml

```

#### 查看 pod 调度的节点信息

```bash
kubectl get pod -o wide

```

删除Deployment后再分别给worker01节点打上其它两个污点，然后查看Pod的调度信息
