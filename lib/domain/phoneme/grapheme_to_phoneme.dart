/// Letter-to-sound fallback for words missing from the CMU dictionary, such as
/// names. It is an approximation: longest spelling patterns are matched first.
const Map<String, List<String>> _patterns = {
  'tion': ['SH', 'AH', 'N'],
  'igh': ['AY'],
  'tch': ['CH'],
  'ch': ['CH'],
  'sh': ['SH'],
  'th': ['TH'],
  'ph': ['F'],
  'ng': ['NG'],
  'ck': ['K'],
  'wh': ['W'],
  'qu': ['K', 'W'],
  'ee': ['IY'],
  'ea': ['IY'],
  'oo': ['UW'],
  'ou': ['AW'],
  'ow': ['OW'],
  'ai': ['EY'],
  'ay': ['EY'],
  'oa': ['OW'],
  'oi': ['OY'],
  'oy': ['OY'],
  'au': ['AO'],
  'aw': ['AO'],
  'er': ['ER'],
  'ir': ['ER'],
  'ur': ['ER'],
  'a': ['AE'],
  'b': ['B'],
  'c': ['K'],
  'd': ['D'],
  'e': ['EH'],
  'f': ['F'],
  'g': ['G'],
  'h': ['HH'],
  'i': ['IH'],
  'j': ['JH'],
  'k': ['K'],
  'l': ['L'],
  'm': ['M'],
  'n': ['N'],
  'o': ['AA'],
  'p': ['P'],
  'q': ['K'],
  'r': ['R'],
  's': ['S'],
  't': ['T'],
  'u': ['AH'],
  'v': ['V'],
  'w': ['W'],
  'x': ['K', 'S'],
  'y': ['Y'],
  'z': ['Z'],
};

List<String> graphemeToPhoneme(String word) {
  final letters = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final phonemes = <String>[];
  var i = 0;
  while (i < letters.length) {
    var matched = false;
    for (var size = 4; size >= 1 && !matched; size--) {
      if (i + size > letters.length) continue;
      final pattern = _patterns[letters.substring(i, i + size)];
      if (pattern != null) {
        phonemes.addAll(pattern);
        i += size;
        matched = true;
      }
    }
    if (!matched) i++;
  }
  return phonemes;
}
