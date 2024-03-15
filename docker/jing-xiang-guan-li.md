# 镜像管理

### 搜索镜像

```bash
docker search <image_name>|<image_id>

# 搜索名称为 redis 的docker镜像：
# docker search redis

# -f 过滤输出内容
#    is-official=true 过滤官方镜像
#    stars=30 过滤收藏超过30次的镜像
#
#    案例：docker search -f is-official=true redis

# --limit 限制输出结果的个数
#    案例：docker search --limit 5 redis

# --no-trunc 不截断输出信息（显示完整信息）
```

### 拉取镜像

```bash
docker pull busybox

# 拉取名称为 busybox 的docker镜像
# 默认拉取最新版本
# 推送为 push


docker pull busybox:1.29

# 拉取指定版本的doker镜像
# 版本需要去官网查看，hub.docker.com
```

### 查看镜像

```bash
# 查看本地有哪些镜像

docker image ls

# -a 列出所有镜像（含临时文件）
# -l 只显示镜像短ID
# --digests 列出更全的镜像信息


# 查看指定镜像的详细信息
docker image inspect <image_name>|<image_id>
# -f '{{.xx}}' 获取指定xx字段信息


# 查看指定镜像的构建历史信息
docker image history <image_name>|<image_id>
```

### 导出镜像

```bash
docker image save -o docker_busybox1.29.tar busybox:1.29

# 导出版本号为1.29的busybox镜像到本地目录，导出名称为docker_busybox1.29.tar
# -o 指定导出路径
# 支持将多个镜像打包到一个包中，镜像名称或ID之间用空格隔开

```

#### 导出多个镜像

```bash
docker save -o /opt/nginx.tar nginx:1.19.7 nginx:1.19.8 nginx:1.19.9

# 导出后大小
# 393M nginx.tar
```

#### 导出多个镜像并压缩之gzip

```bash
docker save -o /opt/nginx.tar nginx:1.19.7 nginx:1.19.8 nginx:1.19.9 && gzip -c nginx.tar > nginx.tar.gz
# 简写为
docker save nginx:1.19.7 nginx:1.19.8 nginx:1.19.9 | gzip > /opt/nginx.tar.gz

# 导出后大小
# 149M nginx.tar.gz
```

#### 导出多个镜像并压缩之rar

```bash
docker save -o nginx.tar nginx:1.19.7 nginx:1.19.8 nginx:1.19.9 && rar a nginx.rar nginx.tar > /dev/null

# 导出后大小
# 100M nginx.rar

# rar需要下载软件，官网为：https://www.rarlab.com
# 直接下载地址：
# https://www.rarlab.com/rar/rarlinux-x64-6.0.0.tar.gz


# 直接使用rar命令需要导出环境变量或者复制到环境变量路径下
# 以下载解压后目录为/opt/rar为例
# 导出环境变量命令如下：
# export PATH=$PATH:/opt/rar/
# 复制命令如下：
# cp /opt/rar /opt/unrar /usr/local/bin
```

### 导入镜像

```bash
docker image load -i docker_busybox1.29.tar

# 导入当前目录下名称为docker_busybox1.29.tar的镜像
# -i 指定镜像文件路径

# import 导入会丢掉镜像的标签，所以一般用 load 命令导入
```

#### 批量导入镜像

```bash
ls -lh *.tar.gz | awk '{print $NF}' | sed -r 's#(.*)#docker load -i \1#' | bash

# 批量导入当前目录下tar.gz格式的镜像
```

### 删除镜像

```bash
docker image rm <image_name>|<image_id>
# 删除指定版本的docker镜像，不接版本默认删除最新版
# 案例：docker image rm busybox:1.29

docker image prune
# 清理未使用的镜像（删除所有未使用的镜像）
# -a 删除所有未使用的镜像，而不仅仅是悬空的镜像
# -f 不提示确认直接删除
```

####
