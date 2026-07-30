# Best Practice

## Terraform

**Blocca la versione del provider** con un vincolo pessimistico:

```hcl
arubacloud = {
  source  = "arubacloud/arubacloud"
  version = "~> 0.5"
}
```

**Non archiviare mai segreti nello stato.** Marca tutte le variabili sensibili con `sensitive = true`. Usa un backend remoto (compatibile S3) per deployment condivisi o di produzione.

**Usa workspace o file di stato separati** per ogni ambiente:

```bash
terraform workspace new production
terraform workspace new staging
```

**Usa `terraform plan` prima di ogni apply.** Esamina il diff, specialmente per le risorse che richiedono sostituzione (contrassegnate con `# forces replacement`).

## cloud-init

**Separa la configurazione dai comandi.** Usa `write_files` per inserire i file di configurazione e `runcmd` per i comandi shell. È più leggibile e più facile da debuggare rispetto all'incorporare heredoc negli script shell.

**Aspetta le risorse asincrone.** Le istanze DBaaS gestite potrebbero non essere completamente pronte quando la VM si avvia per la prima volta. Usa sempre un controllo di disponibilità TCP prima di tentare una connessione al database:

```bash
until (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null; do sleep 10; done
```

**Registra tutti i progressi.** Aggiungi istruzioni `echo` e un `final_message` per poter seguire il bootstrap con `tail /var/log/cloud-init-output.log`.

**Testa cloud-init localmente** con `cloud-init devel schema --config-file cloud-init.yaml.tpl` (richiede il pacchetto cloud-init).

## Sicurezza

Consulta [Raccomandazioni di Sicurezza](security.md) per una guida dedicata.

## Gestione dei costi

- Imposta `billing_period = "Hour"` durante lo sviluppo; passa a `"Month"` per la produzione per ridurre il costo unitario.
- Esegui sempre `terraform destroy` al termine di un deployment di test — gli Elastic IP vengono fatturati anche quando inattivi.
- Dimensiona correttamente le VM: inizia con dimensioni piccole e scala verso l'alto. Puoi ridimensionare un CloudServer senza distruggerlo.

## Denominazione

Usa prefissi brevi ma univoci. I nomi visualizzati delle risorse ArubaCloud hanno limiti di lunghezza. Mantieni `name_prefix` sotto i 15 caratteri per evitare errori API quando combinato con suffissi di risorse come `-vm-eip`.
