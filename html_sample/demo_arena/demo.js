(() => {
  const heroEl = document.getElementById("hero");
  const enemyEl = document.getElementById("enemy");
  const heroHp = document.getElementById("hero-hp");
  const enemyHp = document.getElementById("enemy-hp");
  const toast = document.getElementById("toast");
  const timerEl = document.getElementById("timer");
  const slash = document.getElementById("slash");
  const burst = document.getElementById("burst");
  const endBox = document.getElementById("end");
  const canvas = document.getElementById("fx-layer");
  const ctx = canvas.getContext("2d");

  let gold = 1200;
  let speed = 1;
  let battle = null;
  let particles = [];

  function show(id) {
    document.getElementById("screen-menu").hidden = id !== "menu";
    document.getElementById("screen-arena").hidden = id !== "arena";
  }

  function resizeCanvas() {
    const stage = canvas.parentElement;
    canvas.width = stage.clientWidth * devicePixelRatio;
    canvas.height = stage.clientHeight * devicePixelRatio;
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  }

  function setIdle(on) {
    heroEl.classList.toggle("idle", on);
    enemyEl.classList.toggle("idle", on);
  }

  function spawnBurst(x, y, color) {
    for (let i = 0; i < 18; i++) {
      const a = Math.random() * Math.PI * 2;
      const sp = 60 + Math.random() * 140;
      particles.push({
        x, y,
        vx: Math.cos(a) * sp,
        vy: Math.sin(a) * sp - 40,
        life: 0.35 + Math.random() * 0.35,
        age: 0,
        color,
        size: 2 + Math.random() * 3,
      });
    }
  }

  function playVfx(towardEnemy) {
    slash.hidden = false;
    burst.hidden = false;
    slash.classList.remove("show");
    burst.classList.remove("show");
    // force reflow
    void slash.offsetWidth;
    slash.style.left = towardEnemy ? "28%" : "18%";
    burst.style.left = towardEnemy ? "48%" : "18%";
    slash.classList.add("show");
    burst.classList.add("show");
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    spawnBurst(towardEnemy ? w * 0.68 : w * 0.32, h * 0.55, towardEnemy ? "#4ecdc4" : "#e35d6a");
  }

  function attack(attackerIsHero) {
    if (!battle || battle.done) return;
    const atkEl = attackerIsHero ? heroEl : enemyEl;
    const defEl = attackerIsHero ? enemyEl : heroEl;
    setIdle(false);
    atkEl.classList.remove("attack");
    void atkEl.offsetWidth;
    atkEl.classList.add("attack");
    playVfx(attackerIsHero);

    const dmg = (attackerIsHero ? 9 + Math.random() * 7 : 7 + Math.random() * 6) * (battle.ultNext && attackerIsHero ? 2.4 : 1);
    if (attackerIsHero) battle.ultNext = false;

    setTimeout(() => {
      if (!battle || battle.done) return;
      if (attackerIsHero) {
        battle.enemyHp = Math.max(0, battle.enemyHp - dmg);
        enemyHp.style.width = `${(battle.enemyHp / battle.enemyMax) * 100}%`;
      } else {
        battle.heroHp = Math.max(0, battle.heroHp - dmg);
        heroHp.style.width = `${(battle.heroHp / battle.heroMax) * 100}%`;
      }
      defEl.classList.remove("hurt");
      void defEl.offsetWidth;
      defEl.classList.add("hurt");
      toast.textContent = attackerIsHero
        ? `Каэрон бьёт · −${Math.round(dmg)}`
        : `Печать отвечает · −${Math.round(dmg)}`;
      if (battle.enemyHp <= 0 || battle.heroHp <= 0) finish(battle.enemyHp <= 0);
      else setTimeout(() => { if (battle && !battle.done) setIdle(true); }, 120);
    }, 180);

    setTimeout(() => atkEl.classList.remove("attack"), 450);
  }

  function finish(won) {
    battle.done = true;
    setIdle(false);
    endBox.hidden = false;
    const title = document.getElementById("end-title");
    title.textContent = won ? "Победа" : "Поражение";
    title.style.color = won ? "var(--ok)" : "var(--danger)";
    if (won) {
      gold += 180;
      document.getElementById("gold").textContent = String(gold);
      toast.textContent = "+180 soft";
    } else {
      toast.textContent = "Печать победила…";
    }
  }

  function startBattle() {
    resizeCanvas();
    battle = {
      heroHp: 100,
      heroMax: 100,
      enemyHp: 100,
      enemyMax: 100,
      energy: 0,
      elapsed: 0,
      t0: performance.now(),
      raf: 0,
      done: false,
      nextHero: 1.1,
      nextEnemy: 1.6,
      ultNext: false,
    };
    heroHp.style.width = "100%";
    enemyHp.style.width = "100%";
    endBox.hidden = true;
    toast.textContent = "Автобой";
    setIdle(true);
    show("arena");
    loop();
  }

  function stopBattle() {
    if (battle?.raf) cancelAnimationFrame(battle.raf);
    battle = null;
    particles = [];
  }

  function loop() {
    if (!battle) return;
    const now = performance.now();
    const dt = ((now - battle.t0) / 1000) * speed;
    battle.t0 = now;
    if (!battle.done) {
      battle.elapsed += dt;
      const sec = Math.floor(battle.elapsed);
      timerEl.textContent = `${String(Math.floor(sec / 60)).padStart(2, "0")}:${String(sec % 60).padStart(2, "0")}`;
      battle.nextHero -= dt;
      battle.nextEnemy -= dt;
      battle.energy = Math.min(100, battle.energy + dt * 22);
      if (battle.nextHero <= 0) {
        battle.nextHero = 1.05 + Math.random() * 0.35;
        attack(true);
      }
      if (!battle.done && battle.nextEnemy <= 0) {
        battle.nextEnemy = 1.25 + Math.random() * 0.45;
        attack(false);
      }
    }

    // particles
    ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
    particles = particles.filter((p) => {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 220 * dt;
      const t = 1 - p.age / p.life;
      if (t <= 0) return false;
      ctx.globalAlpha = Math.max(0, t);
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size * t, 0, Math.PI * 2);
      ctx.fill();
      return true;
    });
    ctx.globalAlpha = 1;

    battle.raf = requestAnimationFrame(loop);
  }

  document.getElementById("btn-fight").addEventListener("click", () => {
    stopBattle();
    startBattle();
  });
  document.getElementById("btn-menu").addEventListener("click", () => {
    stopBattle();
    show("menu");
  });
  document.getElementById("btn-again").addEventListener("click", () => {
    stopBattle();
    startBattle();
  });
  document.getElementById("btn-speed").addEventListener("click", (e) => {
    speed = speed < 1.5 ? 2 : 1;
    e.currentTarget.textContent = speed > 1.5 ? "×2" : "×1";
  });
  document.getElementById("btn-ult").addEventListener("click", () => {
    if (!battle || battle.done) return;
    if (battle.energy < 70) {
      toast.textContent = "ULT ещё копится…";
      return;
    }
    battle.energy = 0;
    battle.ultNext = true;
    toast.textContent = "ULT готов!";
    attack(true);
  });

  window.addEventListener("resize", resizeCanvas);
  show("menu");
})();
