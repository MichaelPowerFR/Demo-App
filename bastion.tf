data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdDc7ZNzFI/2Ltcc4uUIyob5yfmFYxyIJvVXzLQldqqlmW3sZVRp5UZtuQIIoBYhKTDKYTbtvdKR4pq+TIU+IINNMYfEC0p0jUzk1N+KRXtd8ITExOumh2XMo3Ea3EDp9D2DKzE26w1n/Cu1DoP0at8tYexrYndKLNkVMJ0vFR3rXR96Toi/25gbRKT49k+jZ09NYBCzLtO+StvPiRl+k2tYJAiKZnpfTeSyzgcjOjonQlxZIDU6ih4/y5RbnYvKoTrxM7b60UBqmOj1+GChXARWnsTWqibXQ+eIXlZNXoVzPEnSGM5pSfndA7XBcjs7kD+B4A5Opgmgybei2Gx9cV"
}


resource "aws_security_group" "bastion_host_security_group" {
  description = "Enable SSH access to the bastion host from external via SSH port"
  name        = "${var.resource_name_prefix}-bastion-host-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "public_ssh_bastion" {
  description = "SSH From Public IP to bastion"
  type        = "ingress"
  from_port   = var.public_ssh_port
  to_port     = var.public_ssh_port
  protocol    = "TCP"
  cidr_blocks = [var.ipv4_cidr_block]

  security_group_id = aws_security_group.bastion_host_security_group.id
}

resource "aws_security_group_rule" "ssh_from_client" {
  description              = "Incoming ssh from Client"
  type                     = "ingress"
  from_port                = var.public_ssh_port
  to_port                  = var.public_ssh_port
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.client_security_group.id
  security_group_id        = aws_security_group.bastion_host_security_group.id
}

resource "aws_security_group_rule" "egress_bastion" {
  description = "Outgoing traffic from bastion to instances"
  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.bastion_host_security_group.id
}

resource "aws_security_group" "client_security_group" {
  description = "Enable SSH access to the client host from external via SSH port"
  name        = "${var.resource_name_prefix}-client-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "public_ssh_client" {
  description = "SSH From Public IP to client"
  type        = "ingress"
  from_port   = var.public_ssh_port
  to_port     = var.public_ssh_port
  protocol    = "TCP"
  cidr_blocks = [var.ipv4_cidr_block]

  security_group_id = aws_security_group.client_security_group.id
}


resource "aws_security_group_rule" "egress_client" {
  description = "Outgoing traffic from client to instances"
  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.client_security_group.id
}


resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = "bastion"
  vpc_security_group_ids = [aws_security_group.bastion_host_security_group.id]
  tags = {
    Name = "BastionHost"
  }
}


resource "aws_instance" "client" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = "bastion"
  vpc_security_group_ids = [aws_security_group.client_security_group.id]
  tags = {
    Name = "ClientHost"
  }

  user_data = <<EOF
#!/bin/bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault=1.8.2
EOF

}

resource "aws_instance" "bastion1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = "bastion"
  vpc_security_group_ids = [aws_security_group.bastion_host_security_group.id]
  tags = {
    Name = "BastionHost1"
  }
}
