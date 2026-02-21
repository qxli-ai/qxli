output "instance_public_ip" {
  description = "Dynamic public IP of the EC2 instance (use elastic_ip instead for static IP)."
  value       = aws_instance.qxli.public_ip
}

output "elastic_ip" {
  description = "Static Elastic IP address attached to the instance."
  value       = aws_eip.qxli.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.qxli.id
}

output "ssh_command" {
  description = "Handy SSH command (using Elastic IP)."
  value       = "ssh -i ~/.ssh/qxli-aws ubuntu@${aws_eip.qxli.public_ip}"
}

output "secret_arn" {
  description = "ARN of the SSH private key secret in Secrets Manager."
  value       = aws_secretsmanager_secret.ssh_private_key.arn
}

output "dev_key_setup" {
  description = "One-liner for new devs to pull the SSH key and set correct permissions."
  value       = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.ssh_private_key.name} --query SecretString --output text > ~/.ssh/qxli-aws && chmod 600 ~/.ssh/qxli-aws"
}
