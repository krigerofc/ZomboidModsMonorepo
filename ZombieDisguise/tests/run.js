const fs=require("fs"),path=require("path");const {lua,lauxlib,lualib,to_luastring}=require("fengari");const parse=require("luaparse");
const root=path.resolve(__dirname,".."),mod=path.join(root,"Contents/mods/ZombieDisguise"),game=path.join(mod,"42/media/lua");let failures=0;
function check(v,m){if(!v){failures++;console.log("FAIL "+m)}else console.log("ok "+m)}
function walk(dir){return !fs.existsSync(dir)?[]:fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)])}
check(!fs.existsSync(path.join(mod,"mod.info")),"B42 only");
check(!/^require=.*KRFieldMedicine/m.test(fs.readFileSync(path.join(mod,"42/mod.info"),"utf8")),"FieldMedicine is optional");
for(const f of walk(mod).filter(f=>f.endsWith(".lua"))){try{parse.parse(fs.readFileSync(f,"utf8"),{luaVersion:"5.1"})}catch(e){check(false,path.relative(root,f)+": "+e.message)}}
for(const [rel,w,h] of [["42/poster.png",512,512],["42/icon.png",64,64]]){const p=path.join(mod,rel);check(fs.existsSync(p),"art "+rel);if(fs.existsSync(p)){const b=fs.readFileSync(p);check(b.readUInt32BE(16)===w&&b.readUInt32BE(20)===h,"art dimensions "+rel)}}
for(const spec of ["visibility_spec.lua","standalone_spec.lua","disguise_spec.lua"]){
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);const fwd=p=>p.replace(/\\/g,"/");
const code="package.path="+JSON.stringify(fwd(game)+"/shared/?.lua;"+fwd(game)+"/server/?.lua;")+"..package.path; MODLUA="+JSON.stringify(fwd(game))+"; return dofile("+JSON.stringify(fwd(path.join(__dirname,spec)))+")";
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)check(false,spec+": "+lua.lua_tojsstring(L,-1));else check(lua.lua_tonumber(L,-1)===0,spec);
}
if(fs.existsSync(path.join(root,"tools/i18n.js"))){try{require("child_process").execFileSync(process.execPath,[path.join(root,"tools/i18n.js"),"--check"])}catch(e){check(false,"translation generation")}}
console.log(failures?failures+" FAILURE(S)":"ALL TESTS PASSED");process.exit(failures?1:0);
