# Infra Database - RDS PostgreSQL com Terraform

## 📋 Descrição

Este repositório contém a infraestrutura de banco de dados gerenciado (AWS RDS PostgreSQL) usando Terraform, garantindo:
- ✅ Multi-AZ para alta disponibilidade
- ✅ Backups automatizados
- ✅ Criptografia em repouso e trânsito
- ✅ Subnets privadas e security groups
- ✅ Parametrização completa

## 🛠️ Tecnologias Utilizadas

- **IaC**: Terraform 1.5+
- **Database**: AWS RDS PostgreSQL 15+
- **Networking**: VPC, DB Subnet Groups
- **Segurança**: Security Groups, KMS Encryption
- **Backup**: Automated snapshots
- **Monitoring**: CloudWatch, Enhanced Monitoring
- **CI/CD**: GitHub Actions

## 📁 Estrutura do Projeto

```
infra-database/
├── terraform/
│   ├── providers.tf         # Configuração de providers
│   ├── variables.tf         # Declaração de variáveis
│   ├── outputs.tf           # Outputs (endpoint, etc)
│   ├── main.tf              # RDS Instance, DB Subnet Group
│   ├── networking.tf        # Security Groups
│   ├── iam.tf               # IAM para Enhanced Monitoring
│   ├── backup.tf            # Snapshots e políticas de retenção
│   ├── terraform.tfvars.example
│   └── backend.tf           # Remote state
├── scripts/
│   ├── init-db.sql          # Script de inicialização
│   ├── create-schema.sql    # Schema inicial
│   └── seeds.sql            # Dados de teste
├── .github/
│   └── workflows/
│       ├── plan.yml         # Terraform plan
│       └── apply.yml        # Terraform apply
├── .gitignore
├── README.md
└── ARCHITECTURE.md
```

## 🚀 Como Executar Localmente

### Pré-requisitos
- Terraform 1.5+
- AWS CLI v2
- PostgreSQL client (psql)

### Passos

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/infra-database.git
   cd infra-database/terraform
   ```

2. **Configure as variáveis**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edite terraform.tfvars com seus valores
   ```

3. **Inicialize Terraform**
   ```bash
   terraform init
   ```

4. **Planeje a infraestrutura**
   ```bash
   terraform plan -out=tfplan
   ```

5. **Aplique a infraestrutura**
   ```bash
   terraform apply tfplan
   ```

6. **Inicialize o banco de dados**
   ```bash
   # Obtenha o endpoint
   DB_HOST=$(terraform output -raw rds_endpoint_address)
   
   # Conecte e execute scripts
   psql -h $DB_HOST -U postgres -d postgres -f ../scripts/init-db.sql
   psql -h $DB_HOST -U postgres -d tech_challenge -f ../scripts/create-schema.sql
   ```

## 📊 Arquitetura Provisionada

```
┌─────────────────────────────────────────┐
│        AWS VPC (Private Subnets)        │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  AWS RDS PostgreSQL              │  │
│  │  - Multi-AZ (Primary + Standby)  │  │
│  │  - Automated Backups (7 days)    │  │
│  │  - Enhanced Monitoring           │  │
│  │  - Encryption (KMS)              │  │
│  │  - Storage: 100GB (auto-scaling) │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  DB Subnet Group (Multi-AZ)      │  │
│  │  - Subnet AZ-1                   │  │
│  │  - Subnet AZ-2                   │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Security Group                  │  │
│  │  - Ingress: 5432 (K8s only)      │  │
│  │  - Egress: Unrestricted          │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│    CloudWatch Monitoring                │
│    - CPU, Memory, Storage               │
│    - Backup Status                      │
│    - Connection Metrics                 │
└─────────────────────────────────────────┘
```

## 📝 Variáveis de Entrada (terraform.tfvars)

```hcl
# Database
db_identifier            = "tech-challenge-db"
db_engine_version        = "15.3"
db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_storage_type          = "gp3"

# Network
environment              = "production"
vpc_id                   = "vpc-xxxxx"
db_subnet_group_name     = "tech-challenge-db-subnet"
private_subnet_ids       = ["subnet-xxxxx", "subnet-yyyyy"]

# Security
db_name                  = "tech_challenge"
db_username              = "postgres"
# db_password will be prompted or set via environment
multi_az                 = true
backup_retention_period  = 7

# Encryption
enable_encryption        = true
kms_key_id              = "arn:aws:kms:..."
```

## 🔄 Pipeline CI/CD

- **plan.yml**: Valida Terraform em PRs
- **apply.yml**: Deploy automático em merge para main

## 🔒 Segurança

- ✅ Banco de dados em subnets privadas
- ✅ Criptografia KMS habilitada
- ✅ Security group restritivo (apenas K8s)
- ✅ Backup automático com retenção de 7 dias
- ✅ Enhanced monitoring habilitado
- ✅ IAM role para acesso seguro
- ✅ Senhas armazenadas em AWS Secrets Manager

## 🔧 Manutenção

### Fazer Backup Manual
```bash
aws rds create-db-snapshot \
  --db-instance-identifier tech-challenge-db \
  --db-snapshot-identifier tech-challenge-backup-$(date +%s)
```

### Restaurar de Backup
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier tech-challenge-db-restored \
  --db-snapshot-identifier tech-challenge-backup-xxxxx
```

### Escalar Storage
Edite `terraform.tfvars` e altere `db_max_allocated_storage`:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## 📚 Documentação Adicional

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Terraform AWS RDS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

## 🤝 Contribuindo

1. Crie uma branch: `git checkout -b feature/melhoria-db`
2. Commit: `git commit -am 'Add melhoria'`
3. Push: `git push origin feature/melhoria-db`
4. Abra um Pull Request

## 📄 Licença

MIT
