# 网络访问

### -p / -P 参数说明

| 参数 | 说明   |
| -- | ---- |
| -P | 随机映射 |
| -p | 指定端口 |



### 随机分配映射端口

```bash
docker pull ghost

docker run -d -P ghost

# 启动ghost博客并随机分配映射端口

# -P 宿主机随机分配映射端口
```

#### 查看端口映射

```bash
iptables -t nat -L -n
```



### 指定映射端口

```
docker run -d -p 81:80 nginx
```

#### 访问测试

```
curl 10.0.0.71:81
```



### 同主机使用多ip的相同端口提供映射服务

#### 宿主机添加多ip

```
ifconfig ens33:1 10.0.0.72/24 up

ifconfig ens33:1
```

#### 指定端口映射

```
docker run -d -p 10.0.0.71:80:2368 ghost

docker run -d -p 10.0.0.72:80:2368 ghost
```

#### 测试访问

```bash
curl 10.0.0.71

curl 10.0.0.72
```



### 同ip使用随机端口映射相同服务

#### 开启服务指定映射

```bash
docker run -d -p 10.0.0.71::2368 ghost

docker run -d -p 10.0.0.71::2368 ghost


docker run -d -p 10.0.0.71::2368/udp ghost
# 指定udp协议进行映射
```

```
iptables -t nat -L -n
```

#### 访问测试

```
curl 10.0.0.71:上面结果中的随机端口
```

