# ConfigMap & 环境变量

### 从文件创建 ConfigMap

#### 准备配置文件

```bash
cat > redis.conf << EOF
requirepass redis123
EOF

```

#### 创建

```bash
kubectl create configmap redis.conf --from-file=redis.conf

```

#### 查看

```bash
kubectl get configmaps

kubectl get configmaps redis.conf -o yaml

# apiVersion: v1
# data:
#   redis.conf: |
#     requirepass redis123
# kind: ConfigMap
# ...

```

###

### 从文件夹创建 ConfigMap

#### 准备配置文件

```bash
mkdir configDir

cd configDir

```

```bash
cat > app1.conf << EOF
app=tomcat
app.color=black
EOF

```

```bash
cat > app2.conf << EOF
app=nginx
app.color=yellow
EOF

```

#### 创建

```bash
kubectl create configmap appconfig --from-file=../configDir

```

#### 查看

```bash
kubectl get configmaps

kubectl get configmaps appconfig -o yaml

```



### 自定义 KEY 的名称

#### 准备配置文件

```bash
cat > redis.conf << EOF
requirepass redis123
EOF

```

#### 创建

```bash
# 自定义 KEY 的名称为 redis-conf
# 若不指定文件名是什么，KEY即为什么
kubectl create configmap redis-common --from-file=redis-conf=redis.conf

```

#### 查看

```bash
kubectl get configmaps redis-common -o yaml

apiVersion: v1
data:
# 下方的名称 redis-conf 即自定义的名称
  redis-conf: |
    requirepass redis123
kind: ConfigMap
...
...
  
```

#### 针对多文件自定义 KEY

```bash
kubectl create configmap redis-common --from-file=redis-conf=redis.conf
--from-file=nginx-conf=nginx.conf

```



### 从文件创建环境变量

#### 准备配置文件

```bash
cat > app-env.conf << EOF
app=tomcat
app.color=white
lives=3
EOF

```

#### 创建

```bash
kubectl create configmap app-env --from-env-file=app-env.conf

```

查看

```bash
kubectl get configmaps app-env -o yaml

# 数据是以 key: value 的形式存在的
...
apiVersion: v1
data:
  app: tomcat
  app.color: white
  lives: "3"
...

```



### 从命令行创建环境变量

#### 创建

```bash
kubectl create configmap redis2.conf --from-literal=level=INFO --from-literal=PASSWORD=redis123456

```

#### 查看

```bash
kubectl get configmaps redis2.conf -o yaml

```



### 从 yaml 文件创建

此方法需要提前复制相关yaml文件
