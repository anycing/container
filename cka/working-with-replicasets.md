# Working with ReplicaSets

### 创建副本集

#### 创建 rs.yaml

```bash
cat > rs.yaml << EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-one
spec:
  replicas: 2
  selector:
    matchLabels:
      system: ReplicaOne
  template:
    metadata:
      labels:
        system: ReplicaOne
    spec:
      containers:
      - name: nginx
        image: nginx:1.15.1
        ports:
        - containerPort: 80
EOF

```

#### 创建并查看资源

```bash
kubectl create -f rs.yaml

kubectl get rs

kubectl describe rs rs-one

kubectl get pod

```

###

### 删除副本集不删除关联的 pod

#### 删除 rs 资源但不删除里边的 pod

```bash
kubectl delete rs rs-one --cascade=orphan

```

#### 查看资源

```bash
kubectl describe rs rs-one

kubectl get pod

```

#### 再次创建 rs 资源

```bash
# 只要我们不改变选择器字段，新的 ReplicaSet 就应该拥有所有权

kubectl create -f rs.yaml

kubectl get rs

kubectl describe rs rs-one

kubectl get pod


```



### 编辑标签隔离副本集里的 pod

#### 编辑某个 pod ，达到和 rs 隔离的目的

```bash
kubectl edit pod rs-one-3c6pb

# ....
#   labels:
#     system: IsolatedPod   #<-- Change from ReplicaOne
# managedFields:
# ....

```

#### 查看资源

```bash
kubectl get rs

# 查看标签值为 system 的 pod 资源
kubectl get po -L system

```

```bash
# 查看结果如下：
# NAME           READY   STATUS    RESTARTS   AGE     SYSTEM
# rs-one-bbjlw   1/1     Running   0          19m     IsolatedPod
# rs-one-rftw5   1/1     Running   0          3m50s   ReplicaOne
# rs-one-zpwhj   1/1     Running   0          19m     ReplicaOne
```

#### 删除 rs 再看 pod 资源

```bash
kubectl delete rs rs-one

kubectl get pod

kubectl get rs

```

#### 使用标签删除剩余的 pod

```bash
kubectl delete pod -l system=IsolatedPod

```
