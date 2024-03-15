# 使用Secret管理https证书

#### 准备 ssl 证书文件

```bash
# 正常情况下为购买，此处为演示方便使用本地生产的方式
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=test.com"

```

#### 创建 Secret

```bash
kubectl create secret tls nginx-test-tls --cert=./tls.crt --key=./tls.key

```

#### 挂载使用

```bash
# ingress yaml 文件里一级添加：
tls:
- secretName: nginx-test-tls
```
