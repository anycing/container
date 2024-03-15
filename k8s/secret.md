# Secret

### 基于文件创建 Secret

#### 准备文件

```bash
# echo 后一定要使用 -n 选项进行不换行，否则会对编码结果造成影响
echo -n 'admin' > ./username.txt
echo -n 'password123' > ./password.txt

```

#### 创建 Secret

```bash
kubectl create secret generic db-user-pass \
  --from-file=./username.txt \
  --from-file=./password.txt

```



### 基于命令行字符串创建 Secret

```bash
# 账号密码使用单引号 '' 引起来，否则如果有转义内容将报错
kubectl create secret generic db-user-pass-2 \
  --from-literal=username='devuser' \
  --from-literal=password='password456'

```



### 基于 yaml 文件创建 Secret

#### 准备 yaml 文件

```bash
cat > mysecret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  USER_NAME: YWRtaW4=
  PASSWORD: cGFzc3dvcmQxMjM=
EOF

```

#### 创建 Secret

```bash
kubectl create -f ./mysecret.yaml

```

{% hint style="warning" %}
此方式需要提前将用户、密码进行base64编码
{% endhint %}



#### 改良后：

```bash
cat > mysecret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
stringData:
  USER_NAME: admin
  PASSWORD: password123456
EOF

```

{% hint style="success" %}
将原yaml文件的 data 改成了 stringData，这样在创建前就不需要提前对相关信息使用base64进行编码了
{% endhint %}

