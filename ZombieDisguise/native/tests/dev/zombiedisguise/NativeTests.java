package dev.zombiedisguise;
import java.lang.reflect.*;
import java.nio.file.*;
import java.util.*;
import java.util.function.*;
import java.util.jar.*;
import org.objectweb.asm.*;
import org.objectweb.asm.tree.*;
public final class NativeTests {
 static int tests;
 static void check(boolean ok,String message){tests++;if(!ok)throw new AssertionError(message);}
 public static void main(String[] args)throws Exception {
  Class<?> c;
  try { c=Class.forName("dev.zombiedisguise.LeaseRegistry"); }
  catch(ClassNotFoundException missing){throw new AssertionError("Native finite identity lease implementation is missing");}
  double[] hours={10};long[] nanos={100};
  Object registry=c.getDeclaredConstructor(DoubleSupplier.class,LongSupplier.class).newInstance((DoubleSupplier)()->hours[0],(LongSupplier)()->nanos[0]);
  Method grant=c.getDeclaredMethod("grant",Object.class,double.class,double.class),active=c.getDeclaredMethod("active",Object.class),clear=c.getDeclaredMethod("clear",Object.class);
  Object wearer=new String("same"),other=new String("same");
  check((boolean)grant.invoke(registry,wearer,11d,5d),"valid lease");
  check((boolean)active.invoke(registry,wearer),"wearer protected");
  check(!(boolean)active.invoke(registry,other),"identity must not use equals");
  nanos[0]+=5_000_000_001L;
  check(!(boolean)active.invoke(registry,wearer),"monotonic lease expiry");
  check((boolean)grant.invoke(registry,wearer,11d,5d),"renew");
  hours[0]=11;
  check(!(boolean)active.invoke(registry,wearer),"world expiry");
  hours[0]=10;
  for(double value:new double[]{Double.NaN,Double.POSITIVE_INFINITY,10d,18.01d})
   check(!(boolean)grant.invoke(registry,wearer,value,5d),"reject invalid world expiry "+value);
  for(double value:new double[]{Double.NaN,Double.POSITIVE_INFINITY,-1d,0d,15.01d})
   check(!(boolean)grant.invoke(registry,wearer,11d,value),"reject invalid ttl "+value);
  grant.invoke(registry,wearer,11d,15d);clear.invoke(registry,wearer);
  check(!(boolean)active.invoke(registry,wearer),"clear revokes");
  DisguiseRuntime.arm();
  check(!DisguiseRuntime.attackBlocked(null),"null actor has baseline behavior");
  check(!DisguiseRuntime.attackBlocked(new Object()),"nonzombie actor has baseline behavior");
  Class<?> transformer=Class.forName("dev.zombiedisguise.Transformer");
  Method apply=transformer.getDeclaredMethod("instrument",String.class,byte[].class);
  Field pins=transformer.getDeclaredField("PINS");
  Map<?,?> expected=(Map<?,?>)pins.get(null);
  check(expected.containsKey("zombie/ai/states/AttackNetworkState"),"network attack state must be pinned and guarded");
  try(JarFile jar=new JarFile(args[0])){
   for(Object key:expected.keySet()){
    String name=key.toString();byte[] original=jar.getInputStream(jar.getJarEntry(name+".class")).readAllBytes();
    byte[] changed=(byte[])apply.invoke(null,name,original);
    check(!Arrays.equals(original,changed),"instrument "+name);
    check(Arrays.equals(changed,(byte[])apply.invoke(null,name,changed)),"idempotent "+name);
    ClassNode node=new ClassNode();new ClassReader(changed).accept(node,0);
    if(name.equals("zombie/pathfind/PathFindBehavior2")){
      check(node.fields.stream().anyMatch(f->f.name.equals("__zombieDisguiseGoalCancelled")),"concealed goal needs own cancellation marker");
      for(String route:List.of("update","Succeeded"))
       check(node.methods.stream().filter(m->m.name.equals(route)).anyMatch(m->Arrays.stream(m.instructions.toArray()).anyMatch(i->i instanceof FieldInsnNode f&&f.name.equals("__zombieDisguiseGoalCancelled")&&f.getOpcode()==Opcodes.GETFIELD)),"cached path route guarded "+route);
      check(node.methods.stream().filter(m->m.name.startsWith("pathTo")).allMatch(m->Arrays.stream(m.instructions.toArray()).anyMatch(i->i instanceof FieldInsnNode f&&f.name.equals("__zombieDisguiseGoalCancelled")&&f.getOpcode()==Opcodes.PUTFIELD)),"new goals release only own cancellation marker");
    }
    if(name.equals("zombie/characters/IsoGameCharacter"))
      for(String method:List.of("getZombieDisguiseBridgeVersion","setZombieDisguiseLease","clearZombieDisguiseLease"))
       check(node.methods.stream().anyMatch(m->m.name.equals(method)&&(m.access&Opcodes.ACC_PUBLIC)!=0),"public bridge "+method);
    original[original.length-1]^=1;
    try{apply.invoke(null,name,original);throw new AssertionError("unknown hash accepted "+name);}
    catch(InvocationTargetException rejected){check(rejected.getCause() instanceof IllegalArgumentException,"unknown hash rejected "+name);}
   }
  }
  check(Files.readString(Path.of(args[1])).indexOf("getDeclaredField")==-1,"runtime must not use private reflection");
  Class<?> agent=Class.forName("dev.zombiedisguise.Agent");
  Method preflight;
  try{preflight=agent.getDeclaredMethod("prepareClass",String.class,byte[].class);}
  catch(NoSuchMethodException missing){throw new AssertionError("Preflight must reject unknown premarked classes before transformer registration");}
  try(JarFile jar=new JarFile(args[0])){
   String name="zombie/characters/BodyDamage/BodyDamage";
   byte[] original=jar.getInputStream(jar.getJarEntry(name+".class")).readAllBytes();
   check(Arrays.equals((byte[])preflight.invoke(null,name,original),(byte[])apply.invoke(null,name,original)),"preflight accepts exact engine class");
   byte[] alreadyMarked=(byte[])apply.invoke(null,name,original);
   try{preflight.invoke(null,name,alreadyMarked);throw new AssertionError("premarked disk class bypassed compatibility gate");}
   catch(InvocationTargetException rejected){check(rejected.getCause() instanceof IllegalArgumentException,"premarked disk class rejected before registration");}
  }
  agent.getDeclaredField("agentPath").set(null,"C:/native/disguise.jar");
  Method coop=agent.getDeclaredMethod("prepareCoop",ProcessBuilder.class);
  ProcessBuilder child=new ProcessBuilder("java","-Xmx1g","zombie.network.GameServer","-port","16261");
  coop.invoke(null,child);
  check(child.command().get(1).equals("-javaagent:C:/native/disguise.jar"),"host child inherits exact agent");
  coop.invoke(null,child);check(Collections.frequency(child.command(),"-javaagent:C:/native/disguise.jar")==1,"host insertion idempotent");
  ProcessBuilder unrelated=new ProcessBuilder("java","OtherMain");coop.invoke(null,unrelated);
  check(unrelated.command().size()==2,"unrelated child unchanged");
  System.out.println("PASS "+tests+" native assertions (leases, installed bytecode, unknown hash, idempotence, coop propagation)");
 }
}