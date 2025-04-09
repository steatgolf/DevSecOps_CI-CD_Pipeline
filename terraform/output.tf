output "public_ip" {
  value = aws_instance.vm1.public_ip
}
# output "elastic_ip" {
#   value = aws_eip.ip1.public_ip
# }


output "ec2_id" {
  value = aws_instance.vm1.id
}