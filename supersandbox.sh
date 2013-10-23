#!/bin/bash

#################### user defined variables ################

# path for final wrapper scripts
MYBINPATH="/usr/local/bin"

# location for virtualenvs
MYENVPATH="/usr/local/virtualenv"

# is sudo required to write to the above directories?
DOISUDO="yes"

# name of the virtualenv
MYINSTALLPATH="${MYENVPATH}/supernova"

# which version of supernova do you want?  uncomment only one.
SUPERNOVA="https://github.com/major/supernova/archive/v0.7.5.tar.gz" # 0.7.5 from github
#SUPERNOVA="supernova" # 0.7.4 from pypi

# supernova-keyring addon
HELPERADDON="https://github.com/cgtx/supernova-keyring-helper/archive/v0.3.tar.gz"

############################################################

fail() {
    # this function is for quitters!
    echo -e "${@}"
    exit 1
}

set_variables() {
    # set the sudo variable
    if [[ ${DOISUDO} == "yes" ]]; then
        SUDO="sudo"
    else
        SUDO=""
    fi

    # OS detection
    if [[ -f /etc/arch-release ]]; then
        OSNAME="arch"
        PYTHON="python2"
        VIRTUALENV="virtualenv2"
        TESTCMD="pacman -Q"
        INSTALLCMD="sudo pacman -Sy"
        REMOVECMD="sudo pacman -R"
    elif [[ -f /etc/debian_version ]]; then
        OSNAME="debian"
        PYTHON="python"
        VIRTUALENV="virtualenv"
        TESTCMD="dpkg -l"
        INSTALLCMD="sudo apt-get install"
        REMOVECMD="sudo apt-get purge"
    elif [[ -f /etc/fedora-release ]]; then
        OSNAME="fedora"
        PYTHON="python"
        VIRTUALENV="virtualenv"
        TESTCMD="rpm -q"
        INSTALLCMD="sudo yum install"
        REMOVECMD="sudo yum remove"
    elif [[ -f /etc/redhat-release ]]; then
        OSNAME="redhat"
        PYTHON="python27"
        VIRTUALENV="virtualenv-2.7"
        TESTCMD="rpm -q"
        INSTALLCMD="sudo yum install"
        REMOVECMD="sudo yum remove"
    else
        fail "unrecognized OS"
    fi
}


do_help() {
    echo -e "Description:\tBootstrap a complete supernova environment using virtualenv."
    name=$(basename ${0})
    echo -e "Usage:\t\t${name} install"
    echo -e "\t\t${name} remove"
}

do_install() {
    # test if there already is scripts in our desired location
    echo -n "checking for supernova wrapper script conflict..."
    if [[ ! -f ${MYBINPATH}/supernova ]]; then
        echo "PASS"
    else
        fail "FAIL\n${MYBINPATH}/supernova already exists"
    fi
    echo -n "checking for supernova-keyring wrapper script conflict..."
    if [[ ! -f ${MYBINPATH}/supernova-keyring ]]; then
        echo "PASS"
    else
        fail "FAIL\n${MYBINPATH}/supernova-keyring already exists"
    fi
    echo -n "checking for supernova-keyring-helper wrapper script conflict..."
    if [[ ! -f ${MYBINPATH}/supernova-keyring-helper ]]; then
        echo "PASS"
    else
        fail "FAIL\n${MYBINPATH}/supernova-keyring-helper already exists"
    fi

    # test for the package, and install it if necessary
    echo -n "checking for package ${PYTHON}-virtualenv..."
    if ${TESTCMD} ${PYTHON}-virtualenv &> /dev/null; then
        echo "PASS"
    else
        echo "FAIL"
        echo "installing package ${PYTHON}-virtualenv..."
        ${INSTALLCMD} ${PYTHON}-virtualenv || fail "FAIL"
        echo "PASS"
    fi

    # test for directories, create if needed
    echo -n "checking for directory ${MYBINPATH}..."
    if [[ -d ${MYBINPATH} ]]; then
        echo "PASS"
    else
        echo -n "creating..."
        ${SUDO} mkdir -p ${MYBINPATH} || fail "FAIL"
        echo "PASS"
    fi
    echo -n "checking for directory ${MYENVPATH}..."
    if [[ -d ${MYENVPATH} ]]; then
        echo "PASS"
    else
        echo -n "creating..."
        ${SUDO} mkdir -p ${MYENVPATH} || fail "FAIL"
        echo "PASS"
    fi

    # create isolated python environment
    echo -n "creating isolated python environment ${MYINSTALLPATH}..."
    ${SUDO} ${VIRTUALENV} --no-site-packages ${MYINSTALLPATH} &> /dev/null || fail "FAIL"
    echo "PASS"

    # activate the virtual environment and install pip packages
    echo -n "installing pip packages inside ${MYINSTALLPATH}..."
    . ${MYINSTALLPATH}/bin/activate
    ${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade rackspace-novaclient &> /dev/null || fail "FAIL\nfailed to install rackspace-novaclient"
    ${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade keyring &> /dev/null || fail "FAIL\nfailed to install keyring"
    ${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade ${SUPERNOVA} &> /dev/null || fail "FAIL\nfailed to install ${SUPERNOVA}"
    ${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade ${HELPERADDON} &> /dev/null || fail "FAIL\nfailed to install ${HELPERADDON}"
    ${SUDO} ${MYINSTALLPATH}/bin/pip freeze | ${SUDO} tee ${MYINSTALLPATH}/$(date +%F)-freeze.out &> /dev/null
    deactivate
    echo "PASS"

    # create wrapper scripts
    supernova_wrapper="#!/bin/bash\n. ${MYINSTALLPATH}/bin/activate\n${MYINSTALLPATH}/bin/supernova \${@}"
    supernova-keyring_wrapper="#!/bin/bash\n. ${MYINSTALLPATH}/bin/activate\n${MYINSTALLPATH}/bin/supernova-keyring \${@}"
    supernova-keyring-helper_wrapper="#!/bin/bash\n. ${MYINSTALLPATH}/bin/activate\n${MYINSTALLPATH}/bin/supernova-keyring-helper \${@}"
    config_template="[mine]\nOS_AUTH_SYSTEM=rackspace\nOS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/\nOS_TENANT_NAME=USE_KEYRING\nOS_PROJECT_ID=USE_KEYRING\nOS_USERNAME=USE_KEYRING\nOS_PASSWORD=USE_KEYRING\nOS_REGION_NAME=USE_KEYRING\nNOVA_RAX_AUTH=1"
    echo -n "creating wrapper scripts..."
    echo "${supernova_wrapper}" | ${SUDO} tee ${MYBINPATH}/supernova &> /dev/null
    ${SUDO} chmod +x ${MYBINPATH}/supernova
    echo "${supernova-keyring_wrapper}" | ${SUDO} tee ${MYBINPATH}/supernova-keyring &> /dev/null
    ${SUDO} chmod +x ${MYBINPATH}/supernova-keyring
    echo "${supernova-keyring-helper_wrapper}" | ${SUDO} tee ${MYBINPATH}/supernova-keyring-helper &> /dev/null
    ${SUDO} chmod +x ${MYBINPATH}/supernova-keyring-helper
    echo "PASS"

    # create config file template
    echo -n "creating configuration template file ~/.supernova.sample ..."
    echo "${config_template}" | tee ~/.supernova.sample &> /dev/null
    echo "PASS"    
}

do_remove() {
    # remove installation path
    if [[ -d ${MYINSTALLPATH} ]]; then
        echo -n "remove virtualenv directory ${MYINSTALLPATH}? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            ${SUDO} rm -rf ${MYINSTALLPATH} || fail "FAIL"
        fi
    fi

    # delete wrapper scripts
    if [[ -f ${MYBINPATH}/supernova ]]; then
        echo -n "remove wrapper script ${MYBINPATH}/supernova? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            ${SUDO} rm -f ${MYBINPATH}/supernova || fail "FAIL"
        fi
    fi
    if [[ -f ${MYBINPATH}/supernova-keyring ]]; then
        echo -n "remove wrapper script ${MYBINPATH}/supernova-keyring? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            ${SUDO} rm -f ${MYBINPATH}/supernova-keyring || fail "FAIL"
        fi
    fi
    if [[ -f ${MYBINPATH}/supernova-keyring-helper ]]; then
        echo -n "remove wrapper script ${MYBINPATH}/supernova-keyring-helper? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            ${SUDO} rm -f ${MYBINPATH}/supernova-keyring-helper || fail "FAIL"
        fi
    fi

    # remove config file template
    if [[ -f ~/.supernova.sample ]]; then
        echo -n "remove configuration template file ~/.supernova.sample? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            rm -f ~/.supernova.sample || fail "FAIL"
        fi
    fi

    # uninstall package
    if ${TESTCMD} ${PYTHON}-virtualenv &> /dev/null; then
        echo -n "remove package ${PYTHON}-virtualenv? [y/N] "; read x
        if [[ "${x}" == "y" ]]; then
            ${REMOVECMD} ${PYTHON}-virtualenv || fail "FAIL"
        fi
    fi

    echo "all uninstall checks completed"
}

# start main program

set_variables

case ${1} in
    "remove"|"erase"|"purge")   do_remove;;
    "install")                  do_install;;
    *)                          do_help;;
esac
