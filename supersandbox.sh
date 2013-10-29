#!/bin/bash

#################### user defined variables ################

# path for final wrapper scripts
MYBINPATH="/usr/local/bin"

# location for virtualenvs
MYENVPATH="/usr/local/virtualenvs"

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

# text formatting
_und=$(tput sgr 0 1) # underline
_bld=$(tput bold)    # bold
_red=$(tput setaf 1) # red
_gre=$(tput setaf 2) # green
_yel=$(tput setaf 3) # yellow
_blu=$(tput setaf 4) # blue
_pur=$(tput setaf 5) # purple
_cya=$(tput setaf 6) # cyan
_wht=$(tput setaf 7) # white
_res=$(tput sgr0)    # reset
# echo -e "${_bld}${_red}Usage example.${_res}"

PASS="${_bld}${_gre}PASS${_res}"
FAIL="${_bld}${_red}FAIL${_res}"
DESC="${_bld}Description${_res}"
USAGE="${_bld}Usage${_res}"
YESNO="[${_bld}${_gre}PASS${_res}]"
YESNO="[${_bld}${_gre}y${_res}/${_bld}${_red}N${_res}]"

fail() {
	# this function is for quitters!
	echo -e "${FAIL}\n${_bld}${@}${_res}"
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
	elif [[ -f /etc/debian_version ]]; then
		OSNAME="debian"
		PYTHON="python"
		VIRTUALENV="virtualenv"
		TESTCMD="dpkg -s"
	elif [[ -f /etc/fedora-release ]]; then
		OSNAME="fedora"
		PYTHON="python"
		VIRTUALENV="virtualenv"
		TESTCMD="rpm -q"
	elif [[ -f /etc/redhat-release ]]; then
		OSNAME="redhat"
		PYTHON="python27"
		VIRTUALENV="virtualenv-2.7"
		TESTCMD="rpm -q"
	else
		fail "unrecognized OS"
	fi
}


do_install() {
	# test if there already is scripts in our desired location
	echo -n "checking for supernova wrapper script conflict..."
	if [[ ! -f ${MYBINPATH}/supernova ]]; then
		echo "${PASS}"
	else
		fail "${MYBINPATH}/supernova already exists"
	fi
	echo -n "checking for supernova-keyring wrapper script conflict..."
	if [[ ! -f ${MYBINPATH}/supernova-keyring ]]; then
		echo "${PASS}"
	else
		fail "${MYBINPATH}/supernova-keyring already exists"
	fi
	echo -n "checking for supernova-keyring-helper wrapper script conflict..."
	if [[ ! -f ${MYBINPATH}/supernova-keyring-helper ]]; then
		echo "${PASS}"
	else
		fail "${MYBINPATH}/supernova-keyring-helper already exists"
	fi

	# test for packages
	for pkg in gcc make ${PYTHON}-virtualenv; do
		echo -n "checking for ${pkg} package..."
		if ${TESTCMD} ${pkg} &> /dev/null; then
			echo "${PASS}"
		else
			fail "install ${pkg} before running this script"
		fi
	done

	# test for directories, create if needed
	echo -n "checking for directory ${MYBINPATH}..."
	if [[ -d ${MYBINPATH} ]]; then
		echo "${PASS}"
	else
		echo -n "creating..."
		${SUDO} mkdir -p ${MYBINPATH} || fail
		echo "${PASS}"
	fi
	echo -n "checking for directory ${MYENVPATH}..."
	if [[ -d ${MYENVPATH} ]]; then
		echo "${PASS}"
	else
		echo -n "creating..."
		${SUDO} mkdir -p ${MYENVPATH} || fail
		echo "${PASS}"
	fi

	# create isolated python environment
	echo -n "creating isolated python environment ${MYINSTALLPATH}..."
	${SUDO} ${VIRTUALENV} --no-site-packages ${MYINSTALLPATH} &> /dev/null && echo "${PASS}" || fail

	# activate the virtual environment
	echo -n "activating virutalenv ${MYINSTALLPATH}..."
	. ${MYINSTALLPATH}/bin/activate && echo "${PASS}" || fail

	# install pip packages
	echo -n "installing python-novaclient..."
	${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade python-novaclient &> /dev/null && echo "${PASS}" || fail
	echo -n "installing rackspace-novaclient..."
	${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade rackspace-novaclient &> /dev/null && echo "${PASS}" || fail
	echo -n "installing keyring..."
	${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade keyring &> /dev/null && echo "${PASS}" || fail
	echo -n "installing supernova..."
	${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade ${SUPERNOVA} &> /dev/null && echo "${PASS}" || fail
	echo -n "installing supernova-keyring-helper..."
	${SUDO} ${MYINSTALLPATH}/bin/pip install --upgrade ${HELPERADDON} &> /dev/null && echo "${PASS}" || fail
	echo -n "saving pip freeze output..."
	${SUDO} ${MYINSTALLPATH}/bin/pip freeze | ${SUDO} tee ${MYINSTALLPATH}/$(date +%F)-freeze.out &> /dev/null && echo "${PASS}" || fail

	# deactivate the virtual environment
	echo -n "deactivating virutalenv ${MYINSTALLPATH}..."
	deactivate && echo "${PASS}" || fail

	# create wrapper scripts
	echo -n "creating wrapper scripts..."
	for each in nova supernova supernova-keyring supernova-keyring-helper; do
		cat <<- EOF | ${SUDO} tee ${MYBINPATH}/${each} &> /dev/null
		#!/bin/bash
		. ${MYINSTALLPATH}/bin/activate
		${MYINSTALLPATH}/bin/${each} \${@}
		EOF
		${SUDO} chmod +x ${MYBINPATH}/${each}
	done
	echo "${PASS}"

	# create config file template
	echo -n "creating configuration template file ~/.supernova.sample ..."
	cat <<- EOF | tee ~/.supernova.sample &> /dev/null
	[mine]
	OS_AUTH_SYSTEM=rackspace
	OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
	OS_TENANT_NAME=USE_KEYRING
	OS_PROJECT_ID=USE_KEYRING
	OS_USERNAME=USE_KEYRING
	OS_PASSWORD=USE_KEYRING
	OS_REGION_NAME=USE_KEYRING
	NOVA_RAX_AUTH=1
	EOF
	echo "${PASS}"

	echo "${_bld}installation complete${_res}"
}


do_remove() {
	# remove installation path
	if [[ -d ${MYINSTALLPATH} ]]; then
		echo -n "remove virtualenv directory ${_bld}${MYINSTALLPATH}? ${YESNO} "; read x
		if [[ "${x}" == "y" ]]; then
			${SUDO} rm -rf ${MYINSTALLPATH} || fail
		fi
	fi

	# delete wrapper scripts
	for each in nova supernova supernova-keyring supernova-keyring-helper; do
		if [[ -f ${MYBINPATH}/${each} ]]; then
			echo -n "remove wrapper script ${_bld}${MYBINPATH}/${each}${_res}? ${YESNO} "; read x
			if [[ "${x}" == "y" ]]; then
				${SUDO} rm -f ${MYBINPATH}/${each} || fail
			fi
		fi
	done

	# remove config file template
	if [[ -f ~/.supernova.sample ]]; then
		echo -n "remove configuration template file ${_bld}~/.supernova.sample${_res}? ${YESNO} "; read x
		if [[ "${x}" == "y" ]]; then
			rm -f ~/.supernova.sample || fail
		fi
	fi

	echo "${_bld}uninstall complete${_res}"
}


do_help() {
	echo -e "${DESC}:\tBootstrap a complete supernova environment using virtualenv."
	name=$(basename ${0})
	echo -e "${USAGE}:\t\t${name} install"
	echo -e "\t\t${name} remove"
}


# start main program

set_variables

case ${1} in
	"remove"|"erase"|"purge")	do_remove;;
	"install")			do_install;;
	*)				do_help;;
esac
