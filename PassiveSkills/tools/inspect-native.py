import zipfile,struct,hashlib,sys
z=zipfile.ZipFile(sys.argv[1])
for name in ['zombie/radio/devices/DeviceData.class','zombie/radio/media/RecordedMedia.class','zombie/characters/IsoGameCharacter.class','zombie/inventory/InventoryItem.class','zombie/radio/media/MediaData.class']:
 b=z.read(name);print('CLASS',name,'SHA256',hashlib.sha256(b).hexdigest());n=struct.unpack_from('>H',b,8)[0];p=10;cp=[None]*n;i=1
 while i<n:
  t=b[p];p+=1
  if t==1:
   l=struct.unpack_from('>H',b,p)[0];p+=2;cp[i]=b[p:p+l].decode('utf8','replace');p+=l
  elif t in [3,4]:cp[i]=struct.unpack_from('>f' if t==4 else '>i',b,p)[0];p+=4
  elif t in [5,6]:p+=8;i+=1
  elif t in [7,8,16,19,20]:cp[i]=(t,struct.unpack_from('>H',b,p)[0]);p+=2
  elif t in [9,10,11,12,17,18]:cp[i]=(t,*struct.unpack_from('>HH',b,p));p+=4
  elif t==15:p+=3
  else:raise ValueError(t)
  i+=1
 def resolve(i):
  x=cp[i]
  return '/'.join(str(resolve(v)) for v in x[1:]) if isinstance(x,tuple) else str(x)
 p+=6;ni=struct.unpack_from('>H',b,p)[0];p+=2+2*ni
 for group in ['fields','methods']:
  nn=struct.unpack_from('>H',b,p)[0];p+=2
  for m in range(nn):
   a,nam,desc,ac=struct.unpack_from('>HHHH',b,p);p+=8;nm=resolve(nam)
   for at in range(ac):
    aid,l=struct.unpack_from('>HI',b,p);p+=6;v=b[p:p+l];p+=l
    if group!='methods' or resolve(aid)!='Code':continue
    if nm not in ['register','getMediaTypeForCategory','getRandomFromCategory','init','StartPlayMedia','updateMediaPlaying','addMediaItem','saveKnownMediaLines','loadKnownMediaLines','addKnownMediaLine','isKnownMediaLine','setRecordedMediaData','setRecordedMediaIndex','getMediaType']:continue
    ln=struct.unpack_from('>I',v,4)[0];c=v[8:8+ln];q=0;out=[]
    while q<len(c):
     pos=q;op=c[q];q+=1;count=0;note=''
     if op in [16,18,21,22,23,24,25,54,55,56,57,58,169,188]:count=1
     elif op in [17,19,20,132,*range(153,169),*range(178,185),187,189,192,193,198,199]:count=2
     elif op==197:count=3
     elif op in [185,186,200,201]:count=4
     elif op==196:count=5 if c[q]==132 else 3
     elif op==170:
      q+=(4-q%4)%4;lo,hi=struct.unpack_from('>ii',c,q+4);count=12+4*(hi-lo+1)
     elif op==171:
      q+=(4-q%4)%4;count=8+8*struct.unpack_from('>i',c,q+4)[0]
     if op in [18,19,20,*range(178,187),187,189,192,193]:note=resolve(c[q] if op==18 else struct.unpack_from('>H',c,q)[0])
     elif op in [16,17]:note='push '+str(int.from_bytes(c[q:q+count],signed=True))
     elif op in range(2,9):note='int '+str(op-3)
     elif op in [21,22,23,24,25,54,55,56,57,58]:note='local '+str(c[q])
     elif op in [*range(153,169),198,199]:note='branch '+str(pos+int.from_bytes(c[q:q+2],signed=True))
     out.append(f'{pos:4}: {op:02x} {note}');q+=count
    print('METHOD',nm,resolve(desc));print('\n'.join(out))
