output "ami_id" {
  value = data.aws_ami.vault-server.image_id
}

output "local_ami_id" {
  value = local.vault_server_ami_id
}
