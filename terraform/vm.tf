data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [var.ami_owner]

}

resource "aws_instance" "vm1" {
  ami                         = var.custom_ami != "" ? var.custom_ami : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type != "" ? var.instance_type : var.instance_type_default
  # Uncomment key_name to enable SSH access
  # key_name                    = aws_key_pair.sshkey.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet-1a.id
  vpc_security_group_ids = [
    # Uncomment aws_security_group.ssh.id to enable SSH access for deployment instead of using SSM
    # aws_security_group.ssh.id,
    aws_security_group.http.id
  ]
  user_data_base64     = base64encode(file("${path.module}/script/ubuntu_provision.sh"))
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
}

