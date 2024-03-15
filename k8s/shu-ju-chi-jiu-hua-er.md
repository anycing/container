# 数据持久化 - 二

### 准备 PV 与 PVC

{% hint style="success" %}
PV 是全局资源，PVC是局部资源（只属于某个 namespace）
{% endhint %}

#### 准备创建 PV 所需的 yaml 文件

准备3个 yaml 文件 pv1.yaml、pv2.yaml、pv3.yaml

```bash
cat > pv1.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 10.0.0.31
    path: "/data/pv1"
    readOnly: false
EOF

```

```bash
cat > pv2.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv2
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 10.0.0.31
    path: "/data/pv2"
    readOnly: false
EOF

```

```bash
cat > pv3.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv3
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 10.0.0.31
    path: "/data/pv3"
    readOnly: false
EOF

```

#### 准备创建 PVC 所需的 yaml 文件

此处的 pvc的yaml 文件名为 mysql-pvc.yaml

```bash
# 此 PVC 属于命名空间 database
cat > mysql-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql
  namespace: database
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 3Gi
EOF

```

#### 创建 PV PVC

```bash
# 创建 PV
kubectl create -f pv1.yaml
kubectl create -f pv2.yaml
kubectl create -f pv3.yaml

# 创建命名空间 database
kubectl create namespace database

# 创建 PVC
kubectl create -f mysql-pvc.yaml

```

#### 查看 PV 与 PVC

```bash
kubectl get pv

kubectl -n database get pvc

```



### 使用 PVC

#### 准备 Deployment 资源的 yaml 文件

```bash
cat > mysql-dep.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: database
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      system: mysql
  template:
    metadata: 
      labels:
        system: mysql
    spec:
      volumes:                           # 此处定义数据卷
        - name: mysql-vol                #数据卷的名称
          persistentVolumeClaim:
            claimName: mysql
      containers:
        - name: mysql
          image: mysql:latest
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 3306
          volumeMounts:
            - name: mysql-vol            # 此处挂载数据卷，名称为上方定义的数据卷名称
              mountPath: /var/lib/mysql  # 容器内的挂载目录
          env:
          - name: MYSQL_ROOT_PASSWORD
            value: '123456'
EOF

```

{% hint style="danger" %}
资源的命名空间需要与 PVC 的命名空间一致
{% endhint %}

创建 Deployment 资源

```bash
kubectl create -f mysql-dep.yaml

kubectl -n database get deployment

kubectl -n database get pod

```



### 检验数据持久化结果

#### 方式一：

```bash
kubectl get pvc -n database

kubectl get pv

# 根据结果查看对应文件夹下的文件
ls -lh /data/pv*

```

#### 方式二：

```bash
# 查看 pod 调度到哪个节点
kubectl -n database get pod -o wide

# 在对应节点执行
sudo df -hT | grep nfs
# 10.0.0.31:/data/pv3 nfs4       20G   11G  8.2G  56% /var/lib/kubelet/pods/1bcc66fe-02cf-4682-a9ad-765890c36f0a/volumes/kubernetes.io~nfs/pv3

# 根据上方结果在 nfs 服务器上查看，此处为 10.0.0.31 服务器上的 /data/pv3 文件夹
ls -lh /data/pv3

```
