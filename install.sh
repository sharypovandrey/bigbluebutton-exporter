#!/bin/bash -ex

mkdir ~/bbb-exporter
apt install -y wget apache2-utils

rm ~/bbb-exporter/docker-compose.yml
wget https://raw.githubusercontent.com/greenstatic/bigbluebutton-exporter/master/extras/docker-compose.yml --directory-prefix=/root/bbb-exporter/

BBB_URL=`bbb-conf --secret | sed -n 's/    URL: //p'`
BBB_SECRET=`bbb-conf --secret | sed -n 's/    Secret: //p'`

cat <<HERE > ~/bbb-exporter/secrets.env
API_BASE_URL=${BBB_URL}api/
API_SECRET=$BBB_SECRET
HERE
cd ~/bbb-exporter
BBB_EXPORTER_VERSION=latest docker-compose up -d

htpasswd -b -c /etc/nginx/.htpasswd $1 $2

sed -i 's^   # Handle RTMPT (RTMP Tunneling).  Forwards requests^  location /metrics/ {\n    auth_basic "BigBlueButton";\n    auth_basic_user_file /etc/nginx/.htpasswd;\n    proxy_pass         http://127.0.0.1:9688/;\n    proxy_redirect     default;\n    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;\n    client_max_body_size       10m;\n    client_body_buffer_size    128k;\n    proxy_connect_timeout      90;\n    proxy_send_timeout         90;\n    proxy_read_timeout         90;\n    proxy_buffer_size          4k;\n    proxy_buffers              4 32k;\n    proxy_busy_buffers_size    64k;\n    proxy_temp_file_write_size 64k;\n    include    fastcgi_params;\n  }\n\n  # Handle RTMPT (RTMP Tunneling).  Forwards requests^' /etc/nginx/sites-available/bigbluebutton

systemctl reload nginx

bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

sed -i 's^	# bind to = *^	bind to = 127.0.0.1' /etc/netdata/netdata.conf

sed -i 's^   # Handle RTMPT (RTMP Tunneling).  Forwards requests^  # Netdata Monitoring\n  location /netdata/ {\n    auth_basic "BigBlueButton";\n    auth_basic_user_file /etc/nginx/.htpasswd;\n    proxy_pass         http://127.0.0.1:19999/;\n    proxy_redirect     default;\n    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;\n    client_max_body_size       10m;\n    client_body_buffer_size    128k;\n    proxy_connect_timeout      90;\n    proxy_send_timeout         90;\n    proxy_read_timeout         90;\n    proxy_buffer_size          4k;\n    proxy_buffers              4 32k;\n    proxy_busy_buffers_size    64k;\n    proxy_temp_file_write_size 64k;\n    include    fastcgi_params;\n  }\n\n  # Handle RTMPT (RTMP Tunneling).  Forwards requests^' /etc/nginx/sites-available/bigbluebutton

systemctl reload nginx
