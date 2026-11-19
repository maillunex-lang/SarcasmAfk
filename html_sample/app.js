(() => {
  const state = {
    soft: 1240,
    hard: 48,
    level: 3,
    power: 6280,
    afkHours: 2.4,
    screen: "splash",
    speed: 1,
    battle: null,
  };

  const heroes = [
    { id: "H01", name: "Каэрон", role: "tank", power: 1400, color: "#4ecdc4" },
    { id: "H02", name: "Вейриса", role: "mage", power: 1520, color: "#7aa2ff" },
    { id: "H03", name: "Эльдарион", role: "support", power: 1180, color: "#c9a227" },
    { id: "H04", name: "Рустам", role: "fighter", power: 1300, color: "#e35d6a" },
    { id: "H05", name: "Лейла", role: "ranger", power: 1220, color: "#5dcea0" },
  ];

  const stages = [
    { id: "S01", title: "Площадь талонов", open: true, cleared: true },
    { id: "S02", title: "Очередь у окна", open: true, cleared: false },
    { id: "S03", title: "Архив с характером", open: false, cleared: false },
  ];

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  function go(screen) {
    state.screen = screen;
    $$(".screen").forEach((el) => {
      el.hidden = el.dataset.screen !== screen;
    });
    if (screen === "battle") startBattle();
    if (screen === "afk") renderAfk();
    syncHud();
  }

  function syncHud() {
    const soft = $("#soft");
    const hard = $("#hard");
    const lvl = $("#lvl");
    const power = $("#power");
    if (soft) soft.textContent = String(state.soft);
    if (hard) hard.textContent = String(state.hard);
    if (lvl) lvl.textContent = String(state.level);
    if (power) power.textContent = String(state.power);
  }

  function renderCampaign() {
    const list = $("#stage-list");
    list.innerHTML = "";
    stages.forEach((s) => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="swatch" style="background:${s.cleared ? "var(--success)" : s.open ? "var(--gold)" : "var(--muted)"}"></div>
        <div class="meta">
          <strong>${s.id} · ${s.title}</strong>
          <span>${s.cleared ? "Пройдено" : s.open ? "Открыто" : "Закрыто"}</span>
        </div>
        <button ${s.open ? "" : "disabled"}>Бой</button>
      `;
      const btn = card.querySelector("button");
      if (s.open) {
        btn.textContent = "Бой";
        btn.addEventListener("click", () => {
          $("#chapter").textContent = `Глава 1 · ${s.title}`;
          go("battle");
        });
      } else {
        btn.textContent = "Закрыто";
      }
      list.appendChild(card);
    });
  }

  function renderHeroes() {
    const list = $("#hero-list");
    list.innerHTML = "";
    heroes.forEach((h) => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="swatch" style="background:${h.color}"></div>
        <div class="meta">
          <strong>${h.name}</strong>
          <span>${h.role} · сила ${h.power}</span>
        </div>
        <button type="button">В партии</button>
      `;
      list.appendChild(card);
    });
  }

  function renderAfk() {
    const pct = Math.min(100, (state.afkHours / 8) * 100);
    $("#afk-fill").style.width = `${pct}%`;
    $("#afk-hours").textContent = `Накоплено ${state.afkHours.toFixed(1)} ч / 8 ч`;
    const reward = Math.floor(state.afkHours * 90);
    $("#afk-reward").textContent = `+${reward} soft`;
  }

  function startBattle() {
    stopBattle();
    const end = $("#battle-end");
    end.hidden = true;
    state.speed = 1;
    $("#speed-btn").textContent = "×1";
    $("#toast").textContent = "Автобой";
    $("#timer").textContent = "00:00";

    const party = heroes.map((h, i) => ({
      id: h.id,
      name: h.name,
      color: h.color,
      team: "hero",
      hp: 1,
      energy: 0.2 * i,
      alive: true,
    }));
    const foes = [
      { id: "E1", name: "Талон", color: "#e35d6a", team: "enemy", hp: 1, energy: 0, alive: true },
      { id: "E2", name: "Печать", color: "#c45d7a", team: "enemy", hp: 1, energy: 0.1, alive: true },
      { id: "E3", name: "Очередь", color: "#a84d5f", team: "enemy", hp: 1, energy: 0.05, alive: true },
    ];

    state.battle = {
      t0: performance.now(),
      elapsed: 0,
      units: [...party, ...foes],
      raf: 0,
      done: false,
    };

    paintUnits();
    loopBattle();
  }

  function stopBattle() {
    if (state.battle?.raf) cancelAnimationFrame(state.battle.raf);
    state.battle = null;
  }

  function paintUnits() {
    const heroesEl = $("#side-heroes");
    const enemiesEl = $("#side-enemies");
    const portraits = $("#portraits");
    heroesEl.innerHTML = "";
    enemiesEl.innerHTML = "";
    portraits.innerHTML = "";

    state.battle.units.forEach((u) => {
      const node = document.createElement("div");
      node.className = `unit ${u.team === "enemy" ? "enemy" : ""} ${u.alive ? "" : "dead"}`;
      node.dataset.id = u.id;
      node.style.background = u.color;
      node.innerHTML = `<div class="hp"><i style="width:${Math.max(0, u.hp) * 100}%"></i></div><span class="name">${u.name}</span>`;
      (u.team === "hero" ? heroesEl : enemiesEl).appendChild(node);

      if (u.team === "hero") {
        const p = document.createElement("button");
        p.type = "button";
        p.className = "portrait";
        p.innerHTML = `<div class="face" style="background:${u.color}"></div><span>${u.name.slice(0, 6)}</span><div class="energy"><i style="width:${u.energy * 100}%"></i></div>`;
        p.addEventListener("click", () => {
          if (!u.alive || u.energy < 0.8) return;
          u.energy = 0;
          strike(u, true);
          $("#toast").textContent = `ULT · ${u.name}`;
        });
        portraits.appendChild(p);
      }
    });
  }

  function refreshBars() {
    state.battle.units.forEach((u) => {
      const node = $(`.unit[data-id="${u.id}"]`);
      if (!node) return;
      node.classList.toggle("dead", !u.alive);
      const bar = node.querySelector(".hp > i");
      if (bar) bar.style.width = `${Math.max(0, u.hp) * 100}%`;
    });
    $$("#portraits .portrait").forEach((p, i) => {
      const u = state.battle.units.filter((x) => x.team === "hero")[i];
      if (!u) return;
      const e = p.querySelector(".energy > i");
      if (e) e.style.width = `${u.energy * 100}%`;
    });
  }

  function strike(actor, ultimate = false) {
    const targets = state.battle.units.filter(
      (u) => u.alive && u.team !== actor.team
    );
    if (!targets.length) return;
    const target = targets[Math.floor(Math.random() * targets.length)];
    const dmg = ultimate ? 0.45 : 0.12 + Math.random() * 0.1;
    target.hp = Math.max(0, target.hp - dmg);
    if (target.hp <= 0) target.alive = false;
    const node = $(`.unit[data-id="${target.id}"]`);
    if (node) {
      node.classList.add("hit");
      setTimeout(() => node.classList.remove("hit"), 120);
    }
    $("#toast").textContent = `${actor.name} → ${target.name}`;
    refreshBars();
    checkEnd();
  }

  function checkEnd() {
    const heroesAlive = state.battle.units.some((u) => u.team === "hero" && u.alive);
    const enemiesAlive = state.battle.units.some((u) => u.team === "enemy" && u.alive);
    if (heroesAlive && enemiesAlive) return;
    state.battle.done = true;
    const won = heroesAlive;
    const end = $("#battle-end");
    end.hidden = false;
    $("#end-title").textContent = won ? "Победа" : "Поражение";
    $("#end-title").style.color = won ? "var(--success)" : "var(--danger)";
    if (won) {
      state.soft += 180;
      $("#end-reward").textContent = "+180 soft · этап открыт";
      stages[1].cleared = true;
      stages[2].open = true;
      syncHud();
    } else {
      $("#end-reward").textContent = "Попробуй сменить партию";
    }
  }

  function loopBattle() {
    const b = state.battle;
    if (!b || b.done) return;
    const now = performance.now();
    const dt = ((now - b.t0) / 1000) * state.speed;
    b.t0 = now;
    b.elapsed += dt;
    const sec = Math.floor(b.elapsed);
    $("#timer").textContent = `${String(Math.floor(sec / 60)).padStart(2, "0")}:${String(sec % 60).padStart(2, "0")}`;

    b.units.forEach((u) => {
      if (!u.alive) return;
      u.energy = Math.min(1, u.energy + dt * 0.18);
      if (u.energy >= 1) {
        u.energy = 0;
        strike(u, false);
      }
    });
    refreshBars();
    if (!b.done) b.raf = requestAnimationFrame(loopBattle);
  }

  document.addEventListener("click", (e) => {
    const goEl = e.target.closest("[data-go]");
    if (goEl) {
      go(goEl.getAttribute("data-go"));
      return;
    }
  });

  $("#claim-afk").addEventListener("click", () => {
    const reward = Math.floor(state.afkHours * 90);
    state.soft += reward;
    state.afkHours = 0.1;
    renderAfk();
    syncHud();
    $("#claim-afk").textContent = "Забрано";
    setTimeout(() => { $("#claim-afk").textContent = "Забрать"; }, 1200);
  });

  $("#speed-btn").addEventListener("click", () => {
    state.speed = state.speed < 1.5 ? 2 : 1;
    $("#speed-btn").textContent = state.speed > 1.5 ? "×2" : "×1";
  });

  $("#auto-btn").addEventListener("click", () => {
    $("#toast").textContent = "Автобой включён";
  });

  renderCampaign();
  renderHeroes();
  renderAfk();
  syncHud();
  go("splash");
})();
