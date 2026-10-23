const fs=require("fs"),path=require("path");const T={
  "Mod": {
    "name": [
      "Zombie Disguise",
      "Disfarce Zumbi"
    ],
    "description": [
    "Independent B42 mod with optional Field Medicine blood-exposure integration. The current camouflage backend remains unavailable while its native startup problem is investigated. Removing the medical dependency does not restore camouflage. No launcher changes are required to load this mod.",
    "Mod B42 independente com integração opcional de exposição ao sangue do Medicina de Campo. A camuflagem continua indisponível enquanto o problema de inicialização da extensão é investigado. Remover a dependência médica não recupera a camuflagem. Carregar este mod não exige mudanças no inicializador."
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
    "Camouflage is unavailable without a working perception backend. Native installation is suspended after a startup failure; do not reinstall the withdrawn extension. Field Medicine is optional. No blood is applied while camouflage is unavailable.",
    "Camuflagem indisponível sem um sistema de percepção funcional. A instalação nativa está suspensa após uma falha de inicialização; não reinstale a extensão retirada. Medicina de Campo é opcional. Nenhum sangue é aplicado enquanto a camuflagem estiver indisponível."
],
    "Tooltip_ZD_Peers": [
    "Waiting for the native companion acknowledgment from every connected client. A client without the extension disables new camouflage and revokes active camouflage.",
    "Aguardando a confirmação da extensão nativa de todos os clientes conectados. Um cliente sem a extensão impede novas camuflagens e encerra as ativas."
],
    "Tooltip_ZD_HealthDisabled": [
      "Optional Field Medicine integration is disabled; camouflage does not require it.",
      "A integração opcional do Medicina de Campo está desativada; a camuflagem não depende dela."
    ],
    "Tooltip_ZD_Risk": [
      "Apply blood to exposed skin. Default camouflage lasts 120 game minutes. Running or attacking breaks it. With Field Medicine installed and enabled, blood over wounds or the face can cause common illness. Wash actual blood off to reduce exposure; medicines do not renew camouflage.",
      "Aplique sangue sobre a pele. A camuflagem padrão dura 120 minutos de jogo. Correr ou atacar rompe o efeito. Com Medicina de Campo instalado e ativado, sangue em feridas ou rosto pode causar doenças comuns. Remova o sangue com lavagem para reduzir exposição; remédios não renovam camuflagem."
    ],
    "Tooltip_ZD_Dependency": [
      "Field Medicine is optional. Blood-exposure integration is used only when a compatible API v1 is enabled.",
      "Medicina de Campo é opcional. A integração de exposição ao sangue só é usada com a API v1 compatível e ativada."
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
