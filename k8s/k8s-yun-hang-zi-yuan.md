# K8s运行资源

### K8s 运行 Pod 资源

```yaml
mkdir /root/k8s/pod -p
cd /root/k8s/pod/

cat > k8s_pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: testpod-nginx
  labels:
    app: web-nginx
spec:
  containers:
    - name: nginx
      image: 10.0.0.10:5000/nginx:1.16.1
      ports:
        - containerPort: 80
    - name: busybox
      image: 10.0.0.10:5000/busybox:latest
      command: ["sleep", "1000"]
EOF

kubectl create -f k8s_pod.yaml
kubectl get pod
kubectl describe pod testpod-nginx

```



### K8s 运行 ReplicationController 资源

```yaml
mkdir /root/k8s/rc -p
cd /root/k8s/rc/

cat > k8s_rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: testrc-nginx
spec:
  replicas: 5
  selector:
    app: myweb
  template:
    metadata:
      labels:
        app: myweb
    spec:
      containers:
        - name: nginx
          image: 10.0.0.10:5000/nginx:1.16.1
          ports:
            - containerPort: 80
EOF

kubectl create -f k8s_rc.yaml
kubectl get rc
kubectl describe rc testrc-nginx

```

#### RC的滚动升级

#### 配置文件 k8s\_rc.yaml 内容

```yaml
cat > k8s_rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 5
  selector:
    app: myweb
  template:
    metadata:
      labels:
        app: myweb
    spec:
      containers:
        - name: nginx
          image: 10.0.0.10:5000/nginx:1.16.1
          ports:
            - containerPort: 80
EOF

```

#### 配置文件 k8s\_rc2.yaml 内容

```yaml
cat > k8s_rc2.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx2
spec:
  replicas: 5
  selector:
    app: myweb2
  template:
    metadata:
      labels:
        app: myweb2
    spec:
      containers:
        - name: nginx
          image: 10.0.0.10:5000/nginx:1.19.1
          ports:
            - containerPort: 80
EOF

```

#### 滚动升级

```bash
kubectl rolling-update nginx -f k8s_rc2.yaml --update-period=10s

# 使用配置文件k8s_rc2.yaml 对RC资源 "nginx" 进行升级
# --update-period 指定升级周期，此处为10秒升级一次
```

#### 回滚

```bash
kubectl rolling-update nginx2 -f k8s_rc.yaml --update-period=10s
```



### K8s 运行 Service 资源（用来创建VIP）

```bash
mkdir /root/k8s/svc -p
cd /root/k8s/svc/

cat > k8s_svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: testsvc
spec:
  type: NodePort       # 端口映射的类型
  ports:
    - port: 80         # cluster IP 端口 (VIP 用来与Pod绑定)
      nodePort: 30000  # node (宿主机IP的端口，访问此端口不会直接访问Pod的端口，而是访问VIP的端口)
      targetPort: 80   # pod
  selector:
    app: myweb         # 标签，跟打了此名称标签的pod进行关联
EOF

kubectl create -f k8s_svc.yaml
kubectl get svc
kubectl describe svc testsvc

```



### K8s 运行 Deployment 资源

```yaml
cat > k8s_deployment.yaml << EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: 10.0.0.10:5000/nginx:1.19.1
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 100m
          requests:
            cpu: 100m
EOF

```

#### K8s 直接编辑升级 Deployment

```yaml
kubectl edit deployment <deployment_name>
# 直接修改配置文件里的镜像镜像名称
```

#### K8s 回滚 Deployment

```yaml
# 查看Deployment资源的历史版本
kubectl rollout history deployment <deployment_name>

# 回滚到上一个版本
kubectl rollout undo deployment <deployment_name>

# 回滚到指定版本，此处为回滚到第三版
kubectl rollout undo deployment <deployment_name> --to-revision=3
```

#### K8s 命令行创建 Deployment ，并记录资源变化

```yaml
# 使用--record参数记录
kubectl run nginx-web --image=10.0.0.10:5000/nginx:1.16.1 --replicas=3 --record

# 查看记录
kubectl rollout history deployment nginx-web

# 更新镜像版本，此方法更新会留下版本历史
# 此处第一个nginx-web为Deployment资源的名称
# 此处第二个nginx-web为kubectl get all 中CONTAINER(S)中的名称
# 使用文件形式创建名称会更加清晰
kubectl set image deploy nginx-web nginx-web=10.0.0.10:5000/nginx:1.19.1

```

{% hint style="success" %}
\--record 参数适用于kubectl的各种命令，包括kubectl create -f&#x20;
{% endhint %}



### K8s 创建 namespace

```yaml
kubectl create namespace will

kubectl get namespace

kubectl get all -n will
kubectl get all --namespace=will

# 默认的命名空间为default

```

```yaml
# 在metadata下面插入
metadata:
  namespace: xxxxxx
```
