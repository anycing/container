# RBAC

### 开启 RBAC

#### kubeadm 安装的开启方式

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml

spec:
  containers:
  - command:
    - --authorization-mode=Node,RBAC
```

#### 二进制安装的开启方式

```bash
vim /usr/lib/systemd/system/kube-apiserver.service
# 添加如下选项
--authorization-mode=Node,RBAC \
```



### Role 示例

下面是一个位于 "default" 名字空间的 Role 的示例，可用来授予对 pods 的读访问权限：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" 标明 core API 组
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```



### ClusterRole 示例

下面是一个 ClusterRole 的示例，可用来为任一特定名字空间中的 Secret 授予读访问权限， 或者跨名字空间的访问权限（取决于该角色是如何绑定的）：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" 被忽略，因为 ClusterRoles 不受名字空间限制
  name: secret-reader
rules:
- apiGroups: [""]
  # 在 HTTP 层面，用来访问 Secret 对象的资源的名称为 "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```



### RoleBinding 示例

下面的例子中的 RoleBinding 将 "pod-reader" Role 授予在 "default" 名字空间中的用户 "jane"。 这样，用户 "jane" 就具有了读取 "default" 名字空间中 pods 的权限。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# 此角色绑定允许 "jane" 读取 "default" 名字空间中的 Pods
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# 你可以指定不止一个“subject（主体）”
- kind: User
  name: jane # "name" 是区分大小写的
  apiGroup: rbac.authorization.k8s.io
roleRef:
  # "roleRef" 指定与某 Role 或 ClusterRole 的绑定关系
  kind: Role # 此字段必须是 Role 或 ClusterRole
  name: pod-reader     # 此字段必须与你要绑定的 Role 或 ClusterRole 的名称匹配
  apiGroup: rbac.authorization.k8s.io
```



### ClusterRoleBinding 示例

要跨整个集群完成访问权限的授予，你可以使用一个 ClusterRoleBinding。 下面的 ClusterRoleBinding 允许 "manager" 组内的所有用户访问任何名字空间中的 Secrets。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# 此集群角色绑定允许 “manager” 组中的任何人访问任何名字空间中的 secrets
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager # 'name' 是区分大小写的
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```
