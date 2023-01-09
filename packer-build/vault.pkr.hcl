variable "vault_version" {
  type = string
}

variable "ami_user" {
  type        = string
  description = "AWS Account owner"
}

variable "instance_type" {
  type        = string
  description = "Instance type of the EC2 instance on spin  up"
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "source_commit_author" {
  type        = string
  description = "Commit Author could be consumed from pipeline environmental variables or hardcoded"
  default     = "MP"
}

variable "source_ami_type" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "source_root_device_type" {
  default = "ebs"
}

variable "source_virtualization_type" {
  default = "hvm"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to be spun up with"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to be spun in"
}

source "amazon-ebs" "vault" {
  ami_name      = "packer-vault-${formatdate("YYYY-MM-DD'T'hh-mm-ssZ", timestamp())}"
  ami_regions   = [var.region]
  ami_users     = [var.ami_user]
  encrypt_boot  = false
  instance_type = var.instance_type

  region = var.region
  run_tags = {
    env         = "amis"
    owner       = var.source_commit_author
    service     = "packer"
    source_repo = "packer-aws-vault"
  }
  snapshot_tags = {
    service = "packer"
  }
  source_ami_filter {
    filters = {
      name                = var.source_ami_type
      root-device-type    = var.source_root_device_type
      virtualization-type = var.source_virtualization_type
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = var.ssh_user
  subnet_id    = var.subnet_id
  tags = {
    env           = "amis"
    owner         = var.source_commit_author
    service       = "packer"
    vault_version = var.vault_version
  }
  vpc_id = var.vpc_id
  temporary_iam_instance_profile_policy_document {
    Statement {
      Action = [
        "ec2:*",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:DeleteRolePolicy",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:AddRoleToInstanceProfile"
      ]
      Effect   = "Allow"
      Resource = ["*"]
    }
    Version = "2012-10-17"
  }
}

build {
  sources = ["source.amazon-ebs.vault"]

  provisioner "shell" {
    inline = ["echo 'Amazon AMI Build for vault service starting' "]
  }

  provisioner "shell" {
    inline = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"]
  }

  provisioner "shell" {
    inline = [

      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update",
      "sudo apt-get -y install unattended-upgrades",
      "sudo apt-get install -y vault=${var.vault_version}",
      "sudo apt-get update",
      "sudo apt-get install -y awscli jq",


      "echo \"Configuring system time\"",
      "DEBIAN_FRONTEND=noninteractive sudo timedatectl set-timezone UTC",

      # removing any default installation files from /opt/vault/tls/
      "sudo rm -rf /opt/vault/tls/*",

      # /opt/vault/tls should be readable by all users of the system
      "sudo chmod 0755 /opt/vault/tls",

      "sudo chown root:root /etc/vault.d",
      "sudo chown root:vault /etc/vault.d/vault.hcl",
      "sudo chmod 640 /etc/vault.d/vault.hcl",

      "sudo systemctl enable vault",
      "sudo systemctl start vault",

      "echo \"Setup Vault profile\"",
      "cat <<PROFILE | sudo tee /etc/profile.d/vault.sh",
      "export VAULT_ADDR=\"http://127.0.0.1:8200\"",
      "PROFILE",

    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }

}
