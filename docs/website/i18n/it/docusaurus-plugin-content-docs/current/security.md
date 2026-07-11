# Raccomandazioni di Sicurezza

## Sicurezza di rete

**Limita l'accesso SSH al tuo IP.** Ogni esempio espone una variabile `ssh_cidr`. Impostala al tuo IP pubblico:

```hcl
ssh_cidr = "203.0.113.42/32"   # solo il tuo IP
```

Il valore predefinito `0.0.0.0/0` è intenzionale per comodità nella fase iniziale. Modificalo prima di distribuire in produzione.

**Esponi solo le porte necessarie.** Il security group di ogni esempio apre solo le porte richieste dall'applicazione. Non aggiungere regole per porte che non stai usando.

**Limita l'accesso DBaaS all'IP della VM.** La regola MySQL nel security group negli esempi con database consente l'ingresso solo dall'Elastic IP della VM, non da Internet pubblico.

## Credenziali

**Usa password forti e univoche.** Ogni esempio verifica che le password soddisfino la lunghezza minima. Usa un gestore password per generare le credenziali.

**Ruota le credenziali periodicamente.** Aggiorna `db_password` e le password degli amministratori delle applicazioni secondo una pianificazione. Per la maggior parte degli esempi, un `terraform apply` con una nuova password aggiornerà l'utente DBaaS e attiverà una sostituzione della VM (nuovo `user_data` cloud-init) per aggiornare la configurazione dell'applicazione.

**Non committare `terraform.tfvars`.** È nel gitignore per impostazione predefinita in ogni esempio. Archivialo in un secrets manager o nelle variabili d'ambiente CI/CD.

## Hardening dell'applicazione

**Abilita HTTPS.** Tutti gli esempi che espongono un'interfaccia web includono il supporto opzionale per Certbot/Let's Encrypt. Imposta la variabile `domain` per abilitarlo. Non eseguire applicazioni di produzione su plain HTTP.

**Mantieni il software aggiornato.** cloud-init esegue `package_upgrade: true` al primo avvio. Configura unattended-upgrades per le patch continue:

```yaml
packages:
  - unattended-upgrades
runcmd:
  - dpkg-reconfigure -f noninteractive unattended-upgrades
```

**Consulta la sezione Sicurezza nel README di ogni esempio** per le raccomandazioni di hardening specifiche per l'applicazione.

## Credenziali del provider

Archivia le credenziali API come variabili d'ambiente invece che in `terraform.tfvars`:

```bash
export TF_VAR_arubacloud_client_id="il-tuo-client-id"
export TF_VAR_arubacloud_client_secret="il-tuo-client-secret"
```

Oppure usa un secrets store CI/CD (GitHub Actions secrets, variabili GitLab CI, ecc.).
