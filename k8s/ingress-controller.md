# Ingress Controller

参考：[https://www.cnblogs.com/hsyw/p/17804493.html](https://www.cnblogs.com/hsyw/p/17804493.html)



### 下载Ingress

#### 使用helm仓库

```bash
helm repo list
helm repo add nginx-stable https://helm.nginx.com/stable
helm search repo nginx-ingress
helm pull ingress-nginx/ingress-nginx # 拉取最新版 
helm pull ingress-nginx/ingress-nginx --version 4.9.0 --untar # 拉取4.9.0，不解压
```

#### 使用github直接下载

```bash
# 地址：https://github.com/kubernetes/ingress-nginx/releases

# 此处下载helm-charts，使用helm方式部署
wget https://github.com/kubernetes/ingress-nginx/releases/download/helm-chart-4.9.1/ingress-nginx-4.9.1.tgz
```



### 部署ingress-controller

#### 修改配置

```bash
tar xf ingress-nginx-4.9.1.tgz
cd ingress-nginx

vim values.yaml
# 修改所有 registry: registry.k8s.io 为国内镜像地址
# 其余各项参考https://www.cnblogs.com/hsyw/p/17804493.html
```

#### 安装

```bash
helm upgrade --install ingress-nginx -n ingress-nginx -f ./values.yaml .
```

#### 卸载

```bash
helm delete ingress-nginx -n ingress-nginx
```

