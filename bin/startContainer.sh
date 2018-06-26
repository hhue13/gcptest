#!/usr/bin/env bash
set -x
xxEXITONSERVERSTOP="true"

xxProfileDir="/opt/IBM/WebSphere/AppServer/profiles/dmgr"
#############################################
## This script becomes /bin/startContainer.sh
#############################################
################################################################################################
## Assign parameter values to the script variables ....
################################################################################################
__processArg ()
{
  terminate=
  extraShift=

  case ${1} in
     -exitOnServerStop)         xxEXITONSERVERSTOP=$(echo ${2} | tr [:upper:] [:lower:]) ; extraShift=1  ;;
     *)                         __errorMsg "Unsupported parameter \"${1}\" passed. Exiting ..."
                                terminate=1
																;;
  esac
}
################################################################################################
## Initiailization tasks ......
##
## Note: This include requires the function __processArg in the including script
################################################################################################
__init()
{

  while [[ $# -gt 0 ]]
  do
    __processArg $1 $2
    if [[ -n "$terminate" ]] ; then
      return 1
    fi

    shift
    if [[ -n "$extraShift" ]] ; then
      if [[ $# -gt 0 ]] ; then shift ; fi
    fi
  done
}
######################################################################################
## Terminate the container
######################################################################################
__termAll()
{
	local waitPid=$(ps -ef | grep infinity | grep -v grep | awk '{print $2}')
	${xxProfileDir}/bin/stopManager.sh
	kill -9 ${waitPid}

	exit 0
}
##################################################################################
## MAIN Script
##################################################################################
# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo '**CAUGHT TRAP**' ; /opt/IBM/WebSphere/AppServer/profiles/dmgr/bin/stopManager.sh ; exit 0" HUP INT QUIT TERM
#
# WAS9 is installed using hostname was9.docker.container --> need to make sure we can resolve the host
# Using aliases in the docker files is not sufficient as the derby containers use wp85-derby as hostname
thisHostIp=$(grep $(hostname) /etc/hosts | awk '{print $1}') && \
echo "${thisHostIp} was9.docker.container was9" >> /etc/hosts || {
	echo "ERROR: Could not create /etc/hosts entry for host name was9.docker.container"
	exit 3
}
trap "echo '**CAUGHT TRAP**' ; __termAll" HUP INT QUIT TERM
#
# Assign parameters
__init  $@ || exit 1

#
# Set the permissions to ensure that we have proper rights to start the server
cd /opt/IBM/WebSphere/AppServer/profiles
find . ! -user wasadmin -exec chown wasadmin {} \;

#
# start service in background here
/opt/IBM/WebSphere/AppServer/profiles/dmgr/bin/startManager.sh
rc=$?
echo "Deployment Manager started with rc=${rc}"
#
# Let the dmgr start and wait a moment
sleep 7
#
# Run the test configuration projects
rm -rf /tmp/wasconfig.log*; cd /opt/wasconfig/bin/ && . ./env ; sh run.sh -d ..//config-test/complete/ -l 9
rc=$?

echo "Running \"wasconfig\" test finished with rc=${rc} ..."
exit ${rc}
