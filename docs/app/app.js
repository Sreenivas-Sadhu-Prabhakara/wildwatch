/* Squirrel Watch PH — responsive web reporter.
   No backend. Submitting opens the phone's own email app (mailto:), pre-addressed
   to the agency with the subject and details filled in — the user just presses
   Send. History is kept in localStorage. The CAMPAIGN object is the single unit
   of reuse — swap it to retarget the app at another animal / country / agency
   (mirrors the Flutter app). */

const CAMPAIGN = {
  id: "squirrel-ph",
  appName: "Squirrel Watch PH",
  emoji: "🐿️",
  country: "Philippines",
  tagline: "Spotted a squirrel? Help DENR track it.",
  blurb:
    "Finlayson’s squirrels are invasive and not native to the Philippines. Your report helps the DENR Biodiversity Management Bureau map their spread.",
  agency: { name: "DENR – Biodiversity Management Bureau", short: "DENR-BMB" },
  email: {
    to: "bmb@bmb.gov.ph",
    subjectTemplate: "Squirrel sighting report — {species} @ {locality}",
  },
  map: { center: [14.5995, 120.9842], zoom: 11 },
  speciesPrompt: "Which squirrel did you see?",
  species: [
    {
      id: "finlaysons-squirrel",
      common: "Finlayson's squirrel",
      scientific: "Callosciurus finlaysonii",
      emoji: "🐿️",
      hint: "Slender, long bushy tail. Colour varies widely — cream, grey, reddish or near-white. Often on trees, fences and power lines.",
      target: true,
    },
    {
      id: "other-squirrel",
      common: "Other / unsure squirrel",
      emoji: "❓",
      hint: "Pick this if it looks like a squirrel but you are not certain.",
    },
  ],
  fields: {
    count: { label: "How many did you see?" },
    behavior: {
      label: "What was it doing?",
      choices: ["On a tree", "On power lines / cables", "On the ground", "On a fence or wall", "Inside / on a building", "Feeding", "Other"],
    },
    habitat: {
      label: "Where did you see it?",
      choices: ["Residential area", "Park or garden", "Forest / wooded area", "Roadside", "Commercial area", "Other"],
    },
    still_present: { label: "Is it still there now?" },
  },
  submitLabel: "Email report to DENR",
  safety: [
    "Do not touch, catch or feed the squirrel — wild animals can carry disease (including rabies).",
    "Keep a safe distance and keep pets and children away.",
    "A clear photo from a distance is more useful than getting close.",
  ],
};

const STORE_KEY = "squirrelwatch.reports.v1";
const $ = (id) => document.getElementById(id);

const state = {
  speciesId: null,
  photoFile: null,
  photoThumb: null,
  lat: null,
  lng: null,
  accuracy: null,
  fields: { count: 1, behavior: null, habitat: null, still_present: null },
};

let map = null,
  marker = null;

/* ------------------------------------------------------------------ init */
function init() {
  $("crest").textContent = CAMPAIGN.emoji;
  $("appName").textContent = CAMPAIGN.appName;
  $("country").textContent = CAMPAIGN.country;
  $("tagline").textContent = CAMPAIGN.tagline;
  $("blurb").textContent = CAMPAIGN.blurb;
  $("q-species").textContent = CAMPAIGN.speciesPrompt;
  $("agencyShort").textContent = CAMPAIGN.agency.short;
  $("footName").textContent = CAMPAIGN.appName;
  $("footAgency").textContent = CAMPAIGN.agency.short;
  $("sendLabel").textContent = CAMPAIGN.submitLabel;
  document.title = `${CAMPAIGN.appName} — Report a sighting`;

  renderSpecies();
  renderDetails();
  renderSafety();
  renderPhotoSlot();
  setupMap();
  wire();
  renderHistory();
  applyDeepLink();
  updateSend();
}

/* --------------------------------------------------------------- species */
function renderSpecies() {
  $("speciesList").innerHTML = CAMPAIGN.species
    .map(
      (s) => `
    <div class="spec" data-id="${s.id}">
      <div class="pic">${s.emoji || "🐾"}</div>
      <div>
        <div class="nm">${esc(s.common)}</div>
        ${s.scientific ? `<div class="sci">${esc(s.scientific)}</div>` : ""}
        ${s.hint ? `<div class="tip">${esc(s.hint)}</div>` : ""}
      </div>
      ${s.target ? `<span class="badge">Invasive</span>` : ""}
      <div class="check">✓</div>
    </div>`
    )
    .join("");
  $("speciesList")
    .querySelectorAll(".spec")
    .forEach((el) =>
      el.addEventListener("click", () => {
        state.speciesId = el.dataset.id;
        syncSpecies();
        updateSend();
      })
    );
}
function syncSpecies() {
  document
    .querySelectorAll(".spec")
    .forEach((el) => el.classList.toggle("sel", el.dataset.id === state.speciesId));
}

/* --------------------------------------------------------------- details */
function renderDetails() {
  const f = CAMPAIGN.fields;
  $("details").innerHTML = `
    <label class="fld">${esc(f.count.label)}</label>
    <div class="stepper" id="countStep">
      <button type="button" data-d="-1" aria-label="Fewer">−</button>
      <span class="val" id="countVal">1</span>
      <button type="button" data-d="1" aria-label="More">+</button>
    </div>
    <label class="fld">${esc(f.behavior.label)}</label>
    <div class="chips" id="behaviorChips"></div>
    <label class="fld">${esc(f.habitat.label)}</label>
    <div class="chips" id="habitatChips"></div>
    <label class="fld">${esc(f.still_present.label)}</label>
    <div class="seg" id="stillSeg">
      <button type="button" data-v="true">Yes</button>
      <button type="button" data-v="false">No</button>
    </div>`;

  buildChips("behaviorChips", f.behavior.choices, "behavior");
  buildChips("habitatChips", f.habitat.choices, "habitat");

  $("countStep").addEventListener("click", (e) => {
    const b = e.target.closest("button");
    if (!b) return;
    state.fields.count = Math.max(1, state.fields.count + Number(b.dataset.d));
    $("countVal").textContent = state.fields.count;
  });
  $("stillSeg").addEventListener("click", (e) => {
    const b = e.target.closest("button");
    if (!b) return;
    state.fields.still_present = state.fields.still_present === b.dataset.v ? null : b.dataset.v;
    $("stillSeg")
      .querySelectorAll("button")
      .forEach((x) => x.classList.toggle("on", x.dataset.v === state.fields.still_present));
  });
}
function buildChips(containerId, choices, key) {
  const c = $(containerId);
  c.innerHTML = choices
    .map((ch) => `<button type="button" class="chip" data-v="${esc(ch)}">${esc(ch)}</button>`)
    .join("");
  c.addEventListener("click", (e) => {
    const b = e.target.closest(".chip");
    if (!b) return;
    state.fields[key] = state.fields[key] === b.dataset.v ? null : b.dataset.v;
    c.querySelectorAll(".chip").forEach((x) => x.classList.toggle("sel", x.dataset.v === state.fields[key]));
  });
}

/* --------------------------------------------------------------- safety */
function renderSafety() {
  $("safety").innerHTML =
    `<h4>🛡 Stay safe</h4><ul>` +
    CAMPAIGN.safety.map((s) => `<li>${esc(s)}</li>`).join("") +
    `</ul>`;
}

/* ---------------------------------------------------------------- photo */
function renderPhotoSlot() {
  const slot = $("photoSlot");
  if (state.photoThumb) {
    slot.innerHTML = `
      <div class="preview">
        <img src="${state.photoThumb}" alt="Your photo" />
        <button class="rm" id="rmPhoto">✕ Remove</button>
      </div>`;
    $("rmPhoto").addEventListener("click", () => {
      state.photoFile = null;
      state.photoThumb = null;
      renderPhotoSlot();
      updatePhotoShare();
    });
  } else {
    slot.innerHTML = `
      <div class="drop">
        <div class="ic">📷</div>
        <div class="photo-actions">
          <button class="btn tonal" id="btnCam">📸 Camera</button>
          <button class="btn" id="btnLib">🖼 Gallery</button>
        </div>
      </div>`;
    $("btnCam").addEventListener("click", () => $("fileCam").click());
    $("btnLib").addEventListener("click", () => $("fileLib").click());
  }
}
async function onPhotoPicked(file) {
  if (!file) return;
  state.photoFile = file;
  try {
    state.photoThumb = await makeThumb(file, 640);
  } catch {
    state.photoThumb = null;
  }
  renderPhotoSlot();
  updatePhotoShare();
}

// True when this device can share the photo file via the OS share sheet
// (mobile Safari / Chrome). On desktop this is usually false.
function canSharePhoto() {
  return !!(state.photoFile && navigator.canShare && navigator.canShare({ files: [state.photoFile] }));
}
function updatePhotoShare() {
  $("sharePhoto").hidden = !canSharePhoto();
}
async function sharePhoto() {
  if (!canSharePhoto()) return;
  try {
    await navigator.share({
      files: [state.photoFile],
      title: "Squirrel sighting photo",
      text: "Photo for my squirrel sighting report to DENR.",
    });
  } catch (e) {
    // user dismissed the share sheet — nothing to do
  }
}

/* ------------------------------------------------------------------ map */
function setupMap() {
  if (!window.L) {
    $("map").innerHTML =
      '<div style="padding:24px;text-align:center;color:#5e6a59;font-size:13px">Map unavailable offline — use “Use my location” or type a landmark.</div>';
    return;
  }
  map = L.map("map", { zoomControl: true }).setView(CAMPAIGN.map.center, CAMPAIGN.map.zoom);
  L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "© OpenStreetMap",
  }).addTo(map);
  map.on("click", (e) => setPin(e.latlng.lat, e.latlng.lng));
}
function setPin(lat, lng, acc) {
  state.lat = lat;
  state.lng = lng;
  state.accuracy = acc ?? null;
  if (map) {
    if (!marker) {
      marker = L.marker([lat, lng], { draggable: true }).addTo(map);
      marker.on("dragend", () => {
        const p = marker.getLatLng();
        state.lat = p.lat;
        state.lng = p.lng;
        state.accuracy = null;
        showCoords();
      });
    } else {
      marker.setLatLng([lat, lng]);
    }
  }
  showCoords();
  updateSend();
}
function showCoords() {
  if (state.lat == null) return;
  $("coords").textContent =
    `Pin: ${state.lat.toFixed(5)}, ${state.lng.toFixed(5)}` +
    (state.accuracy ? `  (±${Math.round(state.accuracy)} m)` : "");
}
function useMyLocation() {
  if (!navigator.geolocation) return toast("Geolocation isn’t available on this device.");
  $("coords").textContent = "Locating…";
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const { latitude, longitude, accuracy } = pos.coords;
      if (map) map.setView([latitude, longitude], 16);
      setPin(latitude, longitude, accuracy);
    },
    (err) => {
      $("coords").textContent =
        err.code === 1
          ? "Location permission denied — tap the map or type a landmark instead."
          : "Couldn’t get a location fix — tap the map instead.";
    },
    { enableHighAccuracy: true, timeout: 12000 }
  );
}

/* -------------------------------------------------------------- wire-up */
function wire() {
  $("fileCam").addEventListener("change", (e) => onPhotoPicked(e.target.files[0]));
  $("fileLib").addEventListener("change", (e) => onPhotoPicked(e.target.files[0]));
  $("useLoc").addEventListener("click", useMyLocation);
  $("locality").addEventListener("input", updateSend);
  $("send").addEventListener("click", submit);
  $("sharePhoto").addEventListener("click", sharePhoto);
  $("newReport").addEventListener("click", () => resetForm());
  $("openHist").addEventListener("click", () => toggleDrawer(true));
  $("closeHist").addEventListener("click", () => toggleDrawer(false));
  $("scrim").addEventListener("click", () => toggleDrawer(false));
}

function updateSend() {
  const hasSpecies = !!state.speciesId;
  const hasLoc = state.lat != null || $("locality").value.trim() !== "";
  const ready = hasSpecies && hasLoc;
  $("send").disabled = !ready;
  $("sendMeta").textContent = !hasSpecies
    ? "Choose a species to continue · no account needed"
    : !hasLoc
    ? "Add a location — use the map or a landmark"
    : `Opens your email app, addressed to ${CAMPAIGN.email.to}`;
}

/* -------------------------------------------------------------- submit */
function buildReport() {
  return {
    id: uid(),
    ts: Date.now(),
    campaignId: CAMPAIGN.id,
    speciesId: state.speciesId,
    speciesName: speciesName(state.speciesId),
    lat: state.lat,
    lng: state.lng,
    accuracy: state.accuracy,
    locality: $("locality").value.trim(),
    fields: { ...state.fields },
    notes: $("notes").value.trim(),
    contact: {
      name: $("cname").value.trim(),
      phone: $("cphone").value.trim(),
      email: $("cemail").value.trim(),
    },
    thumb: state.photoThumb,
    hasPhoto: !!state.photoFile,
    status: "saved",
  };
}
function subjectFor(r) {
  const loc = r.locality || (r.lat != null ? `${r.lat.toFixed(4)}, ${r.lng.toFixed(4)}` : "Unknown location");
  return CAMPAIGN.email.subjectTemplate
    .replace("{species}", r.speciesName || "Wildlife sighting")
    .replace("{locality}", loc);
}
function bodyFor(r) {
  const L = [];
  L.push(`${CAMPAIGN.appName} — wildlife sighting report`);
  L.push(`For: ${CAMPAIGN.agency.name} (${CAMPAIGN.country})`, "");
  L.push("SPECIES", `  ${r.speciesName || "Not specified"}`, "");
  L.push("WHEN", `  Observed/Reported: ${new Date(r.ts).toLocaleString()}`, "");
  L.push("WHERE");
  if (r.lat != null) {
    L.push(`  Coordinates: ${r.lat}, ${r.lng}`);
    if (r.accuracy) L.push(`  Accuracy: ±${Math.round(r.accuracy)} m`);
    L.push(`  Map: https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}`);
  }
  if (r.locality) L.push(`  Landmark / address: ${r.locality}`);
  if (r.lat == null && !r.locality) L.push("  Not provided");
  L.push("");
  L.push("DETAILS");
  L.push(`  ${CAMPAIGN.fields.count.label} ${r.fields.count}`);
  if (r.fields.behavior) L.push(`  ${CAMPAIGN.fields.behavior.label} ${r.fields.behavior}`);
  if (r.fields.habitat) L.push(`  ${CAMPAIGN.fields.habitat.label} ${r.fields.habitat}`);
  if (r.fields.still_present) L.push(`  ${CAMPAIGN.fields.still_present.label} ${r.fields.still_present === "true" ? "Yes" : "No"}`);
  L.push("");
  if (r.notes) L.push("NOTES", `  ${r.notes}`, "");
  L.push("REPORTER");
  const c = r.contact;
  if (!c.name && !c.phone && !c.email) L.push("  Anonymous (no contact details provided)");
  else {
    if (c.name) L.push(`  Name: ${c.name}`);
    if (c.phone) L.push(`  Phone: ${c.phone}`);
    if (c.email) L.push(`  Email: ${c.email}`);
  }
  L.push("");
  L.push(r.hasPhoto ? "A photo is attached / will be attached to this email." : "No photo was attached.");
  L.push("", `Report ID: ${r.id}`, `Sent via ${CAMPAIGN.appName} (web).`);
  return L.join("\n");
}

// Opens the phone's email app (composer), pre-addressed to the agency with the
// subject and body filled in. mailto can't carry a file attachment, so when a
// photo is present we prompt the sender to attach it in their mail app.
function deliver(r) {
  const subject = subjectFor(r);
  let body = bodyFor(r);
  if (r.hasPhoto) {
    body +=
      "\n\n[Please attach your photo to this email before sending — use the attachment / paperclip button in your mail app.]";
  }
  window.location.href =
    `mailto:${CAMPAIGN.email.to}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}

function submit() {
  const r = buildReport();
  r.status = "sent";
  saveReport(r);
  renderHistory();
  deliver(r); // must run during the click gesture so the mail app opens

  if (canSharePhoto()) {
    // Keep the form so the user can also attach the photo to their email; offer
    // an explicit "new report" reset instead of clearing automatically.
    $("newReport").hidden = false;
    $("sendMeta").textContent = "Email opened ✓ — now tap “Attach photo” to add the picture.";
    toast("Email opened. Tap “Attach photo” to add your picture.");
  } else {
    toast(
      state.photoFile
        ? "Email opened — attach your photo in your mail app, then Send."
        : "Email opened — review and press Send."
    );
    resetForm();
  }
}

function resetForm() {
  state.speciesId = null;
  state.photoFile = null;
  state.photoThumb = null;
  state.lat = state.lng = state.accuracy = null;
  state.fields = { count: 1, behavior: null, habitat: null, still_present: null };
  syncSpecies();
  renderPhotoSlot();
  updatePhotoShare();
  renderDetails();
  $("locality").value = "";
  $("notes").value = "";
  $("cname").value = $("cphone").value = $("cemail").value = "";
  $("coords").textContent = "Tap the map to drop a pin, or use your location.";
  $("newReport").hidden = true;
  if (marker && map) {
    map.removeLayer(marker);
    marker = null;
    map.setView(CAMPAIGN.map.center, CAMPAIGN.map.zoom);
  }
  updateSend();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

/* ------------------------------------------------------------- history */
function loadReports() {
  try {
    return JSON.parse(localStorage.getItem(STORE_KEY) || "[]");
  } catch {
    return [];
  }
}
function saveReport(r) {
  const all = loadReports();
  all.unshift(r);
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(all));
  } catch {
    // storage full (large thumbs) — drop the oldest and retry once
    all.pop();
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(all));
    } catch {}
  }
}
function deleteReport(id) {
  localStorage.setItem(STORE_KEY, JSON.stringify(loadReports().filter((r) => r.id !== id)));
  renderHistory();
}
function renderHistory() {
  const all = loadReports();
  const n = all.length;
  $("histCount").hidden = n === 0;
  $("histCount").textContent = n;
  if (!n) {
    $("histBody").innerHTML = `<div class="empty"><div class="ic">🗂</div><p>Your reports will appear here.</p></div>`;
    return;
  }
  $("histBody").innerHTML = all
    .map(
      (r) => `
    <div class="rep" data-id="${r.id}">
      <div class="th">${r.thumb ? `<img src="${r.thumb}" style="width:100%;height:100%;object-fit:cover;border-radius:10px" alt=""/>` : CAMPAIGN.emoji}</div>
      <div style="min-width:0">
        <div class="nm">${esc(r.speciesName || "Sighting")}</div>
        <div class="mt">${esc(r.locality || (r.lat != null ? `${r.lat.toFixed(4)}, ${r.lng.toFixed(4)}` : "Unknown location"))}</div>
        <div class="mt">${new Date(r.ts).toLocaleString()}</div>
        <span class="pill ${r.status === "sent" ? "sent" : "saved"}">${r.status === "sent" ? "✓ Sent" : "Saved"}</span>
      </div>
      <div class="acts">
        <button class="lnk" data-act="resend">Resend</button>
        <button class="lnk del" data-act="del">Delete</button>
      </div>
    </div>`
    )
    .join("");
  $("histBody")
    .querySelectorAll(".rep")
    .forEach((el) => {
      const id = el.dataset.id;
      el.querySelector('[data-act="del"]').addEventListener("click", () => deleteReport(id));
      el.querySelector('[data-act="resend"]').addEventListener("click", () => {
        const r = loadReports().find((x) => x.id === id);
        if (r) deliver(r);
      });
    });
}
function toggleDrawer(on) {
  $("drawer").classList.toggle("on", on);
  $("scrim").classList.toggle("on", on);
  $("drawer").setAttribute("aria-hidden", String(!on));
}

/* ----------------------------------------------------------- deep link */
// Lets a shortcut / link prefill the form: ?species=&lat=&lng=&locality=&count=&behavior=&notes=
function applyDeepLink() {
  const q = new URLSearchParams(location.search);
  if ([...q.keys()].length === 0) return;
  const sp = q.get("species");
  if (sp && CAMPAIGN.species.some((s) => s.id === sp)) {
    state.speciesId = sp;
    syncSpecies();
  }
  const lat = parseFloat(q.get("lat")),
    lng = parseFloat(q.get("lng"));
  if (!isNaN(lat) && !isNaN(lng)) {
    if (map) map.setView([lat, lng], 16);
    setPin(lat, lng);
  }
  if (q.get("locality")) $("locality").value = q.get("locality");
  if (q.get("notes")) $("notes").value = q.get("notes");
  const count = parseInt(q.get("count"), 10);
  if (!isNaN(count) && count > 0) {
    state.fields.count = count;
    $("countVal").textContent = count;
  }
  ["behavior", "habitat"].forEach((k) => {
    const v = q.get(k);
    if (v) {
      state.fields[k] = v;
      const cont = $(k + "Chips");
      if (cont) cont.querySelectorAll(".chip").forEach((x) => x.classList.toggle("sel", x.dataset.v === v));
    }
  });
}

/* --------------------------------------------------------------- utils */
function speciesName(id) {
  const s = CAMPAIGN.species.find((x) => x.id === id);
  return s ? (s.scientific ? `${s.common} (${s.scientific})` : s.common) : null;
}
function esc(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
}
function uid() {
  return "r-" + Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}
function toast(msg) {
  const t = $("toast");
  t.textContent = msg;
  t.classList.add("on");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => t.classList.remove("on"), 3200);
}
function fileToImage(file) {
  return new Promise((res, rej) => {
    const img = new Image();
    img.onload = () => res(img);
    img.onerror = rej;
    img.src = URL.createObjectURL(file);
  });
}
async function makeThumb(file, max) {
  const img = await fileToImage(file);
  const s = Math.min(1, max / Math.max(img.width, img.height));
  const w = Math.round(img.width * s),
    h = Math.round(img.height * s);
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  c.getContext("2d").drawImage(img, 0, 0, w, h);
  URL.revokeObjectURL(img.src);
  return c.toDataURL("image/jpeg", 0.82);
}
document.addEventListener("DOMContentLoaded", init);
