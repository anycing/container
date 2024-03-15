# Secret的挂载

### 挂载 Secret 中指定键值至环境变量之 env

#### 创建 Secret

```bash
kubectl create secret generic db-user-pass \
  --from-literal=username='admin' \
  --from-literal=password='password123456'

```

#### 准备 Deployment 的 yaml 文件

```bash
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
      containers:
      - image: nginx
        name: nginx
        env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-user-pass
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-user-pass
              key: password
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-secret --image=nginx --dry-run=client -o yaml > dp-secret.yaml

删除不必要的项后在 container 下添加如下信息

env
- name: SECRET_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-user-pass
      key: password
```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-secret.yaml

```

#### 验证环境变量

```bash
kubectl get deployment
kubectl get pod

kubectl exec dp-secret-6695d9986-7mc22 -- env


# 也可进容器查看
kubectl exec -it dp-secret-6695d9986-7mc22 -- bash
env
```



### 挂载 Secret 中所有键值至环境变量之 envFrom

#### 创建 Secret

```bash
kubectl create secret generic db-user-pass \
  --from-literal=username='admin' \
  --from-literal=password='password123456'

```

#### 准备 Deployment 的 yaml 文件

```bash
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
      containers:
      - image: nginx
        name: nginx
        envFrom:
        - secretRef:
            name: db-user-pass
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-secretsecret --image=nginx --dry-run=client -o yaml > dp-secret.yaml

删除不必要的项后在 container 下添加如下信息

envFrom:
- secretRef:
    name: db-user-pass

```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-secret.yaml

```

#### 验证环境变量

```bash
kubectl get deployment
kubectl get pod

kubectl exec dp-secret-67c57685b4-jk7v6 -- env


# 也可进容器查看
kubectl exec -it dp-secret-67c57685b4-jk7v6 -- bash
env
```



### 挂载 Secret 至容器中的指定位置之 volumeMounts

#### 创建 Secret

```bash
kubectl create secret generic db-user-pass \
  --from-literal=username='admin' \
  --from-literal=password='password123456'

```

#### 准备 Deployment 的 yaml 文件

```bash
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
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: vol-db-user-pass
          mountPath: "/tmp/vol-db-user-pass"
          readOnly: true
      volumes:
      - name: vol-db-user-pass
        secret:
          secretName: db-user-pass
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-secretsecret --image=nginx --dry-run=client -o yaml > dp-secret.yaml

删除不必要的项后在 container 下添加如下信息

# 与 container 项同级添加
      volumes:
        - name: vol-db-user-pass
          secret:
            name: db-user-pass
# 在 container 下添加如下信息
      volumeMounts:
      - name: vol-db-user-pass
        mountPath: "/tmp/vol-db-user-pass"

```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-secret.yaml

```

#### 验证挂载结果

```bash
kubectl get deployment
kubectl get pod

# 可进容器查看
kubectl exec -it dp-secret-59c97d8f6f-b47kp -- bash

cd /tmp/vol-db-user-pass
ls

# 挂载内容会以文件形式出现在挂载的目录里
```

