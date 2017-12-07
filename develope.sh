#!/bin/bash
CONFIG=".helm-developerc"
if [ -a $CONFIG ]; then
    . $CONFIG
    echo Your current config is: 
    echo 
    echo Release: $RELEASE
    echo Pod: $POD
    echo Container: $CONTAINER
    echo Path: $APPPATH;
fi

# install inotify-tools if necesary
if [ -a !$(which inotifywait) ];
  then echo 'Would you like to install inotify-tools? (y/n)';
      read INSTALL
      case $INSTALL in
        y) echo 'Installing inotify-tools' && sudo apt-get install -y inotify-tools;;
        n) echo 'You can still use this plugin to manualy copy code to your release';;
        *) echo 'Usage: type "y" or "n"' && exit;;
      esac
fi
inotifywait -m --format %w --event modify `pwd`/* | while read FILE;
  do
    echo "uploading ${FILE}"
    kubectl cp ${FILE} ${POD}:$(echo ${FILE} | sed "s@$(pwd)@${APPPATH}@g") -c ${CONTAINER}
  done
# select a release from the cluster
echo "Fetching release names from cluster..."
select RELEASE in $(helm ls | tail -n+2 | awk -F"\t" '{ print $1 }')
do
# select a pod
  echo "Select a pod in the ${RELEASE} release"
  select POD in $(kubectl get po -l "release=${RELEASE}" | tail -n+2 | awk -F" " '{ print $1 }' )
  do
    echo "Select a container in the ${POD} pod"
    select CONTAINER in $(kubectl get po ${POD} -o jsonpath="{.spec.containers[*].name}")
    do
# create configuration file
      echo RELEASE="${RELEASE}" > ${CONFIG}
      echo POD="${POD}" >> ${CONFIG}
      echo CONTAINER="${CONTAINER}" >> ${CONFIG}
      echo "Specify the path where your code lives inside the container (ej: /path/subpath)"
      read PATH
      echo PATH="${PATH}" >> ${CONFIG}
      echo ${CONFIG} >> .gitignore
      echo $(cat ${CONFIG})
      source ${CONFIG}
    done
  done
done


