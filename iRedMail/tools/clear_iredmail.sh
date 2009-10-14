#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)
# Purpose:  Remove main components which installed by iRedMail, so that
#           you can re-install iRedMail.
# Project:  iRedMail (http://www.iredmail.org/)

# TODO remove non binary packages/files.

export CONF_DIR='../conf'

# Source functions.
. ${CONF_DIR}/global
. ${CONF_DIR}/functions
. ${CONF_DIR}/core

# Source configurations.
. ${CONF_DIR}/apache_php
. ${CONF_DIR}/openldap
. ${CONF_DIR}/phpldapadmin
. ${CONF_DIR}/mysql
. ${CONF_DIR}/postfix
. ${CONF_DIR}/policyd
. ${CONF_DIR}/pypolicyd-spf
. ${CONF_DIR}/dovecot
. ${CONF_DIR}/managesieve
. ${CONF_DIR}/procmail
. ${CONF_DIR}/amavisd
. ${CONF_DIR}/clamav
. ${CONF_DIR}/spamassassin
. ${CONF_DIR}/squirrelmail
. ${CONF_DIR}/roundcube
. ${CONF_DIR}/postfixadmin
. ${CONF_DIR}/phpmyadmin
. ${CONF_DIR}/awstats
. ${CONF_DIR}/iredadmin

# Source user configurations of iRedMail.
. ../config

confirm_to_remove()
{
    # Usage: confirm_to_remove [FILE|DIR]
    DEST="${1}"

    if [ ! -z ${DEST} ]; then
        if [ -e ${DEST} -o -L ${DEST} ]; then
            ECHO_QUESTION -n "Remove ${DEST}? [y|N] "
            read ANSWER
            case $ANSWER in
                Y|y )
                    ECHO_INFO -n "Removing ${DEST} ..."
                    rm -rf ${DEST}
                    echo -e "\t[ DONE ]"
                    ;;
                N|n|* ) : ;;
            esac
        else
            :
        fi
    else
        :
    fi
}

# ---- Below is code snippet of conf/core ----
# Do NOT use '-y' in yum and apt-get, let user confirm this operation.
remove_pkg_rhel()
{
    ECHO_INFO "Removing package(s): $@"
    ${YUM} remove $@
    [ X"$?" != X"0" ] && ECHO_ERROR "Package removed failed, please check the terminal output."
}

remove_pkg_debian()
{
    ECHO_INFO "Removing package(s): $@"
    apt-get purge $@
    [ X"$?" != X"0" ] && ECHO_ERROR "Package removed failed, please check the terminal output."
}

# ---- Below is code snippet of functions/packages.sh ----
get_all_pkgs()
{
    ALL_PKGS=''

    # Apache and PHP.
    if [ X"${USE_EXIST_AMP}" != X"YES" ]; then
        # Apache & PHP.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} httpd.${ARCH} mod_ssl.${ARCH} php.${ARCH} php-imap.${ARCH} php-gd.${ARCH} php-mbstring.${ARCH} libmcrypt.${ARCH} php-mcrypt.${ARCH} php-pear.noarch php-xml.${ARCH} php-pecl-fileinfo.${ARCH} php-mysql.${ARCH} php-ldap.${ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} apache2 apache2-mpm-prefork apache2.2-common libapache2-mod-php5 libapache2-mod-auth-mysql php5-cli php5-imap php5-gd php5-mcrypt php5-mysql php5-ldap"
        else
            :
        fi
    else
        :
    fi

    # Postfix.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix.${ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre"
    else
        :
    fi

    # Awstats.
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        else
            :
        fi
    else
        :
    fi

    # Note: mysql server is required, used to store extra data,
    #       such as policyd, roundcube webmail data.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} mysql-server.${ARCH} mysql.${ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} mysql-server-5.0 mysql-client-5.0"
    else
        :
    fi

    # Backend: OpenLDAP or MySQL.
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # OpenLDAP server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap.${ARCH} openldap-clients.${ARCH} openldap-servers.${ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-ldap slapd ldap-utils"
        else
            :
        fi
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # MySQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql.${ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-mysql"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql"
        else
            :
        fi
    else
        :
    fi

    # Policyd.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} policyd.${ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix-policyd"
    else
        :
    fi

    # Dovecot.
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot.${ARCH} dovecot-sieve.${ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d"
        else
            :
        fi

    else
        ALL_PKGS="procmail.${ARCH}"
    fi

    # Amavisd-new & ClamAV & Altermime.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new.${ARCH} clamd.${ARCH} clamav.${ARCH} clamav-db.${ARCH} spamassassin.${ARCH} altermime.${ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl clamav-freshclam clamav-daemon spamassassin altermime"
    else
        :
    fi

    # SPF.
    if [ X"${ENABLE_SPF}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            # SPF implemention via perl-Mail-SPF.
            ALL_PKGS="${ALL_PKGS} perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} libmail-spf-perl"
        else
            :
        fi
    else
        :
    fi

    # pysieved.
    # Warning: Do *NOT* add 'pysieved' service in 'ENABLED_SERVICES'.
    #          We don't have rc/init script under /etc/init.d/ till
    #          package is installed.
    if [ X"${USE_MANAGESIEVE}" == X"YES" ]; then
        # Note for Ubuntu & Debian:
        # Dovecot shipped in Debian/Ubuntu has managesieve plugin patched.
        [ X"${DISTRO}" == X"RHEL" ] && ALL_PKGS="${ALL_PKGS} pysieved.noarch"
    else
        :
    fi

    # SquirrelMail.
    if [ X"${USE_SM}" == X"YES" ]; then
        [ X"${DISTRO}" == X"RHEL" ] && ALL_PKGS="${ALL_PKGS} php-pear-db.noarch"
        [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && \
            ALL_PKGS="${ALL_PKGS} php-db"
    else
        :
    fi

    # iRedAdmin.
    if [ X"${USE_IREDADMIN}" == X"YES" ]; then
        [ X"${DISTRO}" == X"RHEL" ] && \
        ALL_PKGS="${ALL_PKGS} python-jinja2.${ARCH} python-webpy.noarch python-ldap.${ARCH} MySQL-python.${ARCH} mod_wsgi.${ARCH}"

        # TODO sill missing webpy-0.32, Jinja2, netifaces
        [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ] && \
            ALL_PKGS="${ALL_PKGS} libapache2-mod-wsgi python-mysqldb python-ldap python-jinja2 python-netifaces python-webpy"
    else
        :
    fi

    export ALL_PKGS
}

get_all_misc()
{
    EXTRA_FILES=''

    # Amavisd.
    EXTRA_FILES="${EXTRA_FILES} ${AMAVISD_CONF} ${AMAVISD_DKIM_CONF} ${AMAVISD_DKIM_DIR} ${AMAVISD_LOGFILE} ${AMAVISD_LOGROTATE_FILE}"

    # Roundcube webmail.
    EXTRA_FILES="${EXTRA_FILES} ${RCM_HTTPD_ROOT} ${HTTPD_SERVERROOT}/roundcubemail"

    export EXTRA_FILES
}

get_all_pkgs
get_all_misc
eval ${remove_pkg} ${ALL_PKGS}

for i in ${EXTRA_FILES}; do
    confirm_to_remove ${i}
done

# Delete users created by iRedMail.
userdel -r ${VMAIL_USER_NAME}
groupdel ${VMAIL_GROUP_NAME}