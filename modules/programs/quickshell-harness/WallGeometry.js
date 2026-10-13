.pragma library

const NW = 8, NE = 4, SW = 2, SE = 1;
const WALL_ABOVE = NW | NE, WALL_BELOW = SW | SE;
const WALL_LEFT = NW | SW, WALL_RIGHT = NE | SE;
const SOLID = 15;

function inside(r, x, y) {
    return x > r.x && x < r.x + r.w && y > r.y && y < r.y + r.h;
}

function clampRect(r, area) {
    const x0 = Math.max(r.x, area.x), y0 = Math.max(r.y, area.y);
    const x1 = Math.min(r.x + r.w, area.x + area.w), y1 = Math.min(r.y + r.h, area.y + area.h);
    return { x: x0, y: y0, w: Math.max(0, x1 - x0), h: Math.max(0, y1 - y0) };
}

function frameFor(win, area, reach, edgeReach) {
    let x0 = win.x - reach, y0 = win.y - reach;
    let x1 = win.x + win.w + reach, y1 = win.y + win.h + reach;
    if (win.x - area.x <= edgeReach + 1) x0 = area.x;
    if (win.y - area.y <= edgeReach + 1) y0 = area.y;
    if (area.x + area.w - (win.x + win.w) <= edgeReach + 1) x1 = area.x + area.w;
    if (area.y + area.h - (win.y + win.h) <= edgeReach + 1) y1 = area.y + area.h;
    return clampRect({ x: x0, y: y0, w: x1 - x0, h: y1 - y0 }, area);
}

function breakpoints(rects, lo, hi, pos, len) {
    const set = new Set([lo, hi]);
    for (const r of rects) {
        for (const v of [r[pos], r[pos] + r[len]]) {
            if (v > lo && v < hi) set.add(Math.round(v));
        }
    }
    return Array.from(set).sort((a, b) => a - b);
}

function compute(windows, area, reach, edgeReach, tileSize) {
    const holes = windows.map(w => clampRect(w, area)).filter(r => r.w > 0 && r.h > 0);
    const frames = holes.map(w => frameFor(w, area, reach, edgeReach));
    const all = holes.concat(frames);
    const xs = breakpoints(all, area.x, area.x + area.w, "x", "w");
    const ys = breakpoints(all, area.y, area.y + area.h, "y", "h");
    const cols = xs.length - 1, rows = ys.length - 1;

    const wall = [];
    for (let j = 0; j < rows; j++) {
        const row = [];
        const cy = (ys[j] + ys[j + 1]) / 2;
        for (let i = 0; i < cols; i++) {
            const cx = (xs[i] + xs[i + 1]) / 2;
            row.push(frames.some(f => inside(f, cx, cy)) && !holes.some(h => inside(h, cx, cy)));
        }
        wall.push(row);
    }

    const at = (i, j) => wall[Math.min(rows - 1, Math.max(0, j))][Math.min(cols - 1, Math.max(0, i))];

    const fills = [];
    for (let j = 0; j < rows; j++) {
        let start = -1;
        for (let i = 0; i <= cols; i++) {
            if (i < cols && wall[j][i]) {
                if (start < 0) start = i;
            } else if (start >= 0) {
                fills.push({ x: xs[start], y: ys[j], w: xs[i] - xs[start], h: ys[j + 1] - ys[j], tile: SOLID, aligned: true });
                start = -1;
            }
        }
    }

    const half = tileSize / 2;
    const pieces = [];
    if (rows <= 0 || cols <= 0) return { fills: fills, pieces: pieces };

    for (let j = 0; j <= rows; j++) {
        for (let i = 0; i <= cols; i++) {
            const tile = (at(i - 1, j - 1) ? NW : 0) | (at(i, j - 1) ? NE : 0)
                       | (at(i - 1, j) ? SW : 0) | (at(i, j) ? SE : 0);
            if (tile !== 0 && tile !== SOLID) {
                pieces.push({ x: xs[i] - half, y: ys[j] - half, w: tileSize, h: tileSize, tile: tile });
            }
        }
    }

    for (let j = 0; j <= rows; j++) {
        for (let i = 0; i < cols; i++) {
            const above = at(i, j - 1), below = at(i, j);
            const len = xs[i + 1] - xs[i] - tileSize;
            if (above !== below && len > 0) {
                pieces.push({ x: xs[i] + half, y: ys[j] - half, w: len, h: tileSize, tile: above ? WALL_ABOVE : WALL_BELOW });
            }
        }
    }

    for (let i = 0; i <= cols; i++) {
        for (let j = 0; j < rows; j++) {
            const left = at(i - 1, j), right = at(i, j);
            const len = ys[j + 1] - ys[j] - tileSize;
            if (left !== right && len > 0) {
                pieces.push({ x: xs[i] - half, y: ys[j] + half, w: tileSize, h: len, tile: left ? WALL_LEFT : WALL_RIGHT });
            }
        }
    }

    return { fills: fills, pieces: pieces };
}

function forMonitor(clients, monitor, width, height, opts) {
    const empty = { fills: [], pieces: [] };
    if (!monitor || !monitor.activeWorkspace) return empty;
    const onScreen = clients.filter(c => c.mapped && !c.hidden
        && c.workspace && c.workspace.id === monitor.activeWorkspace.id);
    if (onScreen.some(c => c.fullscreen > 0)) return empty;
    const reserved = monitor.reserved || [0, 0, 0, 0];
    const area = {
        x: reserved[0], y: reserved[1],
        w: width - reserved[0] - reserved[2], h: height - reserved[1] - reserved[3]
    };
    const windows = onScreen.map(c => ({ x: c.at[0] - monitor.x, y: c.at[1] - monitor.y, w: c.size[0], h: c.size[1] }));
    return compute(windows, area, opts.reach, opts.edgeReach, 8 * opts.pixelScale);
}
