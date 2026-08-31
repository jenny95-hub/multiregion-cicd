resource "aws_instance" "jenkins" {

  ami = var.ami_id

  instance_type = var.instance_type

  subnet_id = var.subnet_id

  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = var.instance_profile

  key_name = var.key_name

  user_data = file("${path.module}/install.sh")

  tags = {
    Name = "${var.project_name}-jenkins"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = false
  }
}