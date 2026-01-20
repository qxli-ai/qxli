[qxli]
qxli ansible_host=${ELASTIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_PRIVATE_KEY} ansible_python_interpreter=/usr/bin/python3

[qxli:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
