# 使用标签分配Pod

#### 查看节点标签和污点

```bash
kubectl describe nodes | grep -A 6 -i 'label'

kubectl describe nodes | grep aint
# Taints:    <none>
# Taints:    <none>
# 此演示需确保没有污点
```

#### 给节点打标签

```bash
kubectl label nodes k8scp status=vip

kubectl label nodes worker status=other

```

#### 再次查看节点标签

```bash
kubectl get nodes --show-labels

```

#### 准备 yaml 文件

```bash
cat > vip.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: vip
spec:
  containers:
  - name: vip1
    image: busybox
    args:
    - sleep
    - "1000000"
  - name: vip2
    image: busybox
    args:
    - sleep
    - "1000000"
  - name: vip3
    image: busybox
    args:
    - sleep
    - "1000000"
  - name: vip4
    image: busybox
    args:
    - sleep
    - "1000000"
  - name: vip5
    image: busybox
    args:
    - sleep
    - "1000000"
  nodeSelector:
    status: vip
EOF

```

#### 创建资源

```bash
kubectl create -f vip.yaml

```

#### 查看资源

```bash
kubectl get pods -o wide

```

删除资源后修改yaml文件的nodeSelector为另外一个标签，然后再次创建资源查看



{% hint style="info" %}
此实验使用 nodeSelector 进行标签选择，实现调度 Pod 到打了标签的指定节点上
{% endhint %}
