# bash only
: '
hosts=( 127.0.0.1 192.168.0.100 )
ports=( 22 80 )

for host in "${hosts[@]}"
do
  for port in "${ports[@]}"
  do
    (echo >/dev/tcp/${host}/${port}) &>/dev/null && echo "${host}:${port} open" || echo "${host}:${port} closed"
  done
  echo "--==--"
done
'

# sh version
hosts='127.0.0.1
192.168.0.100
192.168.1.1'

ports='22
80'

echo "${hosts}" | while read host ; do
  echo "${ports}" | while read port ; do
    if nc -z -w 1 "${host}" "${port}" 2>/dev/null 
    then
      echo "${host}:${port} open"
    else
      echo "${host}:${port} closed"
    fi
  done
  echo "--==--"
done

