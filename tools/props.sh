#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "config file is required"
  exit 1
fi

if [ ! -f "${1}" ]
then
  echo "config file must exists"
  exit 1
fi

declare -A properties=()
pattern='^(\s*)([^#].+)([=]).+$'

load () {
  while IFS= read -r line
  do
    if [[ "${line}" =~ $pattern ]]
    then
      key=$(echo "${line}" | awk '{sub(/( *)=( *)/,"=")}1' | awk -F'=' '{print $1}' | sed 's/^ *//;s/ *$//')
      val=$(echo "${line}" | awk '{sub(/( *)=( *)/,"=")}1' | awk -F'=' '{$1=""; print $0}' | sed 's/^ *//;s/ *$//')
      if [ ! -z "${key}" ]&&[ ! -z "${val}" ]
      then
        #echo "[${key}] -> [${val}]"
        properties["${key}"]="${val}"
      fi
    fi
  done < "${1}"
}

print () {
  for key in "${!properties[@]}"
  do
    echo -e "[${key}] ->\t[${properties[$key]}]"
  done
}

get () {
  echo $(echo ${properties["${1}"]} | tr -d '\n\t\r ')
}

put () {
  if [ ! -z "$(get "${1}")" ]
  then
    echo "${1} update"
  fi
  properties["${1}"]="${2}"
}

del () {
  if [ ! -z "$(get "${1}")" ]
  then
    unset "properties[${1}]"
  fi
}

#############################################
: '
# load properties file to array
load "${1}"

# print array of properties
print

key="foo"
# insert property
put "${key}" "bar"

# retrieve property value
echo "${key} = $(get "${key}")"

# remove key
del "${key}"
'
#############################################

