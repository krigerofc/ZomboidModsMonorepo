const fs=require("fs"),path=require("path");const T={
  "Mod": {
    "name": [
      "Zombie Disguise",
      "Disfarce Zumbi"
    ],
    "description": [
    "Temporary blood disguise using the game's built-in ghost mode (invisibility). No native companion; Field Medicine is optional. Running, attacking, expiry, washing, death, disconnect and saving clear the temporary effect. This mode can affect visibility to other players and sound reactions. On inspected42.19.2, ordinary non-debug single-player is unsupported; multiplayer and debug single-player require actual gameplay validation.",
    "Disfarce temporário com a modo fantasma (invisibilidade) do próprio jogo. Sem extensão nativa; Medicina de Campo é opcional. Correr, atacar, expirar, lavar, morrer, desconectar ou salvar encerram o efeito. Este modo pode afetar a visibilidade para outros jogadores e a reação a sons. Na42.19.2 inspecionada, single-player comum sem depuração não é suportado; multiplayer e single-player com depuração precisam de validação em partida."
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
    "The game does not allow temporary invisibility in this context, or the public API is unavailable. Ordinary non-debug single-player is blocked on inspected42.19.2. No blood is applied when the effect is refused. No native extension is required.",
    "O jogo não permite invisibilidade temporária neste contexto, ou a API pública está indisponível. Single-player comum sem depuração está bloqueado na42.19.2 inspecionada. Nenhum sangue é aplicado quando o efeito é recusado. Não exige extensão nativa."
],
    "Tooltip_ZD_Peers": [
    "Waiting for every connected client to acknowledge this Lua invisibility version. Older versions or missing acknowledgments disable new disguises and revoke active effects.",
    "Aguardando a confirmação desta versão Lua de todos os clientes conectados. Versões antigas ou confirmações ausentes impedem novos disfarces e encerram os efeitos ativos."
],
    "Tooltip_ZD_HealthDisabled": [
      "Optional Field Medicine integration is disabled; camouflage does not require it.",
      "A integração opcional do Medicina de Campo está desativada; a camuflagem não depende dela."
    ],
    "Tooltip_ZD_Risk": [
      "Apply blood to exposed skin. Default duration is120 game minutes. Running, attacking or saving breaks it. Uses built-in ghost mode (invisibility), including its visibility and sound behavior. With Field Medicine installed and enabled, blood over wounds or the face can cause common illness. Wash actual blood off to reduce exposure; medicines do not renew camouflage.",
      "Aplique sangue sobre a pele. A duração padrão é120 minutos de jogo. Correr, atacar ou salvar rompe o efeito. Usa invisibilidade nativa, incluindo seu comportamento visual e sonoro. Com Medicina de Campo instalado e ativado, sangue em feridas ou rosto pode causar doenças comuns. Remova o sangue com lavagem para reduzir exposição; remédios não renovam camuflagem."
    ],
    "Tooltip_ZD_Dependency": [
      "Field Medicine is optional. Blood-exposure integration is used only when a compatible API v1 is enabled.",
      "Medicina de Campo é opcional. A integração de exposição ao sangue só é usada com a API v1 compatível e ativada."
    ],
    "Tooltip_ZD_Active": [
      "Existing disguise does not renew automatically. Saving, expiry or hostile activity ends it. With Field Medicine, residual blood exposure remains until washing.",
      "O disfarce existente não renova automaticamente. Salvar, expirar ou agir de forma hostil encerra o efeito. Com Medicina de Campo, a exposição residual permanece até a lavagem."
    ],
    "Tooltip_ZD_Reach": [
      "Use an accessible zombie corpse on the same floor within two tiles. Stay still until the action completes.",
      "Use cadáver zumbi acessível no mesmo piso a até dois quadrados. Fique parado até concluir a ação."
    ]
  },
  "Sandbox": {
    "Sandbox_ZombieDisguise": [
      "Zombie Disguise",
      "Disfarce Zumbi"
    ],
    "Sandbox_ZD_Enabled": [
      "Enable blood camouflage",
      "Ativar camuflagem com sangue"
    ],
    "Sandbox_ZD_Enabled_tooltip": [
      "Disabling removes only camouflage protection owned by this mod.",
      "Desativar remove apenas proteção de camuflagem pertencente a este mod."
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
