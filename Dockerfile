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
RUN echo 'root:admin' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

#
# CUPS Printers
#
RUN sed -i 's/Listen localhost:631/Listen *:631/' /etc/cups/cupsd.conf
RUN sed -i 's/Order allow,deny/Allow all/' /etc/cups/cupsd.conf
EXPOSE 631
CMD ["/etc/init.d/cups", "start"]


#
# PostgreSQL
#
RUN /etc/init.d/postgresql start && su postgres -c "createuser -s odoo"
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
RUN chown -R postgres.postgres /var/lib/postgresql
VOLUME  ["/var/lib/postgresql"]
EXPOSE 5432

#
# Odoo
#
RUN git clone https://github.com/OCA/l10n-spain.git /var/lib/odoo/.local/share/Odoo/addons/8.0/
RUN chown odoo.odoo /var/lib/odoo/.local/share/Odoo/addons/8.0 -R
CMD ["/usr/bin/python", "/usr/bin/odoo.py", "--config", "/etc/odoo/openerp-server.conf", "--logfile", "/var/log/odoo/odoo-server.log"]
EXPOSE 8069

