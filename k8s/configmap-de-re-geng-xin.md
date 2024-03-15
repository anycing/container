# configMap的热更新

### 方式一：

```bash
kubectl edit configmaps <config-map>
```



### 方式二：

```bash
# 此方式用于yaml方式的创建的configMap
kubectl replace -f <config-map>.yaml
```



### 方式三：

```bash
# 此方式用于文件创建的configMap
kubectl create configmap nginx-conf --from-file=nginx.conf --dry-run=client -o yaml | kubectl replace -f -
```



{% hint style="danger" %}
configMap注意事项：

1. 对于环境变量无法热更新；
2. 有命名空间隔离；
3. subPath也无法热更新
4. configMap不要太大
{% endhint %}



### 设置configMap无法被热更新修改

```bash
# 增加一级参数
# 使用edit命令编辑
# 或在yaml文件结尾增加
# 之后就无法使用edit编辑
immutable: true
```
