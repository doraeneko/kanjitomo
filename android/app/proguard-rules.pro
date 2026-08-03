# ONNX Runtime's native (C++) JNI glue calls FindClass()/GetMethodID() with
# hardcoded class/method names (e.g. ai.onnxruntime.TensorInfo) that appear
# nowhere in Java/Kotlin bytecode -- R8 can't see those as "used" and was
# stripping TensorInfo entirely from the release APK, crashing OrtSession.run()
# with "JNI DETECTED ERROR: java_class == null" on first real inference call.
-keep class ai.onnxruntime.** { *; }
