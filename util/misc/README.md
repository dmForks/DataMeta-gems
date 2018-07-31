# Miscellaneous utilities

## Console coloring and decor

See example in [`envCommon.sh`](./envCommon.sh) and in [`ansi.rb`, the `test` method](./ansi.rb).

## GCP (Google Cloud Platform) utils

* `envCommon.sh` - setting the environment for a terminal. An example of using it in a project:

```
#!/bin/bash

export DATAMETA_SCP_COMMON='../../'

SUPP_ENVS='Supported environments are: \e[1;35mdev\e[m and \e[1;35mtest\e[m'

. ../../envCommon.sh
chk_srcing "${BASH_SOURCE[0]}" "${0}"

DEPL_ENV="$1"

if [[ -z "$DEPL_ENV" ]]
then
   (>&2 echo -e "\e[1;31m《ERROR》\e[m Must specify the target environment. ${SUPP_ENVS}")
   return 5
fi

echo "Setting up the deployment environment \e[1;35m$DEPL_ENV\e[m..."

case "${DEPL_ENV}" in

  dev)
      set_env dmsvc-dev-test datameta-dev us-west1-std-m us-west1-a
  ;;

  test)
      set_env dmsvc-dev-test datameta-test us-west1-std-m us-west1-a
  ;;

  *) (>&2 echo -e "\e[1;31m《ERROR》\e[m \e[31m$DEPL_ENV\e[m is not supported. ${SUPP_ENVS}")
     return 2
  ;;

esac

```

