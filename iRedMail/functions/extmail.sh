#!/bin/sh

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

# -------------------------------------------
# Functions to install and configure ExtMail.
# -------------------------------------------

extmail_install()
{
    cd ${MISC_DIR}

    ECHO_INFO "Create necessary directory and extract ExtMail: ${EXTMAIL_TARBALL}..."
    [ -d ${EXTSUITE_HTTPD_ROOT} ] || mkdir -p ${EXTSUITE_HTTPD_ROOT}
    extract_pkg ${EXTMAIL_TARBALL} ${EXTSUITE_HTTPD_ROOT}
    cd ${EXTSUITE_HTTPD_ROOT} && mv extmail-${EXTMAIL_VERSION} extmail

    ECHO_INFO "Set correct permission for ExtMail: ${EXTSUITE_HTTPD_ROOT}."
    chown root:root ${EXTSUITE_HTTPD_ROOT}
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${EXTMAIL_HTTPD_ROOT}
    chmod -R 0755 ${EXTSUITE_HTTPD_ROOT}
    chmod 0000 ${EXTMAIL_HTTPD_ROOT}/{AUTHORS,ChangeLog,CREDITS,dispatch.*,INSTALL,README.*}

    # For ExtMail-1.0.5. We don't have 'question/answer' field in SQL template. disable it.
    perl -pi -e 's/(.*sth.*execute.*opt.*question.*opt.*answer.*)/#${1}/' ${EXTMAIL_HTTPD_ROOT}/libs/Ext/Auth/MySQL.pm

    echo 'export status_extmail_install="DONE"' >> ${STATUS_FILE}
}

extmail_config_basic()
{
    ECHO_INFO "Enable virtual host in Apache."
    perl -pi -e 's/#(NameVirtualHost)/${1}/' ${HTTPD_CONF}

    ECHO_INFO "Create Apache directory alias for ExtMail."
    cat > ${HTTPD_CONF_DIR}/extmail.conf <<EOF
${CONF_MSG}
<VirtualHost *:80>
ServerName $(hostname)

DocumentRoot ${HTTPD_DOCUMENTROOT}

ScriptAlias /extmail/cgi ${EXTMAIL_HTTPD_ROOT}/cgi
Alias /extmail ${EXTMAIL_HTTPD_ROOT}/html

#Alias /mail ${EXTMAIL_HTTPD_ROOT}/html
#Alias /webmail ${EXTMAIL_HTTPD_ROOT}/html

SuexecUserGroup ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
</VirtualHost>
EOF

    ECHO_INFO "Basic configuration for ExtMail."
    cd ${EXTMAIL_HTTPD_ROOT} && cp -f webmail.cf.default ${EXTMAIL_CONF}

    # Set default user language.
    perl -pi -e 's#(SYS_USER_LANG.*)en_US#${1}$ENV{'SYS_USER_LANG'}#' ${EXTMAIL_CONF}

    # Set mail attachment size.
    perl -pi -e 's#^(SYS_MESSAGE_SIZE_LIMIT.*=)(.*)#${1} $ENV{'MESSAGE_SIZE_LIMIT'}#' ${EXTMAIL_CONF}

    export VMAIL_USER_HOME_DIR
    perl -pi -e 's#(SYS_MAILDIR_BASE.*)/home/domains#${1}$ENV{VMAIL_USER_HOME_DIR}#' ${EXTMAIL_CONF}

    ECHO_INFO "Fix incorrect quota display."
    perl -pi -e 's#(.*mailQuota})(.*0S.*)#${1}*1024000${2}#' ${EXTMAIL_HTTPD_ROOT}/libs/Ext/App.pm

    #ECHO_INFO "Enable USER_LANG."
    #perl -pi -e 's/#(.*lang.*usercfg.*lang.*USER_LANG.*)/${1}/' App.pm

    ECHO_INFO "Disable some functions we don't support yet."
    cd ${EXTMAIL_HTTPD_ROOT}/html/default/
    perl -pi -e 's#(.*filter.cgi.*)#\<\!--${1}--\>#' OPTION_NAV.html

    echo 'export status_extmail_config_basic="DONE"' >> ${STATUS_FILE}
}

extmail_config_mysql()
{
    ECHO_INFO "Configure ExtMail for MySQL support.."
    cd ${EXTMAIL_HTTPD_ROOT}

    export MYSQL_SERVER
    export MYSQL_ADMIN_PW
    perl -pi -e 's#(SYS_MYSQL_USER.*)db_user#${1}$ENV{'MYSQL_ADMIN_USER'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_PASS.*)db_pass#${1}$ENV{'MYSQL_ADMIN_PW'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_DB.*)extmail#${1}$ENV{'VMAIL_DB'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_HOST.*)localhost#${1}$ENV{'MYSQL_SERVER'}#' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_MYSQL_ATTR_CLEARPW.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_MYSQL_ATTR_DISABLEWEBMAIL.*)disablewebmail#${1}disableimap#' ${EXTMAIL_CONF}

    echo 'export status_extmail_config_mysql="DONE"' >> ${STATUS_FILE}
}

extmail_config_ldap()
{
    ECHO_INFO "Configure ExtMail for LDAP support."
    cd ${EXTMAIL_HTTPD_ROOT}

    perl -pi -e 's#(SYS_AUTH_TYPE.*)mysql#${1}ldap#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_BASE)(.*)#${1} = $ENV{'LDAP_BASEDN'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_RDN)(.*)#${1} = $ENV{'LDAP_ADMIN_DN'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_PASS.*=)(.*)#${1} $ENV{'LDAP_ADMIN_PW'}#' ${EXTMAIL_CONF}
    perl -pi -e 's#(SYS_LDAP_HOST.*=)(.*)#${1} $ENV{'LDAP_SERVER_HOST'}#' ${EXTMAIL_CONF}

    perl -pi -e 's#(SYS_LDAP_ATTR_DOMAIN.*=)(.*)#${1} o#' ${EXTMAIL_CONF}

    perl -pi -e 's/^(SYS_LDAP_ATTR_CLEARPW.*)/#${1}/' ${EXTMAIL_CONF}
    #perl -pi -e 's/^(SYS_LDAP_ATTR_NDQUOTA.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's#^(SYS_LDAP_ATTR_DISABLEWEBMAIL.*)disablewebmail#${1}disableIMAP#' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLENETDISK.*)/#${1}/' ${EXTMAIL_CONF}
    perl -pi -e 's/^(SYS_LDAP_ATTR_DISABLEPWDCHANGE.*)/#${1}/' ${EXTMAIL_CONF}

    perl -pi -e 's#(SYS_LDAP_ATTR_ACTIVE.*=)(.*)#${1} $ENV{'LDAP_ATTR_USER_STATUS'}#' ${EXTMAIL_CONF}

    echo 'export status_extmail_config_ldap="DONE"' >> ${STATUS_FILE}
}

extmail_config()
{
    check_status_before_run extmail_config_basic

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        check_status_before_run extmail_config_ldap
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        check_status_before_run extmail_config_mysql
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
ExtMail:
    * Configuration files:
        - ${EXTMAIL_CONF}
    * Reference:
        - ${HTTPD_CONF_DIR}/extmail.conf
    * URL:
        - $(hostname)/extmail
EOF

    echo 'export status_extmail_config="DONE"' >> ${STATUS_FILE}
}
