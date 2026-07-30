# Contribuire

I contributi a terraform-arubacloud-examples sono benvenuti. Questo documento spiega come aggiungere un nuovo esempio, correggerne uno esistente o migliorare la documentazione.

## Prima di iniziare

- Apri una issue per discutere l'esempio che vuoi aggiungere (a meno che non sia già nella roadmap).
- Verifica che l'applicazione non sia già in lavorazione da parte di qualcun altro.

## Aggiungere un nuovo esempio

### 1. Crea la directory

```bash
mkdir myapp
```

### 2. Crea i file richiesti

Ogni esempio deve contenere esattamente questi file:

```text
myapp/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── cloud-init.yaml.tpl
├── terraform.tfvars.example
├── .gitignore
└── LICENSE
```

Copia `wordpress/` come template e adattalo.

### 3. Usa il modulo di rete condiviso

```hcl
module "network" {
  source = "../modules/network"
  # ...
}
```

Non duplicare il codice VPC / subnet / security group / Elastic IP inline.

### 4. Scrivi un README completo

Segui il README di WordPress come template. Ogni README deve includere:

- Diagramma Mermaid dell'architettura
- Infrastruttura creata (elenco puntato)
- Raccomandazione sulla dimensione della VM
- Costo mensile stimato
- Tutte le variabili (obbligatorie e opzionali)
- Istruzioni per il deployment e la distruzione
- Raccomandazioni sulla sicurezza
- Sezione di risoluzione dei problemi

### 5. Aggiungi una pagina di documentazione

Crea `docs/examples/myapp.md`:

```markdown
---
title: My App
---

{%
  include-markdown "../../myapp/README.md"
%}
```

Aggiungila alla categoria appropriata in `docs/website/sidebars.js`.

### 6. Aggiungi alla matrice CI

Aggiungi l'esempio alla lista `matrix.example` in `.github/workflows/terraform.yml`.

## Stile del codice

- Esegui `terraform fmt -recursive` prima di fare il commit.
- Mantieni i nomi delle risorse brevi (prefisso ≤ 15 caratteri) per evitare errori di lunghezza nome ArubaCloud.
- Marca tutti i segreti come `sensitive = true`.
- Aggiungi blocchi `validation {}` per le variabili che hanno vincoli significativi.
- Non hardcodare location, zone o nomi di flavor — usa sempre variabili con valori predefiniti documentati.

## Checklist pull request

- [ ] `terraform fmt -check -recursive` passa
- [ ] `terraform validate` passa per il nuovo esempio
- [ ] Il README segue la struttura del template
- [ ] `docs/examples/myapp.md` creato e aggiunto a `docs/website/sidebars.js`
- [ ] Esempio aggiunto alla matrice CI
- [ ] `terraform.tfvars.example` contiene tutte le variabili richieste con valori segnaposto

## Eseguire la documentazione localmente

```bash
cd docs/website
npm install
npm run start
# Apri http://localhost:3000
```
