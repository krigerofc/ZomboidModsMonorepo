"""Reproducible native agent build. Does not change any installed game file."""
from pathlib import Path
import subprocess,sys,zipfile,json,hashlib
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'ZombieDisguise/native'
TOOL=ROOT.parent/'native-toolchain'
GAME=Path(sys.argv[1] if len(sys.argv)>1 else 'E:/SteamLibrary/steamapps/common/ProjectZomboid')
OUT=ROOT/'outputs/native-disguise'
OUT.mkdir(parents=True,exist_ok=True)
JAVA=GAME/'jre64/bin/java.exe'
deps=json.loads((TOOL/'dependencies.json').read_text())
for item in deps:
 assert hashlib.sha256((TOOL/item['file']).read_bytes()).hexdigest()==item['sha256'],item['file']
asm=[TOOL/x['file'] for x in deps if x['file'].startswith('asm')]
cp=';'.join(map(str,asm))
classes=OUT/'classes';classes.mkdir(exist_ok=True)
sources=sorted((BASE/'src').rglob('*.java'))+sorted((BASE/'tests').rglob('*.java'))
cmd=[str(JAVA),'-jar',str(TOOL/'ecj-3.43.0.jar'),'-17','-encoding','UTF-8','-nowarn','-cp',cp,'-d',str(classes),*map(str,sources)]
subprocess.run(cmd,check=True)
with zipfile.ZipFile(OUT/'zombie-disguise-agent.jar','w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 entries={'META-INF/MANIFEST.MF':b'Manifest-Version: 1.0\r\nPremain-Class: dev.zombiedisguise.Agent\r\nCan-Redefine-Classes: false\r\nCan-Retransform-Classes: false\r\n\r\n'}
 for f in classes.rglob('*.class'):
  if any(f.name==s.stem+'.class' or f.name.startswith(s.stem+'$') for s in (BASE/'src').rglob('*.java')):entries[f.relative_to(classes).as_posix()]=f.read_bytes()
 for dep in asm:
  with zipfile.ZipFile(dep) as dependency:
   for n in dependency.namelist():
    if n.startswith('org/objectweb/asm/') and n.endswith('.class'):entries[n]=dependency.read(n)
 for n,data in sorted(entries.items()):
  info=zipfile.ZipInfo(n,(2026,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,data)
test=[str(JAVA),'-Xverify:all','-cp',str(classes)+';'+cp,'dev.zombiedisguise.NativeTests',str(GAME/'projectzomboid.jar'),str(BASE/'src/dev/zombiedisguise/DisguiseRuntime.java')]
result=subprocess.run(test,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(OUT/'native-tests.log').write_text(result.stdout,encoding='utf8')
print(result.stdout)
if result.returncode:sys.exit(result.returncode)
jar=OUT/'zombie-disguise-agent.jar'
(OUT/'build-manifest.json').write_text(json.dumps({'agentSha256':hashlib.sha256(jar.read_bytes()).hexdigest(),'dependencies':deps},indent=2))
startup=[str(JAVA),'-Xverify:all','-javaagent:'+str(jar),'-cp',str(jar)+';'+str(classes)+';'+str(GAME/'projectzomboid.jar'),'dev.zombiedisguise.StartupSmoke']
result=subprocess.run(startup,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,cwd=GAME)
(OUT/'engine-startup.log').write_text(result.stdout,encoding='utf8')
print(result.stdout)
if result.returncode:sys.exit(result.returncode)
with zipfile.ZipFile(GAME/'projectzomboid.jar') as game:
 data=bytearray(game.read('zombie/characters/BodyDamage/BodyDamage.class'));data[-1]^=1
with zipfile.ZipFile(OUT/'unsupported-engine-fixture.jar','w') as fixture:
 fixture.writestr('zombie/characters/BodyDamage/BodyDamage.class',data)
unknown=[str(JAVA),'-Xverify:all','-javaagent:'+str(jar),'-cp',str(OUT/'unsupported-engine-fixture.jar')+';'+str(jar)+';'+str(classes)+';'+str(GAME/'projectzomboid.jar'),'dev.zombiedisguise.UnavailableSmoke']
result=subprocess.run(unknown,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,cwd=GAME)
(OUT/'unsupported-startup.log').write_text(result.stdout,encoding='utf8')
print(result.stdout)
if result.returncode:sys.exit(result.returncode)
print('Built',jar)
