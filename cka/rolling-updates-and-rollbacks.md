# Rolling Updates and Rollbacks

### 更新资源方式一

#### 创建并编辑测试用的 ds 资源的 yaml 文件

```bash
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

#### 使用 yaml 创建 ds 资源并查看

```bash
kubectl create -f ds.yaml

kubectl get ds

kubectl get pod

kubectl describe pod ds-one-b2dpt | grep Image:
kubectl describe pod ds-one-ggqf6 | grep Image:


```

#### 查看 ds 资源的更新策略

```bash
kubectl get ds ds-one -o yaml | grep -A 4 Strategy

```

#### 编辑 ds 资源的更新策略

```bash
# 编辑对象以使用 OnDelete 更新策略。
# 这将允许手动终止某些 pod，从而在重新创建它们时更新映像。

kubectl edit ds ds-one

....
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: OnDelete        #<-- Edit to be this line
status:
....
```

#### 更新 ds 以使用较新版本的 nginx 服务器

```bash
# 使用命令而不是 edit
kubectl set image ds ds-one nginx=nginx:1.16.1-alpine

```

#### 再次查看 pod 的镜像版本

```bash
kubectl describe pod ds-one-b2dpt | grep Image:
kubectl describe pod ds-one-ggqf6 | grep Image:

```

#### 删除一个 pod ，等待替换的 pod 运行并查看

```bash
kubectl delete pod ds-one-b2dpt

kubectl get pod

kubectl describe pod ds-one-ggqf6 | grep Image:
# 显示结果仍未1.15.1的镜像

kubectl describe pod ds-one-vjnvm | grep Image:
# 显示结果为1.16.1-alpine


```



### 回滚资源

#### 查看 ds 资源的更改历史记录

```bash
kubectl rollout history ds ds-one

```

#### 查看个版本 ds 的设置

```bash
# 可以看到具体的设置信息
kubectl rollout history ds ds-one --revision=1

kubectl rollout history ds ds-one --revision=2

```

#### 回退 ds 到早期版本

```bash
kubectl rollout undo ds ds-one --to-revision=1

```

#### 查看执行回滚命令后 pod 的镜像版本信息

```bash
# 由于我们仍在使用 OnDelete 策略，因此 Pod 应该没有变化。

kubectl describe pod ds-one-vjnvm | grep Image:

```

#### 删除 Pod，等待替换生成，然后再次检查镜像版本

```bash
kubectl delete pod ds-one-vjnvm

kubectl get pod

kubectl describe pod ds-one-ktd2w | grep Image:
kubectl describe pod ds-one-ggqf6 | grep Image:

```



{% hint style="warning" %}
更新策略为 OnDelete 时，需要手动删除 pod 后 K8s 才能完成升级和回滚
{% endhint %}



### 更新资源方式二

#### 创建用于测试的 ds 资源的 yaml 文件

```bash
kubectl get ds ds-one -o yaml > ds2.yaml

```

```bash
vim ds2.yaml

# 修改以下两处
....
  name: ds-two
....
    type: RollingUpdate
    
```

#### 创建 ds 并检验相关资源

```bash
kubectl create -f ds2.yaml

kubectl get ds

kubectl get pod

kubectl describe pod ds-two-68gfh | grep Image:
kubectl describe pod ds-two-mg55q | grep Image:

```

#### 编辑配置文件

```bash
# 将镜像设置为较新的版本，例如 1.16.1-alpine。 使用 --record 选项
kubectl edit ds ds-two --record

....
      - image: nginx:1.16.1-alpine
.....
```

#### 查看资源详情

```bash
kubectl get ds ds-two

kubectl get pod

kubectl describe pod ds-two-7d4ld | grep Image:
kubectl describe pod ds-two-cqjw6 | grep Image:

```

#### 查看 ds 的推出状态和历史记录

```bash
kubectl rollout status ds ds-two

```

```bash
kubectl rollout history ds ds-two

```

```bash
kubectl rollout history ds ds-two --revision=2

```



{% hint style="success" %}
更新策略为 RollingUpdate 时，不需要手动删除 pod，整个过程为全自动更新
{% endhint %}



### 编辑资源总结

```bash
# 方式一：通过set命令
kubectl set image ds ds-one nginx=nginx:1.16.1-alpine

# 方式二：通过edit命令
kubectl edit ds ds-two --record
```
