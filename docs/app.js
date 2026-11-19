const KEY = "logbuch.v1";
const TAGS = ["Arbeit", "Geld", "Idee", "Privat", "Kacke"];

let state = load();
let filter = "alle";
let query = "";
let draftTag = "";

const $ = (id) => document.getElementById(id);
const list = $("list");
const text = $("text");
const saveBtn = $("save");
const toastEl = $("toast");

function load() {
  try {
    const raw = JSON.parse(localStorage.getItem(KEY) || "{}");
    return { entries: Array.isArray(raw.entries) ? raw.entries : [] };
  } catch {
    return { entries: [] };
  }
}

function persist() {
  localStorage.setItem(KEY, JSON.stringify(state));
}

function toast(msg) {
  toastEl.textContent = msg;
  toastEl.hidden = false;
  clearTimeout(toast.t);
  toast.t = setTimeout(() => (toastEl.hidden = true), 1800);
}

function todayKey(d = new Date()) {
  return d.toLocaleDateString("sv-SE");
}

function dayLabel(key) {
  const t = todayKey();
  const y = todayKey(new Date(Date.now() - 864e5));
  if (key === t) return "Heute";
  if (key === y) return "Gestern";
  return new Date(key + "T12:00:00").toLocaleDateString("de-DE", {
    weekday: "short", day: "2-digit", month: "2-digit", year: "numeric",
  });
}

function time(iso) {
  return new Date(iso).toLocaleTimeString("de-DE", { hour: "2-digit", minute: "2-digit" });
}

function visible() {
  const q = query.trim().toLowerCase();
  return state.entries
    .filter((e) => (filter === "alle" ? true : e.tag === filter))
    .filter((e) => (q ? (e.text + " " + (e.tag || "")).toLowerCase().includes(q) : true))
    .sort((a, b) => b.at.localeCompare(a.at));
}

function render() {
  const rows = visible();
  list.replaceChildren();

  if (!rows.length) {
    const p = document.createElement("p");
    p.className = "empty";
    p.textContent = state.entries.length ? "Nichts gefunden." : "Noch nichts drin. Schreib unten die erste Zeile.";
    list.append(p);
    return;
  }

  let lastDay = "";
  for (const e of rows) {
    const key = todayKey(new Date(e.at));
    if (key !== lastDay) {
      lastDay = key;
      const h = document.createElement("div");
      h.className = "day";
      h.textContent = dayLabel(key);
      list.append(h);
    }

    const row = document.createElement("article");
    row.className = "entry";

    const meta = document.createElement("div");
    meta.className = "meta";
    const tm = document.createElement("time");
    tm.dateTime = e.at;
    tm.textContent = time(e.at);
    meta.append(tm);
    if (e.tag) {
      const tag = document.createElement("span");
      tag.className = "tag";
      tag.textContent = e.tag;
      meta.append(tag);
    }

    const body = document.createElement("div");
    body.className = "body";
    body.textContent = e.text;

    const del = document.createElement("button");
    del.className = "del";
    del.textContent = "×";
    del.setAttribute("aria-label", "Eintrag löschen");
    del.onclick = () => {
      if (!confirm("Eintrag löschen?")) return;
      state.entries = state.entries.filter((x) => x.id !== e.id);
      persist();
      render();
      toast("Gelöscht");
    };

    row.append(meta, body, del);
    list.append(row);
  }
}

function renderTags() {
  const all = $("tags");
  all.replaceChildren();
  for (const t of ["alle", ...TAGS]) {
    const b = document.createElement("button");
    b.className = "chip";
    b.textContent = t;
    b.setAttribute("aria-pressed", String(filter === t));
    b.onclick = () => {
      filter = t;
      renderTags();
      render();
    };
    all.append(b);
  }

  const pick = $("tagpick");
  pick.replaceChildren();
  for (const t of TAGS) {
    const b = document.createElement("button");
    b.className = "chip";
    b.textContent = t;
    b.setAttribute("aria-pressed", String(draftTag === t));
    b.onclick = () => {
      draftTag = draftTag === t ? "" : t;
      renderTags();
    };
    pick.append(b);
  }
}

function add() {
  const value = text.value.trim();
  if (!value) return;
  state.entries.push({
    id: crypto.randomUUID(),
    at: new Date().toISOString(),
    text: value,
    tag: draftTag,
  });
  persist();
  text.value = "";
  draftTag = "";
  autosize();
  renderTags();
  render();
  counting();
  text.focus();
}

function counting() {
  const n = state.entries.filter((e) => todayKey(new Date(e.at)) === todayKey()).length;
  $("count").textContent = n === 1 ? "1 heute" : n + " heute";
}

function autosize() {
  text.style.height = "auto";
  text.style.height = Math.min(text.scrollHeight, innerHeight * 0.4) + "px";
  saveBtn.disabled = !text.value.trim();
}

function exportAll() {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "logbuch-" + todayKey() + ".json";
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 4000);
  toast("Datei gesichert");
}

function importFile() {
  const input = document.createElement("input");
  input.type = "file";
  input.accept = "application/json,.json";
  input.onchange = async () => {
    const file = input.files?.[0];
    if (!file) return;
    try {
      const raw = JSON.parse(await file.text());
      const add = (raw.entries || []).filter((e) => e && e.id && e.at && e.text);
      const seen = new Set(state.entries.map((e) => e.id));
      const fresh = add.filter((e) => !seen.has(e.id));
      state.entries.push(...fresh);
      persist();
      render();
      counting();
      toast(fresh.length + " übernommen");
    } catch {
      toast("Datei nicht lesbar");
    }
  };
  input.click();
}

saveBtn.onclick = add;

const when = $("when");

$("bell").onclick = () => {
  if (!text.value.trim()) return toast("Erst Text schreiben");
  when.hidden = false;
};

$("when-cancel").onclick = () => (when.hidden = true);

for (const b of when.querySelectorAll("button[data-min]")) {
  b.onclick = () => remind(Number(b.dataset.min));
}

async function remind(minutes) {
  const value = text.value.trim();
  when.hidden = true;
  if (!value) return;

  add();

  const title = "Logbuch";
  const body = value.length > 120 ? value.slice(0, 117) + "…" : value;

  if (window.webkit?.messageHandlers?.notify) {
    window.webkit.messageHandlers.notify.postMessage({ title, body, minutes });
    toast(minutes >= 1440 ? "Erinnerung morgen" : "Erinnerung gesetzt");
    return;
  }

  if (!("Notification" in window)) return toast("Erinnerung nur in der App");
  const perm = await Notification.requestPermission();
  if (perm !== "granted") return toast("Nicht erlaubt");
  toast("Nur solange die Seite offen ist");
  setTimeout(() => new Notification(title, { body }), minutes * 60000);
}

text.addEventListener("input", autosize);
text.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    add();
  }
});
$("q").addEventListener("input", (e) => {
  query = e.target.value;
  render();
});
$("export").onclick = exportAll;
$("import").onclick = importFile;

renderTags();
render();
counting();
autosize();

if ("serviceWorker" in navigator) {
  addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
}
