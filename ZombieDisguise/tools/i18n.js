const fs=require("fs"),path=require("path");const T={
  "Mod": {
    "name": [
      "Field Medicine: Zombie Disguise",
      "Medicina de Campo: Disfarce Zumbi"
    ],
    "description": [
    "Blood camouflage with shared Field Medicine exposure. Requires the supported native companion on the game and every multiplayer server/client. Actions stay unavailable when the native bridge or any client acknowledgment is missing. Running, attacking, expiry and washing end camouflage; residual blood remains a health risk until washed.",
    "Camuflagem com sangue e exposição compartilhada do Medicina de Campo. Exige a extensão nativa compatível no jogo e em todos os servidores/clientes multijogador. A ação fica indisponível sem a ponte nativa ou a confirmação de algum cliente. Correr, atacar, expirar e lavar encerram a camuflagem; o sangue residual mantém o risco à saúde até a lavagem."
]
  },
  "ContextMenu": {
    "ContextMenu_ZD_Apply": [
      "Apply zombie blood camouflage",
      "Aplicar camuflagem com sangue zumbi"
    ],
    "ContextMenu_ZD_Status": [
      "Camouflage: %1 game minutes left",
      "Camuflagem: restam %1 minutos de jogo"
    ]
  },
  "Tooltip": {
    "Tooltip_ZD_Backend": [
    "The supported native zombie-perception companion is missing or incompatible. Install it in the game and on every multiplayer server/client, then restart. No blood is applied without the bridge.",
    "A extensão nativa compatível de percepção dos zumbis está ausente ou é incompatível. Instale-a no jogo e em todos os servidores/clientes multijogador e reinicie. Nenhum sangue é aplicado sem a ponte."
],
    "Tooltip_ZD_Peers": [
    "Waiting for the native companion acknowledgment from every connected client. A client without the extension disables new camouflage and revokes active camouflage.",
    "Aguardando a confirmação da extensão nativa de todos os clientes conectados. Um cliente sem a extensão impede novas camuflagens e encerra as ativas."
],
    "Tooltip_ZD_HealthDisabled": [
      "Field Medicine is disabled in sandbox settings. Enable it before using this expansion.",
      "Medicina de Campo está desativado nas opções de sandbox. Ative-o antes de usar esta expansão."
    ],
    "Tooltip_ZD_Risk": [
      "Apply blood to exposed skin. Default camouflage lasts 120 game minutes. Running or attacking breaks it. Blood over wounds or the face can cause common illness through Field Medicine. Wash actual blood off to reduce exposure; medicines do not renew camouflage.",
      "Aplique sangue sobre a pele. A camuflagem padrão dura 120 minutos de jogo. Correr ou atacar rompe o efeito. Sangue em feridas ou rosto pode causar doenças comuns pelo Medicina de Campo. Remova o sangue com lavagem para reduzir exposição; remédios não renovam camuflagem."
    ],
    "Tooltip_ZD_Dependency": [
      "Requires a compatible Field Medicine (KRFieldMedicine) exposure API v1. Camouflage is unavailable.",
      "Exige Medicina de Campo (KRFieldMedicine) com API de exposição v1 compatível. Camuflagem indisponível."
    ],
    "Tooltip_ZD_Active": [
      "Existing camouflage does not renew automatically. Expiry or hostile activity leaves residual blood exposure until washing.",
      "A camuflagem existente não renova automaticamente. Expirar ou agir de forma hostil mantém exposição pelo sangue até a lavagem."
    ],
    "Tooltip_ZD_Reach": [
      "Use an accessible zombie corpse on the same floor within two tiles. Stay still until the action completes.",
      "Use cadáver zumbi acessível no mesmo piso a até dois quadrados. Fique parado até concluir a ação."
    ]
  },
  "Sandbox": {
    "Sandbox_ZombieDisguise": [
      "Field Medicine: Zombie Disguise",
      "Medicina de Campo: Disfarce Zumbi"
    ],
    "Sandbox_ZD_Enabled": [
      "Enable blood camouflage",
      "Ativar camuflagem com sangue"
    ],
    "Sandbox_ZD_Enabled_tooltip": [
      "Disabling removes only camouflage protection owned by this expansion.",
      "Desativar remove apenas proteção de camuflagem pertencente a esta expansão."
    ],
    "Sandbox_ZD_DurationMinutes": [
      "Camouflage duration (game minutes)",
      "Duração da camuflagem (minutos de jogo)"
    ],
    "Sandbox_ZD_DurationMinutes_tooltip": [
      "Default120. Expiry does not wash blood or cure illness.",
      "Padrão120. Expirar não lava sangue nem cura doenças."
    ],
    "Sandbox_ZD_RequiredCoverage": [
      "Required remaining blood coverage",
      "Cobertura de sangue restante exigida"
    ],
    "Sandbox_ZD_RequiredCoverage_tooltip": [
      "Default0.65. Uses actual regional blood, never wetness alone.",
      "Padrão0,65. Usa sangue real por região, nunca apenas umidade."
    ],
    "Sandbox_ZD_BreakOnRun": [
      "Running breaks camouflage",
      "Correr rompe a camuflagem"
    ],
    "Sandbox_ZD_BreakOnRun_tooltip": [
      "Running or sprinting breaks protection; exposure remains until washing.",
      "Correr ou disparar rompe a proteção; exposição permanece até a lavagem."
    ],
    "Sandbox_ZD_BreakOnAttack": [
      "Attacking breaks camouflage",
      "Atacar rompe a camuflagem"
    ],
    "Sandbox_ZD_BreakOnAttack_tooltip": [
      "Hostile actions break protection; exposure remains until washing.",
      "Ações hostis rompem a proteção; exposição permanece até a lavagem."
    ]
  }
};const root=path.resolve(__dirname,"../Contents/mods/ZombieDisguise/common/media/lua/shared/Translate");let stale=0;for(const [index,lang]of ["EN","PTBR"].entries())for(const [file,entries]of Object.entries(T)){const out=JSON.stringify(Object.fromEntries(Object.entries(entries).map(([k,v])=>[k,v[index]])),null,4)+"\n";const p=path.join(root,lang,file+".json");if(process.argv.includes("--check")){if(!fs.existsSync(p)||fs.readFileSync(p,"utf8")!==out){stale++;console.log("stale "+p)}}else{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,out)}}if(stale)process.exit(1);module.exports=T;
