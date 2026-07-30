# Domande Frequenti

## Deployment

**D: Quanto tempo richiede il deployment?**

Tipicamente 8–15 minuti. La maggior parte del tempo è impiegata in: avvio della VM (1–2 min), provisioning DBaaS (3–5 min per MySQL), installazione dei pacchetti e bootstrap dell'applicazione via cloud-init (3–8 min).

**D: L'apply è completato ma l'applicazione non è ancora accessibile. Perché?**

Terraform termina quando la VM e tutte le risorse sono create. Il bootstrap cloud-init continua a girare all'interno della VM dopo che Terraform esce. Attendi 3–5 minuti e riprova. Puoi seguire i progressi tramite SSH nella VM ed eseguendo:

```bash
sudo tail -f /var/log/cloud-init-output.log
```

**D: Vedo "One or more validation errors" dal provider.**

Abilita il logging di debug per vedere l'errore API completo:

```bash
TF_LOG=DEBUG terraform apply 2>&1 | grep -A5 "error"
```

Cause comuni: il nome della risorsa esiste già da un'esecuzione precedente fallita, quota Elastic IP esaurita, o permessi di progetto mancanti.

**D: Come ottengo la password dell'applicazione dopo il deployment?**

Esegui `terraform output`. I valori sensibili sono oscurati nel terminale; recuperali con:

```bash
terraform output -raw admin_password
```

## Networking

**D: Posso usare un dominio personalizzato con HTTPS?**

Sì — imposta la variabile `domain` al tuo nome di dominio (es. `blog.esempio.com`) e punta un record A all'Elastic IP della VM prima di eseguire `terraform apply`. Certbot emetterà automaticamente un certificato Let's Encrypt durante cloud-init.

**D: MySQL dice "Error establishing a database connection".**

1. Il DBaaS potrebbe essere ancora in avvio quando cloud-init viene eseguito. Lo script di bootstrap attende fino a 15 minuti; se non è sufficiente, accedi via SSH e riesegui il passaggio fallito.
2. Verifica che la risorsa `arubacloud_databasegrant` sia stata creata correttamente — senza un grant, MySQL rifiuta l'utente anche con la password corretta.
3. Verifica che la regola di sicurezza del DBaaS consenta TCP 3306 dall'Elastic IP della VM.

## Costi

**D: Sarò addebitato se eseguo `terraform destroy`?**

Sarai addebitato per il tempo in cui le risorse erano in esecuzione. Dopo che `terraform destroy` è completato, tutte le risorse vengono eliminate e la fatturazione si interrompe.

**D: Gli Elastic IP vengono fatturati quando non sono collegati a una VM?**

Sì. `terraform destroy` rilascia sempre gli Elastic IP. Non rimuovere singole risorse dallo stato senza distruggerle.

## Personalizzazione

**D: Posso cambiare la dimensione della VM dopo il deployment?**

Aggiorna la variabile `vm_flavor` ed esegui `terraform apply`. Se questo richiede una sostituzione dipende dal comportamento di aggiornamento del provider per l'attributo flavor — controlla prima l'output del piano.

**D: Posso aggiungere altre VM che condividono lo stesso DBaaS?**

Sì — puoi aggiungere altre risorse `arubacloud_cloudserver` che si connettono allo stesso `arubacloud_dbaas`. Usa un load balancer (es. l'esempio Traefik) come front-end.
