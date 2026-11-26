# Aggiornare la Rubrica DPG

## Obiettivo

La rubrica serve a chi lavora nel Dipartimento di Psicologia Generale dell’Università di Padova. È un’iniziativa personale di Enrico Toffalini, non un servizio ufficiale del DPG o dell’Ateneo: il sito deve dirlo chiaramente (testata e avvertenza in fondo a `index.qmd`) e non deve usare loghi, sigilli o altri segni istituzionali. Il logo e la favicon sono lo scarabocchio personale di Enrico, in `logo/scarabocchio.svg` (vettoriale, con esportazioni PNG e ICO nella stessa cartella). Ogni voce risponde a un’esigenza concreta con il percorso più breve verso un modulo, un applicativo o un contatto. Scrivi in italiano. Parti dall’azione da compiere e dai termini che una persona userebbe per cercarla.

Il pubblico va dai dottorandi in su (assegnisti, ricercatori, docenti): una scheda che interessa soprattutto agli studenti va tolta o riscritta dicendo perché serve a chi lavora nel Dipartimento. Prediligi, mantieni e aumenta i link interni e profondi (applicativi dietro SSO, area riservata, portale richieste, moduli), cioè quelli che anche partendo da Google richiederebbero più di un paio di clic ovvi. Elimina le schede che una ricerca Google con le stesse parole chiave trova altrettanto bene, per esempio «carta servizi dpg».

Quando più fonti sembrano rispondere alla stessa esigenza ma mostrano cose diverse, la scheda deve disambiguare: dire che cosa contiene ciascuna fonte, che cosa manca e in quale fase della procedura compare un dato. Per esempio, l’elenco dei laureandi assegnati in Uniweb può non comprendere chi è stato approvato dal relatore ma non ha ancora un titolo. Ricostruisci la differenza confrontando le fonti con casi concreti e riporta nella scheda solo la regola generale, senza riferimenti a persone.

## Dove intervenire

- **Cartella Drive «Rubrica DPG»** (<https://drive.google.com/drive/folders/1N7jQwipu2Dlrv_LFhM7S-lt1jxVirZRo>), visibile a chiunque abbia il link. Contiene quattro file distinti:
  - **«Rubrica DPG – Voci»** (<https://docs.google.com/spreadsheets/d/18lKhyLEYYB2PoiSrWFU4NJZklvNQ81ohMt3GSircG1M/edit>), la fonte del sito, commentabile da chiunque abbia il link e modificabile da Enrico. Il foglio `voci` ha una riga per voce; `categorie` elenca le categorie nell’ordine del menu (nel sito le voci sono raggruppate per categoria in quest’ordine, poi per riga) e alimenta il menu a tendina della colonna `categoria`. Il sito legge solo `voci` (gid 0) e `categorie` (gid 1): non cambiare questi due gid né l’ID del file.
  - **«Rubrica DPG – Istruzioni per compilare»** (<https://docs.google.com/document/d/1W3OzpDlt5tu8FO5wXc7gxUtPirfsj7i2jPFuALK3gJY/edit>), Google Doc con la guida ai campi per chi compila. Tienilo allineato a questa sezione quando cambiano le regole.
  - **«Rubrica DPG – Modulo proposte»**, il Google Form descritto più sotto.
  - **«Rubrica DPG – Proposte dal modulo»** (<https://docs.google.com/spreadsheets/d/1-zzI3RBeIZosUxKT3D46IoUczpBqqrNO8m6EE2MLiq4/edit>), dove il modulo scrive le risposte. Il sito non lo legge. Cerca lì una voce affine prima di crearne una. Modifica la voce esistente se l’intento è lo stesso e conserva il suo ID, che è anche l’ancora del link. Per scrivere sul foglio usa il connettore Google Sheets. Le date vanno scritte come testo con l’apostrofo iniziale (`'2026-11-25`).
- **`dati/voci.csv`** e **`dati/categorie.csv`** sono la copia del foglio scaricata all’ultimo render. Non modificarli a mano: `rubrica.lua` li riscrive a ogni `quarto render` e li usa solo se il foglio non è raggiungibile (in quel caso stampa «ATTENZIONE»). Servono anche a vedere nel diff cosa è cambiato.
- **`index.qmd`**, **`rubrica.lua`**, **`ricerca.js`** e **`styles.css`** definiscono la pagina, il download e la generazione delle voci, la ricerca e l’aspetto. Per aggiornare i contenuti basta il foglio.
- **`docs/`** ospita il sito generato da Quarto. Aggiornalo con `render.bat` (o `quarto render`) dalla radice della repo: `render.bat` controlla anche che `docs/` sia pronto per il deploy. `versioni.lua`, eseguito dopo ogni render, aggiunge a `styles.css` e `ricerca.js` un parametro `?v=` che cambia col contenuto, così i browser non tengono in cache la versione vecchia.
- **Anteprima social e statistiche.** I meta Open Graph/Twitter e lo script GoatCounter (account `enricotoffalini.goatcounter.com`, dove le visite compaiono con il percorso `/rubricaDPG/`) sono in `include-in-header` di `_quarto.yml`. L’immagine `logo/social-preview.png` (1200×630) si genera da `logo/social-card.html` con Chrome headless (comando in fondo al file): rigenerala se cambiano titolo, categorie o aspetto della testata.
- Il vecchio `foglioWIKI.xlsx` e le pagine di `procedures/` sono nella revisione `eadaf75`; il vecchio Google Sheet «foglioWIKI» (<https://docs.google.com/spreadsheets/d/12qy-fnp6ZtXgQDtF1kgHFdlyJtsWK1e4OO5my9U9JrM/>) è di una collega e non alimenta più il sito. Puoi usarli per orientarti e poi verificare i riferimenti.

I colleghi possono proporre aggiunte e correzioni in tre modi, tutti indicati in fondo a `index.qmd`:

- il **Google Form «Rubrica DPG – Modulo proposte»** (<https://docs.google.com/forms/d/e/1FAIpQLSd8CiX7botJWyEVYDsOsdSb2o425Cn0JFfkF1aakLnLnmX8ww/viewform>, modifica: <https://docs.google.com/forms/d/1Vi-Eb1-Kpvji0BlzrtpZFR99Fp9wPylfOaHhu69QGgU/edit>), nella stessa cartella Drive; non raccoglie indirizzi email e scrive ogni proposta come riga del file «Rubrica DPG – Proposte dal modulo»;
- i **commenti** sul Google Sheet;
- una mail a Enrico con oggetto «Rubrica DPG – Segnalazione».

Per comunicazioni rapide con l’agent Enrico preferisce file `.txt` nella radice della repo, da compilare e restituire, per esempio un elenco di link da aggiungere o domande a cui rispondere. Quando ti serve un’informazione strutturata da Enrico, prepara tu un file del genere con le domande e i campi da riempire. Quando un file è stato elaborato, segnalalo nel resoconto. Non pubblicarlo nel sito e non includerlo nei commit senza una richiesta esplicita.

Le proposte non compaiono nel sito da sole. Se l’utente chiede di elaborare le segnalazioni, leggi le nuove righe di «Rubrica DPG – Proposte dal modulo», i commenti su «Rubrica DPG – Voci» (`get_spreadsheet` con `commentsIncluded`) e le mail con quell’oggetto, verifica ogni proposta seguendo i passaggi sotto e solo allora aggiorna `voci`. La cartella è visibile a chiunque abbia il link, quindi anche le proposte lo sono: se una proposta contiene dati personali, segnalalo all’utente.

## Come scrivere una voce

Ogni campo corrisponde a una colonna del foglio `voci`. Nelle celle con più valori (`parole_chiave`, `fonti`) separa i valori con il punto e virgola; per `fonti` va bene anche andare a capo. Le azioni occupano le colonne `azione1_etichetta`, `azione1_url`, `azione1_tipo` e così via fino a `azione4_…`; se ne servono di più, aggiungi colonne con lo stesso schema.

| Campo | Contenuto |
| --- | --- |
| `id` | Identificatore unico e stabile in minuscolo con trattini, per esempio `rimborso-missione`. |
| `titolo` | Azione o esigenza riconoscibile a colpo d’occhio, per esempio «Rimborso missione». |
| `categoria` | Una di quelle elencate in `categorie`. Aggiungine una solo se aiuta a orientarsi fra più voci. |
| `parole_chiave` | Lista di sinonimi, sigle, verbi, nomi di portali e formule d’uso comune. Parti da due o tre ricerche plausibili. Una sola forma per parola: le varianti di genere e numero sono coperte dal troncamento, le famiglie di parole dall’asterisco (vedi sotto). |
| `azioni` | Uno o più collegamenti in ordine di utilità, ciascuno con etichetta e URL. Usa il link HTTPS esatto oppure l’indirizzo email così com’è, mai `mailto:`: nel sito compare come testo con un pulsante per copiarlo. Per guide e istruzioni scrivi `istruzioni` nella colonna del tipo. |
| `nota` | Facoltativa. Di solito una frase se serve a trovare la voce di menu, capire quando usare il link o scegliere il contatto giusto. Quando servono più specifiche può essere lunga e accetta Markdown semplice: `**grassetto**`, elenchi con `- `, titoletti con `### `, link `[testo](https://…)`, a capo (Alt+Invio nella cella) e righe vuote fra paragrafi. L’anteprima mostra fino a tre righe ed evidenzia le etichette racchiuse tra backtick. Se la nota è tagliata o contiene altra formattazione o link, un clic sulla scheda (o su «Leggi tutto») apre la scheda estesa con la nota completa, le azioni, le fonti e la data di verifica. La scheda estesa ha un link diretto `#scheda-<id>`. Valgono le stesse regole delle azioni: niente nomi di persone o ruoli, email come testo e mai `mailto:`. |
| `fonti` | Lista degli URL istituzionali o descrizioni sintetiche delle fonti consultate. Per un PDF puoi indicare la pagina. Usa riferimenti che si possono conservare nella repo. |
| `verificata_il` | Data `AAAA-MM-GG` in cui hai verificato destinazioni e contatti o li hai riscontrati nelle fonti. Segnala gli eventuali passaggi dopo il login ancora da controllare. |

Nelle note, racchiudi tra backtick il testo esatto di menu, voci, schede, campi e pulsanti. Il sito aggiunge le virgolette caporali e mostra l’etichetta in carattere monospaziato. Per un percorso, separa i passaggi con ` > `, come in `` `Documenti e richieste` > `Richiesta emanazione bando per borsa di ricerca` ``.

Unisci le varianti che portano allo stesso percorso. Tieni separate le azioni con esiti distinti, come autorizzazione preventiva e rimborso di missione. Usa etichette brevi come «Portale richieste», «Ticket HelpMe» o «Istruzioni». Per le email lascia l’etichetta vuota oppure indica solo la struttura (DPG, Scuola, Polo, Ateneo), mai nomi di persone o ruoli; anche le note non nominano persone o ruoli. Riporta solo indirizzi che compaiono in una pagina o in un documento pubblico, raggiungibile senza login, e cita quella fonte in `fonti`. Le icone vengono aggiunte durante la compilazione (freccia per i link, busta per le email, foglio per le istruzioni). Se serve l’accesso UniPD, chiudi l’etichetta con « · SSO»: diventa un piccolo badge. Collega un punto d’ingresso stabile e scrivi il nome esatto del menu se il link profondo dipende dalla sessione.

Nel sito il colore pieno indica le azioni che aprono il servizio dove si svolge la procedura o si consulta il dato cercato, anche dopo SSO. Email, guide, modulistica da inviare a parte, pagine informative e Ticket HelpMe hanno uno stile più discreto. Quando aggiungi o cambi una destinazione diretta, aggiorna l’elenco in `rubrica.lua`.

Una scheda ha al massimo due link principali (a colore pieno). Se un servizio offre funzioni diverse, come comunicare le disponibilità, consultare i calendari e inserire le valutazioni, crea una scheda per ciascuna. Più di due link principali sono ammessi solo in casi eccezionali, quando hanno la stessa funzione e differiscono per un solo aspetto, come i moduli di accesso ai laboratori per ricerca, tirocinio o didattica.

La ricerca usa titoli, parole chiave, promemoria, etichette, categoria e indirizzi email. Accetta parole in qualsiasi ordine, normalizza gli accenti e gestisce i prefissi digitati (`laur` trova «laureandi»). Tutte le parole significative della query devono trovare corrispondenza. Per evitare elenchi di varianti:

- **Troncamento automatico.** Query e parole chiave perdono la vocale finale (e la `i` di `-io`/`-ia`, la `h` di `-che`/`-ghi`) prima del confronto. Basta quindi una forma: `laureando` copre laureandi, laureanda e laureande; `laboratorio` copre laboratori; `ricevuta` copre ricevute.
- **Asterisco finale** per famiglie di parole con desinenze diverse: `prenot*` copre prenotare, prenotazione e prenotazioni; `relat*` relatore e relatrice; `richie*` richiesta, richieste e richiedere. Scegli una radice di almeno quattro lettere e abbastanza specifica da non pescare parole estranee.

Inserisci invece sinonimi veri, come «tesisti» e «studenti assegnati» accanto a `laureand*`. Evita parole generiche in tutte le voci, perché rendono i risultati meno selettivi.

## Come raccogliere e verificare le informazioni

1. Parti dalle esigenze richieste e dai sinonimi già in rubrica. Controlla che eventuali voci concorrenti rispondano davvero a esigenze diverse.
2. Cerca il riferimento ufficiale più specifico. Parti dalle pagine del DPG, dalla Carta dei servizi, dalla Scuola di Psicologia o dai portali UniPD. Confronta le fonti in caso di discrepanza. Per un referente nominativo verifica anche che il ruolo sia quello pertinente.
3. Se serve la posta e l’utente ha chiesto o autorizzato di consultarla, cerca per oggetto, ufficio, periodo e termini della procedura. Usa i messaggi per ricostruire il percorso e capire a chi ci si rivolgeva. Una risposta su un caso passato è una pista da verificare, soprattutto per nominativi, scadenze e allegati. Per le aree riservate usa la sessione autorizzata e verifica in sola lettura il punto d’ingresso, la voce di menu e le eventuali restrizioni di ruolo. Per informazioni fornite nel prompt, registra «Indicazione di Enrico, AAAA-MM-GG» e verifica ciò che si può riscontrare.
4. Tratta repo e sito come pubblicabili. Riporta solo indirizzi istituzionali pertinenti e pubblici o esplicitamente autorizzati per questo uso. Tieni fuori dai file sorgente, dalle parole chiave e dall’HTML i contenuti di email e allegati privati, i riferimenti a studenti o pratiche individuali e i link con token, identificativi di sessione o dati personali. Per una fonte non pubblica basta una descrizione neutra come «Area riservata DPG, voce Prenotazioni». La consultazione di una fonte è un’attività in sola lettura. Invii di mail e presentazione di domande richiedono una richiesta esplicita.
5. Prova il collegamento fino alla destinazione consentita. Se puoi vedere solo la pagina pubblica o il login, usa la pagina ufficiale che rimanda al servizio e registra il punto ancora da verificare. Un recapito di assistenza documentato è utile anche quando manca il link al modulo. Lascia fuori dal sito destinazioni o recapiti ipotetici e segnala il vuoto nel resoconto.

## Controlli prima di chiudere

- Esegui `render.bat` (o `quarto render`) e controlla nel diff di `dati/` e `docs/` che le modifiche al foglio siano arrivate e che non compaia «ATTENZIONE» nell’output. Per modifiche al comportamento della pagina, usa anche `quarto preview`.
- Cerca ogni voce toccata con formule naturali e sinonimi. Per esempio «quali sono i miei laureandi», «posti liberi per la tesi», «parere etico», «rimborsi missioni» o «spostare una prenotazione». Verifica che le destinazioni siano già cliccabili nei risultati e che il filtro per categoria funzioni.
- Nel resoconto indica le voci aggiornate, i riferimenti verificati e gli eventuali passaggi rimasti aperti. Per ora resta da confermare il percorso per spostare le prenotazioni delle sale riunioni (le proprie prenotazioni sono in MyGeBeS). Per i rimborsi diversi dalle missioni la Carta dei servizi indica il fondo economale (piccole spese in contanti); altri casi restano da verificare.
