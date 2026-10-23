"""Fetch pinned compiler/build dependencies over official Maven HTTPS and verify SHA256."""
from pathlib import Path
import hashlib,json,urllib.request,os
repo=Path(__file__).resolve().parents[3]
target=repo.parent/'native-toolchain'
target.mkdir(parents=True,exist_ok=True)
deps=json.loads((Path(__file__).parent/'dependencies.json').read_text(encoding='utf-8'))
for dep in deps:
 name=dep['file']
 if Path(name).name!=name or '/' in name or '\\' in name:raise ValueError('Invalid dependency filename')
 if not dep['url'].startswith('https://repo.maven.apache.org/maven2/'):raise ValueError('Unexpected dependency origin')
 file=target/name
 if file.exists() and hashlib.sha256(file.read_bytes()).hexdigest()==dep['sha256']:
  print('Verified',name);continue
 with urllib.request.urlopen(dep['url'],timeout=60) as response:data=response.read(20*1024*1024+1)
 if len(data)>20*1024*1024 or hashlib.sha256(data).hexdigest()!=dep['sha256']:raise ValueError('Dependency integrity mismatch: '+name)
 temp=target/(name+'.tmp');temp.write_bytes(data);os.replace(temp,file);print('Fetched and verified',name)
(target/'dependencies.json').write_text(json.dumps(deps,indent=2),encoding='utf-8')
