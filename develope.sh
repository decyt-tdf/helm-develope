#!/bin/bash
# Watch and upgrade files inside a release as you code.

readonly CONFIG="./.helm-developerc"
function check_deps () {
# install inotify-tools if necesary
  if [[ -a !$(which inotifywait) ]]; then
    echo 'Would you like to install inotify-tools? (y/n)';
    read install
    case "${install}" in
      y)
        echo 'Installing inotify-tools'
        sudo apt-get install -y inotify-tools
        ;;
      n)
        echo 'You can still use this plugin to manualy copy code to your release'
        ;;
      *)
        echo 'Usage: type "y" or "n"'
        exit
        ;;
    esac
  fi
}

function watch () {
  inotifywait -m --format %w --event modify "$(pwd)"/* | while read file; do
    echo "uploading ${file}"
    kubectl cp "${file}" "${pod}":"${file//$(pwd)/${app_path}}" -c "${container}"
  done
}

function create_config () {
  # select a release from the cluster
  echo "Select a release" 
  echo "Fetching release names from cluster..."
  function select_release () {
    local releases
    releases="$(helm ls | tail -n+2 | awk -F"\t" '{ print $1 }')"
    select release in ${releases}; do
      echo "${release}"
      break
    done
  }
  current_release="$(select_release)"
  # select a pod
  echo "Select a pod in the ${current_release} release"
  echo "Fetching pod names from cluster..."
  function select_pod () {
    local pods
    pods="$(kubectl get po -l release="${current_release}" | tail -n+2 | awk -F" " '{ print $1 }')" 
    select pod in ${pods}; do
      echo "${pod}"
      break
    done
  }
  current_pod="$(select_pod)"

  # select a container
  echo "Select a container in the ${current_pod} pod"
  echo "Fetching container names from cluster..."
  function select_container () {
    local containers
    containers="$(kubectl get po "${current_pod}" -o jsonpath="{.spec.containers[*].name}")"
    select container in ${containers}; do
      echo "${container}"
      break
    done
  }
  current_container="$(select_container)"
  function select_path () {
    read path
    echo "${path}"
  }
  echo "Where does your code live inside the container?"
  current_path="$(select_path)"
  cat <<-EOF > "${CONFIG}"
  release="${current_release}"
  pod="${current_pod}"
  container="${current_container}"
  app_path="${current_path}"
EOF
}

function main () {
  check_deps
  if [[ ! -f ${CONFIG} ]]; then
    create_config
  fi
  . "${CONFIG}"
  echo Your current config is: 
  echo 
  echo Release: "${release}"
  echo Pod: "${pod}"
  echo Container: "${container}"
  echo Path: "${app_path}";
  watch
}
main
