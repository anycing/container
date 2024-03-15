# 手动制作镜像

### 制作基于CentOS6.9的nginx镜像

#### 准备镜像及容器

```bash
# 拉取镜像
docker pull centos:6.9

# 启动并进入容器
docker run --name web01 -it -p 80:80 centos:6.9 /bin/bash
```

#### 安装环境

```bash
# 配置国内软件源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
curl -o /etc/yum.repos.d/epel-6.repo http://mirrors.aliyun.com/repo/epel-6.repo


# 安装 nginx
yum install nginx -y


# 启动nginx
nginx -g 'daemon off;'


# 访问测试
# 退出容器
```

#### 提交镜像

```bash
docker container commit web01 centos6.9_nginx:v1
```

#### 运行测试

```bash
docker run -d -p 80:80 centos6.9_nginx:v1 nginx -g 'daemon off;'
```



### 制作PHP环境的镜像（运行可道云）

#### 准备镜像及容器

```bash
# 启动并进入容器（基于上方centos6.9_nginx:v1镜像）
docker run --name web02 -it -p 80:80 centos6.9_nginx:v1 /bin/bash
```

#### 安装环境

```bash
# 安装PHP及运行可道云所需的PHP包
yum install php-fpm php-gd php-mbstring -y

# 修改PHP配置文件
sed -i 's#user = apache#user = nginx#g' /etc/php-fpm.d/www.conf
sed -i 's#group = apache#group = nginx#g' /etc/php-fpm.d/www.conf

# 启动PHP
service php-fpm start


# 修改nginx配置文件
# 若新建配置文件则用如下命令：
# grep -Ev '^$|#' /etc/nginx/nginx.conf.default > /etc/nginx/nginx.conf
# /etc/nginx/nginx.conf.default 为nginx提供的默认配置参考

# 此案例在默认配置文件的基础上进行修改
sed -i '14a \ \ \ \ \ \ \ \ index index.php index.html index.htm;' /etc/nginx/conf.d/default.conf
sed -i '17a \ \ \ \ location ~ \\\.php\$ {\n\ \ \ \ \ \ \ \ #root           html;\n\ \ \ \ \ \ \ \ fastcgi_pass   127.0.0.1:9000;\n\ \ \ \ \ \ \ \ fastcgi_index  index.php;\n\ \ \ \ \ \ \ \ fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;\n\ \ \ \ \ \ \ \ include        fastcgi_params;\n\ \ \ \ }\n' /etc/nginx/conf.d/default.conf

# 测试nginx配置
nginx -t


# 文件准备
rm -rf /usr/share/nginx/html/*

# 下载可道云源码包
curl -o /opt/kod.zip http://static.kodcloud.com/update/download/kodbox.1.13.zip

# 安装unzip
yum install unzip -y

# 解压可道云
unzip /opt/kod.zip -d /usr/share/nginx/html

# 修改文件属主及属组
chown -R nginx:nginx /usr/share/nginx/html

# 启动nginx
service nginx start

# 访问测试


# 配置服务启动脚本
cat > /init.sh << EOF
#!/bin/bash

service php-fpm start
nginx -g 'daemon off;'
EOF

# 停止服务
service php-fpm stop
service nginx stop

# 使用脚本启动
sh /init.sh

# 访问测试
# 退出容器
```

#### 将容器提交为镜像

```bash
docker commit web02 kod:v1
```

#### 将容器直接导出为文件

```bash
docker export -o /tmp/kod_v1.tar web02

# 将文件导入为镜像
docker import /tmp/kod_v1.tar 
```

#### 运行测试

```bash
docker run -d -p 80:80 kod:v1 /bin/bash /init.sh
```



### 制作MySQL环境的镜像（运行phpwind）

#### 准备镜像及容器

```bash
# 启动并进入容器（基于上方kod:v1镜像）
docker run --name web03 -it -p 80:80 kod:v1 /bin/bash
```

#### 安装环境

```bash
# 安装MySQL
yum install mysql-server -y
service mysqld start

# 安装phpwind运行所需软件包
yum install php-mysql php-mcrypt php-xml php-dom -y

# 准备软件源代码
rm -rf /usr/share/nginx/html/*
unzip /opt/phpwind.zip -d /usr/share/nginx/html/
mv /usr/share/nginx/html/phpwind/upload/* /usr/share/nginx/html/
rm -rf /usr/share/nginx/html/phpwind/
chown -R nginx:nginx /usr/share/nginx/html/


# 创建phpwind数据库及创建root秘密
mysql
> create database phpwind;
> exit

mysqladmin -uroot password '123456'

# 启动服务
service php-fpm start
service nginx start


# 访问测试


# 修改启动脚本
sed -i '2a service mysqld start' /init.sh

# 停止服务
service nginx stop
service php-fpm stop
service mysqld stop

# 使用脚本启动
sh /init.sh
# 访问测试
# 退出容器
```

#### 提交镜像

```bash
docker commit web03 phpwind:v1
```

#### 运行测试

```bash
docker run -d -p 80:80 phpwind:v1 /bin/bash /init.sh
```





{% file src="../.gitbook/assets/phpwind.zip" %}

{% hint style="danger" %}
docker运行镜像需注意时区问题，使用如下命令修改时区

/bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
{% endhint %}

> 万能hang住命令：tail -F \<file>

