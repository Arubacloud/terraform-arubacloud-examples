# Guida Rapida

## Prerequisiti

| Strumento | Versione minima | Installazione |
|-----------|-----------------|---------------|
| Terraform | 1.9 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/downloads) |
| ArubaCloud Provider | 0.5 | Installato automaticamente da `terraform init` |
| Git | qualsiasi | [git-scm.com](https://git-scm.com) |

Hai anche bisogno di:

- Un **account Aruba Cloud** con un progetto e credenziali API (OAuth2 client ID e secret)
- Una **coppia di chiavi SSH** — la chiave pubblica viene caricata su ArubaCloud; la chiave privata rimane sulla tua macchina
- Opzionale: un nome di dominio per HTTPS (Let's Encrypt/Certbot) — alcuni esempi supportano TLS automatico

## 1. Clona il repository

```bash
git clone https://github.com/arubacloud/terraform-arubacloud-examples.git
cd terraform-arubacloud-examples
```

## 2. Scegli un esempio

```bash
cd wordpress      # oppure: wireguard, nextcloud, minio, ...
```

## 3. Configura le variabili

```bash
cp terraform.tfvars.example terraform.tfvars
```

Apri `terraform.tfvars` nel tuo editor e compila almeno:

```hcl
arubacloud_client_id     = "il-tuo-oauth2-client-id"
arubacloud_client_secret = "il-tuo-oauth2-client-secret"
ssh_public_key           = "ssh-rsa AAAA..."
```

Tutte le altre variabili hanno valori predefiniti ragionevoli. Consulta il `README.md` dell'esempio per un riferimento completo alle variabili.

## 4. Esegui il deploy

```bash
terraform init
terraform plan   # esamina le modifiche prima di applicarle
terraform apply
```

Il provisioning richiede tipicamente **5–15 minuti** — la VM si avvia, cloud-init installa i pacchetti e l'applicazione parte.

## 5. Accedi all'applicazione

Dopo che `apply` è completato, Terraform mostra gli output:

```bash
terraform output
```

Gli output comuni includono `app_url`, `ssh_command` e `admin_password`.

## 6. Distruggi

```bash
terraform destroy
```

:::warning[Fatturazione Elastic IP]
Gli Elastic IP vengono fatturati anche quando non sono collegati a una VM. `terraform destroy` li rilascia.
Distruggi sempre i deployment non utilizzati per evitare addebiti imprevisti.
:::

## Sicurezza delle credenziali

- Non committare mai `terraform.tfvars` — è nel gitignore per impostazione predefinita
- Usa variabili `sensitive = true` (già impostate in tutti gli esempi) per tenere i segreti fuori dall'output del piano
- Per la produzione, memorizza le credenziali in un secrets manager e referenziale tramite variabili d'ambiente o Vault
