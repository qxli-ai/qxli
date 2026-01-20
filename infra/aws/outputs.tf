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
  value       = "ssh -i ~/.ssh/<private_key> ubuntu@${aws_eip.qxli.public_ip}"
}
