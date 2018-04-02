# STAGE 1. Build
FROM bitnami/minideb:stretch as builder

# Install requirements
RUN apt update && \
    apt install -y make build-essential libpcre3-dev zlibc zlib1g-dev checkinstall

ENV LUAJIT_VER="2.0.5" \
    NGINX_DEV_KIT_VER="0.3.0" \
    NGINX_VER="1.13.10" \
    NGINX_LUA_VER="0.10.11"

# Install lua
ADD http://luajit.org/download/LuaJIT-${LUAJIT_VER}.tar.gz ./
RUN tar xvf LuaJIT-${LUAJIT_VER}.tar.gz
RUN cd LuaJIT-${LUAJIT_VER} && \
    make && make install

# Download and untar ngx devel kit and lua-nginx-module
ADD https://github.com/simplresty/ngx_devel_kit/archive/v${NGINX_DEV_KIT_VER}.tar.gz ./
RUN tar xvf v${NGINX_DEV_KIT_VER}.tar.gz
ADD https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_VER}.tar.gz ./
RUN tar xvf v${NGINX_LUA_VER}.tar.gz

# Compile nginx with required options and create deb file
ADD http://nginx.org/download/nginx-${NGINX_VER}.tar.gz ./
ENV LUAJIT_LIB=/usr/local/lib \
    LUAJIT_INC=/usr/local/include/luajit-2.0/
RUN tar xvf nginx-${NGINX_VER}.tar.gz
WORKDIR /nginx-${NGINX_VER}
RUN ./configure --prefix=/etc/nginx \
                --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
                --error-log-path=/var/log/nginx_error.log \
                --http-log-path=/var/log/nginx_access.log \
                --pid-path=/var/run/nginx.pid \
                --add-module=/ngx_devel_kit-${NGINX_DEV_KIT_VER} \
                --add-dynamic-module=/lua-nginx-module-${NGINX_LUA_VER}
RUN checkinstall --install=no -D -y --maintainer=pzab --pkgversion=$NGINX_VER --pkgname=nginx

# STAGE 2. Dockerize
FROM bitnami/minideb:stretch as application
ENV NGINX_VER="1.13.10"
COPY --from=builder /nginx-${NGINX_VER}/nginx_${NGINX_VER}-1_amd64.deb /nginx_${NGINX_VER}_amd64.deb
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib/libluajit-5.1.so.2
RUN dpkg -i nginx_${NGINX_VER}_amd64.deb
EXPOSE 80
CMD ["/etc/nginx/sbin/nginx", "-g", "daemon off;"]
