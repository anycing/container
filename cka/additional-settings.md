# Additional settings

### 设置 cp 节点可调度

```
kubectl get node

kubectl describe node k8scp

```

```bash
# 查看并过滤污点信息
kubectl describe node | grep -i taint
# Taints:             node-role.kubernetes.io/master:NoSchedule
# Taints:             <none>

# 取消污点（node-role.kubernetes.io/master为上方过滤的信息）
kubectl taint nodes --all node-role.kubernetes.io/master-

```

