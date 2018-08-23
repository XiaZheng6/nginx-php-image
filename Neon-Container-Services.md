# Neon容器服务

## 单节点单店架构

![底层架构图](/Users/xiazheng/Documents/底层架构图.jpg)

项目地址：

### 基础镜像

此镜像以 centos7.2 为 base，编译安装 nginx 和 php，使用 supervisord 进行多进程管理。

#### baeseimage-php56

include:

* centos/7.2
* nginx/1.15
* php/5.6

Dockerfile: 

#### baseimage-php72

include:

- centos/7.2
- nginx/1.15
- php/7.2

Dockerfile: 

### 服务镜像

以基础镜像为 base，将服务代码和相关配置拷贝至主目录（不同服务的主目录不同，需特别注意）。

#### neon/web

Dockerfile:

```dockerfile
FROM baseimage-php56:latest

ENV TZ="Asia/Shanghai"

ADD neonweb /data/www/
ADD ng_web.conf /usr/local/nginx/conf/nginx.conf
```



#### neon/api

Dockerfile:

```dockerfile
FROM baseimage-php56:latest

ENV TZ="Asia/Shanghai"

COPY neon_api /data/www/neon_api
COPY ng_api.conf /usr/local/nginx/conf/nginx.conf
```



#### neon/socketio

Dockerfile:

```dockerfile
FROM baseimage-php56:latest

ENV TZ="Asia/Shanghai"

COPY socketio /data/www/socketio
COPY ng_socket.conf /usr/local/nginx/conf/nginx.conf

WORKDIR /data/www/socketio/socket

CMD ["/usr/local/php/bin/php", "server.php", "start"]

EXPOSE 2050
EXPOSE 2051
```



#### neon/stock

Dockerfile:

```dockerfile
FROM baseimage-php7:latest

ENV TZ="Asia/Shanghai"

COPY neon_stock /data/www/neon_stock
COPY ng_stock.conf /usr/local/nginx/conf/nginx.conf
```



### 容器启动及端口

#### web

```shell
docker run --name web -p 16888:80 -v /data/volume/web/Runtime:/data/www/App/Runtime -v /data/volume/web/Upload:/data/www/Upload -v /data/volume/web/Public/img:/data/www/Public/img -v /data/volume/web/Public/Upload:/data/www/Public/Upload -d neon/web
```



#### api

```shell
docker run --name api -p 16889:80 -v /data/volume/api/Public/Runtime:/data/www/neon_api/Public/Runtime -v /data/volume/api/Public/Upload:/data/www/neon_api/Public/Upload -d neon/api
```



#### socketio

```shell
docker run --name socket -p 16890:80 -p 2051:2051 -p 2050:2050 -d neon/socket
```



#### stock

```shell
docker run --name stock -p 16891:80 -d neon/stock
```



### Nginx代理

#### 容器Nginx配置

针对PHP版本和框架进行相应设置

##### php56

```
user www www;  #modify
worker_processes auto;  #modify

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
error_log /var/log/nginx_error.log crit;  #add

#pid        logs/nginx.pid;
pid /var/run/nginx.pid;  #modify
worker_rlimit_nofile 51200;


events {
    use epoll;
    worker_connections 51200;
    multi_accept on;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    client_max_body_size 100m;  #add
    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  120; #65;

    #gzip  on;

    server {
        listen       80;
	    server_name web1.neon.teamar.cn;
        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        root   /data/www;
        include /usr/local/nginx/conf/rewrite/thinkphp.conf;
        index  index.php index.html index.htm;

        #location / {
        #    try_files $uri $uri/ /index.php?$args;
        #}

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        location ~ \.php$ {
            root           /data/www;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /$document_root$fastcgi_script_name;
            include        fastcgi_params;
            set $real_script_name $fastcgi_script_name;
            if ($fastcgi_script_name ~ "^(.+?\.php)(/.+)$") {
              set $real_script_name $1;
            }
            fastcgi_param SCRIPT_NAME $real_script_name;
        }
        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
          expires 30d;
          access_log off;
        }
        location ~ .*\.(js|css)?$ {
          expires 7d;
          access_log off;
        }
        location ~ /\.ht {
          deny all;
        }
    }

    #add
    ##########################vhost#####################################
    include vhost/*.conf;

}

daemon off;
```

##### Php72

```
user www www;  #modify
worker_processes auto;  #modify

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
error_log /var/log/nginx_error.log crit;  #add

#pid        logs/nginx.pid;
pid /var/run/nginx.pid;  #modify
worker_rlimit_nofile 51200;


events {
    use epoll;
    worker_connections 51200;
    multi_accept on;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    client_max_body_size 100m;  #add
    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  120; #65;

    #gzip  on;

    server {
        listen       80;
        server_name  web1.neon.teamar.cn;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        root   /data/www/neon_stock/public;
        index  index.php index.html index.htm;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        location ~ \.php$ {
            root           /data/www/neon_stock/public;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /$document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }

    #add
    ##########################vhost#####################################
    include vhost/*.conf;

}

daemon off;
```



#### 宿主机 Nginx 配置

不同服务配置不同端口，且端口固定，不可更改，配置文件在vhost目录下

##### web1-web.conf

```
server {
    listen 80;
    server_name web1.neon.teamar.cn;
    access_log /data/wwwlogs/access_nginx_web.log combined;
    #error_page 404 /404.html;
    #error_page 502 /502.html;
    location / {
      proxy_pass http://10.25.82.53:16888;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      client_max_body_size 6m;
    }
  }
```



##### web1-api.conf

```
server {
    listen 8089;
    server_name web1.neon.teamar.cn;
    access_log /data/wwwlogs/access_nginx_stock.log combined;
    #error_page 404 /404.html;
    #error_page 502 /502.html;
    location / {
      proxy_pass http://10.25.82.53:16889;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      client_max_body_size 6m;
    }
  }
```



##### web1-socketio.conf

```
server {
    listen 8989;
    server_name web1.neon.teamar.cn;
    access_log /data/wwwlogs/access_nginx_stock.log combined;
    #error_page 404 /404.html;
    #error_page 502 /502.html;
    location / {
      proxy_pass http://10.25.82.53:16890;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      client_max_body_size 6m;
    }
  }
```



##### web1-stock.conf

```
server {
    listen 8899;
    server_name web1.neon.teamar.cn;
    access_log /data/wwwlogs/access_nginx_stock.log combined;
    #error_page 404 /404.html;
    #error_page 502 /502.html;
    location / {
      proxy_pass http://10.25.82.53:16891;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      client_max_body_size 6m;
    }
  }
```



### 挂载目录

宿主机创建目录，结构如下：

#### web

```
├── Public
│   ├── img
│   └── Upload
├── Runtime
└── Upload
    ├── excel
    └── UploadErrorlog
```

Public/img:/data/www/Public/img

Public/Upload:/data/www/Public/Upload 

Runtime:/data/www/App/Runtime 

Upload:/data/www/Upload 

#### api

```
└── Public
    ├── Runtime
    └── Upload
```

Public/Runtime:/data/www/neon_api/Public/Runtime 

Public/Upload:/data/www/neon_api/Public/Upload

### 定时任务

定时任务使用docker容器独立运行

Dockerfile:

```dockerfile
FROM ubuntu:14.04

ENV TZ Asia/Shanghai
# Add crontab file in the cron directory
ADD crontab /etc/cron.d/hello-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/hello-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

#Install Cron
RUN apt-get update
RUN apt-get -y install cron


# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
```



## 单节点多店架构

## 多节点多店架构

# 部署



