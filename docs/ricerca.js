(() => {
  const search = document.querySelector("#ricerca");
  if (!search) return;

  const input = search.querySelector("#cerca");
  const chips = Array.from(search.querySelectorAll(".filtro"));
  const status = search.querySelector("#risultati");
  const empty = document.querySelector("#nessun-risultato");
  const list = document.querySelector("#voci");
  const stopWords = new Set(
    "a al ai alla alle allo che chi come con da dal de dei del della delle devo di dove e fa faccio fare gli ho i il in l la le lo mi mia miei mie nel per posso qual quale quali se si sono su un una vorrei".split(" ")
  );
  let category = "";

  // Minuscole senza accenti; con keepStars le parole chiave tipo «laureand*» restano radici
  function words(value, keepStars = false) {
    return value.toLowerCase().normalize("NFD").replace(/\p{M}/gu, "")
      .match(keepStars ? /[a-z0-9]+\*?/g : /[a-z0-9]+/g) ?? [];
  }

  // Troncamento della desinenza: laureando, laureandi, laureanda -> laureand;
  // laboratorio, laboratori -> laborator; banca, banche -> banc
  function stem(word) {
    if (word.length < 4) return word;
    return word.replace(/[aeiou]$/, "").replace(/i$/, "").replace(/([cg])h$/, "$1");
  }

  function prepare(list) {
    return { exact: list, stems: list.map(stem) };
  }

  const entries = Array.from(list.querySelectorAll(".voce"), (row, order) => {
    const heading = row.querySelector("h2");
    const keys = words(row.dataset.paroleChiave, true);
    return {
      row,
      order,
      heading,
      titleText: heading.textContent,
      title: prepare(words(heading.textContent)),
      keywords: prepare(keys.filter(word => !word.endsWith("*"))),
      roots: keys.filter(word => word.endsWith("*")).map(word => word.slice(0, -1)),
      details: prepare(words(row.textContent
        + (row.querySelector(".azione-mail") ? " email mail indirizzo scrivere" : "")))
    };
  });

  function matches(term, set) {
    if (set.exact.includes(term)) return 2;
    if (set.stems.includes(stem(term))) return 1;
    return 0;
  }

  function startsWith(term, set) {
    return term.length >= 3 && set.exact.some(word => word.startsWith(term));
  }

  function termScore(term, entry) {
    const title = matches(term, entry.title);
    if (title) return 5 + title;
    if (matches(term, entry.keywords) || entry.roots.some(root => term.startsWith(root))) return 4;
    if (startsWith(term, entry.title)) return 3;
    if (matches(term, entry.details)) return 2;
    if (startsWith(term, entry.keywords) || startsWith(term, entry.details)
      || (term.length >= 3 && entry.roots.some(root => root.startsWith(term)))) return 1;
    return 0;
  }

  function escapeHtml(value) {
    return value.replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  }

  // Evidenzia nel titolo le parole che corrispondono alla ricerca
  function highlight(entry, terms) {
    if (!terms.length) {
      entry.heading.textContent = entry.titleText;
      return;
    }
    entry.heading.innerHTML = entry.titleText.split(/(\s+)/).map(part => {
      const word = words(part)[0];
      const hit = word && terms.some(term => word === term || stem(word) === stem(term)
        || (term.length >= 3 && word.startsWith(term)));
      return hit ? `<mark>${escapeHtml(part)}</mark>` : escapeHtml(part);
    }).join("");
  }

  function update() {
    const terms = [...new Set(words(input.value).filter(word => !stopWords.has(word)))];
    const found = [];
    for (const entry of entries) {
      const scores = terms.map(term => termScore(term, entry));
      entry.row.hidden = Boolean(category && entry.row.dataset.categoria !== category)
        || scores.includes(0);
      if (!entry.row.hidden) {
        found.push({ ...entry, score: scores.reduce((total, score) => total + score, 0) });
        highlight(entry, terms);
      }
    }
    found.sort((a, b) => b.score - a.score || a.order - b.order);
    // Riordina solo se serve, così le schede non ripartono con l'animazione a ogni tasto
    const visible = Array.from(list.querySelectorAll(".voce:not([hidden])"));
    if (found.some((entry, i) => visible[i] !== entry.row)) list.append(...found.map(entry => entry.row));
    found.forEach((entry, i) => entry.row.style.setProperty("--i", Math.min(i, 12)));
    list.classList.toggle("filtrata", terms.length > 0 || Boolean(category));
    status.textContent = found.length === 1 ? "1 voce" : `${found.length} voci`;
    empty.hidden = found.length > 0;
    expandable();
  }

  // Schede estese: si aprono se la nota è tagliata nell'anteprima o contiene formattazione e link
  function expandable() {
    for (const row of list.querySelectorAll(".voce:not([hidden])")) {
      const button = row.querySelector(".apri-scheda");
      if (!button) continue;
      const preview = row.querySelector(".promemoria");
      const open = row.hasAttribute("data-ricca") || preview.scrollHeight > preview.clientHeight + 1;
      row.classList.toggle("estesa", open);
      button.hidden = !open;
    }
  }

  function openCard(id) {
    const card = document.getElementById(id);
    if (!card || card.open || !card.showModal || card.closest(".voce").hidden) return;
    card.showModal();
    history.replaceState(null, "", "#" + id);
  }

  list.addEventListener("click", event => {
    const button = event.target.closest(".apri-scheda");
    if (button) return openCard(button.dataset.scheda);
    const row = event.target.closest(".voce");
    // clic su qualsiasi scheda, ma non su link, pulsanti, indirizzi o testo selezionato
    if (!row || event.target.closest("a, button, dialog, .azione-mail") || String(getSelection())) return;
    openCard("scheda-" + row.id);
  });

  document.querySelectorAll(".scheda").forEach(card => {
    card.querySelector(".scheda-chiudi").addEventListener("click", () => card.close());
    card.addEventListener("click", event => { if (event.target === card) card.close(); });
    card.addEventListener("close", () => history.replaceState(null, "", location.pathname + location.search));
  });

  let resizing;
  addEventListener("resize", () => {
    clearTimeout(resizing);
    resizing = setTimeout(expandable, 150);
  });

  chips.forEach(chip => chip.addEventListener("click", () => {
    category = chip.dataset.categoria;
    chips.forEach(other => other.setAttribute("aria-pressed", String(other === chip)));
    update();
  }));

  document.querySelectorAll("[data-prova]").forEach(button => button.addEventListener("click", () => {
    input.value = button.dataset.prova;
    input.focus();
    update();
  }));

  // «/» porta alla ricerca, Esc la svuota, Invio apre il primo collegamento del primo risultato
  document.addEventListener("keydown", event => {
    if (event.key === "/" && document.activeElement !== input && !event.ctrlKey && !event.metaKey
      && !document.querySelector("dialog[open]")) {
      event.preventDefault();
      input.focus();
    }
  });
  input.addEventListener("keydown", event => {
    if (event.key === "Escape" && input.value) {
      input.value = "";
      update();
    } else if (event.key === "Enter") {
      const first = list.querySelector(".voce:not([hidden]) .azioni a");
      if (first && input.value.trim()) first.click();
    }
  });

  // Pulsanti «copia» accanto agli indirizzi email
  document.querySelectorAll(".copia").forEach(button => {
    button.hidden = false;
    button.addEventListener("click", () => {
      // copia sincrona (funziona ovunque nel gesto dell'utente), poi Clipboard API come riserva
      const area = document.createElement("textarea");
      area.value = button.dataset.copia;
      area.setAttribute("readonly", "");
      area.style.cssText = "position:fixed;opacity:0;pointer-events:none";
      document.body.append(area);
      area.select();
      let ok = false;
      try { ok = document.execCommand("copy"); } catch { ok = false; }
      area.remove();
      if (!ok) navigator.clipboard?.writeText(button.dataset.copia).catch(() => {});
      button.classList.add("copiato");
      button.setAttribute("aria-label", "Copiato");
      setTimeout(() => {
        button.classList.remove("copiato");
        button.setAttribute("aria-label", "Copia " + button.dataset.copia);
      }, 1600);
    });
  });

  input.addEventListener("input", update);
  update();
  search.hidden = false;
  document.documentElement.classList.add("js");
  // misura le anteprime solo a pagina impaginata (con i font caricati)
  expandable();
  document.fonts?.ready.then(expandable);
  if (location.hash.startsWith("#scheda-")) openCard(decodeURIComponent(location.hash.slice(1)));
})();
