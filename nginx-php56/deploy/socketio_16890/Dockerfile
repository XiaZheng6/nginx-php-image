FROM baseimage-nginx-php56:latest

ENV TZ="Asia/Shanghai"

COPY socketio /data/www/socketio
COPY ng_socket.conf /usr/local/nginx/conf/nginx.conf

WORKDIR /data/www/socketio/socket

CMD ["/usr/local/php/bin/php", "server.php", "start"]

EXPOSE 2050
EXPOSE 2051