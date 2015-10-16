#!/bin/bash

##########################################################################################
#
# Apache Segfault Watcher (apache_segfault_watcher.sh) (c) by Jack Szwergold
#
# Apache Segfault Watcher is licensed under a
# Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
#
# You should have received a copy of the license along with this
# work. If not, see <http://creativecommons.org/licenses/by-nc-sa/4.0/>.
#
# w: http://www.preworn.com
# e: me@preworn.com
#
# Created: 2013-03-01, js
# Version: 2013-03-01, js: creation
#          2013-03-01, js: development
#
##########################################################################################

LOCK_NAME="APACHE_SEGFAULT_WATCH"
LOCK_DIR=/tmp/${LOCK_NAME}.lock
PID_FILE=${LOCK_DIR}/${LOCK_NAME}.pid

APACHE_ERROR_LOG="/var/log/apache2/error.log"
APACHE_RESTART="/etc/init.d/apache2 restart"
TEXT_TO_WATCH="exit signal Segmentation fault"
# TEXT_TO_WATCH="File does not exist"

HOSTNAME=$(hostname)
MAIL_ADDRESS="email_address@example.com"
MAIL_SUBJECT=${HOSTNAME}": Apache Segfault Notification"

SCRIPT_NAME=$(basename ${0})
SCRIPT_BASE_NAME=${SCRIPT_NAME%.*}

LOG_DIR="/var/log/apache2/"
LOG_FILENAME=${SCRIPT_BASE_NAME}".log"
LOG_FULLPATH=${LOG_DIR}${LOG_FILENAME}

if mkdir ${LOCK_DIR} 2>/dev/null; then
  # If the ${LOCK_DIR} doesn't exist, then start working & store the ${PID_FILE}
  echo $$ > ${PID_FILE}

  while true; do
    LOOP_MESSAGE="`date` (re)starting control loop"
    echo ${LOOP_MESSAGE} >> ${LOG_FULLPATH}
    tail --follow=name --retry -n 0 "$APACHE_ERROR_LOG" 2>/dev/null | while read LOG_LINE; do
    if [[ `echo "$LOG_LINE" | egrep "$TEXT_TO_WATCH"` ]]; then
      LOG_MESSAGE="`date` Segfault detected on "$HOSTNAME

      # Log the error to the file.
      echo ${LOG_MESSAGE} >> ${LOG_FULLPATH}

      # Send e-mail notification.
      echo ${LOG_MESSAGE}$'\n\r'${LOG_LINE} | mail -s "${MAIL_SUBJECT}" ${MAIL_ADDRESS}

      # Restart Apache
      # ${APACHE_RESTART}

      break
    fi
    done
  sleep 5
  done

  rm -rf ${LOCK_DIR}
  exit
else
  if [ -f ${PID_FILE} ] && kill -0 $(cat ${PID_FILE}) 2>/dev/null; then
    # Confirm that the process file exists & a process
    # with that PID is truly running.
    # echo "Running [PID "$(cat ${PID_FILE})"]" >&2
    exit
  else
    # If the process is not running, yet there is a PID file--like in the case
    # of a crash or sudden reboot--then get rid of the ${LOCK_DIR}
    rm -rf ${LOCK_DIR}
    exit
  fi
fi