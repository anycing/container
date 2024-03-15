# 常用命令

### 创建并运行容器

```bash
docker run -it --name centos6 centos:6.9 /bin/bash

# -it 分配交互式的终端 interactive tty
# -d 以守护进程的方式运行（在后台运行）
# -p 端口映射
# -v 源地址（宿主机）：目标地址（容器）
# --name 指定容器的名称
# /bin/bash 覆盖容器的初始命令
# --rm 当容器退出时自动删除

# docker run = docker create + docker start
```

### 查看容器

```bash
docker container ls

docker ps

#查看当前运行的容器


docker container ls -a -q

docker ps -a -q

# -a 查看所有状态容器（包括历史记录）
# -q 安静模式显示，只显示ID号
# -l 最近一个容器
# --no-trunc 不截断信息（完整显示信息）
```

### 启动和停止容器

```bash
docker start centos6

# 可直接将 docker container ls -a 中已结束的容器启动
# centos6为上方命令中的容器名称


docker stop 0c810a1cbf32

# 数字为容器id
# 可在 docker container ls -a 中查看

# 名称和ID都可启动和停止容器


docker kill centos6

# 直接杀死容器进程
```

### 删除容器

```bash
docker container rm centos6
# 删除名为 centos6 的容器


docker container rm -f `docker ps -a -q`
# container可省
# 删除所有容器
# 可使用名称和ID删除
# -f 强制删除运行中的容器

# -a, --all    Show all containers (default shows just running)
# -q, --quiet  Only display numeric IDs
```

### 进入正在运行的容器

```bash
docker attach cf35142ac80a

# 使用同一个终端进入容器（两边终端会同步）
# Ctrl + p , Ctrl + q (可以偷偷离开)


docker container exec -it cf35142ac80a /bin/bash
# Ctrl + d 或 exit 退出

# 重新分配一个终端进入指定容器
```

