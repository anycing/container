# Service

### ClusterIP 类型

#### 编辑类型为 ClusterIP 的 svc 的 yaml 文件

```bash
cat > nginx-svc-cluster.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    run: nginx
  name: nginx-svc-cluster
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  - name: https
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    run: nginx
EOF

```

#### 创建 svc

```bash
kubectl create -f nginx-svc-cluster.yaml

```

#### 创建 pod 用于测试 svc

```bash
kubectl run nginx --image=nginx

```

#### 访问测试

```bash
kubectl get svc

curl <CLUSTER-IP>

```



### NodePort 类型

```bash
cat > nginx-svc-nodeport.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    run: nginx
  name: nginx-svc-nodeport
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 443
    nodePort: 30443
  selector:
    run: nginx
EOF

```

#### 创建 svc

```bash
kubectl create -f nginx-svc-nodeport.yaml

```

#### 创建 pod 用于测试 svc

```bash
kubectl run nginx --image=nginx

```

#### 访问测试

```bash
kubectl get svc

kubectl get node -o wide

curl <INTERNAL-IP>

```

