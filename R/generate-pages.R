library(readxl)
library(dplyr)
library(stringr)
library(stringi)
library(glue)
library(yaml)
library(tibble)

dir.create("procedures", showWarnings = FALSE)

clean_text <- function(x) {
  if (length(x) == 0) return("")
  if (is.na(x)) return("")
  x <- as.character(x)
  x <- stri_enc_toutf8(x)
  x <- str_squish(x)
  if (x %in% c("", "NA", "No", "NO", "no", "?")) return("")
  x
}

slugify <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[àáâãäå]", "a") |>
    str_replace_all("[èéêë]", "e") |>
    str_replace_all("[ìíîï]", "i") |>
    str_replace_all("[òóôõö]", "o") |>
    str_replace_all("[ùúûü]", "u") |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_replace_all("^-|-$", "")
}

short_description <- function(x, max_length = 240) {
  x <- clean_text(x)
  if (x == "") return("Descrizione non ancora disponibile.")
  str_trunc(x, width = max_length)
}

make_categories <- function(...) {
  cats <- c(...)
  cats <- vapply(cats, clean_text, character(1))
  cats <- cats[cats != ""]
  unique(cats)
}

make_markdown_link <- function(label, url) {
  url <- clean_text(url)
  if (url == "") return("")
  paste0("[", label, "](", url, ")")
}

make_bullet <- function(label, value) {
  value <- clean_text(value)
  if (value == "") return("")
  paste0("- **", label, "**: ", value, "\n")
}

make_link_bullet <- function(label, url) {
  url <- clean_text(url)
  if (url == "") return("")
  paste0("- **", label, "**: [", url, "](", url, ")\n")
}

make_all_fields_table <- function(row) {
  values <- as.list(row)
  
  lines <- c(
    "\n\n## Tutti i campi disponibili\n",
    "| Campo | Valore |",
    "|---|---|"
  )
  
  for (field_name in names(values)) {
    value <- clean_text(values[[field_name]])
    
    if (value == "") {
      value <- "-"
    }
    
    value <- str_replace_all(value, "\\|", "\\\\|")
    value <- str_replace_all(value, "\n", "<br>")
    
    lines <- c(lines, paste0("| ", field_name, " | ", value, " |"))
  }
  
  paste(lines, collapse = "\n")
}

procedure <- read_excel("foglioWIKI.xlsx") |>
  mutate(across(where(is.character), ~ stri_enc_toutf8(.x))) |>
  mutate(across(where(is.character), ~ str_squish(.x))) |>
  filter(
    !is.na(titoloSezione),
    str_squish(as.character(titoloSezione)) != ""
  )

procedure <- procedure |>
  mutate(
    slug_base = slugify(titoloSezione),
    slug = make.unique(slug_base, sep = "-")
  )

old_pages <- list.files("procedures", pattern = "\\.qmd$", full.names = TRUE)
if (length(old_pages) > 0) {
  file.remove(old_pages)
}

for (i in seq_len(nrow(procedure))) {
  
  p <- procedure[i, ]
  
  title <- clean_text(p$titoloSezione)
  description_short <- short_description(p$descrizione)
  
  categories <- make_categories(
    p$MacroCAT1,
    p$MacroCAT2,
    p$MacroCAT3
  )
  
  yaml_header <- as.yaml(
    list(
      title = title,
      description = description_short,
      categories = categories
    )
  )
  
  descrizione <- clean_text(p$descrizione)
  if (descrizione == "") {
    descrizione <- "Descrizione non ancora disponibile."
  }
  
  link_operativo <- clean_text(p$linkOperativo)
  link_documentazione <- clean_text(p$linkDocumentazione)
  
  link_operativo_section <- ""
  if (link_operativo != "") {
    link_operativo_section <- glue(
      '\n\n## Link operativo\n\n:::{{.callout-important}}\n[{link_operativo}]({link_operativo})\n:::\n'
    )
  }
  
  link_documentazione_section <- ""
  if (link_documentazione != "") {
    link_documentazione_section <- glue(
      '\n\n## Documentazione\n\n[{link_documentazione}]({link_documentazione})\n'
    )
  }
  
  categories_section <- ""
  if (length(categories) > 0) {
    categories_section <- paste0(
      "\n\n## Categorie\n\n",
      paste0("- ", categories, collapse = "\n")
    )
  }
  
  referenti <- paste0(
    make_bullet("Struttura referente 1", p$StrutturaReferente1),
    make_bullet("Contatto struttura 1", p$ContattoStruttura1),
    make_bullet("Struttura referente 2", p$StrutturaReferente2),
    make_bullet("Contatto struttura 2", p$ContattoStruttura2)
  )
  
  referenti_section <- ""
  if (referenti != "") {
    referenti_section <- paste0("\n\n## Referenti e contatti\n\n", referenti)
  }
  
  faq <- paste0(
    make_bullet("FAQ 1", p$FAQ1),
    make_bullet("FAQ 2", p$FAQ2),
    make_bullet("FAQ 3", p$FAQ3)
  )
  
  faq_section <- ""
  if (faq != "") {
    faq_section <- paste0("\n\n## FAQ / Note\n\n", faq)
  }
  
  useful_links <- paste0(
    make_link_bullet("Link operativo", p$linkOperativo),
    make_link_bullet("Link documentazione", p$linkDocumentazione)
  )
  
  useful_links_section <- ""
  if (useful_links != "") {
    useful_links_section <- paste0("\n\n## Link utili\n\n", useful_links)
  }
  
  all_fields_table <- make_all_fields_table(p)
  
  content <- glue(
    '---
{yaml_header}---

[← Torna alle procedure](../index.qmd)

## Descrizione

{descrizione}

{link_operativo_section}

{link_documentazione_section}

{useful_links_section}

{categories_section}

{referenti_section}

{faq_section}

{all_fields_table}
'
  )
  
  writeLines(
    content,
    file.path("procedures", paste0(p$slug, ".qmd")),
    useBytes = TRUE
  )
}

message("Generate ", nrow(procedure), " procedure pages.")