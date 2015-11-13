FROM ubuntu:14.04
MAINTAINER Jose Tormo Main Informatica @maininformatica


#
# Configure APT 
#
RUN echo deb http://nightly.odoo.com/8.0/nightly/deb/ ./ > /etc/apt/sources.list.d/odoo-80.list
RUN apt-get update


#
# Locale setup 
#
RUN echo "locales locales/locales_to_be_generated multiselect es_ES.UTF-8 UTF-8" | debconf-set-selections &&\
    echo "locales locales/default_environment_locale select es_ES.UTF-8" | debconf-set-selections
RUN apt-get install locales -qq
RUN locale-gen es_ES.UTF-8
ENV LC_ALL es_ES.UTF-8

#
# Paquetes
#
RUN apt-get install --allow-unauthenticated -y supervisor postgresql odoo make gcc libncurses5-dev bison flex mc joe git openssh-server cups
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

#
# Preparamos el SSH
#
RUN mkdir /var/run/sshd
RUN echo 'root:odooadmin' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
## CMD ["/etc/init.d/ssh", "start", "&"]
# CMD ["/usr/sbin/sshd", "-D", "&"]

#
# CUPS Printers
#
RUN sed -i 's/Listen localhost:631/Listen *:631/' /etc/cups/cupsd.conf
RUN sed -i 's/Order allow,deny/Allow all/' /etc/cups/cupsd.conf
EXPOSE 631
## CMD ["/etc/init.d/cups", "start", "&"]


#
# PostgreSQL
#
RUN /etc/init.d/postgresql start && su postgres -c "createuser -s odoo"
RUN echo "update pg_database set datallowconn = TRUE where datname = 'template0';" > /tmp/utf8.sql
RUN echo "\c template0" >> /tmp/utf8.sql
RUN echo "update pg_database set datistemplate = FALSE where datname = 'template1';" >> /tmp/utf8.sql
RUN echo "drop database template1;" >> /tmp/utf8.sql
RUN echo "create database template1 with template = template0 encoding = 'UTF8';" >> /tmp/utf8.sql
RUN echo "update pg_database set datistemplate = TRUE where datname = 'template1';" >> /tmp/utf8.sql
RUN echo "\c template1" >> /tmp/utf8.sql
RUN echo "update pg_database set datallowconn = FALSE where datname = 'template0';" >> /tmp/utf8.sql
RUN echo "\q" >> /tmp/utf8.sql
RUN sleep 2 && chmod 777 /tmp/utf8.sql && su postgres -c "psql postgres < /tmp/utf8.sql"
# CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
RUN chown -R postgres.postgres /var/lib/postgresql
VOLUME  ["/var/lib/postgresql"]
EXPOSE 5432
## CMD ["/etc/init.d/postgresql", "start", "&"]

#
# Odoo
#
RUN git clone https://github.com/OCA/l10n-spain.git /var/lib/odoo/.local/share/Odoo/addons/8.0/
RUN chown odoo.odoo /var/lib/odoo/.local/share/Odoo/addons/8.0 -R
RUN chmod 777 /var/lib/odoo/.local/share/Odoo -R
RUN sed -i '$d' /etc/odoo/openerp-server.conf
RUN echo "addons_path = /usr/lib/python2.7/dist-packages/openerp/addons,/var/lib/odoo/.local/share/Odoo/addons/8.0" >> /etc/odoo/openerp-server.conf
RUN sed -i 's/; admin_passwd = admin/admin_passwd = odooadmin/' /etc/odoo/openerp-server.conf
# CMD ["/usr/bin/python", "/usr/bin/odoo.py", "--config", "/etc/odoo/openerp-server.conf", "--logfile", "/var/log/odoo/odoo-server.log"]
EXPOSE 8069
## CMD ["/etc/init.d/odoo", "start", "&"]
