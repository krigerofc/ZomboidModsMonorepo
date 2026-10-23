package dev.zombiedisguise;
import java.lang.instrument.*;
import java.nio.file.*;
import java.util.*;
public final class Agent {
 static String agentPath;
 public static void premain(String options,Instrumentation inst){
  try{
   agentPath=Paths.get(Agent.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toAbsolutePath().toString();
   ClassLoader loader=ClassLoader.getSystemClassLoader();
   Set<String> names=Transformer.PINS.keySet();
   for(Class<?> loaded:inst.getAllLoadedClasses())if(names.contains(loaded.getName().replace('.','/')))throw new IllegalStateException("Class loaded before agent: "+loaded.getName());
   Map<String,byte[]> prepared=new HashMap<>();
   for(String name:names){
    try(var stream=loader.getResourceAsStream(name+".class")){
     if(stream==null)throw new IllegalArgumentException("Missing supported class "+name);
     prepared.put(name,prepareClass(name,stream.readAllBytes()));
    }
   }
   Transformer transformer=new Transformer(prepared);inst.addTransformer(transformer,false);
   for(String name:names)Class.forName(name.replace('/','.'),false,loader);
   if(!transformer.installed.equals(names))throw new IllegalStateException("Partial instrumentation "+transformer.installed);
   DisguiseRuntime.arm();
   System.err.println("[ZombieDisguiseNative] READY bridge=1 build=42.19.2 classes="+prepared.size()+" jar="+agentPath);
  }catch(Throwable error){DisguiseRuntime.disable(error);}
 }
 static byte[] prepareClass(String name,byte[] bytes){
  if(!Transformer.sha(bytes).equals(Transformer.PINS.get(name)))throw new IllegalArgumentException("Unsupported original class SHA256: "+name+" "+Transformer.sha(bytes));
  return Transformer.instrument(name,bytes);
 }
 /** Scope propagation to the game-hosted dedicated child only. */
 public static ProcessBuilder prepareCoop(ProcessBuilder child){
  if(agentPath!=null&&child.command().contains("zombie.network.GameServer")){
   String arg="-javaagent:"+agentPath;
   if(!child.command().contains(arg))child.command().add(1,arg);
  }
  return child;
 }
}