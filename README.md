# vault-demo
vault operator init

vault status

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='ROOT_TOKEN_GENERATED_DURING_INIT'

export VAULT_ADDR='http://INTERNAL_LB_ADDRESS:8200'
export VAULT_TOKEN='ROOT_TOKEN_GENERATED_DURING_INIT'


# Run in Vault Server
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='ROOT_TOKEN_GENERATED_DURING_INIT'

vault secrets enable -path=ssh-client-signer ssh

vault write ssh-client-signer/config/ca generate_signing_key=true

vault write ssh-client-signer/roles/ssh-role -<<"EOH"
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "*",
  "allowed_extensions": "permit-pty,permit-port-forwarding",
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m0s"
}
EOH


# Run in the Bastion host
export VAULT_ADDR='http://INTERNAL_LB_ADDRESS:8200'
curl -o /etc/ssh/trusted-user-ca-keys.pem $VAULT_ADDR/v1/ssh-client-signer/public_key
vault read -field=public_key ssh-client-signer/config/ca > /etc/ssh/trusted-user-ca-keys.pem

vi  /etc/ssh/sshd_config
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem

systemctl restart sshd.service


# Run in Client machine to configure and ssh from client to bastion
ssh-keygen -t rsa

export VAULT_ADDR='http://INTERNAL_LB_ADDRESS:8200'
export VAULT_TOKEN='ROOT_TOKEN_GENERATED_DURING_INIT'

<!-- Optional -->
vault write ssh-client-signer/sign/ssh-role public_key=@$HOME/.ssh/id_rsa.pub

vault write -field=signed_key ssh-client-signer/sign/ssh-role public_key=@$HOME/.ssh/id_rsa.pub > ~/.ssh/signed-cert.pub

<!-- Optional -->
ssh-keygen -Lf ~/.ssh/signed-cert.pub

ssh -i ~/.ssh/signed-cert.pub -i ~/.ssh/id_rsa ubuntu@BASTION_PRIVATE_IP
