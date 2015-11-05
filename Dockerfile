FROM ubuntu:14.04
MAINTAINER Jose Tormo Main Informatica @maininformatica


#
# Configure APT packages and upgrad
#
RUN echo deb http://nightly.odoo.com/8.0/nightly/deb/ ./ > /etc/apt/sources.list.d/odoo-80.list
RUN apt-get update
RUN apt-get upgrade -y

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
RUN apt-get install --allow-unauthenticated -y supervisor postgresql odoo make gcc libncurses5-dev bison flex mc joe git python-cups python-dateutil python-decorator python-docutils python-feedparser python-gdata python-geoip python-gevent python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests python-simplejson python-tz python-unicodecsv python-unittest2 python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml wkhtmltopdf python-pip

#
# Clean
#
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

#
# PostgreSQL: add user odoo and fix permissions
#
RUN /etc/init.d/postgresql start && su postgres -c "createuser -s odoo"
RUN chown -R postgres.postgres /var/lib/postgresql
VOLUME  ["/var/lib/postgresql"]

#
# Supervisor setup
#
#ADD etc/supervisor/conf.d/10_postgresql.conf /etc/supervisor/conf.d/10_postgresql.conf
#ADD etc/supervisor/conf.d/20_odoo.conf /etc/supervisor/conf.d/20_odoo.conf

EXPOSE 8069
#CMD ["/usr/bin/supervisord", "-n"]
