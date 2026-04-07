addr="http://192.168.0.100"
addr="http://127.0.0.1"

if [ ! -z "${1}" ]
then
  addr="${1}"
fi

while true
do
  curl -w '@curl_format' -sS -o /dev/null -X 'GET' "${addr}" -H 'accept: */*'
  sleep 1
done

