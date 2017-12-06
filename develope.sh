#!/bin/bash
if [ -a !$(which inotifywait) ];
  then echo 'Would you like to install inotify-tools? (y/n)';
      read INSTALL
      case $INSTALL in
        y) echo 'Installing inotify-tools' && sudo apt-get install -y inotify-tools;;
        n) echo 'You can still use this plugin to manualy copy code to your release';;
        *) echo 'Usage: type "y" or "n"' && exit;;
      esac
fi
echo "Fetching release names from cluster..."
select VARNAME in $(helm ls | tail -n+2 | awk -F"\t" '{ print $1 }')
do
  echo "Select a pod in the ${VARNAME} release"
  select POD in $(kubectl get po -l "release=${VARNAME}" -o jsonpath={.items[*].spec.pods[*].name})
  do
    echo ${VARNAME} ${POD}
  done
done
