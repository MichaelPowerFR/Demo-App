locals {
  vault_server_ami_id = var.user_supplied_ami_id != null ? var.user_supplied_ami_id : data.aws_ami.vault-server.image_id
}
