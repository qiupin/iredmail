#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

PROG = 'iRedAdmin'

# Contact info: Name <email address>.
ADMIN = 'Zhang Huangbin <michaelbibby@gmail.com>'

# Default skin: default.
SKIN = 'default'

# Default language: en_US, zh_CN.
LANG = 'en_US'

# Backend you used to store virtual domains and users: mysql, ldap.
BACKEND = 'ldap'

# Mailbox base directory. Don't need append slash (/).
MAILBOX_BASE = '/home/vmail'

# Mailbox type: maildir, mbox.
# WARNING: Currently, mbox is not support.
MAILBOX_TYPE = 'maildir'

# Mailbox style: hashed, original.
# Example username:     user@domain.ltd
#   hashed mailbox:     domain.ltd/u/us/user/
#   original mailbox:   domain.ltd/user/
MAILBOX_STYLE = 'hashed'

# MySQL configure.
DB_SERVER_ADDR = 'localhost'
DB_SERVER_PORT = 3306

# Session relate config.
SESSION_DB_DBN = 'mysql'        # Database type: mysql.
SESSION_DB_NAME = 'iredadmin'   # Database name.
SESSION_DB_USER = 'iredadmin'   # Database user.
SESSION_DB_PASSWD = 'passwd'    # Database password.
SESSION_DB_TABLE_SESSION = 'sessions'

# Run webpy in debug mode: True, False.
DEBUG = False