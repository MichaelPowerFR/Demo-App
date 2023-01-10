aws_region = "eu-west-3"
vpc_cidr   = "10.0.0.0/16"
public_subnet_cidrs = [
  "10.0.128.0/20",
  "10.0.144.0/20",
  "10.0.160.0/20",
]
private_subnet_cidrs = [
  "10.0.0.0/19",
  "10.0.32.0/19",
  "10.0.64.0/19",
]
private_subnet_tags = {
  subnet = "private"
}
instance_type         = "t3.micro"
leader_tls_servername = "vault.demo.internal"
lb_type               = "application"
node_count            = 3
vault_version         = "1.8.2"
ipv4_cidr_block       = "86.254.98.54/32"
