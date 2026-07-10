---
title: Modulo Network
---

# modules/network

Modulo Terraform condiviso usato da tutti gli esempi ArubaCloud. Crea il livello di rete fondamentale: VPC, subnet, security group per la VM con regole di ingresso configurabili, Elastic IP per la VM e (opzionalmente) security group ed Elastic IP per il DBaaS.

## Perché un modulo condiviso?

Ogni esempio necessita delle stesse 6–10 risorse di rete. Senza un modulo, quel codice verrebbe duplicato in ogni directory di esempio. Il modulo mantiene gli esempi concentrati sulla loro logica applicativa.

## Decisioni di design

- **Le regole di sicurezza specifiche per l'app NON sono in questo modulo.** Ad esempio, l'esempio WordPress crea la regola MySQL 3306 nel proprio `main.tf` per poter limitare il CIDR sorgente a `${module.network.vm_elastic_ip_address}/32`. Il modulo crea solo regole generiche egress-all e le regole di ingresso VM configurabili.
- **Il networking DBaaS è opzionale.** Imposta `create_dbaas_network = true` negli esempi che usano un database gestito. Il security group DBaaS viene creato senza regole di ingresso — il chiamante le aggiunge.
- **Una subnet per VPC.** Tutti gli esempi usano una singola subnet Basic. Le topologie multi-subnet esulano dall'ambito di questa raccolta.

## Utilizzo

```hcl
module "network" {
  source = "../modules/network"

  name_prefix  = "wp-prod"
  location     = var.location
  project_id   = arubacloud_project.this.id
  tags         = ["wordpress", "prod"]
  billing_period = "Hour"

  vm_ingress_ports = {
    ssh   = { port = "22",  cidr = var.ssh_cidr }
    http  = { port = "80",  cidr = "0.0.0.0/0" }
    https = { port = "443", cidr = "0.0.0.0/0" }
  }

  create_dbaas_network = true
}

# Regola di ingresso MySQL specifica per DBaaS (creata fuori dal modulo così
# il CIDR sorgente può referenziare module.network.vm_elastic_ip_address)
resource "arubacloud_securityrule" "dbaas_mysql" {
  name              = "wp-prod-db-mysql"
  location          = var.location
  project_id        = arubacloud_project.this.id
  vpc_id            = module.network.vpc_id
  security_group_id = module.network.dbaas_security_group_id

  properties = {
    direction = "Ingress"
    protocol  = "TCP"
    port      = "3306"
    target = {
      kind  = "Ip"
      value = "${module.network.vm_elastic_ip_address}/32"
    }
  }
}
```

## Requisiti

| Nome | Versione |
|------|---------|
| terraform | >= 1.9 |
| arubacloud/arubacloud | ~> 0.5 |

## Input

| Nome | Descrizione | Tipo | Default | Obbligatorio |
|------|-------------|------|---------|--------------|
| `name_prefix` | Prefisso breve per tutti i nomi delle risorse. 2–15 caratteri. | `string` | — | sì |
| `location` | Regione ArubaCloud (es. `ITBG-Bergamo`) | `string` | `"ITBG-Bergamo"` | no |
| `project_id` | ID progetto ArubaCloud | `string` | — | sì |
| `tags` | Tag da allegare a tutte le risorse | `list(string)` | `[]` | no |
| `billing_period` | Periodo di fatturazione Elastic IP (`Hour` o `Month`) | `string` | `"Hour"` | no |
| `vm_ingress_ports` | Mappa di regole di ingresso TCP per il security group VM | `map(object({port=string, cidr=string}))` | `{ssh, http, https}` | no |
| `create_dbaas_network` | Crea security group ed Elastic IP per il DBaaS | `bool` | `false` | no |

## Output

| Nome | Descrizione |
|------|-------------|
| `vpc_id` | ID VPC |
| `vpc_uri` | URI VPC (per `vpc_uri_ref`) |
| `subnet_id` | ID Subnet |
| `subnet_uri` | URI Subnet (per `subnet_uri_refs`) |
| `vm_security_group_id` | ID security group VM |
| `vm_security_group_uri` | URI security group VM (per `securitygroup_uri_refs`) |
| `vm_elastic_ip_address` | Indirizzo IP pubblico della VM |
| `vm_elastic_ip_uri` | URI Elastic IP VM (per `elastic_ip_uri_ref`) |
| `dbaas_security_group_id` | ID security group DBaaS (null se `create_dbaas_network=false`) |
| `dbaas_security_group_uri` | URI security group DBaaS (null se `create_dbaas_network=false`) |
| `dbaas_elastic_ip_address` | Indirizzo IP pubblico DBaaS (null se `create_dbaas_network=false`) |
| `dbaas_elastic_ip_uri` | URI Elastic IP DBaaS (null se `create_dbaas_network=false`) |
