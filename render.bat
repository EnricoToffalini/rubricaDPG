@echo off
rem Rigenera il sito in docs/ e controlla che sia pronto per il deploy su GitHub Pages.
rem Uso: doppio clic, oppure "render.bat" dal terminale ("render.bat nopause" per non fermarsi alla fine).
setlocal
chcp 65001 >nul
cd /d "%~dp0"
set "LOG=%TEMP%\rubricaDPG-render.log"
set "ERRORI=0"

echo === quarto render
call quarto render > "%LOG%" 2>&1
set "ESITO=%ERRORLEVEL%"
type "%LOG%"
if not "%ESITO%"=="0" (
  echo.
  echo ERRORE: quarto render terminato con codice %ESITO%.
  set "ERRORI=1"
  goto fine
)

echo.
echo === Controlli
findstr /c:"ATTENZIONE" "%LOG%" >nul && (
  echo ERRORE: il Google Sheet non era raggiungibile, docs/ e' stato generato dalla copia in dati/.
  set "ERRORI=1"
)
for %%F in (styles.css ricerca.js logo\scarabocchio.svg logo\social-preview.png) do (
  fc /b "%%F" "docs\%%F" >nul 2>&1 || (
    echo ERRORE: docs\%%F manca o non coincide con %%F.
    set "ERRORI=1"
  )
)
for %%F in (styles.css ricerca.js) do (
  findstr /c:"%%F?v=" "docs\index.html" >nul || (
    echo ERRORE: in docs\index.html manca la versione ?v= per %%F, il browser potrebbe usare la copia in cache.
    set "ERRORI=1"
  )
)
findstr /c:"og:image" "docs\index.html" >nul || (
  echo ERRORE: in docs\index.html mancano i meta per l'anteprima social.
  set "ERRORI=1"
)
findstr /c:"class=\"voce\"" "docs\index.html" >nul || (
  echo ERRORE: docs\index.html non contiene voci.
  set "ERRORI=1"
)
if "%ERRORI%"=="0" echo OK: docs/ e' aggiornato e coerente con i sorgenti.

echo.
echo === File modificati da includere nel commit
git status --short -- docs dati index.qmd _quarto.yml rubrica.lua ricerca.js styles.css versioni.lua logo
git status --short --untracked-files=all -- docs | findstr /b "??" >nul && echo Nota: in docs/ ci sono file nuovi non ancora aggiunti a git.

:fine
echo.
if "%ERRORI%"=="0" (echo Pronto: fai commit e push di docs/ e dati/ per pubblicare.) else (echo NON pubblicare: correggi gli errori sopra e rilancia render.bat.)
if /i not "%~1"=="nopause" pause
exit /b %ERRORI%
