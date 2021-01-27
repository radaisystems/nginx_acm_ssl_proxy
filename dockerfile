ARG NGINX_VERSION=latest

FROM nginx:$NGINX_VERSION as builder

ARG COOKIE_FLAG_VERSION=1.1.0

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libpcre++-dev \
        zlib1g-dev \
        libgeoip-dev \
        wget \
        git

RUN cd /opt \
    && git clone --depth 1 -b v$COOKIE_FLAG_VERSION --single-branch https://github.com/AirisX/nginx_cookie_flag_module.git \
    && cd /opt/nginx_cookie_flag_module \
    && git submodule update --init \
    && cd /opt \
    && wget -O - http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar zxfv - \
    && mv /opt/nginx-$NGINX_VERSION /opt/nginx \
    && cd /opt/nginx \
    && ./configure --with-compat --add-dynamic-module=/opt/nginx_cookie_flag_module \
    && make modules

FROM nginx:$NGINX_VERSION

COPY --from=builder /opt/nginx/objs/ngx_http_cookie_flag_filter_module.so /usr/lib/nginx/modules

RUN chmod -R 644 \
        /usr/lib/nginx/modules/ngx_http_cookie_flag_filter_module.so \
    && sed -i '1iload_module \/usr\/lib\/nginx\/modules\/ngx_http_cookie_flag_filter_module.so;' /etc/nginx/nginx.conf 

# END building nginx with custom module(s)


ENV NX_PROXY_BUFFER_NUMBER=16
ENV NX_PROXY_BUFFER_SIZE=4k

# All this just for the awscli
RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-pip \
        python3-setuptools \
        curl \
        jq \
    && python3 -m pip --no-cache-dir install --upgrade pip \
    && python3 -m pip --no-cache-dir install --upgrade awscli \
    && apt-get clean


# Copy our launch and configuration files
COPY ./scripts /opt/scripts
COPY conf/default.conf /default.conf

# Remove built in default.conf- it gets replaced by launch_proxy.sh
RUN rm -f /etc/nginx/conf.d/default.conf

# Upstream nginx uses CMD instead of ENTRYPOINT so we do too.
CMD ["bash", "/opt/scripts/entrypoint.sh"]
