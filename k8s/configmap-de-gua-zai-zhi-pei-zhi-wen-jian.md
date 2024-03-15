# ConfigMap的挂载之配置文件

### 基于文件创建 ConfigMap

#### 准备配置文件

```bash
cat > redis.conf << EOF
requirepass redis123
port 9333
EOF

```

#### 创建 ConfigMap

```bash
kubectl create configmap redis-conf --from-file=./redis.conf

```

###

### 基于 yaml 文件创建 Deployment

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
        volumeMounts:
        - name: config-volume
          mountPath: /tmp
      volumes:
        - name: config-volume
          configMap:
            name: redis-conf
EOF

```

此文件可以使用如下命令生成后删除不必要的项后得到

```bash
kubectl create deployment dp-cm --image=nginx --dry-run=client -o yaml > dp-cm.yaml

# 与 container 项同级添加
      volumes:
        - name: config-volume
          configMap:
            name: redis-conf
# 在 container 下添加如下信息
      volumeMounts:
      - name: config-volume
        mountPath: /tmp

```

#### 创建 Deployment 资源

```bash
kubectl create -f dp-cm.yaml

```



### 验证 ConfigMap 挂载的配置文件

```bash
kubectl get deployment
kubectl get pod

kubectl exec -it dp-cm-59c6578598-qr8z9 -- bash
cd /tmp
ls
cat redis.conf

```



{% hint style="success" %}
可以使用 kubectl edit configmap xxx 动态更新配置文件；如果是基于文件修改则需手动进行替换更新
{% endhint %}



### 自定义挂载至容器里的配置文件属性

#### 自定义文件名

```bash
# 使用 items 选项可以自定义挂载至容器里的配置文件的名称
# key 为 ConfigMap 生成时源自文件的配置文件名称
# path 为 挂载至容器里的自定义的配置文件名称
# 此案例将在容器中挂载 redis-rename.conf 配置文件
volumes:
  - name: config-volume
    configMap:
      name: redis-conf
      items:
      - key: redis.conf
        path: redis-rename.conf
```

#### 自定义文件挂载权限

```bash
# 此案例将在容器中挂载 redis-rename.conf 配置文件
# redis-rename.conf 的权限为 0666
volumes:
  - name: config-volume
    configMap:
      name: redis-conf
      items:
      - key: redis.conf
        path: redis-rename.conf
      defaultMode: 0666
```

#### 优先级更高的挂载文件权限方式

```bash
# 此案例将在容器中挂载 redis-rename.conf 配置文件
# redis-rename.conf 的权限为 0644
# 权限覆盖默认的0666
# 当有多个配置文件需要自定义权限时使用此方式
volumes:
  - name: config-volume
    configMap:
      name: redis-conf
      items:
      - key: redis.conf
        path: redis-rename.conf
        mode: 06444             # 用mode选项将文件权限定义为0644，优先级高于defaultMode
      defaultMode: 0666
```

{% hint style="success" %}
自定义权限后进容器查看文件的权限时需要查看原始文件的权限（默认查看的文件为软连接文件，权限为777，查看原始文件即可看到正确的文件权限）
{% endhint %}



### 解决挂载覆盖目录的问题

```bash
volumeMounts:
- name: config-volume
  mountPath: /etc/nginx/nginx.conf
  subPath: nginx.conf

# moutPath后直接跟目录会导致覆盖掉原有目录，而且目录内只有configMap相关的文件
# 要解决此问题，需要：
# 挂载路径指定到文件，使用subPath选项后面跟文件名
# 这样就不会覆盖目录了
```
