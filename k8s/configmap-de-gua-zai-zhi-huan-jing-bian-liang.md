# ConfigMap的挂载之环境变量

### env

#### 创建环境变量的 ConfigMap

```bash
kubectl create configmap test-env.conf --from-literal=level=INFO --from-literal=lives=3

```

#### 准备 Deployment 的 yaml 文件

```bash
cat > dp-cm.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dp-cm
  name: dp-cm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dp-cm
  template:
    metadata:
      labels:
        app: dp-cm
    spec:
      containers:
      - image: nginx
        name: nginx
        env:
        - name: test_env1
          value: pingpong1
        - name: level
          valueFrom:
            configMapKeyRef:
              name: test-env.conf
              key: level
        - name: lives
          valueFrom:
            configMapKeyRef:
              name: test-env.conf
              key: lives
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-cm --image=nginx --dry-run=client -o yaml > dp-cm.yaml

删除不必要的项后在 container 下添加如下信息

env
- name: level
  valueFrom:
    configMapKeyRef:
      name: test-env.conf
      key: level
```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-cm.yaml

```

#### 验证环境变量

```bash
kubectl get deployment
kubectl get pod

kubectl exec dp-cm-96cc7b4f7-w9w4f -- env


# 也可进容器查看
kubectl exec -it dp-cm-96cc7b4f7-w9w4f -- bash
env
```



### envFrom

#### 创建环境变量的 ConfigMap

```bash
kubectl create configmap mysql57.conf --from-literal=MYSQL_USER=root --from-literal=MYSQL_PASSWORD=123456 --from-literal=MYSQL_DATABASE=wordpress

```

#### 准备 Deployment 的 yaml 文件

```bash
cat > dp-cm.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dp-cm
  name: dp-cm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dp-cm
  template:
    metadata:
      labels:
        app: dp-cm
    spec:
      containers:
      - image: nginx
        name: nginx
        envFrom:
        - configMapRef:
            name: mysql57.conf
          prefix: CM_
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-cm --image=nginx --dry-run=client -o yaml > dp-cm.yaml

删除不必要的项后在 container 下添加如下信息

envFrom:
- configMapRef:
    name: mysql57.conf
  prefix: CM_
```

{% hint style="info" %}
prefix: 参数为给环境变量添加前缀，使环境变量的来源更好区分（更好区分哪些环境变量是通过ConfigMap创建的）；一般情况下不必使用
{% endhint %}

#### 创建 Deployment 资源

```bash
kubectl create -f dp-cm.yaml

```

#### 验证环境变量

```bash
kubectl get deployment
kubectl get pod

kubectl exec dp-cm-7867f8d565-zcg8h -- env


# 也可进容器查看
kubectl exec -it dp-cm-7867f8d565-zcg8h -- bash
env
```

