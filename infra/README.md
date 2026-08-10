# infra

## 1. Conf

Edit `terraform.tfvars`:

- set `api_key`

## 2. Init

```bash
cd infra
terraform init
```

## 3. Create VMs

```bash
terraform apply
```

Wait until `vm1`, `vm2`, `vm3` are `ACTIVE`.

## 4. Private IPs

```bash
terraform output nodes
```

Note each `private` IP.

## 5. Public IPs ---> Arvan panel


## 6. Add public IPs to Terraform

Edit `terraform.tfvars`:

```hcl
public_ips = {
  vm1 = "PASTE_VM1_PUBLIC_IP"
  vm2 = "PASTE_VM2_PUBLIC_IP"
  vm3 = "PASTE_VM3_PUBLIC_IP"
}
```

Apply :

```bash
terraform apply
terraform output nodes
```

## 7. SSH

```bash
./ssh.sh vm1
./ssh.sh vm2
./ssh.sh vm3
```

