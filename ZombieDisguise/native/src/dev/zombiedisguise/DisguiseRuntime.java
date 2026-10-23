package dev.zombiedisguise;
import java.lang.reflect.*;
import java.util.*;
/** No persistent flags; private engine state is accessed only by injected own-class code. */
public final class DisguiseRuntime {
 private static volatile boolean ready;
 private static final LeaseRegistry leases=new LeaseRegistry(DisguiseRuntime::worldHours,System::nanoTime);
 private static final ClassValue<Map<String,Method>> PUBLIC_METHODS=new ClassValue<>(){
  protected Map<String,Method> computeValue(Class<?> c){Map<String,Method> out=new HashMap<>();for(Method m:c.getMethods())if(m.getParameterCount()==0)out.put(m.getName(),m);return out;}
 };
 static void arm(){ready=true;}
 static void disable(Throwable error){ready=false;leases.clearAll();System.err.println("[ZombieDisguiseNative] UNAVAILABLE: "+error);}
 public static int version(){return ready?1:0;}
 private static double worldHours(){
  try{Class<?> t=Class.forName("zombie.GameTime");Object clock=PUBLIC_METHODS.get(t).get("getInstance").invoke(null);return ((Number)call(clock,"getWorldAgeHours")).doubleValue();}
  catch(ReflectiveOperationException|RuntimeException e){return Double.NaN;}
 }
 public static boolean grant(Object player,double expiry,double ttl){
  return ready && isType(player,"zombie.characters.IsoPlayer") && leases.grant(player,expiry,ttl);
 }
 public static void clear(Object player){leases.clear(player);}
 public static boolean blocked(Object target){return ready&&leases.active(target);}
 static boolean isType(Object o,String name){for(Class<?> c=o==null?null:o.getClass();c!=null;c=c.getSuperclass())if(c.getName().equals(name))return true;return false;}
 private static Object call(Object o,String n)throws ReflectiveOperationException {
  Method m=PUBLIC_METHODS.get(o.getClass()).get(n);if(m==null)throw new NoSuchMethodException(o.getClass().getName()+"."+n);return m.invoke(o);
 }
 /** Delegates to own-class direct bytecode; no access override, private reflection or retained zombie. */
 public static void scrub(Object zombie){
  if(!ready||!isType(zombie,"zombie.characters.IsoZombie"))return;
  try{call(zombie,"__zombieDisguiseScrub");}catch(ReflectiveOperationException e){disable(e);}
 }
 public static boolean pathBlocked(Object pfb,Object target){
  if(!blocked(target))return false;
  try{return isType(call(pfb,"__zombieDisguiseOwner"),"zombie.characters.IsoZombie");}catch(ReflectiveOperationException e){disable(e);return false;}
 }
 public static boolean attackBlocked(Object actor){
  if(!ready||!isType(actor,"zombie.characters.IsoZombie"))return false;
  try{boolean deny=blocked(call(actor,"__zombieDisguiseRawTarget"));if(deny)scrub(actor);return deny;}
  catch(ReflectiveOperationException e){disable(e);return false;}
 }
 public static boolean damageBlocked(Object damage,Object attacker){
  if(!isType(attacker,"zombie.characters.IsoZombie"))return false;
  try{return blocked(call(damage,"getParentChar"));}catch(ReflectiveOperationException e){disable(e);return false;}
 }
 public static boolean pairBlocked(Object attacker,Object victim){return isType(attacker,"zombie.characters.IsoZombie")&&blocked(victim);}
 public static boolean victimBlocked(Object victim,Object attacker){return pairBlocked(attacker,victim);}
 private static Object character(Object value)throws ReflectiveOperationException {
  if(value==null||isType(value,"zombie.characters.IsoGameCharacter"))return value;
  return call(value,"getAnimatable");
 }
 public static boolean grappleBlocked(Object a,Object b){
  if(!ready)return false;
  try{Object first=character(a),second=character(b);return pairBlocked(first,second)||pairBlocked(second,first);}
  catch(ReflectiveOperationException e){disable(e);return false;}
 }
}