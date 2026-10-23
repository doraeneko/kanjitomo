package com.kanjitomo.kanjitomo

import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.kanjitomo/anki_notes"
    private val ankiPermission = "com.ichi2.anki.permission.READ_WRITE_DATABASE"
    private val permissionRequestCode = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (ContextCompat.checkSelfPermission(this, ankiPermission)
                            == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this, arrayOf(ankiPermission), permissionRequestCode
                            )
                        }
                    }
                    "queryDecks" -> {
                        try {
                            result.success(queryDecks())
                        } catch (e: Exception) {
                            result.error("QUERY_FAILED", e.message, null)
                        }
                    }
                    "queryModels" -> {
                        try {
                            result.success(queryModels())
                        } catch (e: Exception) {
                            result.error("QUERY_FAILED", e.message, null)
                        }
                    }
                    "queryNotesByDeck" -> {
                        try {
                            val deckName = call.argument<String>("deckName") ?: ""
                            result.success(queryNotesByDeck(deckName))
                        } catch (e: Exception) {
                            result.error("QUERY_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val granted = grantResults.isNotEmpty()
                && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun queryDecks(): List<Map<String, Any>> {
        val uri = Uri.parse("content://com.ichi2.anki.flashcards/decks")
        val cursor = contentResolver.query(uri, null, null, null, null)
            ?: return emptyList()

        val decks = mutableListOf<Map<String, Any>>()
        cursor.use {
            // Column names vary across AnkiDroid versions.
            val idIdx = bestColumnIndex(it, "_id", "deck_id")
            val nameIdx = bestColumnIndex(it, "deck_name", "name")
            if (idIdx < 0 || nameIdx < 0) return@use
            while (it.moveToNext()) {
                decks.add(mapOf(
                    "id" to it.getLong(idIdx),
                    "name" to (it.getString(nameIdx) ?: "")
                ))
            }
        }
        return decks
    }

    private fun queryModels(): List<Map<String, Any>> {
        val uri = Uri.parse("content://com.ichi2.anki.flashcards/models")
        val cursor = contentResolver.query(uri, null, null, null, null)
            ?: return emptyList()

        val models = mutableListOf<Map<String, Any>>()
        cursor.use {
            val idIdx = bestColumnIndex(it, "_id", "model_id")
            val nameIdx = bestColumnIndex(it, "name", "model_name")
            val fieldsIdx = bestColumnIndex(it, "field_names", "fld_names")
            if (idIdx < 0 || nameIdx < 0) return@use
            while (it.moveToNext()) {
                val map = mutableMapOf<String, Any>(
                    "id" to it.getLong(idIdx),
                    "name" to (it.getString(nameIdx) ?: "")
                )
                if (fieldsIdx >= 0) {
                    map["fieldNames"] = it.getString(fieldsIdx) ?: ""
                }
                models.add(map)
            }
        }
        return models
    }

    private fun queryNotesByDeck(deckName: String): List<Map<String, Any>> {
        val notesUri = Uri.parse("content://com.ichi2.anki.flashcards/notes")
        // The notes provider interprets the selection as an Anki search
        // query, so the deck name must be escaped for that syntax.
        val selection = "deck:\"${escapeAnkiSearch(deckName)}\""
        val cursor = contentResolver.query(
            notesUri,
            arrayOf("_id", "mid", "flds", "tags"),
            selection,
            null,
            null
        ) ?: return emptyList()

        val notes = mutableListOf<Map<String, Any>>()
        cursor.use {
            val idIdx = it.getColumnIndex("_id")
            val midIdx = it.getColumnIndex("mid")
            val fldsIdx = it.getColumnIndex("flds")
            val tagsIdx = it.getColumnIndex("tags")
            while (it.moveToNext()) {
                val flds = it.getString(fldsIdx) ?: ""
                notes.add(mapOf(
                    "id" to it.getLong(idIdx),
                    "mid" to it.getLong(midIdx),
                    "fields" to flds.split("\u001f"),
                    "tags" to (it.getString(tagsIdx) ?: "")
                ))
            }
        }
        return notes
    }

    /**
     * Escape characters that are special inside a quoted Anki search term:
     * backslash and quote, plus the wildcards `*` and `_`.
     */
    private fun escapeAnkiSearch(text: String): String =
        text.replace(Regex("""([\\"*_])"""), """\\$1""")

    /** Return the index of the first column name that exists, or -1. */
    private fun bestColumnIndex(cursor: android.database.Cursor, vararg names: String): Int {
        for (name in names) {
            val idx = cursor.getColumnIndex(name)
            if (idx >= 0) return idx
        }
        return -1
    }
}
