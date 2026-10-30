import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/entry.dart';
import '../crypto/aes_gcm.dart';

class VaultRepository {
  static const _prefsKey = 'pk_vault_blob';

  Future<void> save(Uint8List key, List<VaultEntry> entries) async {
    final json = jsonEncode({
      'version': 1,
      'entries': entries
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'username': e.username,
                'password': e.password,
                'website': e.website,
                'notes': e.notes,
                'category': e.category.name,
                'favorite': e.favorite,
                'createdAt': e.createdAt.toIso8601String(),
                'updatedAt': e.updatedAt.toIso8601String(),
              })
          .toList(),
    });
    final cipher =
        await AesGcm.encrypt(key, Uint8List.fromList(utf8.encode(json)));
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, base64Encode(cipher));
    } else {
      final f = await _file();
      await f.writeAsBytes(cipher, flush: true);
    }
  }

  Future<List<VaultEntry>> load(Uint8List key) async {
    Uint8List bytes;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_prefsKey);
      if (v == null) return [];
      bytes = base64Decode(v);
    } else {
      final f = await _file();
      if (!await f.exists()) return [];
      bytes = await f.readAsBytes();
      if (bytes.isEmpty) return [];
    }
    final plain = await AesGcm.decrypt(key, bytes);
    final map = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final list = (map['entries'] as List).cast<Map<String, dynamic>>();
    return list.map((m) {
      return VaultEntry(
        id: m['id'] as String,
        title: m['title'] as String,
        username: m['username'] as String?,
        password: m['password'] as String?,
        website: m['website'] as String?,
        notes: m['notes'] as String?,
        category: EntryCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => EntryCategory.other,
        ),
        favorite: m['favorite'] as bool? ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
    }).toList();
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } else {
      final f = await _file();
      if (await f.exists()) await f.delete();
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/vault.enc');
  }
}
