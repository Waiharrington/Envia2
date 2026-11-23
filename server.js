const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const fs = require("node:fs");
const fsp = require("node:fs/promises");
const crypto = require("node:crypto");
const sea = require("node:sea");
const { spawn } = require("node:child_process");
const { pipeline } = require("node:stream/promises");

const ASSET_ROOT = __dirname;
const IS_EXE = sea.isSea();
const DATA_ROOT = IS_EXE ? path.dirname(process.execPath) : __dirname;
const INBOX = path.join(DATA_ROOT, "Archivos recibidos");
let PORT = Number(process.env.PORT || 53317);
const FIXED_PORT = Boolean(process.env.PORT);
const MAX_FILE_BYTES = 2 * 1024 * 1024 * 1024;
const PIN = "160620";
const sessions = new Set();
const folderSessions = new Map();

function localAddresses() {
  const found = [];
  for (const entries of Object.values(os.networkInterfaces())) {
    for (const entry of entries || []) {
      if (entry.family === "IPv4" && !entry.internal) found.push(entry.address);
    }
  }
  return [...new Set(found)];
}

function json(res, status, value) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  res.end(JSON.stringify(value));
}

function authorized(req) {
  const token = (req.headers.authorization || "").replace(/^Bearer\s+/i, "");
  return token && sessions.has(token);
}

function cleanName(raw) {
  let name;
  try { name = decodeURIComponent(raw || "archivo"); } catch { name = "archivo"; }
  name = path.basename(name).replace(/[\x00-\x1f<>:"/\\|?*]/g, "_").trim();
  return (name || "archivo").slice(0, 180);
}

function cleanRelativePath(raw) {
  let value;
  try { value = decodeURIComponent(raw || ""); } catch { value = ""; }
  const parts = value.replace(/\\/g, "/").split("/").filter(Boolean).map(cleanName);
  return parts.filter(part => part !== "." && part !== "..").join(path.sep);
}

async function uniqueFolderName(requested) {
  const base = cleanName(requested).replace(/\.+$/g, "") || "Carpeta";
  let candidate = base;
  let number = 2;
  while (true) {
    try { await fsp.access(path.join(INBOX, candidate)); candidate = `${base} (${number++})`; }
    catch { return candidate; }
  }
}

function compressFolder(source, destination) {
  const command = `Compress-Archive -LiteralPath $env:ENVIA2_SOURCE -DestinationPath $env:ENVIA2_DESTINATION -Force`;
  return new Promise((resolve, reject) => {
    const child = spawn("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", command], {
      windowsHide: true,
      env: { ...process.env, ENVIA2_SOURCE: source, ENVIA2_DESTINATION: destination }
    });
    let errorText = "";
    child.stderr.on("data", chunk => { errorText += chunk; });
    child.on("error", reject);
    child.on("exit", code => code === 0 ? resolve() : reject(new Error(errorText || `PowerShell terminó con código ${code}.`)));
  });
}

async function readFiles() {
  const entries = await fsp.readdir(INBOX, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith(".json")) continue;
    try {
      const item = JSON.parse(await fsp.readFile(path.join(INBOX, entry.name), "utf8"));
      const stat = await fsp.stat(path.join(INBOX, item.diskName));
      files.push({ id: item.id, name: item.name, size: stat.size, uploadedAt: item.uploadedAt });
    } catch { /* Ignore incomplete or stale entries. */ }
  }
  return files.sort((a, b) => b.uploadedAt.localeCompare(a.uploadedAt));
}

async function handle(req, res) {
  const url = new URL(req.url, "http://localhost");
  if (req.method === "GET" && url.pathname === "/") {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
    if (IS_EXE) res.end(Buffer.from(sea.getAsset("index.html")));
    else fs.createReadStream(path.join(ASSET_ROOT, "index.html")).pipe(res);
    return;
  }
  if (req.method === "GET" && url.pathname === "/api/info") {
    return json(res, 200, { port: PORT, addresses: localAddresses(), maxFileBytes: MAX_FILE_BYTES });
  }
  if (req.method === "GET" && url.pathname === "/favicon.ico") {
    res.writeHead(204, { "cache-control": "public, max-age=86400" });
    return res.end();
  }
  if (req.method === "POST" && url.pathname === "/api/login") {
    let body = "";
    for await (const chunk of req) body += chunk;
    let pin;
    try { pin = JSON.parse(body).pin; } catch { return json(res, 400, { error: "Solicitud inválida." }); }
    if (pin !== PIN) return json(res, 401, { error: "El código no coincide." });
    const token = crypto.randomBytes(24).toString("hex");
    sessions.add(token);
    return json(res, 200, { token });
  }
  if (!authorized(req)) return json(res, 401, { error: "Ingresa el código de esta sala." });

  if (req.method === "GET" && url.pathname === "/api/files") {
    return json(res, 200, { files: await readFiles() });
  }
  if (req.method === "POST" && url.pathname === "/api/folders/start") {
    let body = "";
    for await (const chunk of req) body += chunk;
    let requestedName;
    try { requestedName = JSON.parse(body).name; } catch { return json(res, 400, { error: "Nombre de carpeta inválido." }); }
    const folderId = crypto.randomUUID();
    const folderName = await uniqueFolderName(requestedName);
    const folderPath = path.join(INBOX, folderName);
    await fsp.mkdir(folderPath, { recursive: true });
    folderSessions.set(folderId, { folderName, folderPath });
    return json(res, 201, { folderId, folderName });
  }
  if (req.method === "POST" && url.pathname === "/api/folders/finish") {
    let body = "";
    for await (const chunk of req) body += chunk;
    let folderId;
    try { folderId = JSON.parse(body).folderId; } catch { return json(res, 400, { error: "Carpeta inválida." }); }
    const folder = folderSessions.get(folderId);
    if (!folder) return json(res, 404, { error: "La carpeta ya no está disponible." });
    const id = crypto.randomUUID();
    const diskName = `${id}.zip`;
    try {
      await compressFolder(folder.folderPath, path.join(INBOX, diskName));
      const item = { id, diskName, name: `${folder.folderName}.zip`, uploadedAt: new Date().toISOString() };
      await fsp.writeFile(path.join(INBOX, `${id}.json`), JSON.stringify(item), { flag: "wx" });
      folderSessions.delete(folderId);
      return json(res, 201, { id, name: item.name });
    } catch (error) {
      console.error(error);
      return json(res, 500, { error: "No se pudo preparar la carpeta para descargar." });
    }
  }
  if (req.method === "POST" && url.pathname === "/api/files") {
    const length = Number(req.headers["content-length"] || 0);
    if (length > MAX_FILE_BYTES) { req.resume(); return json(res, 413, { error: "El archivo supera el límite de 2 GB." }); }
    const folder = folderSessions.get(String(req.headers["x-folder-id"] || ""));
    const relativePath = cleanRelativePath(req.headers["x-relative-path"]);
    const id = crypto.randomUUID();
    const diskName = `${id}.data`;
    const destination = folder && relativePath ? path.join(folder.folderPath, relativePath) : path.join(INBOX, diskName);
    let size = 0;
    req.on("data", chunk => { size += chunk.length; });
    try {
      await fsp.mkdir(path.dirname(destination), { recursive: true });
      await pipeline(req, fs.createWriteStream(destination, { flags: "wx" }));
      if (size > MAX_FILE_BYTES) {
        await fsp.rm(destination, { force: true });
        return json(res, 413, { error: "El archivo supera el límite de 2 GB." });
      }
      const item = { id, diskName, name: cleanName(req.headers["x-file-name"]), uploadedAt: new Date().toISOString() };
      if (!folder) await fsp.writeFile(path.join(INBOX, `${id}.json`), JSON.stringify(item), { flag: "wx" });
      return json(res, 201, { id, name: item.name, size });
    } catch (error) {
      await fsp.rm(destination, { force: true }).catch(() => {});
      if (!res.headersSent) return json(res, 500, { error: "No se pudo guardar el archivo." });
    }
    return;
  }
  const download = url.pathname.match(/^\/api\/files\/([0-9a-f-]+)$/i);
  if (req.method === "GET" && download) {
    const id = download[1];
    try {
      const item = JSON.parse(await fsp.readFile(path.join(INBOX, `${id}.json`), "utf8"));
      res.writeHead(200, {
        "content-type": "application/octet-stream",
        "content-length": (await fsp.stat(path.join(INBOX, item.diskName))).size,
        "content-disposition": `attachment; filename*=UTF-8''${encodeURIComponent(item.name)}`,
        "cache-control": "no-store"
      });
      fs.createReadStream(path.join(INBOX, item.diskName)).pipe(res);
    } catch { json(res, 404, { error: "El archivo ya no está disponible." }); }
    return;
  }
  return json(res, 404, { error: "No encontrado." });
}

async function main() {
  await fsp.mkdir(INBOX, { recursive: true });
  const server = http.createServer((req, res) => {
    handle(req, res).catch(error => {
      console.error(error);
      if (!res.headersSent) json(res, 500, { error: "Ocurrió un error inesperado." });
    });
  });
  server.on("error", error => {
    if (error.code === "EADDRINUSE" && !FIXED_PORT && PORT < 65535) {
      PORT += 1;
      server.listen(PORT, "0.0.0.0");
      return;
    }
    console.error(error);
    process.exitCode = 1;
  });
  server.listen(PORT, "0.0.0.0", () => {
    const addresses = localAddresses();
    console.log("Envia2 está listo en tu red local.");
    console.log(`En esta computadora: http://localhost:${PORT}`);
    for (const address of addresses) console.log(`En otros dispositivos: http://${address}:${PORT}`);
    console.log(`Código de acceso: ${PIN}`);
    console.log("Mantén esta ventana abierta mientras compartes archivos. Ctrl+C para cerrar.");
  });
}

main().catch(error => { console.error(error); process.exitCode = 1; });
