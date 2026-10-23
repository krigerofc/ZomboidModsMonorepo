package dev.zombiedisguise;
import java.lang.ref.*;
import java.util.*;
import java.util.function.*;
/** Weak object identity, independent game-hour and monotonic expiration. */
final class LeaseRegistry {
 private final ReferenceQueue<Object> queue=new ReferenceQueue<>();
 private final Map<Key,Lease> leases=new HashMap<>();
 private final DoubleSupplier hours; private final LongSupplier nanos;
 private record Lease(double expiry,long deadline) {}
 private static final class Key extends WeakReference<Object> {
  final int hash;
  Key(Object o,ReferenceQueue<Object> q){super(o,q);hash=System.identityHashCode(o);}
  public int hashCode(){return hash;}
  public boolean equals(Object other){return this==other || other instanceof Key k && get()!=null && get()==k.get();}
 }
 LeaseRegistry(DoubleSupplier h,LongSupplier n){hours=h;nanos=n;}
 private void reap(){Reference<?> k;while((k=queue.poll())!=null)leases.remove(k);}
 synchronized boolean grant(Object player,double expiry,double seconds){
  reap();double now=hours.getAsDouble();
  if(player==null||!Double.isFinite(now)||!Double.isFinite(expiry)||!Double.isFinite(seconds)||expiry<=now||expiry-now>8||seconds<=0||seconds>15){
   clear(player);return false;
  }
  leases.put(new Key(player,queue),new Lease(expiry,nanos.getAsLong()+(long)(seconds*1_000_000_000L)));return true;
 }
 synchronized boolean active(Object player){
  if(player==null)return false;reap();Key key=new Key(player,null);Lease lease=leases.get(key);
  if(lease==null)return false;double now=hours.getAsDouble();
  if(!Double.isFinite(now)||now>=lease.expiry||nanos.getAsLong()-lease.deadline>=0){leases.remove(key);return false;}
  return true;
 }
 synchronized void clear(Object player){reap();if(player!=null)leases.remove(new Key(player,null));}
 synchronized void clearAll(){leases.clear();}
}