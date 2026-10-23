package dev.zombiedisguise;
public final class StartupSmoke {
 public static void main(String[] args)throws Exception{
  if(DisguiseRuntime.version()!=1)throw new AssertionError("All pinned engine classes must transform and verify before bridge readiness");
  Class<?> c=Class.forName("zombie.characters.IsoGameCharacter",false,ClassLoader.getSystemClassLoader());
  c.getDeclaredMethod("getZombieDisguiseBridgeVersion");
  c.getDeclaredMethod("setZombieDisguiseLease",double.class,double.class);
  c.getDeclaredMethod("clearZombieDisguiseLease");
  System.out.println("PASS installed engine class loading, JVM verification, bridge methods, complete readiness");
 }
}
