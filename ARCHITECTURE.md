# Arquitetura - Infra Database

## 📐 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                      AWS VPC                            │
│                   10.0.0.0/16                           │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Availability Zone 1 (us-east-1a)       │  │
│  │                                                 │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │  Private Subnet: 10.0.1.0/24              │ │  │
│  │  │                                            │ │  │
│  │  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  │  RDS PostgreSQL - Primary Instance  │ │ │  │
│  │  │  │  - db.t4g.medium                    │ │ │  │
│  │  │  │  - 100 GB initial storage           │ │ │  │
│  │  │  │  - Auto-scaling to 500 GB          │ │ │  │
│  │  │  │  - Multi-AZ Failover               │ │ │  │
│  │  │  │  - Encrypted (KMS)                 │ │ │  │
│  │  │  └──────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│                      │                                  │
│                      ▼ Synchronous Replication         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Availability Zone 2 (us-east-1b)       │  │
│  │                                                 │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │  Private Subnet: 10.0.2.0/24              │ │  │
│  │  │                                            │ │  │
│  │  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  │  RDS PostgreSQL - Standby Instance  │ │ │  │
│  │  │  │  (Read-only, auto-failover)         │ │ │  │
│  │  │  └──────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         DB Subnet Group                         │  │
│  │  - Encompasses all private subnets              │  │
│  │  - Multi-AZ support                             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Security Group                          │  │
│  │  - Ingress: 5432 from K8s sg                    │  │
│  │  - Egress: All                                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         │                    │
         │                    │
    ┌────▼──────────┐   ┌─────▼────────┐
    │  KMS Key      │   │  CloudWatch  │
    │  - Encryption │   │  Monitoring  │
    │  - Rotation   │   │  - Metrics   │
    │    enabled    │   │  - Alerts    │
    └───────────────┘   └──────────────┘
         │
         ▼
    Secrets Manager
    - DB Password
    - Master Username
```

## 📊 Modelo de Dados

```
CLIENTES
├── id (PK)
├── cpf (UNIQUE)
├── nome
├── email
├── telefone
├── status (ATIVO, INATIVO, BLOQUEADO)
└── timestamps

VEICULOS
├── id (PK)
├── cliente_id (FK → CLIENTES)
├── placa (UNIQUE)
├── marca
├── modelo
├── ano
└── status

PECAS
├── id (PK)
├── nome
├── descricao
├── valor_unitario
├── quantidade_estoque
└── quantidade_minima

SERVICOS
├── id (PK)
├── nome
├── descricao
├── valor_mao_obra
└── tempo_estimado_horas

ORDENS_SERVICO
├── id (PK)
├── cliente_id (FK → CLIENTES)
├── veiculo_id (FK → VEICULOS)
├── status (DIAGNOSTICO, ORCAMENTO, APROVADO, REJEITADO, EXECUCAO, FINALIZADO, ENTREGUE)
├── descricao_problema
├── valor_total
└── timestamps

ITENS_SERVICO
├── id (PK)
├── ordem_servico_id (FK → ORDENS_SERVICO)
├── servico_id (FK → SERVICOS)
├── quantidade
└── valor_unitario

ITENS_PECA
├── id (PK)
├── ordem_servico_id (FK → ORDENS_SERVICO)
├── peca_id (FK → PECAS)
├── quantidade
└── valor_unitario

ORCAMENTOS
├── id (PK)
├── ordem_servico_id (FK → ORDENS_SERVICO, UNIQUE)
├── valor_total
├── status (PENDENTE, APROVADO, REJEITADO)
└── timestamps
```

## 🔄 Fluxo de Dados

```
Application (K8s)
    │
    │ JDBC Connection
    │ (Secrets Manager credentials)
    │
    ▼
┌──────────────────────────────┐
│ AWS RDS Security Group       │
│ - Validates source IP/SG     │
└──────────┬───────────────────┘
           │
           ▼
    ┌──────────────────┐
    │ PostgreSQL       │
    │ Primary Instance │
    │ (Read/Write)     │
    └────────┬─────────┘
             │
    ┌────────▼─────────┐
    │ Synchronous      │
    │ Replication      │
    └────────┬─────────┘
             │
    ┌────────▼──────────┐
    │ PostgreSQL        │
    │ Standby Instance  │
    │ (Read-only)       │
    └───────────────────┘

Automated Failover (< 1 minute)
```

## 🚀 Provisionamento com Terraform

```bash
# 1. Inicializar Terraform
cd infra-database/terraform
terraform init

# 2. Configurar variáveis
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars

# 3. Planejar provisionamento
terraform plan -out=tfplan

# 4. Aplicar plano
terraform apply tfplan

# 5. Inicializar banco de dados
DB_ENDPOINT=$(terraform output -raw rds_endpoint_address)
psql -h $DB_ENDPOINT -U postgres -d postgres -f ../scripts/init-db.sql

# 6. Verificar conexão
psql -h $DB_ENDPOINT -U postgres -d tech_challenge \
  -c "SELECT version();"
```

## 🔐 Segurança

### Criptografia
- **Em repouso**: KMS encryption habilitado
- **Em trânsito**: SSL/TLS 1.2+ obrigatório
- **Conexões**: Via VPC endpoint privado

### Acesso
- **Security Group**: Apenas do cluster K8s
- **Senhas**: Armazenadas em AWS Secrets Manager
- **IAM**: Enhanced Monitoring role
- **VPC**: Database em subnets privadas

### Backup
- **Retenção**: 7 dias (configurável)
- **Tipo**: Automated + Point-in-time restore
- **Replicação**: Multi-AZ automatic

## 📈 Performance e Escalabilidade

### Storage
- **Tipo**: GP3 (General Purpose 3)
- **Inicial**: 100 GB
- **Máximo**: 500 GB (auto-scaling)
- **IOPS**: 3000 (provisioned)
- **Throughput**: 125 MB/s

### Compute
- **Instance**: db.t4g.medium
- **vCPU**: 1
- **Memory**: 2 GB
- **Escalável**: Manual ou via automation

### Índices
```sql
- idx_clientes_cpf
- idx_clientes_status
- idx_veiculos_cliente
- idx_ordens_status
- idx_ordens_data
- idx_orcamentos_ordem
```

## 🔧 Manutenção

### Backup Manual
```bash
aws rds create-db-snapshot \
  --db-instance-identifier tech-challenge-db \
  --db-snapshot-identifier backup-$(date +%s)
```

### Restore
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier tech-challenge-db-restored \
  --db-snapshot-identifier backup-xxxxx
```

### Performance Insights
- Monitora waitevents em tempo real
- Identifica gargalos de database
- Visível no CloudWatch

## 📚 Referências

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Terraform RDS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
