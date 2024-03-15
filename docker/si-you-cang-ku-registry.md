# 私有仓库registry

### 搭建私有仓库

#### 准备镜像及启动容器

```bash
# 拉取registry镜像
docker pull registry

# 创建本地目录挂载目录
mkdir /opt/local_registry

# 启动registry容器
docker run -d \
-p 5000:5000 \
--restart always \
--mount type=bind,src=/opt/local_registry,dst=/var/lib/registry \
--name registry \
registry
```

#### 推送镜像

```bash
# 先准备一个镜像
docker pull nginx

# 创建一个标签
# docker tag ID | <local_name>:<tag> <REMOTE_name>:<new_tag>
docker tag nginx:latest 10.0.0.71:5000/nginx:latest

# 推送镜像
docker push 10.0.0.71:5000/nginx:latest

# 抛出错误信息:
# Get https://10.0.0.71:5000/v2/: http: server gave HTTP response to HTTPS client
# 需要修改/etc/docker/daemon.json 添加信任的私有仓库
# "insecure-registries": ["10.0.0.71:5000"]
```

#### 查看镜像

```bash
# 查看镜像列表，浏览器访问
http://10.0.0.71:5000/v2/_catalog

# 查看镜像版本，浏览器访问（此处为查看nginx镜像的版本，查看其他镜像换掉nginx字符串即可）
http://10.0.0.71:5000/v2/nginx/tags/list
```



### 配置带basic认证的registry

#### 配置basic认证账号密码

```bash
yum install httpd-tools -y

mkdir -p /opt/local_registry_var/auth/

htpasswd -Bbn user01 user01_password >> /opt/local_registry_var/auth/htpasswd
# user01为账号，user01_password为密码
```

#### 启动docker容器

```bash
docker run -d -p 5000:5000 \
--name registry01 \
--restart always \
--mount type=bind,src=/opt/local_registry,dst=/var/lib/registry \
--mount type=bind,src=/opt/local_registry_var/auth,dst=/auth \
--env "REGISTRY_AUTH=htpasswd" \
--env "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
--env "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
registry
```

#### 测试拉取镜像

```bash
docker pull 10.0.0.71:5000/nginx
# 抛出错误
# Error response from daemon: Get http://10.0.0.71:5000/v2/nginx/manifests/latest: no basic auth credentials

# 登录
docker login 10.0.0.71:5000
# 登录成功后密码保存在 /root/.docker/config.json
# 直接保存此文件发给别人则无需登录

# 再次拉取
docker pull 10.0.0.71:5000/nginx
```



### 删除仓库里的镜像

#### 进入 docker registry 容器

```bash
docker exec -it  registry01 /bin/sh
```

#### 删除repositories中的镜像

```bash
rm -rf /var/lib/registry/docker/registry/v2/repositories/nginx/
# 删除哪个镜像结尾的目录就是镜像名，此处为nginx
# 这一步删除后还需清理blobs，不然空间不释放
```

#### 清理blobs

```bash
registry garbage-collect /etc/docker/registry/config.yml
```

