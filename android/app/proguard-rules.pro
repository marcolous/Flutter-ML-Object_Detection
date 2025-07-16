# Keep TFLite core and GPU classes (including inner classes)
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$* { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate$* { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
