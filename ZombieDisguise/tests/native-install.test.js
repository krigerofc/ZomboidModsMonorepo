const {test}=require("node:test");
const assert=require("node:assert/strict"),fs=require("node:fs"),os=require("node:os"),path=require("node:path");
const deploy=require("../tools/native-install.js");
function fixture(t){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),"zd-native-install-"));
 t.after(()=>{const resolved=path.resolve(root),base=path.resolve(os.tmpdir());assert.equal(path.dirname(resolved),base);assert.ok(path.basename(resolved).startsWith("zd-native-install-"));fs.rmSync(resolved,{recursive:true,force:true});});
 const game=path.join(root,"game"),mod=path.join(root,"mods","ZombieDisguise"),agent=path.join(root,"built-agent.jar");
 fs.mkdirSync(game,{recursive:true});fs.mkdirSync(path.join(mod,"42"),{recursive:true});
 fs.writeFileSync(path.join(game,"projectzomboid.jar"),"game fixture");
 fs.writeFileSync(path.join(game,"ProjectZomboid64.json"),JSON.stringify({mainClass:"zombie/gameStates/MainScreenState",vmArgs:["-Xmx3072m","-Duser.option=keep"]},null,2));
 fs.writeFileSync(path.join(game,"ProjectZomboid64.bat"),'@echo off\r\n".\\jre64\\bin\\java.exe" -Xmx3072m -cp .;projectzomboid.jar zombie.gameStates.MainScreenState %1 %2\r\nIF ERRORLEVEL 1 (\r\n".\\jre64\\bin\\java.exe" -cp .;projectzomboid.jar zombie.gameStates.MainScreenState %1 %2\r\n)\r\n');
 fs.writeFileSync(path.join(game,"ProjectZomboidServer.bat"),'".\\jre64\\bin\\java.exe" -Xmx3072m -cp .;projectzomboid.jar zombie.network.GameServer\r\n');
 fs.writeFileSync(path.join(mod,"42/mod.info"),"id=ZombieDisguise\nrequire=KRFieldMedicine\n");
 fs.writeFileSync(agent,Buffer.from([80,75,3,4,0,0,0,0]));
 return {root,gameDir:game,modDir:mod,agentSource:agent,backupDir:path.join(root,"backup")};
}
test("install preserves flags, patches both fallback commands and dedicated launch, and is reversible",t=>{
 const x=fixture(t),before=fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.json"));
 const m=deploy.install(x);
 let j=JSON.parse(fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.json")));assert.ok(j.vmArgs.includes("-Duser.option=keep"));assert.equal(j.vmArgs.filter(a=>a.startsWith("-javaagent:")).length,1);
 assert.equal((fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.bat"),"utf8").match(/-javaagent:/g)||[]).length,2);
 assert.equal((fs.readFileSync(path.join(x.gameDir,"ProjectZomboidServer.bat"),"utf8").match(/-javaagent:/g)||[]).length,1);
 assert.deepEqual(fs.readFileSync(m.agentTarget),fs.readFileSync(x.agentSource));
 deploy.uninstall(m.manifestPath);assert.deepEqual(fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.json")),before);assert.equal(fs.existsSync(m.agentTarget),false);
});
test("repeat installation does not duplicate arguments",t=>{const x=fixture(t);deploy.install(x);deploy.install({...x,backupDir:path.join(x.root,"backup2")});const j=JSON.parse(fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.json")));assert.equal(j.vmArgs.filter(a=>a.startsWith("-javaagent:")).length,1);assert.equal((fs.readFileSync(path.join(x.gameDir,"ProjectZomboid64.bat"),"utf8").match(/-javaagent:/g)||[]).length,2);});
test("uninstall preserves options edited after install",t=>{const x=fixture(t),m=deploy.install(x),p=path.join(x.gameDir,"ProjectZomboid64.json");const j=JSON.parse(fs.readFileSync(p));j.vmArgs.push("-Dlater.user.option=keep");fs.writeFileSync(p,JSON.stringify(j));deploy.uninstall(m.manifestPath);const current=JSON.parse(fs.readFileSync(p));assert.ok(current.vmArgs.includes("-Dlater.user.option=keep"));assert.equal(current.vmArgs.some(a=>a.startsWith("-javaagent:")),false);});
test("invalid metadata rejects before any launcher mutation",t=>{const x=fixture(t),p=path.join(x.gameDir,"ProjectZomboid64.json"),before=fs.readFileSync(p);fs.writeFileSync(path.join(x.modDir,"42/mod.info"),"id=OtherMod\n");assert.throws(()=>deploy.install(x),/ZombieDisguise/);assert.deepEqual(fs.readFileSync(p),before);assert.equal(fs.existsSync(x.backupDir),false);});

test("uninstall removes supported agent options and normalized path without deleting a referenced JAR",t=>{
 const x=fixture(t),m=deploy.install(x),p=path.join(x.gameDir,"ProjectZomboid64.json");
 const j=JSON.parse(fs.readFileSync(p));j.vmArgs=j.vmArgs.map(a=>a.startsWith("-javaagent:")?a.replace(/\\/g,"/")+"=debug":a);fs.writeFileSync(p,JSON.stringify(j));
 const bat=path.join(x.gameDir,"ProjectZomboid64.bat");fs.writeFileSync(bat,fs.readFileSync(bat,"utf8").split(m.argument).join(m.argument.replace(/\\/g,"/")+"=debug"));
 deploy.uninstall(m.manifestPath);
 assert.equal(JSON.parse(fs.readFileSync(p)).vmArgs.some(a=>a.startsWith("-javaagent:")),false);
 assert.equal(fs.readFileSync(bat,"utf8").includes("-javaagent:"),false);
 assert.equal(fs.existsSync(m.agentTarget),false);
});

test("uninstall handles Windows quotes around only the JAR path with spaces",t=>{
 const x=fixture(t),spaced=path.join(x.root,"mods","Zombie Disguise");fs.cpSync(x.modDir,spaced,{recursive:true});x.modDir=spaced;
 const m=deploy.install(x),bat=path.join(x.gameDir,"ProjectZomboid64.bat");
 fs.writeFileSync(bat,fs.readFileSync(bat,"utf8").split('"'+m.argument+'"').join('-javaagent:"'+m.agentTarget+'"=debug'));
 const result=deploy.uninstall(m.manifestPath);
 assert.equal(fs.readFileSync(bat,"utf8").includes("-javaagent:"),false);
 assert.equal(fs.existsSync(m.agentTarget),false);
 assert.deepEqual(result.warnings,[]);
});
