FROM ubuntu:14.04
MAINTAINER Jose Tormo Main Informatica @maininformatica


#
# Configure APT packages and upgrad
#
RUN echo deb http://nightly.odoo.com/8.0/nightly/deb/ ./ > /etc/apt/sources.list.d/odoo-80.list
RUN apt-get update
# RUN apt-get upgrade -y

#
# Locale setup (if not set, PostgreSQL creates the database in SQL_ASCII)
#
RUN echo "locales locales/locales_to_be_generated multiselect es_ES.UTF-8 UTF-8" | debconf-set-selections &&\
    echo "locales locales/default_environment_locale select es_ES.UTF-8" | debconf-set-selections
RUN apt-get install locales -qq
RUN locale-gen es_ES.UTF-8
ENV LC_ALL es_ES.UTF-8

#
# Install PostgreSQL, Odoo and Supervisor
#
RUN apt-get install --allow-unauthenticated -y supervisor postgresql odoo make gcc libncurses5-dev bison flex mc joe git openssh-server

#
# Clean
#
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

# Preparamos el SSH
RUN mkdir /var/run/sshd
RUN echo 'root:odoomain' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]


# CUPS Printers
EXPOSE 631



#
# PostgreSQL: add user odoo and fix permissions
#
VOLUME  ["/var/lib/postgresql"]
RUN chown -R postgres.postgres /var/lib/postgresql
RUN /etc/init.d/postgresql start && su postgres -c "createuser -s odoo"
EXPOSE 5432

# Odoo Custom
EXPOSE 8069

