# Rubrica DPG

Una pagina per trovare link operativi e contatti del Dipartimento di Psicologia Generale, cercando anche con abbreviazioni, sinonimi e parole d’uso comune.

Sito: <https://enricotoffalini.github.io/rubricaDPG/> (GitHub Pages, cartella `docs/` del ramo `main`).

## Aggiornare la rubrica

Le voci si compilano nel Google Sheet [Rubrica DPG – Voci](https://docs.google.com/spreadsheets/d/18lKhyLEYYB2PoiSrWFU4NJZklvNQ81ohMt3GSircG1M/edit), commentabile da chiunque abbia il link, seguendo le [istruzioni per compilare](https://docs.google.com/document/d/1W3OzpDlt5tu8FO5wXc7gxUtPirfsj7i2jPFuALK3gJY/edit). I colleghi possono proporre voci anche con il [modulo](https://docs.google.com/forms/d/e/1FAIpQLSd8CiX7botJWyEVYDsOsdSb2o425Cn0JFfkF1aakLnLnmX8ww/viewform), le cui risposte finiscono nel foglio [Rubrica DPG – Proposte dal modulo](https://docs.google.com/spreadsheets/d/1-zzI3RBeIZosUxKT3D46IoUczpBqqrNO8m6EE2MLiq4/edit). Tutti i file stanno nella cartella Drive [Rubrica DPG](https://drive.google.com/drive/folders/1N7jQwipu2Dlrv_LFhM7S-lt1jxVirZRo). I campi, le fonti e i controlli per gli aggiornamenti sono descritti in [AGENTS.md](AGENTS.md).

```sh
quarto preview
render.bat
```

Il primo comando apre l’anteprima locale. Il secondo (su Windows; altrove `quarto render`) scarica il foglio, ne salva una copia in `dati/` e rigenera il sito statico in `docs/`, da includere nelle modifiche se cambia il sito. Se il foglio non è raggiungibile, il render usa la copia in `dati/` e `render.bat` lo segnala come errore. `render.bat` controlla anche che i file in `docs/` coincidano con i sorgenti e che CSS e JavaScript abbiano il parametro di versione contro la cache del browser. Per la compilazione basta Quarto. I link restano navigabili anche con JavaScript disattivato.

La vecchia wiki e il foglio Excel si possono recuperare dalla revisione `eadaf75` con `git show eadaf75:procedures/missioni-fuori-sede.qmd` o `git log -- foglioWIKI.xlsx`.

L’anteprima per i social (`logo/social-preview.png`) si rigenera da `logo/social-card.html` con Chrome headless; le visite sono contate da GoatCounter (`enricotoffalini.goatcounter.com`, percorso `/rubricaDPG/`).
