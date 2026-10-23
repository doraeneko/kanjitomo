# ONNX Runtime's native (C++) JNI glue calls FindClass()/GetMethodID() with
# hardcoded class/method names (e.g. ai.onnxruntime.TensorInfo) that appear
# nowhere in Java/Kotlin bytecode -- R8 can't see those as "used" and was
# stripping TensorInfo entirely from the release APK, crashing OrtSession.run()
# with "JNI DETECTED ERROR: java_class == null" on first real inference call.
-keep class ai.onnxruntime.** { *; }

# ML Kit text recognition: the Flutter plugin references Chinese/Korean/Devanagari
# recognizer classes that aren't bundled when only the Japanese module is included.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# google_mlkit_text_recognition plugin references Chinese/Korean/Devanagari
# recognizer classes that aren't included when only the Japanese dependency
# is added.  Suppress the R8 missing-class errors.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**
