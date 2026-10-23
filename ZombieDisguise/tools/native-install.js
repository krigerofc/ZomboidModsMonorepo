"use strict";
const fs=require("node:fs"),path=require("node:path"),crypto=require("node:crypto");
const sha=b=>crypto.createHash("sha256").update(b).digest("hex");
const read=p=>fs.existsSync(p)?fs.readFileSync(p):null;
function atomic(file,bytes){fs.mkdirSync(path.dirname(file),{recursive:true});const temp=file+".zd-tmp-"+process.pid;fs.writeFileSync(temp,bytes,{flag:"wx"});try{fs.renameSync(temp,file);}catch(e){fs.unlinkSync(temp);throw e;}}
function planInstall(options){
 const gameDir=path.resolve(options.gameDir),modDir=path.resolve(options.modDir),agentSource=path.resolve(options.agentSource),backupDir=path.resolve(options.backupDir);
 for(const p of [gameDir,modDir,agentSource,backupDir])if(/["%!\r\n]/.test(p))throw Error("Unsupported launcher path characters");
 if(!fs.existsSync(path.join(gameDir,"projectzomboid.jar")))throw Error("Project Zomboid installation missing");
 const info=fs.readFileSync(path.join(modDir,"42/mod.info"),"utf8");
 if(!/^id=ZombieDisguise\r?$/m.test(info))throw Error("Expected ZombieDisguise mod metadata");
 const jar=fs.readFileSync(agentSource);
 if(jar.length<4||jar.readUInt32LE(0)!==0x04034b50)throw Error("Expected native agent JAR archive");
 const agentTarget=path.join(modDir,"native","zd-native-agent.jar"),argument="-javaagent:"+agentTarget;
 if(agentTarget.includes("="))throw Error("Agent path cannot contain =");
 const changes=[];
 function add(target,after,kind){const before=read(target);changes.push({target,after:Buffer.from(after),before,kind});}
 const jsonPath=path.join(gameDir,"ProjectZomboid64.json"),json=JSON.parse(fs.readFileSync(jsonPath,"utf8"));
 if(!Array.isArray(json.vmArgs)||!/zombie[/.]gameStates[/.]MainScreenState/.test(json.mainClass||""))throw Error("Unexpected client launcher configuration");
 if(!json.vmArgs.includes(argument)){json.vmArgs.push(argument);add(jsonPath,JSON.stringify(json,null,"\t")+"\n","json");}
 for(const name of ["ProjectZomboid64.bat","ProjectZomboid64ShowConsole.bat","ProjectZomboidOpenGLDebug64.bat","ProjectZomboidServer.bat"]){
  const target=path.join(gameDir,name);if(!fs.existsSync(target))continue;
  const original=fs.readFileSync(target,"utf8");let matches=0;
  const updated=original.replace(/^.*$/gm,line=>{
   if(!/zombie\.(?:gameStates\.MainScreenState|network\.GameServer)/.test(line)||!/java\.exe/i.test(line))return line;
   matches++;if(line.includes('"'+argument+'"'))return line;
   return line.replace(/("(?:[^"\r\n]*[\\/])?java\.exe")/i,'$1 "'+argument+'"');
  });
  if(!matches)throw Error("No supported JVM launch command in "+name);
  if(updated!==original)add(target,updated,"bat");
 }
 if(!read(agentTarget)||sha(read(agentTarget))!==sha(jar))add(agentTarget,jar,"jar");
 return{gameDir,modDir,agentSource,agentTarget,argument,backupDir,changes};
}
function install(options){
 const plan=planInstall(options);
 if(fs.existsSync(plan.backupDir))throw Error("Backup directory already exists; choose a new backup directory");
 fs.mkdirSync(plan.backupDir,{recursive:true});
 const manifestPath=path.join(plan.backupDir,"manifest.json");
 const records=plan.changes.map((c,i)=>{
  const backup=c.before?path.join(plan.backupDir,"baseline-"+i):null;
  if(backup)fs.writeFileSync(backup,c.before,{flag:"wx"});
  return{target:c.target,kind:c.kind,beforeSha:c.before?sha(c.before):null,beforePath:backup,afterSha:sha(c.after)};
 });
 const manifest={version:1,created:new Date().toISOString(),gameDir:plan.gameDir,modDir:plan.modDir,agentTarget:plan.agentTarget,argument:plan.argument,records};
 fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2),{flag:"wx"});
 const written=[];
 try{
  // Put the JAR in place before enabling the launch flag.
  for(const c of [...plan.changes].sort((a,b)=>(a.kind==="jar"?-1:0)-(b.kind==="jar"?-1:0))){
   const current=read(c.target);
   if((current?sha(current):null)!==(c.before?sha(c.before):null))throw Error("File changed after preflight: "+c.target);
   atomic(c.target,c.after);written.push(c);
  }
 }catch(e){
  for(const c of written.reverse()){
   const current=read(c.target);if(!current||sha(current)!==sha(c.after))continue;
   if(c.before)atomic(c.target,c.before);else fs.unlinkSync(c.target);
  }
  throw e;
 }
 return{manifestPath,agentTarget:plan.agentTarget,argument:plan.argument,changed:records.map(r=>r.target)};
}
function ownsArgument(argument,target,gameDir){
 if(typeof argument!=="string"||!argument.startsWith("-javaagent:"))return false;
 let jar=argument.slice(11).split("=")[0];if(jar.startsWith('"')&&jar.endsWith('"'))jar=jar.slice(1,-1);
 const canonical=p=>path.resolve(gameDir,p).replace(/\\/g,"/").toLowerCase();
 return canonical(jar)===canonical(target);
}
function batchTokens(text){
 const tokens=[];let i=0;
 while(i<text.length){
  if(/\s/.test(text[i])){i++;continue;}
  const start=i;let quoted=false,cooked="";
  while(i<text.length){
   const ch=text[i];
   if(ch==='"'){quoted=!quoted;i++;continue;}
   if(ch==="^"&&!quoted&&i+1<text.length){cooked+=text[i+1];i+=2;continue;}
   if(/\s/.test(ch)&&!quoted)break;
   cooked+=ch;i++;
  }
  tokens.push({start,end:i,cooked});
 }
 return tokens;
}
function stripBatchAgent(text,target,gameDir){
 const remove=batchTokens(text).filter(t=>ownsArgument(t.cooked,target,gameDir));
 for(const t of remove.reverse())text=text.slice(0,t.start)+text.slice(t.end);
 return text;
}
function remainingReference(gameDir,target){
 for(const name of ["ProjectZomboid64.json","ProjectZomboid64.bat","ProjectZomboid64ShowConsole.bat","ProjectZomboidOpenGLDebug64.bat","ProjectZomboidServer.bat"]){
  const file=path.join(gameDir,name);if(!fs.existsSync(file))continue;const text=fs.readFileSync(file,"utf8");
  if(name.endsWith(".json")){try{if((JSON.parse(text).vmArgs||[]).some(a=>ownsArgument(a,target,gameDir)))return true;}catch{return true;}}
  else{
   if(batchTokens(text).some(t=>ownsArgument(t.cooked,target,gameDir)))return true;
   // Unknown shell variable/escaping syntax is preserved instead of deleting a referenced JAR.
   if(/-javaagent:/i.test(text)&&text.toLowerCase().includes(path.basename(target).toLowerCase()))return true;
  }
 }
 return false;
}
function uninstall(manifestPath){
 manifestPath=path.resolve(manifestPath);
 const m=JSON.parse(fs.readFileSync(manifestPath,"utf8")),backup=path.dirname(manifestPath),warnings=[];
 if(m.version!==1||!Array.isArray(m.records))throw Error("Unknown installation manifest");
 for(const r of m.records){
  const target=path.resolve(r.target),inGame=path.dirname(target)===path.resolve(m.gameDir),isAgent=target===path.resolve(m.agentTarget)&&path.dirname(path.dirname(target))===path.resolve(m.modDir);
  if(!inGame&&!isAgent)throw Error("Manifest target outside installation");
  if(r.beforePath&&path.dirname(path.resolve(r.beforePath))!==backup)throw Error("Backup path outside manifest directory");
  const current=read(target);if(!current){warnings.push("Missing file: "+target);continue;}
  if(sha(current)===r.afterSha){
   if(r.beforePath){const original=fs.readFileSync(r.beforePath);if(sha(original)!==r.beforeSha)throw Error("Backup integrity mismatch");atomic(target,original);}
   else if(r.kind==="jar"&&remainingReference(m.gameDir,m.agentTarget))warnings.push("Agent JAR preserved because a launcher still references it: "+target);else fs.unlinkSync(target);
  }else if(r.kind==="json"){
   const json=JSON.parse(current.toString("utf8"));
   if(!Array.isArray(json.vmArgs))throw Error("Changed JSON launcher is not supported");
   json.vmArgs=json.vmArgs.filter(x=>!ownsArgument(x,m.agentTarget,m.gameDir));atomic(target,Buffer.from(JSON.stringify(json,null,"\t")+"\n"));
  }else if(r.kind==="bat"){
   atomic(target,Buffer.from(stripBatchAgent(current.toString("utf8"),m.agentTarget,m.gameDir)));
  }else warnings.push("Changed file preserved: "+target);
 }
 return{warnings};
}
module.exports={planInstall,install,uninstall};
if(require.main===module){
 const [action,...args]=process.argv.slice(2),o={};
 for(let i=0;i<args.length;i+=2){if(!args[i].startsWith("--")||!args[i+1])throw Error("Expected --key value");o[args[i].slice(2)]=args[i+1];}
 if(action==="install")console.log(JSON.stringify(install({gameDir:o.game,modDir:o.mod,agentSource:o.agent,backupDir:o.backup}),null,2));
 else if(action==="uninstall")console.log(JSON.stringify(uninstall(o.manifest),null,2));
 else throw Error("Usage: native-install.js install --game PATH --mod PATH --agent JAR --backup NEW_DIR | uninstall --manifest PATH");
}
