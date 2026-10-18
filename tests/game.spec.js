const { test, expect } = require('@playwright/test');

async function openMenu(page, port = 8180) {
  await page.goto(`http://127.0.0.1:${port}`);
  await expect(page.getByRole('button', { name: 'Jugar' })).toBeVisible({ timeout: 30000 });
}

test('splash reaches menu and menu navigation returns from every screen', async ({ page }) => {
  const started = Date.now();
  await openMenu(page);
  expect(Date.now() - started).toBeLessThan(15000);
  for (const label of ['Marcadores', 'Configuración', 'Instrucciones']) {
    await page.getByRole('button', { name: label }).click();
    await expect(page.getByRole('button', { name: 'Volver' })).toBeVisible();
    await page.getByRole('button', { name: 'Volver' }).click();
    await expect(page.getByRole('button', { name: 'Jugar' })).toBeVisible();
  }
});

test('game moves, invalid tap, pause, resume and restart', async ({ page }) => {
  await openMenu(page);
  await page.getByRole('button', { name: 'Jugar' }).click();
  await expect(page.getByRole('button', { name: /^Ficha .*movible/ }).first()).toBeVisible();
  const hud = page.getByText(/Nivel .*Movimientos/).first();
  await expect(hud).toContainText('Movimientos 0');
  const movable = page.getByRole('button', { name: /Ficha .*movible/ }).first();
  await movable.click({ force: true });
  await expect(hud).toContainText('Movimientos 1');
  const invalid = page.getByRole('button', { name: /^Ficha (?!.*movible)/ }).first();
  if (await invalid.count()) {
    await invalid.click({ force: true });
    await expect(hud).toContainText('Movimientos 1');
  }
  await page.getByRole('button', { name: 'Pausa' }).click();
  await expect(page.getByRole('button', { name: 'Reanudar' })).toBeVisible();
  await expect(page.getByRole('group', { name: /Partida pausada/ })).toBeVisible();
  const pausedFrame = await stableScreenshot(page);
  await page.waitForTimeout(1200);
  expect((await stableScreenshot(page)).equals(pausedFrame)).toBe(true);
  await page.getByRole('button', { name: 'Reanudar' }).click();
  await page.getByRole('button', { name: 'Reiniciar' }).click();
  await expect(hud).toContainText('Movimientos 0');
});

async function stableScreenshot(page) {
  let previous = await page.screenshot();
  for (let attempt = 0; attempt < 12; attempt++) {
    await page.waitForTimeout(200);
    const current = await page.screenshot();
    if (current.equals(previous)) return current;
    previous = current;
  }
  return previous;
}

test('exit dialog can cancel and confirm back to menu', async ({ page }) => {
  await openMenu(page);
  await page.getByRole('button', { name: 'Jugar' }).click();
  await expect(page.getByRole('button', { name: /^Ficha .*movible/ }).first()).toBeVisible();
  await page.getByRole('button', { name: 'Salir' }).click();
  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toBeVisible();
  await dialog.getByRole('button', { name: 'Volver' }).click();
  await expect(page.getByRole('button', { name: 'Pausa' })).toBeVisible();
  await page.getByRole('button', { name: 'Salir' }).click();
  await expect(page.getByRole('alertdialog')).toBeVisible();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Salir' }).click();
  await expect(page.getByRole('button', { name: 'Jugar' })).toBeVisible();
});

test('one-move game wins, result actions work, and win appears in leaderboard', async ({ page }) => {
  await openMenu(page, 8181);
  await page.getByRole('button', { name: 'Jugar' }).click();
  const solution = (await findSolution(page)) ?? [3, 2, 5, 8];
  for (const tile of solution) await page.getByRole('button', { name: new RegExp(`^Ficha ${tile},`) }).click({ force: true });
  await expect(page.getByText(/¡Victoria!/).first()).toBeVisible({ timeout: 15000 });
  await expect(page.getByText('¡Nuevo récord!')).toBeVisible();
  await page.getByRole('button', { name: 'Jugar de nuevo' }).click();
  await expect(page.getByRole('button', { name: 'Pausa' })).toBeVisible();
  const replaySolution = (await findSolution(page)) ?? [3, 2, 5, 8];
  for (const tile of replaySolution) await page.getByRole('button', { name: new RegExp(`^Ficha ${tile},`) }).click({ force: true });
  await expect(page.getByText(/¡Victoria!/).first()).toBeVisible({ timeout: 15000 });
  await page.getByRole('button', { name: 'Menú' }).click();
  await expect(page.getByRole('button', { name: 'Jugar' })).toBeVisible();
  await page.getByRole('button', { name: 'Marcadores' }).click();
  await expect(page.getByRole('tabpanel')).toContainText('movimientos');
  await expect(page.getByRole('tabpanel')).toContainText('#1');
});

async function findSolution(page) {
  return page.evaluate(() => {
    const labels = [...document.querySelectorAll('flt-semantics[role="button"]')]
      .map(node => node.getAttribute('aria-label') || node.innerText || node.textContent)
      .filter(label => label.startsWith('Ficha '));
    const tiles = labels.map(label => {
      const match = label.match(/^Ficha (\d+), fila (\d+), columna (\d+)/);
      return match && { value: Number(match[1]), row: Number(match[2]) - 1, col: Number(match[3]) - 1 };
    }).filter(Boolean);
    if (tiles.length === 0) return null;
    const size = Math.max(...tiles.flatMap(tile => [tile.row + 1, tile.col + 1]));
    const start = Array(size * size).fill(0);
    for (const tile of tiles) start[tile.row * size + tile.col] = tile.value;
    const keyOf = state => state.join(',');
    const goal = Array.from({ length: size * size }, (_, i) => (i + 1) % (size * size));
    const queue = [{ state: start, path: [] }];
    const seen = new Set([keyOf(start)]);
    for (let head = 0; head < queue.length; head++) {
      const { state, path } = queue[head];
      if (keyOf(state) === keyOf(goal)) return path;
      const empty = state.indexOf(0);
      const r = Math.floor(empty / size), c = empty % size;
      const neighbors = [];
      if (r) neighbors.push(empty - size);
      if (r + 1 < size) neighbors.push(empty + size);
      if (c) neighbors.push(empty - 1);
      if (c + 1 < size) neighbors.push(empty + 1);
      for (const index of neighbors) {
        const next = state.slice();
        const tile = next[index];
        next[empty] = tile;
        next[index] = 0;
        const key = keyOf(next);
        if (!seen.has(key)) { seen.add(key); queue.push({ state: next, path: [...path, tile] }); }
      }
    }
    throw new Error('Board could not be solved');
  });
}

test('QA_SHUFFLE_MOVES=1 creates a one-move board', async ({ page }, testInfo) => {
  await openMenu(page, 8181);
  await page.getByRole('button', { name: 'Jugar' }).click();
  if (testInfo.project.name === 'chromium') await page.screenshot({ path: 'docs/qa/QA-002-shuffle-distance.png', fullPage: true });
  await expect(page.getByRole('button', { name: /^Ficha / }).first()).toBeVisible();
  expect(await findSolution(page)).toHaveLength(1);
});

test('timeout build produces defeat result', async ({ page }) => {
  await openMenu(page, 8182);
  await page.getByRole('button', { name: 'Jugar' }).click();
  await page.getByRole('button', { name: /^Ficha .*movible/ }).first().click();
  await expect(page.getByText(/Derrota/).first()).toBeVisible({ timeout: 20000 });
});

test('settings persist dark theme and sound off after reload', async ({ page }) => {
  await openMenu(page);
  await page.getByRole('button', { name: 'Configuración' }).click();
  await page.getByRole('button', { name: 'Volver' }).click();
  const lightMenu = await page.screenshot();
  await page.getByRole('button', { name: 'Configuración' }).click();
  await page.getByRole('button', { name: 'Oscuro' }).click();
  const sound = page.getByRole('switch', { name: /Sonido/ });
  if (await sound.getAttribute('aria-checked') === 'true') await sound.click();
  await page.getByRole('button', { name: 'Volver' }).click();
  const darkMenu = await page.screenshot();
  expect(darkMenu.equals(lightMenu)).toBe(false);
  await page.reload();
  await page.getByRole('button', { name: 'Configuración' }).click();
  await expect(page.getByRole('button', { name: 'Oscuro' })).toHaveAttribute('aria-current', 'true');
  await expect(page.getByRole('switch', { name: /Sonido/ })).toHaveAttribute('aria-checked', 'false');
});

test('Maestro 6x6 supports 30 rapid tile taps with frame sampling', async ({ page }, testInfo) => {
  test.skip(testInfo.project.name !== 'chromium', 'Performance sampling is limited to desktop Chromium');
  test.setTimeout(60000);
  await openMenu(page);
  await page.getByRole('button', { name: 'Configuración' }).click();
  const adaptive = page.getByRole('switch', { name: /Dificultad adaptativa/ });
  if (await adaptive.getAttribute('aria-checked') === 'true') await adaptive.click({ force: true });
  await expect(adaptive).toHaveAttribute('aria-checked', 'false');
  const level = page.getByRole('button', { name: /Nivel manual/ });
  await level.click();
  const maestro = page.getByRole('menuitem', { name: 'Maestro' });
  await expect(maestro).toBeVisible();
  await maestro.click();
  await expect(level).toContainText('Maestro');
  await page.reload();
  await page.getByRole('button', { name: 'Configuración' }).click();
  await expect(page.getByRole('button', { name: /Nivel manual/ })).toContainText('Maestro');
  await page.getByRole('button', { name: 'Volver' }).click();
  await page.getByRole('button', { name: 'Jugar' }).click();
  await expect(page.getByText(/Nivel Maestro/).first()).toBeVisible();
  await page.evaluate(() => {
    window.__qaFrameGaps = [];
    window.__qaLastFrame = performance.now();
    window.__qaSampling = true;
    const sample = now => {
      if (!window.__qaSampling) return;
      window.__qaFrameGaps.push(now - window.__qaLastFrame);
      window.__qaLastFrame = now;
      requestAnimationFrame(sample);
    };
    requestAnimationFrame(sample);
  });
  const start = Date.now();
  for (let i = 0; i < 30; i++) {
    const tile = page.getByRole('button', { name: /^Ficha .*movible/ }).first();
    await tile.click();
  }
  const elapsed = Date.now() - start;
  const frameGaps = await page.evaluate(() => { window.__qaSampling = false; return window.__qaFrameGaps; });
  // The first gap includes warm-up; headless Chromium often paints at 30 fps
  // (33 ms), so only gaps over 50 ms count as dropped frames.
  const steady = frameGaps.slice(1);
  const drops = steady.filter(gap => gap > 50).length;
  console.log(`30 taps: ${elapsed} ms; frames ${frameGaps.length}; >50ms ${drops}; worst ${Math.round(Math.max(...steady))} ms`);
  expect(drops).toBeLessThan(5);
  expect(elapsed).toBeLessThan(45000);
  expect(frameGaps.length).toBeGreaterThan(0);
});

test('HUD exposes the required individual accessible labels', async ({ page }, testInfo) => {
  await openMenu(page);
  await page.getByRole('button', { name: 'Jugar' }).click();
  if (testInfo.project.name === 'chromium') await page.screenshot({ path: 'docs/qa/QA-001-hud-semantics.png', fullPage: true });
  // Flutter web renders label-only semantics nodes as text content (no
  // aria-label), so assert one dedicated leaf node per metric by exact text.
  const leaf = text => page.locator('flt-semantics:not(:has(flt-semantics))').filter({ hasText: text });
  await expect(leaf(/^Movimientos 0$/)).toHaveCount(1);
  await expect(leaf(/^Tiempo \d\d:\d\d$/)).toHaveCount(1);
  await expect(leaf(/^Nivel \S+$/)).toHaveCount(1);
});

test('adaptive difficulty control is enabled for keyboard and screen reader users', async ({ page }, testInfo) => {
  await openMenu(page);
  await page.getByRole('button', { name: 'Configuración' }).click();
  if (testInfo.project.name === 'chromium') await page.screenshot({ path: 'docs/qa/QA-003-adaptive-control.png', fullPage: true });
  await expect(page.getByRole('switch', { name: /Dificultad adaptativa/ })).toBeEnabled();
});

test('buttons are keyboard focusable and layout fits the viewport', async ({ page }) => {
  await openMenu(page);
  const buttons = page.getByRole('button');
  await expect(buttons.first()).toBeVisible();
  await page.keyboard.press('Tab');
  await expect(page.locator(':focus')).toHaveCount(1);
  await page.getByRole('button', { name: 'Jugar' }).click();
  await expect(page.getByRole('button', { name: 'Pausa' })).toBeVisible();
  const tileButtons = page.getByRole('button', { name: /^Ficha/ });
  for (let i = 0; i < await tileButtons.count(); i++) {
    const bounds = await tileButtons.nth(i).boundingBox();
    expect(bounds).not.toBeNull();
    expect(bounds.x).toBeGreaterThanOrEqual(0);
    expect(bounds.y).toBeGreaterThanOrEqual(0);
    expect(bounds.x + bounds.width).toBeLessThanOrEqual(page.viewportSize().width + 1);
    expect(bounds.y + bounds.height).toBeLessThanOrEqual(page.viewportSize().height + 1);
  }
  for (const label of ['Pausa', 'Reiniciar', 'Salir']) {
    await expect(page.getByRole('button', { name: label })).toBeInViewport();
  }
});

test('no browser console errors during menu and game startup', async ({ page }) => {
  const errors = [];
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  page.on('pageerror', error => errors.push(error.message));
  await openMenu(page);
  await page.getByRole('button', { name: 'Jugar' }).click();
  await expect(page.getByRole('button', { name: 'Pausa' })).toBeVisible();
  expect(errors).toEqual([]);
});

