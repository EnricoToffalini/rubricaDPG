-- Le voci si compilano nel Google Sheet «Rubrica DPG – Voci» (vedi AGENTS.md).
-- A ogni render il filtro scarica i fogli «voci» e «categorie» in CSV,
-- ne salva una copia in dati/ e, se il download non riesce, usa quella copia.
local SHEET = "https://docs.google.com/spreadsheets/d/18lKhyLEYYB2PoiSrWFU4NJZklvNQ81ohMt3GSircG1M/export?format=csv&gid="
local TABS = {voci = "0", categorie = "1"}
local HEADERS = {voci = "id,titolo,categoria,", categorie = "categoria"}

local function escape(value)
  return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    :gsub('"', "&quot;"):gsub("'", "&#39;"))
end

local function trim(value)
  -- solo spazi ASCII: %s può togliere byte delle lettere accentate in UTF-8
  return (value:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

local function read_file(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local text = file:read("*a")
  file:close()
  return text
end

-- Scarica un foglio e aggiorna la copia locale; in caso di errore usa la copia
local function load_tab(name)
  local path = quarto.project.directory .. "/dati/" .. name .. ".csv"
  local ok, _, contents = pcall(pandoc.mediabag.fetch, SHEET .. TABS[name])
  if ok and contents and contents:sub(1, #HEADERS[name]) == HEADERS[name] then
    contents = contents:gsub("\r\n", "\n")
    if contents ~= read_file(path) then
      local file = assert(io.open(path, "wb"))
      file:write(contents)
      file:close()
    end
    return contents
  end
  io.stderr:write("ATTENZIONE: Google Sheet non raggiungibile, uso la copia locale dati/" .. name .. ".csv\n")
  return assert(read_file(path), "Manca dati/" .. name .. ".csv")
end

-- CSV con campi tra virgolette, virgolette raddoppiate e a capo nei campi
local function parse_csv(text)
  local rows, row, field, i, quoted = {}, {}, {}, 1, false
  while i <= #text do
    local c = text:sub(i, i)
    if quoted then
      if c == '"' and text:sub(i + 1, i + 1) == '"' then field[#field + 1] = '"'; i = i + 1
      elseif c == '"' then quoted = false
      else field[#field + 1] = c end
    elseif c == '"' then quoted = true
    elseif c == "," then row[#row + 1] = table.concat(field); field = {}
    elseif c == "\n" then
      row[#row + 1] = table.concat(field); field = {}
      rows[#rows + 1] = row; row = {}
    else field[#field + 1] = c end
    i = i + 1
  end
  if #field > 0 or #row > 0 then row[#row + 1] = table.concat(field); rows[#rows + 1] = row end

  local header, records = rows[1], {}
  for r = 2, #rows do
    local record, filled = {}, false
    for k, name in ipairs(header) do
      record[name] = trim(rows[r][k] or "")
      filled = filled or record[name] ~= ""
    end
    if filled then records[#records + 1] = record end
  end
  return records
end

local function split(value, pattern)
  local items = {}
  for item in value:gmatch(pattern) do
    item = trim(item)
    if item ~= "" then items[#items + 1] = item end
  end
  return items
end

local function load_data()
  local data = {categorie = {}, voci = {}}
  for _, row in ipairs(parse_csv(load_tab("categorie"))) do
    if row.categoria ~= "" then data.categorie[#data.categorie + 1] = row.categoria end
  end
  for _, row in ipairs(parse_csv(load_tab("voci"))) do
    local entry = {
      id = row.id, titolo = row.titolo, categoria = row.categoria,
      parole_chiave = split(row.parole_chiave, "[^;]+"),
      fonti = split(row.fonti, "[^;\n]+"),
      nota = row.nota ~= "" and row.nota or nil,
      verificata_il = row.verificata_il:gsub("^'", ""),
      azioni = {}
    }
    for n = 1, 9 do
      local label, url = row["azione" .. n .. "_etichetta"], row["azione" .. n .. "_url"]
      if label == nil then break end
      if label ~= "" or url ~= "" then
        local tipo = row["azione" .. n .. "_tipo"]
        entry.azioni[#entry.azioni + 1] = {etichetta = label, url = url, tipo = tipo ~= "" and tipo or nil}
      end
    end
    data.voci[#data.voci + 1] = entry
  end
  return data
end

local ICONS = {
  link = '<path d="M7 17 17 7"/><path d="M8 7h9v9"/>',
  mail = '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3.5 7.5 8.5 6 8.5-6"/>',
  doc = '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h4"/>'
}

local function icon(name)
  return '<svg class="icona" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    .. 'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' .. ICONS[name] .. '</svg>'
end

-- La nota accetta Markdown semplice: **grassetto**, elenchi, [testo](https://...), a capo e righe vuote.
-- Restituisce l'HTML completo (scheda estesa), il testo semplice (anteprima) e se c'è formattazione da mostrare.
local function note(text, id)
  local doc = pandoc.read(text, "commonmark+hard_line_breaks-raw_html")
  local rich = #doc.blocks > 1 or doc.blocks[1].t ~= "Para"
  local function mark(el) rich = true; return el end
  doc = doc:walk({
    Header = function(header) header.level = 3; rich = true; return header end,
    Strong = mark, Emph = mark, Code = mark, LineBreak = mark,
    Link = function(link)
      rich = true
      -- le email restano testo, mai link mailto:
      if link.target:match("^mailto:") then return link.content end
      assert(link.target:match("^https://[^%s]+$"), "Link non valido nella nota: " .. id)
      link.attributes.target = "_blank"
      link.attributes.rel = "noopener"
      return link
    end
  })
  local plain = {}
  for _, block in ipairs(doc.blocks) do plain[#plain + 1] = pandoc.utils.stringify(block) end
  return pandoc.write(doc, "html"), table.concat(plain, " "), rich
end

local data

local function get_data()
  if data then return data end
  data = load_data()
  local categories, colors, ids = {}, {}, {}
  for n, category in ipairs(data.categorie) do
    assert(not categories[category], "Categoria duplicata: " .. category)
    categories[category] = n
    colors[category] = (n - 1) % 6 + 1
  end
  data.colore = colors
  for _, entry in ipairs(data.voci) do
    local id = entry.id
    assert(id:match("^[a-z0-9][a-z0-9-]*$") and not ids[id], "ID non valido o duplicato: " .. id)
    ids[id] = true
    assert(categories[entry.categoria], "Categoria sconosciuta: " .. id)
    assert(entry.titolo:match("%S") and #entry.parole_chiave > 0 and #entry.azioni > 0
      and #entry.fonti > 0 and entry.verificata_il:match("^%d%d%d%d%-%d%d%-%d%d$"),
      "Compila titolo, parole chiave, azioni, fonti e data di verifica: " .. id)
    if not data.aggiornata or entry.verificata_il > data.aggiornata then data.aggiornata = entry.verificata_il end
  end
  -- voci raggruppate per categoria (ordine del foglio «categorie»), poi ordine delle righe
  for n, entry in ipairs(data.voci) do entry.riga = n end
  table.sort(data.voci, function(a, b)
    if a.categoria ~= b.categoria then return categories[a.categoria] < categories[b.categoria] end
    return a.riga < b.riga
  end)
  return data
end

-- Barra di ricerca e filtri per categoria (visibili solo con JavaScript)
local function search_box()
  local d = get_data()
  local html = {
    '<div id="ricerca" class="ricerca" role="search" hidden>',
    '<label for="cerca" class="visually-hidden">Cosa cerchi?</label>',
    '<div class="campo">',
    '<svg class="lente" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
    '<input id="cerca" type="search" placeholder="Cosa cerchi? Es. posti tesi, rimborso, laboratorio" autocomplete="off" spellcheck="false">',
    '<kbd aria-hidden="true">/</kbd>',
    '</div>',
    '<div class="filtri" role="group" aria-label="Categoria">',
    '<button type="button" class="filtro" data-categoria="" aria-pressed="true">Tutte</button>'
  }
  for _, category in ipairs(d.categorie) do
    html[#html + 1] = string.format(
      '<button type="button" class="filtro" data-categoria="%s" aria-pressed="false" style="--cat: var(--cat-%d)">%s</button>',
      escape(category), d.colore[category], escape(category))
  end
  html[#html + 1] = '</div>'
  html[#html + 1] = '<p id="risultati" role="status"></p>'
  html[#html + 1] = '</div>'
  return table.concat(html, "\n")
end

-- Destinazioni dove si può svolgere la procedura o consultare direttamente il dato cercato.
local DESTINAZIONI_DIRETTE = {
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:129:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:1083,16418"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:129:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:1083,17121"] = true,
  ["https://uniweb.unipd.it/auth/docente/Graduation/LaureandiAssegnati.do"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:170:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:1083,17130"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:170:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:1083,17133"] = true,
  ["https://unipd.u-web.cineca.it/appts/registro/"] = true,
  ["https://comitati-etici-unipd.scientificnetwork.org/"] = true,
  ["https://unipd.u-web.cineca.it/appts/timesheet/"] = true,
  ["https://richieste.dpg.psy.unipd.it/"] = true,
  ["https://unipd-psy.sona-systems.com/"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:104:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513,3367"] = true,
  ["https://www.unipd.it/richieste/"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=376:4"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:104:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513,3382"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:104:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513,3347"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:104:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513,3359"] = true,
  ["https://apex.cca.unipd.it/pls/apex/f?p=1300:104:::::F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513,3408"] = true,
  ["https://print.dpg.psy.unipd.it/"] = true,
  ["https://unipd.u-web.cineca.it/appced/lista-documenti"] = true,
  ["https://unipd.webfirma.cineca.it/my-web-firma/index#/processes/"] = true
}
local AREA_RISERVATA = "https://apex.cca.unipd.it/pls/apex/f?p=1300:100:::NO:100:F1300_FSVM_COD_ID,F1300_FSVM_COD_ID_SEQUENCE:513"

local function actions(entry)
  local links = {}
  for _, action in ipairs(entry.azioni) do
    local url = action.url
    -- le email sono testo da copiare, mai link mailto:
    local email = url:gsub("^mailto:", ""):match("^[%w._+%-]+@[%w.%-]+%.%a+$")
    assert(email or url:match("^https://[^%s]+$"), "Destinazione non valida: " .. entry.id)
    assert(email or action.etichetta:match("%S"), "Etichetta mancante: " .. entry.id)
    assert(not action.tipo or action.tipo == "istruzioni", "Tipo di azione sconosciuto: " .. entry.id)

    if email then
      local struttura = action.etichetta:match("%S") and
        '<span class="struttura">' .. escape(action.etichetta) .. '</span>' or ""
      links[#links + 1] = string.format(
        '<span class="azione azione-mail">%s%s<span class="indirizzo">%s</span>'
        .. '<button type="button" class="copia" data-copia="%s" aria-label="Copia %s" hidden>'
        .. '<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
        .. '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 0 1 2-2h9"/></svg></button></span>',
        icon("mail"), struttura, escape(email):gsub("@", "<wbr>@"), escape(email), escape(email))
    else
      local label, sso = action.etichetta:gsub("%s*·%s*SSO$", "")
      local kind = action.tipo == "istruzioni" and "doc" or "link"
      local diretta = kind == "link" and (DESTINAZIONI_DIRETTE[url]
        or (entry.id == "area-riservata" and url == AREA_RISERVATA))
      links[#links + 1] = string.format(
        '<a href="%s" target="_blank" rel="noopener" class="azione azione-%s%s">%s<span>%s</span>%s</a>',
        escape(url), kind, diretta and " azione-diretta" or "", icon(kind), escape(label),
        sso > 0 and ' <abbr class="sso" title="Accesso con credenziali UniPD (Single Sign-On)">SSO</abbr>' or "")
    end
  end
  return '<p class="azioni">' .. table.concat(links, "\n") .. '</p>'
end

-- Scheda estesa (finestra modale) con la nota completa, le azioni e le fonti
local function dialog(entry, full)
  local id = "scheda-" .. entry.id
  local sources = {}
  for _, source in ipairs(entry.fonti) do
    local url, rest = source:match("^(https://%S+)(.*)$")
    sources[#sources + 1] = '<li>' .. (url and string.format('<a href="%s" target="_blank" rel="noopener">%s</a>%s',
      escape(url), escape(url), escape(rest)) or escape(source)) .. '</li>'
  end
  return table.concat({
    string.format('<dialog class="scheda" id="%s" aria-labelledby="%s-t">', id, id),
    '<div class="scheda-testa"><p class="voce-categoria">' .. escape(entry.categoria) .. '</p>',
    '<button type="button" class="scheda-chiudi" aria-label="Chiudi">&times;</button></div>',
    '<div class="scheda-corpo">',
    string.format('<h2 class="scheda-titolo" id="%s-t">%s</h2>', id, escape(entry.titolo)),
    '<div class="scheda-nota">' .. full .. '</div>',
    actions(entry),
    string.format('<div class="scheda-fonti"><p>Fonti · verificata il %s</p><ul>%s</ul></div>',
      entry.verificata_il:gsub("(%d+)%-(%d+)%-(%d+)", "%3/%2/%1"), table.concat(sources)),
    '</div>',
    '</dialog>'
  }, "\n")
end

local function entries()
  local d = get_data()
  local html = {
    '<div id="rubrica">',
    '<div id="nessun-risultato" hidden><p class="vuoto-titolo">Nessuna voce trovata</p>',
    '<p>Prova un sinonimo, una parola più corta o scegli «Tutte». Oppure prova con ',
    '<button type="button" data-prova="rimborso">rimborso</button>, ',
    '<button type="button" data-prova="laureandi">laureandi</button>, ',
    '<button type="button" data-prova="prenotare laboratorio">prenotare laboratorio</button>.</p></div>',
    '<div id="voci">'
  }

  for _, entry in ipairs(d.voci) do
    local full, plain, rich
    if entry.nota then full, plain, rich = note(entry.nota, entry.id) end
    html[#html + 1] = string.format(
      '<article class="voce" id="%s" data-categoria="%s" data-parole-chiave="%s"%s style="--cat: var(--cat-%d)">',
      entry.id, escape(entry.categoria), escape(table.concat(entry.parole_chiave, " ")),
      rich and " data-ricca" or "", d.colore[entry.categoria])
    html[#html + 1] = '<p class="voce-categoria">' .. escape(entry.categoria) .. '</p>'
    html[#html + 1] = '<h2>' .. escape(entry.titolo) .. '</h2>'
    if entry.nota then
      -- anteprima di poche righe; se è tagliata o formattata, la scheda estesa si apre con un clic
      html[#html + 1] = '<p class="promemoria">' .. escape(plain) .. '</p>'
      html[#html + 1] = string.format('<button type="button" class="apri-scheda" data-scheda="scheda-%s" '
        .. 'aria-haspopup="dialog" hidden>Leggi tutto</button>', entry.id)
    end
    html[#html + 1] = actions(entry)
    if entry.nota then html[#html + 1] = dialog(entry, full) end
    html[#html + 1] = '</article>'
  end
  html[#html + 1] = '</div>'
  html[#html + 1] = string.format('<p class="aggiornata">%d voci · ultima verifica %s</p>',
    #d.voci, d.aggiornata:gsub("(%d+)%-(%d+)%-(%d+)", "%3/%2/%1"))
  html[#html + 1] = '</div>'
  return table.concat(html, "\n")
end

function Div(div)
  if div.identifier == "ricerca" then return pandoc.RawBlock("html", search_box()) end
  if div.identifier == "rubrica" then return pandoc.RawBlock("html", entries()) end
end
