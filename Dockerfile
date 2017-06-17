FROM docker.finogeeks.club/base/ubuntu

MAINTAINER "linhaitao@finogeeks.com"

ENV VER_NGINX_DEVEL_KIT=0.3.0
ENV VER_LUA_NGINX_MODULE=0.10.8
ENV VER_NGINX=1.11.2
ENV VER_LUAJIT=2.0.5

ENV NGINX_DEVEL_KIT ngx_devel_kit-${VER_NGINX_DEVEL_KIT}
ENV LUA_NGINX_MODULE lua-nginx-module-${VER_LUA_NGINX_MODULE}
ENV NGINX_ROOT=/nginx
ENV WEB_DIR ${NGINX_ROOT}/html

ENV LUAJIT_LIB /usr/local/lib
ENV LUAJIT_INC /usr/local/include/luajit-2.0

WORKDIR /
RUN apt-get -qq update && apt-get -qq -y install wget make gcc libpcre3 libpcre3-dev zlib1g-dev libssl-dev \
    && export https_proxy=http://10.135.186.25:3128 && export http_proxy=http://10.135.186.25:3128 \
    && wget http://nginx.org/download/nginx-${VER_NGINX}.tar.gz \
    && wget http://luajit.org/download/LuaJIT-${VER_LUAJIT}.tar.gz \
    && wget https://github.com/simpl/ngx_devel_kit/archive/v${VER_NGINX_DEVEL_KIT}.tar.gz -O ${NGINX_DEVEL_KIT}.tar.gz \
    && wget https://github.com/openresty/lua-nginx-module/archive/v${VER_LUA_NGINX_MODULE}.tar.gz -O ${LUA_NGINX_MODULE}.tar.gz \
    && tar -xzvf nginx-${VER_NGINX}.tar.gz && rm nginx-${VER_NGINX}.tar.gz \
    && tar -xzvf LuaJIT-${VER_LUAJIT}.tar.gz && rm LuaJIT-${VER_LUAJIT}.tar.gz \
    && tar -xzvf ${NGINX_DEVEL_KIT}.tar.gz && rm ${NGINX_DEVEL_KIT}.tar.gz \
    && tar -xzvf ${LUA_NGINX_MODULE}.tar.gz && rm ${LUA_NGINX_MODULE}.tar.gz

# LuaJIT
WORKDIR /LuaJIT-${VER_LUAJIT}
RUN make && make install

# Nginx with LuaJIT
WORKDIR /nginx-${VER_NGINX}
RUN ./configure --prefix=${NGINX_ROOT} --with-http_ssl_module --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=/${NGINX_DEVEL_KIT} --add-module=/${LUA_NGINX_MODULE} \
    && make -j2 && make install \
    && ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx && ln -s ${NGINX_ROOT}/conf /etc/nginx \
    && apt-get purge --auto-remove -y wget make gcc \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /nginx-${VER_NGINX} /LuaJIT-${VER_LUAJIT} /${NGINX_DEVEL_KIT} /${LUA_NGINX_MODULE} \
    && mkdir /var/log/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

ADD lua ${NGINX_ROOT}/lua

# ***** MISC *****
WORKDIR ${WEB_DIR}
EXPOSE 80
EXPOSE 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
