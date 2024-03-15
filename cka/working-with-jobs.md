# Working with Jobs

### 创建一个 Job

#### 创建一个 job ，该 job 将运行一个休眠三秒钟然后停止的容器

```bash
cat > job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  template:
    spec:
      containers:
      - name: resting
        image: busybox
        command: ["/bin/sleep"]
        args: ["3"]
      restartPolicy: Never
EOF

```

#### 使用 yaml 创建 job ，然后查看详细信息

```bash
kubectl create -f job.yaml

kubectl get job

kubectl describe job sleepy

```

#### 查看实验所要使用的参数

```bash
kubectl get job sleepy -o yaml

# 接下来要用到的三个参数：
# backoffLimit
# completions
# theparallelism

```

#### 删除 job

```bash
kubectl delete job sleepy

```

###

### 创建一个 job ，测试 completions 参数

#### 编辑 yaml

```bash
cat > job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  template:
    spec:
      containers:
      - name: resting
        image: busybox
        command: ["/bin/sleep"]
        args: ["3"]
      restartPolicy: Never
EOF

# completions: 5  # 添加此行

```

#### 创建 job ，并观察

```bash
# 当您查看 job 时，请注意 COMPLETIONS 从 5 的零开始

kubectl create -f job.yaml

kubectl get job

kubectl get pod

```

#### 删除 job

```bash
kubectl delete job sleepy

```



### 创建一个 job ，测试 parallelism 参数

#### 编辑 yaml

```bash
cat > job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  parallelism: 2
  template:
    spec:
      containers:
      - name: resting
        image: busybox
        command: ["/bin/sleep"]
        args: ["3"]
      restartPolicy: Never
EOF

# parallelism: 2  # 添加此行

```

#### 创建 job 并观察

```bash
kubectl create -f job.yaml

kubectl get pod

kubectl get job

```

#### 删除 job

```bash
kubectl delete job sleepy

```



### 创建一个 job ，测试 activeDeadlineSeconds 参数

#### 编辑 yaml

```bash
cat > job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  parallelism: 2
  activeDeadlineSeconds: 15
  template:
    spec:
      containers:
      - name: resting
        image: busybox
        command: ["/bin/sleep"]
        args: ["5"]
      restartPolicy: Never
EOF

# activeDeadlineSeconds: 15  # 添加此行
# sleep 参数改为 5

```

#### 创建 job 并观察

```bash
kubectl create -f job.yaml

kubectl get job

# 间隔几秒后再观察
kubectl get job

```

#### 查看 YAML 输出的状态部分中的条目

```bash
kubectl get job sleepy -o yaml

```

#### 删除 job

```bash
kubectl delete job sleepy

```

