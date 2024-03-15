# 标签

### 给资源打标签

#### 查看 pod 资源的标签

```bash
kubectl get pod --show-labels
```

#### 给指定的 pod 资源打标签

```bash
kubectl label pod nginx2-6c58f67d98-ns529 version=v1
```

#### 修改资源现有的标签 "version=v1" 为 "version=v2"

```bash
kubectl label pod nginx2-6c58f67d98-ns529 version=v2 --overwrite
```



### 通过标签筛选资源

```bash
# 筛选标签中 key 为 version 的 pod 资源
kubectl get pod -l version --show-labels


# 筛选标签中 key=value 为 system=nginx且version=v1 的 pod 资源
kubectl get pod -l system=nginx,version=v1 --show-labels


# 筛选标签中 key=value 为 version=v1或version=v2 的 pod 资源
kubectl get pod -l 'version in (v1, v2)'

```
