openssl req -x509 -newkey rsa:4096 -keyout server.key -out server_base64.cer -sha256 -days 3650 -nodes -subj "/C=PL/L=Warsaw/O=Example Org/OU=Security Dept/CN=127.0.0.1"

