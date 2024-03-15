# Ingress

### 创建deployment

#### deploy-ng.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  labels:
    app: nginx-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

#### 创建

```
kubectl create -f deploy-ng.yaml
```



### 创建service

#### svc-ng.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-ng
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 8888
      targetPort: 80
```

#### 创建

```yaml
kubectl create -f svc-ng.yaml
```



### 创建Ingress

#### ingress-ng.yaml

```
```
