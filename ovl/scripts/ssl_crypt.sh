key="./ssl_crypt.key"
if [ ! -f "${key}" ]
then
  echo "generating new ${key}"
  tr -dc A-Za-z0-9 </dev/urandom | head -c 20 >> "${key}"
fi

secret=$(cat "${key}")
case "${1}" in
  "g") tr -dc A-Za-z0-9 </dev/urandom | head -c 20
  ;;
  "e") read plain; echo -n "${plain}" | openssl enc -e -a -pbkdf2 -k "${secret}"
  ;;
  "d") read hash; echo "${hash}" | openssl base64 -d | openssl enc -d -pbkdf2 -k "${secret}"
  ;;
  *) echo -e "usage:\n\techo 'secret' | ./$(basename "${0}") e|d\nrenew:\n\t./$(basename "${0}") g > ${key}"
  ;;
esac

