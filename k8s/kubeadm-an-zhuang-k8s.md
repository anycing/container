# kubeadm安装K8s

### 节点规划

| Hostname      | 外网IP      | 内网IP        |
| ------------- | --------- | ----------- |
| k8s-master-01 | 10.0.0.91 | 172.16.1.91 |
| k8s-node-01   | 10.0.0.92 | 172.16.1.92 |
| k8s-node-02   | 10.0.0.93 | 172.16.1.93 |

#### 修改hosts

```bash
cat >> /etc/hosts <<EOF
172.16.1.91    k8s-master-01
172.16.1.92    k8s-node-01
172.16.1.93    k8s-node-01
EOF
```



### 关闭SeLinux

```bash
sed -i 's#enforcing#disabled#g' /etc/sysconfig/selinux

setenforce 0
```



### 关闭 swap 分区

```bash
swapoff -a

sed -i.bak 's/^.*centos-swap/#&/g' /etc/fstab

echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
```



### 配置国内 YUM 源

```bash
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

yum makecache

# 更新系统（不更新内核）
yum update -y --exclud=kernel*
```



### 升级系统内核版本

```bash
curl -o ./kernel-lt.el7.elrepo.x86_64.rpm https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-5.4.87-1.el7.elrepo.x86_64.rpm

curl -o ./kernel-lt-devel.el7.elrepo.x86_64.rpm https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-devel-5.4.87-1.el7.elrepo.x86_64.rpm

yum localinstall -y kernel-lt*

grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --default-kernel

reboot
```



### 安装 ipvs

```bash
yum install -y conntrack-tools ipvsadm ipset conntrack libseccomp

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
    /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /sbin/modprobe \${kernel_module}
        fi
    done
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs
```



### 内核参数优化

```bash
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
fs.inotify.max_user_watches = 89100
fs.file-max = 52706963
fs.nr_open = 52706963
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp.keepaliv.probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp.max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp.max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.top_timestamps = 0
net.core.somaxconn = 16384
EOF

sysctl --system
```



### 安装基础软件

```bash
yum install wget expect vim net-tools ntp bash-completion ipvsadm ipset jq iptables conntrack sysstat libseccomp -y
```



### 关闭防火墙

```bash
systemctl disable --now firewalld
```



### 安装 Docker

{% content-ref url="../docker/an-zhuang-docker.md" %}
[an-zhuang-docker.md](../docker/an-zhuang-docker.md)
{% endcontent-ref %}



### 同步集群时间

```bash
yum install ntp -y

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' > /etc/timezone

ntpdate time2.aliyun.com

# 写入定时任务
*/1 * * * * ntpdate time2.aliyun.com > /dev/null 2>&1
```



### 配置 Kubernetes 源

```bash
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet
```



### 导入镜像

```bash
ls -lh /docker_images/ | awk 'NR>1 {print $NF}' | sed -r 's#(.*)#docker image load -i /docker_images/\1#' | bash
```



### 下载镜像

```bash
# 若无本地镜像则需要进行下载
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/kube-apiserver:v1.20.1
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/kube-controller-manager:v1.20.1
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/kube-scheduler:v1.20.1
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/kube-proxy:v1.20.1
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/pause:3.2
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/etcd:3.4.13-0
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/coredns:1.7.0
docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/flannel:v0.13.1-rc1

# 对下载的镜像进行重新打标签
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/kube-apiserver:v1.20.1 k8s.gcr.io/kube-apiserver:v1.20.1
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/kube-controller-manager:v1.20.1 k8s.gcr.io/kube-controller-manager:v1.20.1
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/kube-scheduler:v1.20.1 k8s.gcr.io/kube-scheduler:v1.20.1
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/kube-proxy:v1.20.1 k8s.gcr.io/kube-proxy:v1.20.1
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/pause:3.2 k8s.gcr.io/pause:3.2
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/etcd:3.4.13-0 k8s.gcr.io/etcd:3.4.13-0
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/coredns:1.7.0 k8s.gcr.io/coredns:1.7.0
docker tag registry.cn-chengdu.aliyuncs.com/willsk8s/flannel:v0.13.1-rc1 quay.io/coreos/:v0.13.1-rc1
```



\-----------------------------------以上步骤在主从节点都需要执行--------------------------



### 节点初始化

```bash
# master 节点执行
kubeadm init \
# --image-repository=registry.cn-chengdu.aliyuncs.com/willsk8s \
--kubernetes-version=v1.20.1 \
--service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16

# 若指定私有镜像仓库需先登录
# docker login --username=any****@gmail.com registry.cn-chengdu.aliyuncs.com
```



### 配置 kubernetes 用户信息

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



### 增加命令提示

```bash
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```



### 安装集群网络插件

```bash
cat > kube-flannel.yml <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp.flannel.unprivileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default
    seccomp.security.alpha.kubernetes.io/defaultProfileName: docker/default
    apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
    apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
spec:
  privileged: false
  volumes:
  - configMap
  - secret
  - emptyDir
  - hostPath
  allowedHostPaths:
  - pathPrefix: "/etc/cni/net.d"
  - pathPrefix: "/etc/kube-flannel"
  - pathPrefix: "/run/flannel"
  readOnlyRootFilesystem: false
  # Users and groups
  runAsUser:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  # Privilege Escalation
  allowPrivilegeEscalation: false
  defaultAllowPrivilegeEscalation: false
  # Capabilities
  allowedCapabilities: ['NET_ADMIN', 'NET_RAW']
  defaultAddCapabilities: []
  requiredDropCapabilities: []
  # Host namespaces
  hostPID: false
  hostIPC: false
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  # SELinux
  seLinux:
    # SELinux is unused in CaaSP
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs: ['use']
  resourceNames: ['psp.flannel.unprivileged']
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
      - operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.13.1-rc1
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.13.1-rc1
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni
        hostPath:
          path: /etc/cni/net.d
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg
EOF
```

```bash
# 下载flannel
# wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 换阿里云自建的容器镜像
# sed -i 's#quay.io/coreos/flannel#registry.cn-chengdu.aliyuncs.com/willsk8s/flannel#g' kube-flannel.yml
# docker pull registry.cn-chengdu.aliyuncs.com/willsk8s/flannel:v0.13.1-rc1

kubectl apply -f kube-flannel.yml

kubectl get pods -n kube-system
kubectl get pods -n kube-system -o wide -w
```



### Node 节点加入集群

```bash
# 使用 master 节点创建 TOKEN
kubeadm token create --print-join-command

# Node 节点执行加入命令
kubeadm join 10.0.0.91:6443 --token 08d1bv.86il62ssgffr7gas \
    --discovery-token-ca-cert-hash sha256:7618fb8e93c806791bf41220ab458c6eab355394a269d65177cabb9aa9b11566
```

###

### 查看部署结果

```bash
kubectl get nodes -o wide
```



### 验证部署结果

```bash
# 部署Nginx，看能否正常提供服务
kubectl get svc

kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

kubectl get pods
kubectl get pods -o wide

kubectl get svc

# 使用浏览器进行访问，看Nginx是否正常提供服务
```
