#!/bin/bash

function green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
green "====输入解析到此VPS的域名===="
read domain

sleep 2

yum -y install yum-utils
yum -y install epel-release

yum -y install wget unzip
yum -y install libtool perl-core zlib-devel gcc pcre*

sleep 2

cd ~
mkdir v2ray
wget https://github.com/v2ray/v2ray-core/releases/download/v4.22.1/v2ray-linux-64.zip -P ./v2ray
unzip ./v2ray/v2ray-linux-64.zip -d ./v2ray

sleep 2

sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
setenforce 0

sleep 2

wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
tar xzvf openssl-1.1.1d.tar.gz

sleep 2

useradd nginx
wget https://nginx.org/download/nginx-1.16.1.tar.gz
tar xf nginx-1.16.1.tar.gz && rm nginx-1.16.1.tar.gz
cd nginx-1.16.1
./configure    \
        --user=nginx    \
        --group=nginx    \
        --with-openssl=../openssl-1.1.1d    \
        --with-openssl-opt='enable-tls1_3'    \
        --with-http_v2_module    \
        --with-http_ssl_module    \
        --with-http_gzip_static_module    \
        --with-http_stub_status_module    \
        --with-http_sub_module    \
        --with-stream    \
        --with-stream_ssl_module
make && make install

/usr/local/nginx/sbin/nginx

curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /usr/local/nginx/html/
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /usr/local/nginx/conf/$domain.key \
        --fullchain-file /usr/local/nginx/conf/fullchain.cer \
        --reloadcmd  "service nginx force-reload"



cat > /usr/local/nginx/conf/nginx.conf <<-EOF
user nginx;
worker_processes 1;
pid        /usr/local/nginx/logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /usr/local/nginx/conf/mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  120;
    client_max_body_size 20m;
	
	server {
		listen       80;
		server_name  $domain;
		rewrite ^(.*)$  https://\${server_name}\$1 permanent;
	}
	server {
		listen 443 ssl http2;
		server_name $domain;
		root /usr/local/nginx/html;
		index index.php index.html;
		ssl_certificate /usr/local/nginx/conf/fullchain.cer;
		ssl_certificate_key /usr/local/nginx/conf/$domain.key;
		#TLS 版本控制
		ssl_protocols   TLSv1.3;
		ssl_ciphers     TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256;
		ssl_prefer_server_ciphers   on;
		# 开启 1.3 0-RTT
		ssl_early_data on;
		ssl_stapling on;
		ssl_stapling_verify on;
		
		location /order {
			proxy_redirect off;
			proxy_pass http://127.0.0.1:8986;
			proxy_http_version 1.1;
			proxy_set_header Upgrade \$http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_set_header Host \$http_host;
		}
	
	}
}
EOF