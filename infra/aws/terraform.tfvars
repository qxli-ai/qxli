project = "qxli"
region  = "us-east-1"
product_name = "qxli"

vpc_id    = "vpc-030d3f75ad4845dcd"
subnet_id = "subnet-0c4aed08c8e681b83"

# SSH access
ssh_public_key_path  = "~/.ssh/qxli-aws.pub"
ssh_private_key_path = "~/.ssh/qxli-aws"
key_pair_name        = "qxli-aws-key"

# Optional: lock down SSH; update with your IP/CIDR
# allowed_ssh_cidrs = ["203.0.113.10/32"]
