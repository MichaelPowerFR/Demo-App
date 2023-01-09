data "aws_ami" "vault-server" {
  executable_users = ["self"]
  most_recent      = true
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["packer-vault-*"]
  }

  filter {
    name   = "tag:vault_version"
    values = [var.vault_version]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
