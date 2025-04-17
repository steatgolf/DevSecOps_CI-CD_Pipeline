output "public_ip" {
  value = aws_instance.vm1.public_ip
}

# SSM use EC2_ID to access and run command.
output "ec2_id" {
  value = aws_instance.vm1.id
}

# output "elastic_ip" {
#   value = aws_eip.ip1.public_ip
# }