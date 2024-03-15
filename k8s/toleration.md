# Toleration

### Taint 与 Toleration 关系简介

> 设置了污点的Node将根据taint的eﬀect：NoSchedule、PreferNoSchedule、NoExecute和Pod之间产生互斥的关系， Pod将在一定程度上不会被调度到Node上。
>
> 但我们可以在Pod上设置容忍 (Toleration)，意思是设置了容忍的Pod将可以容忍污点的存在，可以被调度到存在污点的Node上



### 设置

#### pod.spec.tolerations

```
tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
    tolerationSeconds: 3600
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoExecute"
  - key: "key2"
    operator: "Exists"
    effect: "NoSchedule"
```



### 说明

> 其中 key, vaule, eﬀect 要与 Node 上设置的 taint 保持一致
>
> operator 的值为 Exists 将会忽略value值
>
> tolerationSeconds 用于描述当 Pod 需要被驱逐时可以在 Pod 上继续保留运行的时间



#### 当不指定 key 值时，表示容忍所有的污点 key：

```
tolerations:
- operator: "Exists"
```

#### 当不指定 eﬀect 值时，表示容忍所有的污点作用

```
tolerations:
- key: "key"
  operator: "Exists"
```

#### 有多个 Master 存在时，防止资源浪费，可以如下设置（表示k8s将尽量避免将Pod调度到具有该污点的Node上）

```bash
kubectl taint nodes Node-Name node-role.kubernetes.io/master=:PreferNoSchedule

```



### Demo

```bash
cat > toleration-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toleration-deployment
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
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: "Exists"
        effect: "NoSchedule"
EOF

```

​此案例将允许调度 Pod 到主节点上
