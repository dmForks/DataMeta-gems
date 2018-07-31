#!/bin/bash

chk_srcing() {
if [[ "${1}" = "${2}" ]]
then
  (>&2 ruby <<- xx
require '${DATAMETA_SCP_COMMON}/common/ansi'
include AnsiClr

puts %<#{OP}#{BOLD};#{F_RED}m#{LLQBIG}ERROR#{RRQBIG}#{
  RESET}: must run this script sourced in the original shell, like this#{
  SPEAR} #{OP}#{BOLD};#{F_LGREEN};#{REVERSE}m. ${0} dev#{RESET}

#{OP}#{F_RED}mNOT#{RESET} like this#{RTRI} #{OP}#{F_RED};#{BOLD};#{REVERSE}m${0} dev#{RESET}

>
xx
)
  exit 1
fi
}

set_env() {
   gcp_proj="$1"

   kns="$2"
   cluster="$3"
   zone="$4"

   export GCP_PROJ="$1"
   export K8S_NS="$2" # Kubernetes namespace
   export GCP_CLUSTER="$3"
   export GCP_ZONE="$4"

   gcloud config set project ${gcp_proj}
   [[ $? != 0 ]] &&  { (>&2 echo "Failed to set the project to <${GCP_PROJ}>"); return 3; }

   echo "Have set project to <${gcp_proj}>"

   gcloud container clusters get-credentials ${GCP_CLUSTER} --zone ${GCP_ZONE} --project ${GCP_PROJ}
   [[ $? != 0 ]] &&  { (>&2 echo "Failed to retrieve the creds for <${GCP_PROJ}>"); return 4; }

   source ${DATAMETA_SCP_COMMON}/common/whatEnv.sh
}

