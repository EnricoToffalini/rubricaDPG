-- Post-render: aggiunge a styles.css e ricerca.js in docs/index.html un parametro ?v=<hash del
-- contenuto>, così dopo ogni aggiornamento il browser riscarica i file cambiati invece di usare
-- la copia in cache (GitHub Pages li serve con max-age=600) insieme all'HTML nuovo.

local pagina = "docs/index.html"

local function leggi(percorso)
  local f = assert(io.open(percorso, "rb"))
  local testo = f:read("a")
  f:close()
  return testo
end

local html = leggi(pagina)
for _, nome in ipairs({ "styles.css", "ricerca.js" }) do
  local v = pandoc.utils.sha1(leggi("docs/" .. nome)):sub(1, 10)
  local campo = nome:gsub("%.", "%%.")
  local n
  html, n = html:gsub('(["\'])' .. campo .. '%?v=[%w]*%1', '%1' .. nome .. '?v=' .. v .. '%1')
  if n == 0 then
    html, n = html:gsub('(["\'])' .. campo .. '%1', '%1' .. nome .. '?v=' .. v .. '%1')
  end
  if n == 0 then error("versioni.lua: riferimento a " .. nome .. " non trovato in " .. pagina) end
end

local f = assert(io.open(pagina, "wb"))
f:write(html)
f:close()
print("versioni.lua: aggiunto ?v= a styles.css e ricerca.js")
