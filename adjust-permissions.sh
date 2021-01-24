#!/bin/bash

export apps_root=/var/www/ood/apps/sys
export script_path=$(cd ${0%/*} && pwd -P)

set_facl() {
  # params: $1 = app_name $2 enabled $3 comma_separated_list_groups 

  app_folder=${apps_root}/$1
  # check if folder actually exists
  [ ! -d ${app_folder} ] && echo "the folder specified does not exist" && return 1

  # reset permission to make it accessible only to root
  chown root:root ${app_folder}
  chmod 750 ${app_folder}
  setfacl -b ${app_folder}

  # if app is not enabled we are done
  if [ $2 -eq 0  ] ; then 
     return 0
  fi

  setfacl -m ` echo $3 | sed 's/,/:r-x,g:/g' | sed 's/^/g:/' | sed 's/$/:r-x/' ` ${app_folder} 
  #echo "setfacl -m ` echo $3 | sed 's/,/:r-x,g:/g' | sed 's/^/g:/' | sed 's/$/:r-x/' ` ${app_folder} "
}

export -f set_facl

run_tests() {
  # set_facl unit tests

  ## check that it exists if app does not exists
  echo "test1 : check that it exists if app does not exists"
  rm -fr test_app 
  set_facl test_app 1 g_80421,g_75065
  
  sleep 1
  
  ## check that it removes permissions if app exists and inactive
  echo "test2 : set_facl test_app 0 rc_admin,rc_unpriv"
  rm -fr test_app 
  mkdir test_app
  chmod 777 test_app
  setfacl -m u:francesco:r-x test_app
  ls -ld test_app
  getfacl test_app
  
  set_facl test_app 0 rc_admin,rc_unpriv
  
  ls -ld test_app
  getfacl test_app
  
  sleep 1
  
  ## check that it grants the correct permissions for multiple groups"
  echo "test3 : set_facl test_app 1 rc_admin,rc_unpriv"
  rm -fr test_app 
  mkdir test_app
  chmod 777 test_app
  setfacl -m u:francesco:r-x test_app
  ls -ld test_app
  getfacl test_app
  
  set_facl test_app 1 rc_admin,rc_unpriv 
  
  ls -ld test_app
  getfacl test_app
  
  ## check that it grants the correct permissions for single group"
  echo "test3 : set_facl test_app 1 rc_unpriv"
  rm -fr test_app 
  mkdir test_app
  chmod 777 test_app
  setfacl -m u:francesco:r-x test_app
  ls -ld test_app
  getfacl test_app
  
  set_facl test_app 1 rc_unpriv 
  
  ls -ld test_app
  getfacl test_app
}

export -f run_tests

test_jq_parsing() {
  echo "first argument $1"
  echo "second argument $2"
  echo "third argument $3"
  if [ $2 -eq 0  ] ; then
    echo "app is not enabled"
  fi
}
export -f test_jq_parsing

[ ! -f ${script_path}/apps-permissions.json ] && exit 1
echo "setting permissions"

cat ${script_path}/apps-permissions.json | jq --raw-output '.apps[]  | "\(.app_name)  \(.enabled) \(.courses | join(","))"  ' | \
xargs -I {} -t bash -c "set_facl {} "
#xargs -I {} -t bash -c "test_jq_parsing {} "
