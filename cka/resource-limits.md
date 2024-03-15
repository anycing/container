# Resource Limits

### 使用 CPU 和内存约束

#### 创建实验所需的 Deployment 资源

```bash
kubectl create deployment hog --image=vish/stress

```

```bash
kubectl get deployments -o wide

```

#### 查看 hog 的详情

```bash
kubectl describe deployment hog

```

```bash
kubectl get deployment hog -o yaml

# resources: {}
# 从输出可以看出没有资源使用的限制

```

#### 将 hog Deployment 的 yaml 格式的详情输出为文件

```bash
kubectl get deployment hog -o yaml > hog.yaml

```

#### 编辑 hog.yaml ，使之成为配置文件

```bash
vim hog.yaml

# 需删除
# creationTimestamp
# resourceVersion
# uid
# status (all the lines including and after status)

# resources 做如下修改
# 删除 {}，然后添加4行
# 修改后如下所示

resources:
  limits:
    memory: 2Gi
  requests:
    memory: 1000Mi
```

#### 使用编辑好的 hog.yaml 文件替换部署

```bash
kubectl replace -f hog.yaml

```

#### 验证是否已进行更改

```bash
kubectl get deployment hog -o yaml

# 查看 resources

```

#### 查看 hog 容器的输出，注意分配了多少内存

```bash
kubectl get pod -o wide

```

```bash
kubectl logs hog-<tab>

```

#### 编辑 hog 配置文件并添加消耗 CPU 和内存的压力参数

```bash
resources:
  limits:
    cpu: 1
    memory: 2Gi
  requests:
    cpu: 0.5
    memory: 500Mi
args:
- -cpus
- "2"
- -mem-total
- "950Mi"
- -mem-alloc-size
- "100Mi"
- -mem-alloc-sleep
- "1s"

```

#### 删除并重新创建 hog

```bash
kubectl delete deployment hog

kubectl create -f hog.yaml

```

#### 再次查看容器的信息

```bash
kubectl get pod -o wide

kubectl logs hog-<tab>

```



### 命名空间的资源限制

#### 创建一个名为 low-usage-limit 的命名空间

```bash
kubectl create namespace low-usage-limit

kubectl get namespaces

```

#### 创建一个限制 CPU 和内存使用的 YAML 文件

```bash
cat > low-resource-range.yaml << EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: low-resource-range
spec:
  limits:
  - default:
      cpu: 1
      memory: 500Mi
    defaultRequest:
      cpu: 0.5
      memory: 100Mi
    type: Container
EOF

```

#### 创建 LimitRange 对象并将其分配给新创建的命名空间 low-usage-limit

```bash
kubectl --namespace=low-usage-limit create -f low-resource-range.yaml

kubectl get LimitRange --all-namespaces

```

#### 在这个命名空间中创建一个新的 Deployment 资源

```bash
kubectl -n low-usage-limit create deployment limit-hog --image=vish/stress

kubectl get pod -n low-usage-limit

```

#### 查看此 Deployment 里边的 pod 资源的详细信息

```bash
kubectl -n low-usage-limit get pod limit-hog-698c58b7ff-rdqbw -o yaml

# 查看 resources:

```

{% hint style="info" %}
也可以直接修改原始的 Deployment 的 yaml 文件，修改 namespace 为有资源限制的命名空间

验证的时候可以使用查看 pod 的 resources 来验证设置的限制
{% endhint %}

```bash
kubectl -n low-usage-limit get pod hog-<tab> -o yaml
```
