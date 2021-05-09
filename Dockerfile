#Indicar la primera imagen a utilizar, en este caso Debian, y establecer un Alias para después poder importar
#archivos desde este contenedor.
FROM debian AS builder

#Establecer variables de zona y para que no nos salgan errores de frontend
ENV TZ=Europe/Madrid
ENV DEBIAN_FRONTEND=noninteractive

#Establecemos el diretcorio por defecto
WORKDIR /var/www/html

#Copiamos el script de instalación de todos los módulos de modsecurity.
COPY modsec.conf /var/www/html

#Instalamos todos los paquetes necesarios y ejecutamos el script.
RUN apt-get update -y -qq >/dev/null \
    && apt-get install -y bison build-essential ca-certificates curl dh-autoreconf doxygen flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev libpcre3-dev libpcre++-dev libssl-dev libtool libxslt1-dev libgd-dev libxml2 libxml2-dev libyajl-dev locales lua5.3-dev pkg-config wget zlib1g-dev zlibc nginx php7.3-fpm >/dev/null \
    && apt-get purge --auto-remove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    && bash modsec.conf


#Indicar la imagen a utilizar para el contenedor final, en este caso Debian
FROM debian

#Establecer variables de zona y para que no nos salgan errores de frontend
ENV TZ=Europe/Madrid
ENV DEBIAN_FRONTEND=noninteractive

#Directorio por defecto
WORKDIR /var/www/html

#Instalación de paquetes
RUN apt-get update -y -qq >/dev/null \
    && apt-get install -y nano nginx php7.3-fpm >/dev/null \
    && apt-get purge --auto-remove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    && mkdir /etc/nginx/ssl

#Copia de los archivos de la página, de toda la configuración de Modsecurity del contenedor "builder", y algunos ficheros para configurar nginx
COPY public_html  /var/www/html/public_html
COPY private /var/www/html/private
COPY index.php /var/www/html/index.php
COPY --from=builder /downloads/nginx-1.14.2/objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
COPY --from=builder /downloads/owasp-modsecurity-crs /usr/local/owasp-modsecurity-crs
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/
COPY --from=builder /downloads/ModSecurity/unicode.mapping /etc/nginx/modsec/
COPY --from=builder /lib/x86_64-linux-gnu /lib/x86_64-linux-gnu
COPY nginx.conf /etc/nginx/nginx.conf
COPY htpasswd /etc/nginx/ssl/.htpasswd
COPY modsecurity.conf-recommened /etc/nginx/modsec/modsecurity.conf
COPY main.conf /etc/nginx/modsec/main.conf
COPY default /etc/nginx/sites-available/default
COPY ssl-cert-snakeoil.pem /etc/nginx/ssl/ssl-cert-snakeoil.pem
COPY ssl-cert-snakeoil.key /etc/nginx/ssl/ssl-cert-snakeoil.key

#Cambiamos los permisos de la clave privada para añadir seguridad y actualizamos los enlaces de los archivos. Ya que hemos importado nuevos de otra máquina
RUN chmod 400 /etc/nginx/ssl/ssl-cert-snakeoil.key \
    && ldconfig

#En este caso, el entrypoint se lo he especificado directamente, porque mediante archivo no funcionaba
CMD service php7.3-fpm start && nginx -g "daemon off;"
