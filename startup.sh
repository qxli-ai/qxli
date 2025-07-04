sudo mkdir -p /etc/letsencrypt/live/demo.qxli.com
sudo mkdir -p /etc/letsencrypt/live/agents.qxli.com
sudo mkdir -p /etc/letsencrypt/live/flow.qxli.com
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo mkdir -p ~/.cache/nim
sudo chown -R 777 ~/.cache
echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin
sudo systemctl restart docker
sudo apt-get install -y docker-compose-plugin
sudo docker compose up -d
