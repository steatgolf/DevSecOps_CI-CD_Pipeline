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
  ami           = var.custom_ami != "" ? var.custom_ami : data.aws_ami.ubuntu.id
  instance_type = var.instance_type != "" ? var.instance_type : var.instance_type_default
  # Uncomment key_name to enable SSH access
  # key_name                    = aws_key_pair.sshkey.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.public-zone1.id

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    # Uncomment aws_security_group.ssh.id to enable SSH access for deployment instead of using SSM
    # aws_security_group.ssh.id,
    aws_security_group.http.id
  ]
  user_data_base64     = base64encode(file("${path.module}/script/ubuntu_provision.sh"))
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  depends_on           = [aws_iam_role.ec2_ssm]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "aws_ebs_volume" "vm1" {
  availability_zone = local.zone1
  size              = 10
  type              = "gp3"

  tags = {
    Name = "vm1-volume"
  }
}

resource "aws_volume_attachment" "vm1" {
  device_name = var.ebs_device_name
  volume_id   = aws_ebs_volume.vm1.id
  instance_id = aws_instance.vm1.id
}