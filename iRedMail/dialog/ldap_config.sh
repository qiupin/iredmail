#!/bin/bash

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# --------------------------------------------------
# --------------------- LDAP -----------------------
# --------------------------------------------------

# LDAP suffix.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
        --title "\Zb\Z2LDAP suffix (root dn)\Zn" \
        --inputbox "\
Please specify your \Zb\Z2LDAP suffix (root dn)\Zn.

EXAMPLE:

    +---------------------+-----------------------+
    | Your domain name    | Recommend LDAP suffix |
    +---------------------+-----------------------+
    | iredmail.org        | dc=iredmail,dc=org    |
    +---------------------+-----------------------+
    | abc.com.cn          | dc=abc,dc=com,dc=cn   |
    +---------------------+-----------------------+

" 20 76 "dc=iredmail,dc=org" 2>/tmp/ldap_suffix

    LDAP_SUFFIX="$(cat /tmp/ldap_suffix)"
    [ X"${LDAP_SUFFIX}" != X"" ] && break
done

# Get DNS name derived from ldap suffix.
export dn2dnsname="$(echo ${LDAP_SUFFIX} | sed -e 's/dc=//g' -e 's/,/./g')"

export LDAP_SUFFIX_MAJOR="$( echo ${dn2dnsname} | awk -F'.' '{print $1}')"
export LDAP_BINDDN="cn=${VMAIL_USER_NAME},${LDAP_SUFFIX}"
export LDAP_ADMIN_DN="cn=${VMAIL_ADMIN_USER_NAME},${LDAP_SUFFIX}"
export LDAP_ROOTDN="cn=Manager,${LDAP_SUFFIX}"
export LDAP_BASEDN_NAME='domains'
export LDAP_BASEDN="o=${LDAP_BASEDN_NAME},${LDAP_SUFFIX}"
rm -f /tmp/ldap_suffix

cat >> ${CONFIG_FILE} <<EOF
export LDAP_SUFFIX="${LDAP_SUFFIX}"
export LDAP_SUFFIX_MAJOR="${LDAP_SUFFIX_MAJOR}"
export LDAP_BINDDN="cn=${VMAIL_USER_NAME},${LDAP_SUFFIX}"
export LDAP_ADMIN_DN="${LDAP_ADMIN_DN}"
export LDAP_ROOTDN="cn=Manager,${LDAP_SUFFIX}"
export LDAP_BASEDN_NAME="domains"
export LDAP_BASEDN="o=${LDAP_BASEDN_NAME},${LDAP_SUFFIX}"
EOF

# LDAP rootpw.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Password\Zn for LDAP rootdn: ${LDAP_ROOTDN}" \
    --passwordbox "\
Please specify \Zb\Z2password\Zn for LDAP rootdn:

    * ${LDAP_ROOTDN}

Warning:

    * \Zb\Z1EMPTY password is *NOT* permitted.\Zn
" 20 76 2>/tmp/ldap_rootpw

    LDAP_ROOTPW="$(cat /tmp/ldap_rootpw)"
    if [ ! -z "${LDAP_ROOTPW}" ]; then
        break
    fi
done

echo "export LDAP_ROOTPW='${LDAP_ROOTPW}'" >>${CONFIG_FILE}
rm -f /tmp/ldap_rootpw

# LDAP admin dn passwd.
while : ; do
    ${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "\Zb\Z2Password\Zn for vmail LDAP admin user" \
    --passwordbox "\
Please specify \Zb\Z2password\Zn for vmail LDAP admin user:

    * admin dn: ${LDAP_ADMIN_DN}

Warning:

    * \Zb\Z1EMPTY password is *NOT* permitted.\Zn

" 20 76 2>/tmp/vmail_user_passwd

    LDAP_ADMIN_PW="$(cat /tmp/vmail_user_passwd)"
    if [ ! -z "${LDAP_ADMIN_PW}" ]; then
        break
    fi
done

echo "export LDAP_ADMIN_PW='${LDAP_ADMIN_PW}'" >>${CONFIG_FILE}
rm -f /tmp/vmail_user_passwd
