# K8s实战

### 准备配置文件

#### mysql\_rc.yaml

```yaml
cat > mysql_rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    app: mysql
  template:
    metadata:
      labels: 
        app: mysql
    spec:
      containers:
      - name: mysql
        image: 10.0.0.10:5000/mysql:5.7
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
EOF

```

#### tomcat\_rc.yaml

```yaml
cat > tomcat_rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: myweb
spec:
  replicas: 1
  selector:
    app: myweb
  template:
    metadata:
      labels:
        app: myweb
    spec:
      containers:
      - name: myweb
        image: 10.0.0.10:5000/tomcat:latest
        ports:
        - containerPort: 8080
        env:
        - name: MYSQL_SERVICE_HOST
          value: '此处填写MySQL SVC 的 CLUSTER-IP'
        - name: MYSQL_SERVICE_PORT
          value: '3306'
EOF

```

#### mysql\_svc.yaml

```yaml
cat > mysql_svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: ClusterIP
  ports:
    - port: 3306
      targetPort: 3306
  selector:
    app: mysql
EOF

```

#### tomcat\_svc.yaml

```yaml
cat > tomcat_svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: myweb
spec:
  type: NodePort
  ports:
    - port: 8080
      nodePort: 31080
      targetPort: 8080
  selector:
    app: myweb
EOF

```



### 创建资源

```yaml
kubectl create -f mysql_svc.yaml
kubectl create -f tomcat_svc.yaml

kubectl create -f mysql_rc.yaml
kubectl create -f tomcat_rc.yaml

```



{% hint style="danger" %}
一定要修改tomcat\_rc.yaml里环境变量env里mysql的ip，若不修改则需要启动DNS服务，见下一章节
{% endhint %}
