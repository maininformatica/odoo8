#!/bin/bash
/etc/init.d/postgresql start & >/dev/null
/etc/init.d/ssh start  & >/dev/null
/etc/init.d/odoo start & >/dev/null

