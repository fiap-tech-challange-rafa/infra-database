# infra-database

Infraestrutura de banco para o Tech Challenge usando Terraform (AWS RDS PostgreSQL).

## Recursos provisionados

- `aws_db_instance` PostgreSQL
- `aws_db_subnet_group`
- `aws_security_group` para acesso ao banco
- KMS opcional para criptografia
- IAM role para Enhanced Monitoring
- Outputs com endpoint e dados de conexao

## Estrutura

```text
infra-database/
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── networking.tf
│   ├── iam.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── scripts/
│   └── init-db.sql
└── .github/workflows/
    ├── plan.yml
    └── apply.yml
```

## Como usar

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## Variaveis importantes

- `aws_region`
- `vpc_id`
- `private_subnet_ids`
- `allowed_security_groups`
- `db_identifier`
- `db_name`
- `db_username`
- `db_password`

## CI/CD

- `plan.yml`: executa `terraform fmt`, `init`, `validate` e `plan` em PR
- `apply.yml`: executa `plan/apply` em push na branch `main` (quando arquivos em `terraform/**` mudam)
