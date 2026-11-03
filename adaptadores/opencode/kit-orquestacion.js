// Adaptador OpenCode: plugin con el hook tool.execute.before para la herramienta bash.
// OpenCode no tiene "ask" en los hooks: lo irreversible se niega lanzando un error con el motivo.
// La ruta del kit sale de KIT_ORQUESTACION o se fija al instalar (install.sh la reemplaza).
import { spawnSync } from "node:child_process";

const KIT = process.env.KIT_ORQUESTACION || "__KIT__";

export const KitOrquestacion = async () => ({
  "tool.execute.before": async (input, output) => {
    if (input.tool !== "bash") return;
    const cmd = output?.args?.command ?? "";
    const r = spawnSync(`${KIT}/reglas/evaluar.sh`, [cmd], { encoding: "utf8" });
    const [decision, motivo] = (r.stdout || "allow").trim().split("\t");
    if (decision === "deny") throw new Error(motivo);
    if (decision === "ask") throw new Error(`${motivo} (pedile a la persona que lo corra)`);
  },
});
