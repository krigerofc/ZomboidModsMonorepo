package dev.zombiedisguise;
public final class UnavailableSmoke {
 public static void main(String[] args)throws Exception{
  if(DisguiseRuntime.version()!=0)throw new AssertionError("Unknown engine resource must disable grants");
  Class<?> c=Class.forName("zombie.characters.IsoGameCharacter",false,ClassLoader.getSystemClassLoader());
  try{c.getDeclaredMethod("getZombieDisguiseBridgeVersion");throw new AssertionError("No partial instrumentation allowed on unsupported build");}
  catch(NoSuchMethodException expected){}
  System.out.println("PASS unsupported resource leaves all engine classes unmodified and application running");
 }
}
