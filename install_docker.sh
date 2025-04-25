#!/bin/bash -eu

curl https://get.docker.com | sh && sudo systemctl --now enable docker

sudo groupadd -f docker
sudo usermod -aG docker $USER
sudo systemctl restart docker

# (optional) proxy setting
# sudo mkdir -p /etc/systemd/system/docker.service.d
# echo -e "[Service]\nEnvironment=\"HTTP_PROXY=http://{host}:{port}/\" \"HTTPS_PROXY=http://{host}:{port}/\"" | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf

# mkdir -p ~/.docker
# cat <<EOF >~/.docker/config.json
# {
#     "proxies": {
#         "default": {
#             "httpProxy": "http://{host}:{port}/",
#             "httpsProxy": "http://{host}:{port}/"
#         }
#     }
# }
# EOF

# sudo systemctl daemon-reload
