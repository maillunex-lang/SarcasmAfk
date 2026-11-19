(() => {
  const SAVE_KEY = "bashlegends_html_v1";
  const AFK_CAP = 8;
  const AFK_RATE = 90;

  const CATALOG = {
    heroes: [
      { id: "H01", name: "Каэрон", role: "tank", power: 1400, hp: 4200, atk: 280, speed: 95, color: "#4ecdc4", row: "front" },
      { id: "H02", name: "Вейриса", role: "mage", power: 1520, hp: 2800, atk: 420, speed: 110, color: "#7aa2ff", row: "back" },
      { id: "H03", name: "Эльдарион", role: "support", power: 1180, hp: 3000, atk: 220, speed: 100, color: "#c9a227", row: "back" },
      { id: "H04", name: "Рустам", role: "fighter", power: 1300, hp: 3600, atk: 360, speed: 105, color: "#e35d6a", row: "front" },
      { id: "H05", name: "Лейла", role: "ranger", power: 1220, hp: 2600, atk: 390, speed: 120, color: "#5dcea0", row: "back" },
      { id: "H06", name: "Буран", role: "tank", power: 1280, hp: 4400, atk: 250, speed: 85, color: "#8aa0b8", row: "front" },
      { id: "H07", name: "Зима", role: "mage", power: 1450, hp: 2500, atk: 450, speed: 115, color: "#9ec9ff", row: "back" },
      { id: "H08", name: "Орлан", role: "fighter", power: 1240, hp: 3400, atk: 370, speed: 108, color: "#d4a574", row: "front" },
    ],
    stages: [
      {
        id: "S01", title: "Площадь талонов", soft: 120, xp: 40,
        enemies: [
          { id: "E1", name: "Талон", hp: 1800, atk: 160, speed: 90, color: "#e35d6a" },
          { id: "E2", name: "Очередь", hp: 1700, atk: 150, speed: 88, color: "#c45d7a" },
          { id: "E3", name: "Штамп", hp: 1500, atk: 200, speed: 100, color: "#a84d5f" },
        ],
      },
      {
        id: "S02", title: "Очередь у окна", soft: 180, xp: 60,
        enemies: [
          { id: "E4", name: "Окно", hp: 2200, atk: 200, speed: 95, color: "#e35d6a" },
          { id: "E5", name: "Форма", hp: 2000, atk: 210, speed: 100, color: "#c45d7a" },
          { id: "E6", name: "Клерк", hp: 2400, atk: 230, speed: 85, color: "#a84d5f" },
          { id: "E7", name: "Печать", hp: 1900, atk: 240, speed: 110, color: "#8a4050" },
        ],
      },
      {
        id: "S03", title: "Архив с характером", soft: 240, xp: 80,
        enemies: [
          { id: "E8", name: "Дух", hp: 2600, atk: 250, speed: 105, color: "#e35d6a" },
          { id: "E9", name: "Том", hp: 2800, atk: 240, speed: 80, color: "#c45d7a" },
          { id: "E10", name: "Страж", hp: 3200, atk: 260, speed: 75, color: "#a84d5f" },
        ],
      },
      {
        id: "S04", title: "Мост регламента", soft: 300, xp: 100,
        enemies: [
          { id: "E11", name: "Балка", hp: 3000, atk: 270, speed: 90, color: "#e35d6a" },
          { id: "E12", name: "Трос", hp: 2700, atk: 290, speed: 115, color: "#c45d7a" },
          { id: "E13", name: "Надзор", hp: 3400, atk: 280, speed: 85, color: "#a84d5f" },
          { id: "E14", name: "Штраф", hp: 2500, atk: 310, speed: 100, color: "#8a4050" },
        ],
      },
      {
        id: "S05", title: "Начальник окошка", soft: 420, xp: 140,
        enemies: [
          { id: "E15", name: "Охрана", hp: 3600, atk: 300, speed: 80, color: "#e35d6a" },
          { id: "E16", name: "Охрана", hp: 3600, atk: 300, speed: 82, color: "#c45d7a" },
          { id: "BOSS", name: "Начальник", hp: 5200, atk: 360, speed: 90, color: "#ff6b6b" },
        ],
      },
    ],
    shop: [
      { id: "pack_soft", name: "Мешок soft", costHard: 0, costSoft: 0, grantSoft: 500, grantHard: 0, free: true },
      { id: "ticket", name: "Тикет призыва", costHard: 10, costSoft: 0, grantSoft: 0, grantHard: 0, ticket: 1 },
      { id: "gold_bag", name: "Мешок hard", costSoft: 800, costHard: 0, grantSoft: 0, grantHard: 5 },
    ],
  };

  const TABS = [
    { id: "home", label: "Город" },
    { id: "campaign", label: "Кампания" },
    { id: "heroes", label: "Герои" },
    { id: "afk", label: "AFK" },
  ];

  let state = defaultState();
  let battle = null;

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];

  function defaultState() {
    return {
      soft: 800,
      hard: 30,
      xp: 120,
      tickets: 2,
      party: ["H01", "H02", "H03", "H04", "H05"],
      cleared: {},
      activeStage: "S01",
      afkStart: Date.now() - 2.4 * 3600 * 1000,
      freeClaimed: false,
    };
  }

  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return;
      const data = JSON.parse(raw);
      state = { ...defaultState(), ...data };
    } catch (_) { /* ignore */ }
  }

  function save() {
    localStorage.setItem(SAVE_KEY, JSON.stringify(state));
  }

  function level() {
    return Math.max(1, Math.floor(state.xp / 100) + 1);
  }

  function partyPower() {
    return state.party.reduce((sum, id) => {
      const h = CATALOG.heroes.find((x) => x.id === id);
      return sum + (h ? h.power : 0);
    }, 0);
  }

  function stageOpen(id) {
    if (id === "S01") return true;
    const idx = CATALOG.stages.findIndex((s) => s.id === id);
    if (idx <= 0) return false;
    return !!state.cleared[CATALOG.stages[idx - 1].id];
  }

  function afkHours() {
    const h = (Date.now() - state.afkStart) / 3600000;
    return Math.max(0, Math.min(AFK_CAP, h));
  }

  function go(screen) {
    if (battle && screen !== "battle") stopBattle();
    $$(".screen").forEach((el) => {
      el.hidden = el.dataset.screen !== screen;
    });
    if (screen === "home") renderHome();
    if (screen === "campaign") renderCampaign();
    if (screen === "heroes") renderHeroes();
    if (screen === "shop") renderShop();
    if (screen === "afk") renderAfk();
    if (screen === "battle") startBattle(state.activeStage);
    renderTabbars(screen === "shop" ? "home" : screen);
  }

  function renderTabbars(active) {
    $$(".tabbar").forEach((bar) => {
      const key = bar.dataset.tabs || active;
      const current = key === "home" && active === "shop" ? "home" : active;
      bar.innerHTML = TABS.map(
        (t) => `<button type="button" data-nav="${t.id}" class="${t.id === current ? "active" : ""}">${t.label}</button>`
      ).join("");
    });
  }

  function renderHud(host) {
    host.innerHTML = `
      <div class="avatar" aria-hidden="true"></div>
      <div class="meta">
        <strong>Командир</strong>
        <span>Ур.${level()} · Сила ${partyPower()}</span>
      </div>
      <div class="chips">
        <span class="chip">${state.soft}</span>
        <span class="chip hard">${state.hard}</span>
      </div>
    `;
  }

  function renderHome() {
    renderHud($("[data-hud]"));
    const next = CATALOG.stages.find((s) => stageOpen(s.id) && !state.cleared[s.id]);
    $("#home-tip").textContent = next
      ? `Продолжи: ${next.title}`
      : "Все этапы открыты · крути AFK";
  }

  function renderCampaign() {
    const list = $("#campaign-list");
    list.innerHTML = "";
    CATALOG.stages.forEach((s) => {
      const open = stageOpen(s.id);
      const cleared = !!state.cleared[s.id];
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="sw" style="background:${cleared ? "var(--ok)" : open ? "var(--gold)" : "var(--muted)"}"></div>
        <div class="meta">
          <strong>${s.id} · ${s.title}</strong>
          <span>${cleared ? "Пройдено" : open ? `+${s.soft} soft` : "Закрыто"}</span>
        </div>
        <button type="button" ${open ? "" : "disabled"}></button>
      `;
      const btn = card.querySelector("button");
      btn.textContent = open ? "Бой" : "Закрыто";
      if (open) {
        btn.addEventListener("click", () => {
          state.activeStage = s.id;
          save();
          go("battle");
        });
      }
      list.appendChild(card);
    });
  }

  function renderHeroes() {
    $("#party-line").textContent = `Партия ${state.party.length}/5 · сила ${partyPower()}`;
    const list = $("#heroes-list");
    list.innerHTML = "";
    CATALOG.heroes.forEach((h) => {
      const inParty = state.party.includes(h.id);
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="sw" style="background:${h.color}"></div>
        <div class="meta">
          <strong>${h.name}</strong>
          <span>${h.role} · ${h.power} · ${h.row}</span>
        </div>
        <button type="button" class="${inParty ? "ghost" : ""}"></button>
      `;
      const btn = card.querySelector("button");
      btn.textContent = inParty ? "Убрать" : "Взять";
      btn.addEventListener("click", () => {
        toggleParty(h.id);
        renderHeroes();
        save();
      });
      list.appendChild(card);
    });
  }

  function toggleParty(id) {
    const i = state.party.indexOf(id);
    if (i >= 0) {
      if (state.party.length <= 1) return;
      state.party.splice(i, 1);
    } else {
      if (state.party.length >= 5) state.party.shift();
      state.party.push(id);
    }
  }

  function renderShop() {
    const list = $("#shop-list");
    list.innerHTML = "";
    CATALOG.shop.forEach((item) => {
      const card = document.createElement("div");
      card.className = "card";
      const price = item.free
        ? state.freeClaimed
          ? "Уже взято"
          : "Бесплатно"
        : item.costHard
          ? `${item.costHard} hard`
          : `${item.costSoft} soft`;
      card.innerHTML = `
        <div class="sw" style="background:var(--gold)"></div>
        <div class="meta">
          <strong>${item.name}</strong>
          <span>${price}</span>
        </div>
        <button type="button"></button>
      `;
      const btn = card.querySelector("button");
      btn.textContent = "Купить";
      if (item.free && state.freeClaimed) btn.disabled = true;
      btn.addEventListener("click", () => buy(item));
      list.appendChild(card);
    });
  }

  function buy(item) {
    if (item.free) {
      if (state.freeClaimed) return;
      state.soft += item.grantSoft;
      state.freeClaimed = true;
    } else if (item.costHard) {
      if (state.hard < item.costHard) return toastShop("Не хватает hard");
      state.hard -= item.costHard;
      if (item.ticket) state.tickets += item.ticket;
      state.soft += item.grantSoft;
      state.hard += item.grantHard;
    } else if (item.costSoft) {
      if (state.soft < item.costSoft) return toastShop("Не хватает soft");
      state.soft -= item.costSoft;
      state.hard += item.grantHard;
    }
    save();
    renderShop();
  }

  function toastShop(msg) {
    const line = $("#party-line");
    if (!line) alert(msg);
  }

  function renderAfk() {
    const h = afkHours();
    $("#afk-fill").style.width = `${(h / AFK_CAP) * 100}%`;
    $("#afk-hours").textContent = `Накоплено ${h.toFixed(1)} ч / ${AFK_CAP} ч`;
    $("#afk-soft").textContent = `+${Math.floor(h * AFK_RATE)} soft`;
  }

  function claimAfk() {
    const gain = Math.floor(afkHours() * AFK_RATE);
    state.soft += gain;
    state.afkStart = Date.now();
    save();
    renderAfk();
    $("#btn-claim-afk").textContent = `+${gain}`;
    setTimeout(() => { $("#btn-claim-afk").textContent = "Забрать"; }, 1000);
  }

  function heroById(id) {
    return CATALOG.heroes.find((h) => h.id === id);
  }

  function startBattle(stageId) {
    stopBattle();
    const stage = CATALOG.stages.find((s) => s.id === stageId) || CATALOG.stages[0];
    state.activeStage = stage.id;
    $("#chapter").textContent = `Глава 1 · ${stage.title}`;
    $("#battle-end").hidden = true;
    $("#btn-speed").textContent = "×1";
    $("#toast").textContent = "Автобой";

    const party = state.party.map((id) => {
      const h = heroById(id);
      return {
        id: h.id,
        name: h.name,
        team: "hero",
        color: h.color,
        maxHp: h.hp,
        hp: h.hp,
        atk: h.atk,
        speed: h.speed,
        energy: 0,
        alive: true,
      };
    });
    const foes = stage.enemies.map((e) => ({
      id: e.id,
      name: e.name,
      team: "enemy",
      color: e.color,
      maxHp: e.hp,
      hp: e.hp,
      atk: e.atk,
      speed: e.speed,
      energy: Math.random() * 20,
      alive: true,
    }));

    battle = {
      stage,
      units: [...party, ...foes],
      speed: 1,
      t0: performance.now(),
      elapsed: 0,
      raf: 0,
      done: false,
    };
    paintBattle();
    loop();
  }

  function stopBattle() {
    if (battle?.raf) cancelAnimationFrame(battle.raf);
    battle = null;
  }

  function paintBattle() {
    const heroes = $("#col-heroes");
    const enemies = $("#col-enemies");
    const portraits = $("#portraits");
    heroes.innerHTML = "";
    enemies.innerHTML = "";
    portraits.innerHTML = "";

    battle.units.forEach((u) => {
      const el = document.createElement("div");
      el.className = `unit ${u.team === "enemy" ? "enemy" : ""} ${u.alive ? "" : "dead"}`;
      el.dataset.id = u.id;
      el.style.background = u.color;
      el.innerHTML = `<div class="hp"><i style="width:${(u.hp / u.maxHp) * 100}%"></i></div><span class="nm">${u.name}</span>`;
      (u.team === "hero" ? heroes : enemies).appendChild(el);

      if (u.team === "hero") {
        const p = document.createElement("button");
        p.type = "button";
        p.className = "portrait";
        p.innerHTML = `<div class="face" style="background:${u.color}"></div><span>${u.name.slice(0, 6)}</span><div class="en"><i style="width:${u.energy}%"></i></div>`;
        p.addEventListener("click", () => {
          if (!u.alive || u.energy < 80) return;
          u.energy = 0;
          act(u, true);
        });
        portraits.appendChild(p);
      }
    });
  }

  function refreshBattle() {
    battle.units.forEach((u) => {
      const el = $(`.unit[data-id="${u.id}"]`);
      if (!el) return;
      el.classList.toggle("dead", !u.alive);
      const bar = el.querySelector(".hp > i");
      if (bar) bar.style.width = `${Math.max(0, (u.hp / u.maxHp) * 100)}%`;
    });
    $$("#portraits .portrait").forEach((p, i) => {
      const u = battle.units.filter((x) => x.team === "hero")[i];
      if (!u) return;
      const e = p.querySelector(".en > i");
      if (e) e.style.width = `${u.energy}%`;
    });
  }

  function act(actor, ult = false) {
    if (battle.done || !actor.alive) return;
    const targets = battle.units.filter((u) => u.alive && u.team !== actor.team);
    if (!targets.length) return finish(actor.team === "hero");
    const target = targets[Math.floor(Math.random() * targets.length)];
    const dmg = actor.atk * (ult ? 2.2 : 1) * (0.9 + Math.random() * 0.2);
    target.hp = Math.max(0, target.hp - dmg);
    if (target.hp <= 0) target.alive = false;
    const node = $(`.unit[data-id="${target.id}"]`);
    if (node) {
      node.classList.add("hit");
      setTimeout(() => node.classList.remove("hit"), 120);
    }
    $("#toast").textContent = ult
      ? `ULT · ${actor.name} → ${target.name}`
      : `${actor.name} → ${target.name}`;
    refreshBattle();
    checkEnd();
  }

  function checkEnd() {
    const h = battle.units.some((u) => u.team === "hero" && u.alive);
    const e = battle.units.some((u) => u.team === "enemy" && u.alive);
    if (!e) finish(true);
    else if (!h) finish(false);
  }

  function finish(won) {
    if (battle.done) return;
    battle.done = true;
    const end = $("#battle-end");
    end.hidden = false;
    $("#end-title").textContent = won ? "Победа" : "Поражение";
    $("#end-title").style.color = won ? "var(--ok)" : "var(--danger)";
    const nextBtn = $("#btn-next-stage");
    if (won) {
      const s = battle.stage;
      state.soft += s.soft;
      state.xp += s.xp;
      state.cleared[s.id] = true;
      const idx = CATALOG.stages.findIndex((x) => x.id === s.id);
      const next = CATALOG.stages[idx + 1];
      if (next) state.activeStage = next.id;
      save();
      $("#end-reward").textContent = `+${s.soft} soft · +${s.xp} XP`;
      nextBtn.hidden = !next;
      nextBtn.textContent = next ? `Дальше · ${next.title}` : "Дальше";
    } else {
      $("#end-reward").textContent = "Смени партию и попробуй снова";
      nextBtn.hidden = true;
    }
  }

  function loop() {
    if (!battle || battle.done) return;
    const now = performance.now();
    const dt = ((now - battle.t0) / 1000) * battle.speed;
    battle.t0 = now;
    battle.elapsed += dt;
    const sec = Math.floor(battle.elapsed);
    $("#timer").textContent = `${String(Math.floor(sec / 60)).padStart(2, "0")}:${String(sec % 60).padStart(2, "0")}`;

    battle.units.forEach((u) => {
      if (!u.alive) return;
      u.energy = Math.min(100, u.energy + u.speed * dt * 0.35);
      if (u.energy >= 100) {
        u.energy = 0;
        act(u, false);
      }
    });
    refreshBattle();
    if (!battle.done) battle.raf = requestAnimationFrame(loop);
  }

  document.addEventListener("click", (e) => {
    const nav = e.target.closest("[data-nav]");
    if (nav) {
      go(nav.getAttribute("data-nav"));
      return;
    }
  });

  $("#btn-claim-afk").addEventListener("click", claimAfk);
  $("#btn-reset").addEventListener("click", () => {
    localStorage.removeItem(SAVE_KEY);
    state = defaultState();
    go("splash");
  });
  $("#btn-speed").addEventListener("click", () => {
    if (!battle) return;
    battle.speed = battle.speed < 1.5 ? 2 : 1;
    $("#btn-speed").textContent = battle.speed > 1.5 ? "×2" : "×1";
  });
  $("#btn-auto").addEventListener("click", () => {
    $("#toast").textContent = "Автобой включён";
  });
  $("#btn-next-stage").addEventListener("click", () => {
    go("battle");
  });

  load();
  renderTabbars("splash");
  go("splash");
})();
