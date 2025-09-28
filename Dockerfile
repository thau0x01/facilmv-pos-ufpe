FROM php:5.6-apache

# Corrigir repositórios antigos do Debian
RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99allow-unauthenticated && \
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false --allow-unauthenticated

# Instala dependências (sem freetds/libsybdb)
RUN apt-get install -y --allow-unauthenticated \
    libpng-dev libjpeg-dev \
    libpq-dev \
    git zip unzip

# Instala apenas extensões necessárias
RUN docker-php-ext-install \
    gd \
    pdo_pgsql \
    pdo_mysql

# Instala Xdebug compatível com PHP 5.6
RUN mkdir -p /opt/xdebug && \
    cd /opt/xdebug && \
    curl -k -L https://github.com/xdebug/xdebug/archive/XDEBUG_2_5_5.tar.gz | tar zx && \
    cd xdebug-XDEBUG_2_5_5 && \
    phpize && \
    ./configure --enable-xdebug && \
    make clean && sed -i 's/-O2/-O0/g' Makefile && \
    make && make install && \
    rm -rf /opt/xdebug

# Ativa o módulo do Apache e extensões
RUN docker-php-ext-enable xdebug && \
    a2enmod rewrite && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurações do PHP
RUN echo "date.timezone=America/Recife" > /usr/local/etc/php/conf.d/timezone.ini && \
    echo "short_open_tag=On" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "display_errors=On" >> /usr/local/etc/php/conf.d/custom.ini

# Configurações do Xdebug
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Copia aplicação
COPY . /var/www/html/
COPY .htaccess /var/www/html/.htaccess

# Permissões
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

EXPOSE 80
