package dev.zombiedisguise;
import java.lang.instrument.*;
import java.security.*;
import java.util.*;
import org.objectweb.asm.*;
import org.objectweb.asm.tree.*;
public final class Transformer implements ClassFileTransformer,Opcodes {
 static final Map<String,String> PINS=Map.ofEntries(
 Map.entry("zombie/characters/IsoGameCharacter","d9073f19cf93dcab217cd046ae4c2218ac0133ca12226a0d4c21bb24c2b301d2"),
 Map.entry("zombie/characters/IsoZombie","ac1db2c6b90985ba6af45fc441c2f31d32c0952cb523f7d441de14ae7a773c81"),
 Map.entry("zombie/pathfind/PathFindBehavior2","d32a43bb95ea9427b8ee016915bd8799da7030d75f9e27b8daa71eab36036411"),
 Map.entry("zombie/characters/BodyDamage/BodyDamage","63e2b4fccd667d47a89c272de2a6f16070768289370d233c00149f501a25ebee"),
 Map.entry("zombie/ai/states/AttackNetworkState","32232078da489a474deed0eb11bc85231f33359a6d0a7add94691190ad3904cf"),
 Map.entry("zombie/ai/states/AttackState","97cfbfc73f5558bde75be67a5c0694ecf3a7765853796d4e11e27e6733f206a4"),
 Map.entry("zombie/ai/states/FakeDeadAttackState","23b3ab9b8b8d9e82dcfee1211b9aaefdb5f52812e18d5b3649c948976f7955b3"),
 Map.entry("zombie/vehicles/AttackVehicleState","20980cb574894555e2550d5d847903e223a9f436d3d50668560142a9c04b40a6"),
 Map.entry("zombie/network/fields/hit/Bite","3446051e005e123215602ec942476f990b2e5eee4dbff764b344bd479688ea31"),
 Map.entry("zombie/core/skinnedmodel/BaseGrappleable","5849f0f3b6869678592617ba130082709d124a3b4b2b06ed8f431f358b7154ce"),
 Map.entry("zombie/network/CoopMaster","84c22f89d79ded4c4c0beae35697829e3105616a2d29e663f7fb8e6cbdb1685b"));
 private static final String R="dev/zombiedisguise/DisguiseRuntime";
 private final Map<String,byte[]> prepared;final Set<String> installed=new HashSet<>();
 Transformer(Map<String,byte[]> p){prepared=p;}
 public byte[] transform(ClassLoader loader,String name,Class<?> redef,ProtectionDomain domain,byte[] bytes){
  if(!prepared.containsKey(name))return null;
  try{
   if(!sha(bytes).equals(PINS.get(name)))throw new IllegalArgumentException("Runtime class differs: "+name);
   installed.add(name);return prepared.get(name);
  }catch(Throwable e){DisguiseRuntime.disable(e);return null;}
 }
 static String sha(byte[] bytes){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));}catch(NoSuchAlgorithmException e){throw new AssertionError(e);}}
 static byte[] instrument(String name,byte[] bytes){
  ClassNode c=new ClassNode();new ClassReader(bytes).accept(c,0);
  if(c.fields.stream().anyMatch(f->f.name.equals("__zombieDisguiseNativeV1")))return bytes;
  if(!PINS.containsKey(name)||!sha(bytes).equals(PINS.get(name)))throw new IllegalArgumentException("Unsupported class SHA256: "+name+" "+sha(bytes));
  c.fields.add(new FieldNode(ACC_PRIVATE|ACC_STATIC|ACC_FINAL|ACC_SYNTHETIC,"__zombieDisguiseNativeV1","I",null,1));
  int hooks=0;
  if(name.equals("zombie/characters/IsoZombie"))zombieHelpers(c);
  if(name.equals("zombie/pathfind/PathFindBehavior2"))pathHelpers(c);
  if(name.equals("zombie/characters/IsoGameCharacter")){
   bridge(c,"getZombieDisguiseBridgeVersion","()I","version","()I",new int[]{},IRETURN);
   bridge(c,"setZombieDisguiseLease","(DD)Z","grant","(Ljava/lang/Object;DD)Z",new int[]{ALOAD,0,DLOAD,1,DLOAD,3},IRETURN);
   bridge(c,"clearZombieDisguiseLease","()V","clear","(Ljava/lang/Object;)V",new int[]{ALOAD,0},RETURN);hooks+=3;
  }
  for(MethodNode m:c.methods){
   if(name.equals("zombie/characters/IsoZombie")){
    if(Set.of("spotted","spottedNew","spottedOld","setTarget","addAggro","pathToCharacter").contains(m.name)){guard(m,"blocked","(Ljava/lang/Object;)Z",1);hooks++;}
    if(Set.of("updateInternal","preupdate","getTarget","processAggroList").contains(m.name)){InsnList x=new InsnList();x.add(new VarInsnNode(ALOAD,0));x.add(new MethodInsnNode(INVOKEVIRTUAL,c.name,"__zombieDisguiseScrub","()V",false));m.instructions.insert(x);hooks++;}
    if(m.name.equals("getShouldAttack")){guard(m,"attackBlocked","(Ljava/lang/Object;)Z",0);hooks++;}
   }
   if(name.equals("zombie/pathfind/PathFindBehavior2")){
    if(m.name.startsWith("pathTo")){
     InsnList release=new InsnList();release.add(new VarInsnNode(ALOAD,0));release.add(new InsnNode(ICONST_0));release.add(new FieldInsnNode(PUTFIELD,P,"__zombieDisguiseGoalCancelled","Z"));m.instructions.insert(release);
    }
    if(m.name.equals("update")||m.name.equals("Succeeded")){
     InsnList cancel=new InsnList();cancel.add(new VarInsnNode(ALOAD,0));cancel.add(new FieldInsnNode(GETFIELD,P,"__zombieDisguiseGoalCancelled","Z"));
     LabelNode proceed=new LabelNode();cancel.add(new JumpInsnNode(IFEQ,proceed));
     if(m.name.equals("update")){cancel.add(new FieldInsnNode(GETSTATIC,P+"$BehaviorResult","Failed","L"+P+"$BehaviorResult;"));cancel.add(new InsnNode(ARETURN));}
     else cancel.add(new InsnNode(RETURN));
     label(cancel,proceed);m.instructions.insert(cancel);hooks++;
    }
   }
   if(name.equals("zombie/pathfind/PathFindBehavior2")&&m.name.equals("pathToCharacter")){guard(m,"pathBlocked","(Ljava/lang/Object;Ljava/lang/Object;)Z",0,1);hooks++;}
   if(name.equals("zombie/characters/BodyDamage/BodyDamage")&&m.name.equals("AddRandomDamageFromZombie")){guard(m,"damageBlocked","(Ljava/lang/Object;Ljava/lang/Object;)Z",0,1);hooks++;}
   if(name.equals("zombie/characters/IsoGameCharacter")&&m.name.equals("attackFromWindowsLunge")){guard(m,"victimBlocked","(Ljava/lang/Object;Ljava/lang/Object;)Z",0,1);hooks++;}
   if((name.equals("zombie/ai/states/AttackNetworkState")||name.equals("zombie/ai/states/AttackState")||name.equals("zombie/ai/states/FakeDeadAttackState")||name.equals("zombie/vehicles/AttackVehicleState"))&&Set.of("enter","execute","animEvent","isAttacking").contains(m.name)){guard(m,"attackBlocked","(Ljava/lang/Object;)Z",1);hooks++;}
   if(name.equals("zombie/network/fields/hit/Bite")&&m.name.equals("process")){guard(m,"pairBlocked","(Ljava/lang/Object;Ljava/lang/Object;)Z",1,2);hooks++;}
   if(name.equals("zombie/core/skinnedmodel/BaseGrappleable")&&Set.of("Grappled","AcceptGrapple").contains(m.name)){guard(m,"grappleBlocked","(Ljava/lang/Object;Ljava/lang/Object;)Z",0,1);hooks++;}
   if(name.equals("zombie/network/CoopMaster")&&m.name.equals("launchServer")){
    for(AbstractInsnNode i:m.instructions.toArray())if(i instanceof MethodInsnNode call&&call.owner.equals("java/lang/ProcessBuilder")&&call.name.equals("start")){
     m.instructions.insertBefore(i,new MethodInsnNode(INVOKESTATIC,"dev/zombiedisguise/Agent","prepareCoop","(Ljava/lang/ProcessBuilder;)Ljava/lang/ProcessBuilder;",false));hooks++;
    }
   }
  }
  if(hooks==0)throw new IllegalArgumentException("No hooks for "+name);
  ClassWriter w=new ClassWriter(ClassWriter.COMPUTE_MAXS);c.accept(w);return w.toByteArray();
 }
 private static final String Z="zombie/characters/IsoZombie", A="zombie/characters/IsoZombie$Aggro", P="zombie/pathfind/PathFindBehavior2";
 private static MethodNode getter(ClassNode c,String name,String field,String desc){
  MethodNode m=new MethodNode(ACC_PUBLIC|ACC_FINAL|ACC_SYNTHETIC,name,"()"+desc,null,null);
  m.instructions.add(new VarInsnNode(ALOAD,0));m.instructions.add(new FieldInsnNode(GETFIELD,c.name,field,desc));m.instructions.add(new InsnNode(ARETURN));c.methods.add(m);return m;
 }
 private static void pathHelpers(ClassNode c){
  c.fields.add(new FieldNode(ACC_PRIVATE|ACC_SYNTHETIC,"__zombieDisguiseGoalCancelled","Z",null,null));
  getter(c,"__zombieDisguiseOwner","chr","Lzombie/characters/IsoGameCharacter;");
  MethodNode m=new MethodNode(ACC_PUBLIC|ACC_FINAL|ACC_SYNTHETIC,"__zombieDisguiseClearGoal","()V",null,null);InsnList x=m.instructions;
  for(String field:List.of("__zombieDisguiseGoalCancelled","isCancel")){x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(ICONST_1));x.add(new FieldInsnNode(PUTFIELD,P,field,"Z"));}
  x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(ACONST_NULL));x.add(new FieldInsnNode(PUTFIELD,P,"goalCharacter","Lzombie/characters/IsoGameCharacter;"));
  x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETSTATIC,P+"$Goal","None","L"+P+"$Goal;"));x.add(new FieldInsnNode(PUTFIELD,P,"goal","L"+P+"$Goal;"));
  x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETFIELD,P,"path","Lzombie/pathfind/Path;"));x.add(new MethodInsnNode(INVOKEVIRTUAL,"zombie/pathfind/Path","clear","()V",false));
  for(String field:List.of("pathNextIsSet","startedMoving")){x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(ICONST_0));x.add(new FieldInsnNode(PUTFIELD,P,field,"Z"));}
  x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(ICONST_0));x.add(new FieldInsnNode(PUTFIELD,P,"pathIndex","I"));
  pathOwner(x);x.add(new InsnNode(ACONST_NULL));x.add(new MethodInsnNode(INVOKEVIRTUAL,"zombie/characters/IsoGameCharacter","setPath2","(Lzombie/pathfind/Path;)V",false));
  pathOwner(x);x.add(new InsnNode(ICONST_0));x.add(new MethodInsnNode(INVOKEVIRTUAL,"zombie/characters/IsoGameCharacter","setMoving","(Z)V",false));
  pathOwner(x);x.add(new MethodInsnNode(INVOKEVIRTUAL,"zombie/characters/IsoGameCharacter","getFinder","()Lzombie/ai/astar/AStarPathFinderResult;",false));
  x.add(new FieldInsnNode(GETSTATIC,"zombie/ai/astar/AStarPathFinder$PathFindProgress","failed","Lzombie/ai/astar/AStarPathFinder$PathFindProgress;"));x.add(new FieldInsnNode(PUTFIELD,"zombie/ai/astar/AStarPathFinderResult","progress","Lzombie/ai/astar/AStarPathFinder$PathFindProgress;"));
  for(String variable:List.of("bPathfind","bMoving")){
   pathOwner(x);x.add(new LdcInsnNode(variable));x.add(new InsnNode(ICONST_0));x.add(new MethodInsnNode(INVOKEVIRTUAL,"zombie/characters/IsoGameCharacter","setVariable","(Ljava/lang/String;Z)Lzombie/core/skinnedmodel/advancedanimation/IAnimationVariableSlot;",false));x.add(new InsnNode(POP));
  }
  String nativeP="zombie/pathfind/nativeCode/PathfindNative",polygon="zombie/pathfind/PolygonalMap2";LabelNode javaBackend=new LabelNode(),done=new LabelNode();
  x.add(new FieldInsnNode(GETSTATIC,nativeP,"useNativeCode","Z"));x.add(new JumpInsnNode(IFEQ,javaBackend));
  x.add(new FieldInsnNode(GETSTATIC,nativeP,"instance","L"+nativeP+";"));pathOwner(x);x.add(new MethodInsnNode(INVOKEVIRTUAL,nativeP,"cancelRequest","(Lzombie/ai/astar/Mover;)V",false));x.add(new JumpInsnNode(GOTO,done));
  label(x,javaBackend);x.add(new FieldInsnNode(GETSTATIC,polygon,"instance","L"+polygon+";"));pathOwner(x);x.add(new MethodInsnNode(INVOKEVIRTUAL,polygon,"cancelRequest","(Lzombie/ai/astar/Mover;)V",false));label(x,done);
  x.add(new InsnNode(RETURN));c.methods.add(m);
 }
 private static void pathOwner(InsnList x){x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETFIELD,P,"chr","Lzombie/characters/IsoGameCharacter;"));}
 private static void zombieHelpers(ClassNode c){
  getter(c,"__zombieDisguiseRawTarget","target","Lzombie/iso/IsoMovingObject;");
  MethodNode m=new MethodNode(ACC_PUBLIC|ACC_FINAL|ACC_SYNTHETIC,"__zombieDisguiseScrub","()V",null,null);
  InsnList x=m.instructions;
  x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETFIELD,Z,"aggroList","[L"+A+";"));x.add(new VarInsnNode(ASTORE,1));
  x.add(new InsnNode(ICONST_0));x.add(new VarInsnNode(ISTORE,2));
  x.add(new VarInsnNode(ALOAD,0));x.add(new MethodInsnNode(INVOKEVIRTUAL,Z,"getPathFindBehavior2","()L"+P+";",false));x.add(new VarInsnNode(ASTORE,3));
  x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETFIELD,Z,"target","Lzombie/iso/IsoMovingObject;"));x.add(new MethodInsnNode(INVOKESTATIC,R,"blocked","(Ljava/lang/Object;)Z",false));
  LabelNode targetKept=new LabelNode();x.add(new JumpInsnNode(IFEQ,targetKept));
  x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(ACONST_NULL));x.add(new MethodInsnNode(INVOKEVIRTUAL,Z,"setTarget","(Lzombie/iso/IsoMovingObject;)V",false));
  assign(x,"targetSeenTime","F",FCONST_0);assign(x,"canSeeTarget","Z",ICONST_0);
  for(String field:List.of("lastTargetSeenX","lastTargetSeenY","lastTargetSeenZ"))assign(x,field,"I",ICONST_M1);
  x.add(targetKept);x.add(new FrameNode(F_APPEND,3,new Object[]{"[L"+A+";",INTEGER,P},0,null));
  x.add(new VarInsnNode(ALOAD,0));x.add(new FieldInsnNode(GETFIELD,Z,"spottedLast","Lzombie/iso/IsoMovingObject;"));x.add(new MethodInsnNode(INVOKESTATIC,R,"blocked","(Ljava/lang/Object;)Z",false));
  LabelNode spottedKept=new LabelNode();x.add(new JumpInsnNode(IFEQ,spottedKept));assign(x,"spottedLast","Lzombie/iso/IsoMovingObject;",ACONST_NULL);assign(x,"bonusSpotTime","F",FCONST_0);
  label(x,spottedKept);
  LabelNode end=new LabelNode(),loop=new LabelNode(),next=new LabelNode();
  x.add(new VarInsnNode(ALOAD,1));x.add(new JumpInsnNode(IFNULL,end));
  label(x,loop);x.add(new VarInsnNode(ILOAD,2));x.add(new VarInsnNode(ALOAD,1));x.add(new InsnNode(ARRAYLENGTH));x.add(new JumpInsnNode(IF_ICMPGE,end));
  x.add(new VarInsnNode(ALOAD,1));x.add(new VarInsnNode(ILOAD,2));x.add(new InsnNode(AALOAD));x.add(new JumpInsnNode(IFNULL,next));
  x.add(new VarInsnNode(ALOAD,1));x.add(new VarInsnNode(ILOAD,2));x.add(new InsnNode(AALOAD));x.add(new FieldInsnNode(GETFIELD,A,"obj","Lzombie/iso/IsoMovingObject;"));x.add(new MethodInsnNode(INVOKESTATIC,R,"blocked","(Ljava/lang/Object;)Z",false));x.add(new JumpInsnNode(IFEQ,next));
  x.add(new VarInsnNode(ALOAD,1));x.add(new VarInsnNode(ILOAD,2));x.add(new InsnNode(ACONST_NULL));x.add(new InsnNode(AASTORE));
  label(x,next);x.add(new IincInsnNode(2,1));x.add(new JumpInsnNode(GOTO,loop));label(x,end);
  LabelNode done=new LabelNode();x.add(new VarInsnNode(ALOAD,3));x.add(new JumpInsnNode(IFNULL,done));
  x.add(new VarInsnNode(ALOAD,3));x.add(new MethodInsnNode(INVOKEVIRTUAL,P,"getTargetChar","()Lzombie/characters/IsoGameCharacter;",false));x.add(new MethodInsnNode(INVOKESTATIC,R,"blocked","(Ljava/lang/Object;)Z",false));x.add(new JumpInsnNode(IFEQ,done));
  x.add(new VarInsnNode(ALOAD,3));x.add(new MethodInsnNode(INVOKEVIRTUAL,P,"cancel","()V",false));
  x.add(new VarInsnNode(ALOAD,3));x.add(new MethodInsnNode(INVOKEVIRTUAL,P,"__zombieDisguiseClearGoal","()V",false));
  label(x,done);x.add(new InsnNode(RETURN));c.methods.add(m);
 }
 private static void assign(InsnList x,String field,String desc,int value){x.add(new VarInsnNode(ALOAD,0));x.add(new InsnNode(value));x.add(new FieldInsnNode(PUTFIELD,Z,field,desc));}
 private static void label(InsnList x,LabelNode n){x.add(n);x.add(new FrameNode(F_SAME,0,null,0,null));}
 private static void bridge(ClassNode c,String name,String desc,String target,String targetDesc,int[] loads,int ret){
  MethodNode m=new MethodNode(ACC_PUBLIC,name,desc,null,null);
  for(int i=0;i<loads.length;i+=2)m.instructions.add(new VarInsnNode(loads[i],loads[i+1]));
  m.instructions.add(new MethodInsnNode(INVOKESTATIC,R,target,targetDesc,false));m.instructions.add(new InsnNode(ret));c.methods.add(m);
 }
 private static void guard(MethodNode m,String method,String desc,int... locals){
  InsnList x=new InsnList();for(int local:locals)x.add(new VarInsnNode(ALOAD,local));
  x.add(new MethodInsnNode(INVOKESTATIC,R,method,desc,false));LabelNode proceed=new LabelNode();x.add(new JumpInsnNode(IFEQ,proceed));
  Type t=Type.getReturnType(m.desc);
  if(t.getSort()==Type.VOID)x.add(new InsnNode(RETURN));
  else if(t.getSort()==Type.FLOAT){x.add(new InsnNode(FCONST_0));x.add(new InsnNode(FRETURN));}
  else{x.add(new InsnNode(ICONST_0));x.add(new InsnNode(IRETURN));}
  x.add(proceed);x.add(new FrameNode(F_SAME,0,null,0,null));m.instructions.insert(x);
 }
}