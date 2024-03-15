# Working with DaemonSets

#### 创建 ds.yaml

```
cat > ds.yaml << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds-one
spec:
  selector:
    matchLabels:
      system: DaemonSetOne
  template:
    metadata:
      labels:
        system: DaemonSetOne
    spec:
      containers:
      - name: nginx
        image: nginx:1.15.1
        ports:
        - containerPort: 80
EOF

```

#### 创建 ds 并查看相关资源

```
kubectl create -f ds.yaml

kubectl get ds

kubectl get pod

kubectl describe pod ds-one-66ndp | grep Image:

```
