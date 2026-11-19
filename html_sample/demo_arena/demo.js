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
  const stage = document.getElementById("arena-stage");
  const canvas = document.getElementById("fx-layer");
  const ctx = canvas.getContext("2d");

  const SPRITES = {
    hero: {
      idle: "assets/hero_idle.png",
      run: "assets/hero_run.png",
      attack: "assets/hero_attack.png",
    },
    enemy: {
      idle: "assets/enemy_idle.png",
      run: "assets/enemy_run.png",
      attack: "assets/enemy_attack.png",
    },
  };

  let gold = 1200;
  let speed = 1;
  let battle = null;
  let particles = [];

  function show(id) {
    document.getElementById("screen-menu").hidden = id !== "menu";
    document.getElementById("screen-arena").hidden = id !== "arena";
  }

  function resizeCanvas() {
    const parent = canvas.parentElement;
    canvas.width = parent.clientWidth * devicePixelRatio;
    canvas.height = parent.clientHeight * devicePixelRatio;
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  }

  function spriteImg(el) {
    return el.querySelector("[data-role=sprite]");
  }

  function setPose(who, pose) {
    const el = who === "hero" ? heroEl : enemyEl;
    const img = spriteImg(el);
    const src = SPRITES[who][pose] || SPRITES[who].idle;
    if (img.getAttribute("src") !== src) img.setAttribute("src", src);
    el.dataset.pose = pose;
    el.classList.toggle("run", pose === "run");
  }

  function clearAnimClasses(el) {
    el.classList.remove("idle", "enter", "run", "attack", "hurt", "dead");
  }

  function setIdle(on) {
    if (on) {
      if (!heroEl.classList.contains("dead")) {
        clearAnimClasses(heroEl);
        setPose("hero", "idle");
        heroEl.classList.add("idle");
      }
      if (!enemyEl.classList.contains("dead")) {
        clearAnimClasses(enemyEl);
        setPose("enemy", "idle");
        enemyEl.classList.add("idle");
      }
    } else {
      heroEl.classList.remove("idle");
      enemyEl.classList.remove("idle");
    }
  }

  function spawnBurst(x, y, color) {
    for (let i = 0; i < 22; i++) {
      const a = Math.random() * Math.PI * 2;
      const sp = 80 + Math.random() * 160;
      particles.push({
        x, y,
        vx: Math.cos(a) * sp,
        vy: Math.sin(a) * sp - 50,
        life: 0.3 + Math.random() * 0.4,
        age: 0,
        color,
        size: 2 + Math.random() * 3.5,
      });
    }
  }

  function playVfx(towardEnemy) {
    slash.hidden = false;
    burst.hidden = false;
    slash.classList.remove("show");
    burst.classList.remove("show");
    void slash.offsetWidth;
    slash.style.left = towardEnemy ? "26%" : "16%";
    slash.style.transform = towardEnemy ? "scaleX(1)" : "scaleX(-1)";
    burst.style.left = towardEnemy ? "50%" : "16%";
    slash.classList.add("show");
    burst.classList.add("show");
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    spawnBurst(towardEnemy ? w * 0.7 : w * 0.3, h * 0.55, towardEnemy ? "#4ecdc4" : "#e35d6a");
    stage.classList.remove("shake");
    void stage.offsetWidth;
    stage.classList.add("shake");
  }

  function attack(attackerIsHero) {
    if (!battle || battle.done || battle.phase !== "fight") return;
    const who = attackerIsHero ? "hero" : "enemy";
    const atkEl = attackerIsHero ? heroEl : enemyEl;
    const defEl = attackerIsHero ? enemyEl : heroEl;
    if (atkEl.classList.contains("dead") || defEl.classList.contains("dead")) return;

    setIdle(false);
    clearAnimClasses(atkEl);
    setPose(who, "attack");
    void atkEl.offsetWidth;
    atkEl.classList.add("attack");

    const dmg =
      (attackerIsHero ? 10 + Math.random() * 8 : 7 + Math.random() * 6) *
      (battle.ultNext && attackerIsHero ? 2.4 : 1);
    if (attackerIsHero) battle.ultNext = false;

    // Impact mid-lunge
    setTimeout(() => {
      if (!battle || battle.done) return;
      playVfx(attackerIsHero);
      if (attackerIsHero) {
        battle.enemyHp = Math.max(0, battle.enemyHp - dmg);
        enemyHp.style.width = `${(battle.enemyHp / battle.enemyMax) * 100}%`;
      } else {
        battle.heroHp = Math.max(0, battle.heroHp - dmg);
        heroHp.style.width = `${(battle.heroHp / battle.heroMax) * 100}%`;
      }
      clearAnimClasses(defEl);
      void defEl.offsetWidth;
      defEl.classList.add("hurt");
      toast.textContent = attackerIsHero
        ? `Каэрон бьёт · −${Math.round(dmg)}`
        : `Печать отвечает · −${Math.round(dmg)}`;

      if (battle.enemyHp <= 0 || battle.heroHp <= 0) {
        finish(battle.enemyHp <= 0);
      } else {
        setTimeout(() => {
          if (!battle || battle.done) return;
          defEl.classList.remove("hurt");
          if (!defEl.classList.contains("dead")) {
            setPose(attackerIsHero ? "enemy" : "hero", "idle");
            defEl.classList.add("idle");
          }
        }, 320);
      }
    }, 200);

    setTimeout(() => {
      if (!battle) return;
      atkEl.classList.remove("attack");
      if (!atkEl.classList.contains("dead") && battle.phase === "fight" && !battle.done) {
        setPose(who, "idle");
        atkEl.classList.add("idle");
      }
    }, 500);
  }

  function finish(won) {
    battle.done = true;
    battle.phase = "end";
    setIdle(false);
    const loser = won ? enemyEl : heroEl;
    const winner = won ? heroEl : enemyEl;
    clearAnimClasses(loser);
    loser.classList.add("dead");
    clearAnimClasses(winner);
    setPose(won ? "hero" : "enemy", "idle");
    winner.classList.add("idle");

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

  function runEnter() {
    battle.phase = "enter";
    toast.textContent = "Сближение…";
    clearAnimClasses(heroEl);
    clearAnimClasses(enemyEl);
    heroEl.style.opacity = "1";
    enemyEl.style.opacity = "1";
    setPose("hero", "run");
    setPose("enemy", "run");
    heroEl.classList.add("enter", "run");
    enemyEl.classList.add("enter", "run");

    setTimeout(() => {
      if (!battle) return;
      clearAnimClasses(heroEl);
      clearAnimClasses(enemyEl);
      setPose("hero", "idle");
      setPose("enemy", "idle");
      heroEl.classList.add("idle");
      enemyEl.classList.add("idle");
      battle.phase = "fight";
      battle.nextHero = 0.55;
      battle.nextEnemy = 1.05;
      toast.textContent = "Автобой";
    }, 1100 / Math.max(0.5, speed));
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
      phase: "enter",
      nextHero: 999,
      nextEnemy: 999,
      ultNext: false,
    };
    heroHp.style.width = "100%";
    enemyHp.style.width = "100%";
    endBox.hidden = true;
    particles = [];
    show("arena");
    runEnter();
    loop();
  }

  function stopBattle() {
    if (battle?.raf) cancelAnimationFrame(battle.raf);
    battle = null;
    particles = [];
    clearAnimClasses(heroEl);
    clearAnimClasses(enemyEl);
    setPose("hero", "idle");
    setPose("enemy", "idle");
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
      if (battle.phase === "fight") {
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
    }

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
    if (!battle || battle.done || battle.phase !== "fight") return;
    if (battle.energy < 70) {
      toast.textContent = "ULT ещё копится…";
      return;
    }
    battle.energy = 0;
    battle.ultNext = true;
    toast.textContent = "ULT готов!";
    attack(true);
  });

  // Preload poses so first attack/run doesn't hitch
  Object.values(SPRITES).forEach((set) => {
    Object.values(set).forEach((src) => {
      const i = new Image();
      i.src = src;
    });
  });

  window.addEventListener("resize", resizeCanvas);
  show("menu");
})();
