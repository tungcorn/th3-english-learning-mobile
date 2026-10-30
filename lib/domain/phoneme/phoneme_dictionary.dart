import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'arpabet.dart';
import 'grapheme_to_phoneme.dart';

const Map<String, String> _numberWords = {
  '0': 'zero',
  '1': 'one',
  '2': 'two',
  '3': 'three',
  '4': 'four',
  '5': 'five',
  '6': 'six',
  '7': 'seven',
  '8': 'eight',
  '9': 'nine',
  '10': 'ten',
};

/// Lowercases, drops punctuation and spells out small numbers, because speech
/// engines return "4" for a spoken "four".
List<String> normalizeWords(String text) {
  final cleaned = text
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ');
  return cleaned
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r"^'+|'+$"), ''))
      .where((w) => w.isNotEmpty)
      .map((w) => _numberWords[w] ?? w)
      .toList();
}

/// Looks up reference pronunciations in the CMU Pronouncing Dictionary.
class PhonemeDictionary {
  PhonemeDictionary(this._entries);

  final Map<String, List<List<String>>> _entries;

  static Future<PhonemeDictionary> loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/data/cmudict.dict');
    return PhonemeDictionary(await compute(parseCmuDict, raw));
  }

  /// All known pronunciations of [word]; unknown words use letter rules.
  List<List<String>> lookup(String word) {
    final key = word.toLowerCase();
    return _entries[key] ?? [graphemeToPhoneme(key)];
  }

  bool contains(String word) => _entries.containsKey(word.toLowerCase());
}

/// Parses `word(2) AH0 B # comment` lines. Top level so it can run in an isolate.
Map<String, List<List<String>>> parseCmuDict(String raw) {
  final entries = <String, List<List<String>>>{};
  for (final line in const LineSplitter().convert(raw)) {
    final content = line.split('#').first.trim();
    if (content.isEmpty) continue;
    final parts = content.split(RegExp(r'\s+'));
    final word = parts.first.replaceAll(RegExp(r'\(\d+\)$'), '');
    entries
        .putIfAbsent(word, () => [])
        .add(parts.skip(1).map(stripStress).toList());
  }
  return entries;
}
