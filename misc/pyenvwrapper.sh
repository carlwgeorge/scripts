#!/bin/bash
APP_NAME=
PY_ENV_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}/virtualenv
COMMAND=$(basename ${0})
. ${PY_ENV_HOME}/${APP_NAME}/bin/activate
${PY_ENV_HOME}/${APP_NAME}/bin/${COMMAND} ${@}
