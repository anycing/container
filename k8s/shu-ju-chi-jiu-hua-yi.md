# 数据持久化 - 一

### emptyDir 类型

```bash
cat > mysql.yaml << EOF
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
        - name: mysql-vol                # 数据卷的名称
          emptyDir: {}                   # 此处定义数据持久化的类型
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

{% hint style="success" %}
emptyDir 类型的数据卷生命周期与Pod的生命周期相同，与Pod中的容器不同（容器删除但Pod存在则数据卷存在）
{% endhint %}

{% hint style="danger" %}
emptyDir 类型不适合数据库数据持久化（会在每个节点下创建相同目录进行保存数据，但每个节点数据不同）；

适合用于 web server 的访问日志数据持久化
{% endhint %}



### hostPath 类型

```bash
cat > mysql.yaml << EOF
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
        - name: mysql-vol                # 数据卷的名称
          hostPath:                      # 此处定义数据持久化的类型
            path: /data/mysql-data       # 此处为宿主机目录（若不存在则创建）
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

{% hint style="warning" %}
hostPath 类型无法保证每个节点数据一致，若要使用建议指定调度节点（若指定节点碰巧节点故障则无法发挥K8s的自愈的特性）。
{% endhint %}



### NFS 类型

```bash
cat > mysql.yaml << EOF
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
        - name: mysql-vol                # 数据卷的名称
          nfs:                           # 此处定义数据持久化的类型为NFS
            server: 10.0.0.31            # 远端NFS服务器
            path: /data/mysql-data       # 此处为远端NFS目录
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

```bash
# 此实验要验证可能需要手动调度到指定节点
# 在 template spec 下面指定：
# nodeName: <node_hostname>
```

#### Server 端

```bash
sudo apt-get install nfs-kernel-server -y

sudo systemctl start nfs-kernel-server

```

```bash
vim /etc/exports
/data    10.0.0.0/24(rw,sync,subtree_check,no_root_squash,no_all_squash)

sudo mkdir /data
sudo chmod 777 /data
sudo exportfs -a

```

#### Client 端

```bash
sudo apt-get install nfs-common -y

sudo mkdir /opt/data
sudo mount -t nfs 10.0.0.31:/data /opt/data/

```

