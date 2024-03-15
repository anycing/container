# 管理数据

### 将数据从宿主机挂载到容器中的三种方式

*   volumes

    * Volumes are stored in a part of the host filesystem which is managed by Docker (/var/lib/docker/volumes/ on Linux). Non-Docker processes should not modify this part of the filesystem. Volumes are the best way to persist data in Docker.


*   bind mounts

    * Bind mounts may be stored anywhere on the host system. They may even be important system files or directories. Non-Docker processes on the Docker host or a Docker container can modify them at any time.


* tmpfs
  * tmpfs mounts are stored in the host system’s memory only, and are never written to the host system’s filesystem.



![the data lives on the Docker host](../.gitbook/assets/types-of-mounts.png)



### volume

#### 查看数据卷

```bash
docker volume ls
```

#### 创建数据卷

```bash
docker volume create nginx_vol

# 创建名为 nginx_vol 的数据卷
```

#### 查看数据卷详细信息

```bash
docker volume inspect nginx_vol

# 查看名为 nginx_vol 的数据卷的详细信息
```

#### 删除数据卷

```bash
docker volume rm nginx_vol

# 删除名为 nginx_vol 的数据卷
```

#### 挂载案例演示

```bash
docker run --name web01 --mount type=volume,src=nginx_vol,dst=/usr/share/nginx/html -d -p 80:80 nginx:latest

# 以上命令中--mount部分也可使用-v方式书写，如下
# docker run --name web01 -v nginx_vol:/usr/share/nginx/html -d -p 80:80 nginx:latest
# 建议使用--mount

# 如果没有指定卷，则会自动创建

# type=volme 默认可省
# source / src 皆可
# destination / target / dst 皆可
```

{% hint style="success" %}
如果数据卷中没有数据，则会同步容器dst目录中的文件至数据卷中
{% endhint %}





### bind-mounts

#### 挂在案例演示

```bash
docker run --name web01 --mount type=bind,src=/mnt,dst=/usr/share/nginx/html -d -p 90:80 nginx:latest

# 如果挂载的宿主机源目录不存在则会直接报错

# 以上命令中--mount部分也可使用-v方式书写，如下
# docker run --name web01 -v /mnt:/usr/share/nginx/html -d -p 91:80 nginx:latest
# 建议使用 --mount 的方式书写
```

{% hint style="warning" %}
如果容器dst目录中有数据（非空），则数据会被隐藏。（若宿主机目录为空，则容器的目录也会为空）
{% endhint %}



### 综合案例

> 基于Nginx启动一个容器，监听80和81端口，访问80出现nginx默认首页，访问81，出现另外一个站点（站点数据在宿主机上的 /mnt/ 目录，容器中网站目录为 /tmp ）

```
docker run -d --name web01 \
-p 80:80 -p 81:81 \
--mount type=bind,src=/server/scripts/tmp.conf,dst=/etc/nginx/conf.d/tmp.conf \
--mount type=bind,src=/mnt,dst=/tmp \
nginx:latest
```

```
cat > /server/scripts/tmp.conf << EOF
server {
    listen       81;
    server_name  localhost;

    location / {
        root   /tmp;
        index  index.html index.htm;
    }
}
EOF
```





**在宿主机与容器之间拷贝文件**

```bash
docker container cp /tmp/hello web01:/usr/share/nginx/html/

# 拷贝宿主机上的 /tmp/hello 至容器 web01 的/usr/share/nginx/html/下
```

