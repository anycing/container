# docker-compose

> docker-compose 为单机版的容器编排工具，不能跨宿主机



### 案例演示：搭建WordPress

#### docker-compose安装

```bash
# 需epel源

yum install docker-compose -y
```

#### 准备目录

```bash
mkdir /opt/docker-compose
cd /opt/docker-compose

mkdir wordpress
cd wordpress
```

#### 准备docker-compose.yml文件

```bash
cat > docker-compose.yml << EOF
version: '3'

services:
    db:
      image: mysql:5.7
      volumes:
        - db_data:/var/lib/mysql
      restart: always
      environment:
        MYSQL_ROOT_PASSWORD: toor123456..
        MYSQL_DATABASE: wordpress
        MYSQL_USER: wpadmin
        MYSQL_PASSWORD: wppassword

    wordpress:
      depends_on:
        - db
      image: wordpress:latest
      volumes:
        - web_data:/var/www/html
      ports:
        - "80:80"
      restart: always
      environment:
        WORDPRESS_DB_HOST: db
        WORDPRESS_DB_USER: wpadmin
        WORDPRESS_DB_PASSWORD: wppassword

volumes:
    db_data:
    web_data:
EOF


# 如果要启动多个容器，为防止端口冲突导致容器启动失败，则使用随机映射端口的方式，如下：
# ports:
#   - "80"

# 可不使用卷直接挂载宿主机目录至容器，如下
# volumes:
#   - /data/db_data:/var/lib/mysql
# 宿主机如果没有/data/db_data目录则会自动创建
```

#### 启动容器

```bash
docker-compose up -d
# 创建并启动容器，-d在后台运行

# 创建并启动容器
docker-compose up

# 停止并删除容器
docker-compose down

# 重启全部容器
docker-compose restart
# 启动全部容器
docker-compose start
# 停止全部同期
docker-compose stop
```

#### 动态调整容器的数量

```bash
docker-compose up -d --scale wordpress=5
# 此处为调整运行wordpress服务的容器数量为5个
```
