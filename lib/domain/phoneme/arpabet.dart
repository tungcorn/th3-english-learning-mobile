/// ARPAbet phoneme metadata: IPA display, articulation classes and similarity.
library;

const Map<String, String> arpabetToIpa = {
  'AA': 'ɑ',
  'AE': 'æ',
  'AH': 'ʌ',
  'AO': 'ɔ',
  'AW': 'aʊ',
  'AY': 'aɪ',
  'EH': 'ɛ',
  'ER': 'ɝ',
  'EY': 'eɪ',
  'IH': 'ɪ',
  'IY': 'i',
  'OW': 'oʊ',
  'OY': 'ɔɪ',
  'UH': 'ʊ',
  'UW': 'u',
  'B': 'b',
  'CH': 'tʃ',
  'D': 'd',
  'DH': 'ð',
  'F': 'f',
  'G': 'ɡ',
  'HH': 'h',
  'JH': 'dʒ',
  'K': 'k',
  'L': 'l',
  'M': 'm',
  'N': 'n',
  'NG': 'ŋ',
  'P': 'p',
  'R': 'r',
  'S': 's',
  'SH': 'ʃ',
  'T': 't',
  'TH': 'θ',
  'V': 'v',
  'W': 'w',
  'Y': 'j',
  'Z': 'z',
  'ZH': 'ʒ',
};

const Set<String> _vowels = {
  'AA',
  'AE',
  'AH',
  'AO',
  'AW',
  'AY',
  'EH',
  'ER',
  'EY',
  'IH',
  'IY',
  'OW',
  'OY',
  'UH',
  'UW',
};

/// Sounds that are easily confused; substituting within a group is a near miss.
const List<Set<String>> _closeGroups = [
  {'IY', 'IH'},
  {'EH', 'AE'},
  {'AA', 'AH', 'AO'},
  {'UW', 'UH'},
  {'EY', 'EH'},
  {'OW', 'AO'},
  {'P', 'B'},
  {'T', 'D'},
  {'K', 'G'},
  {'F', 'V'},
  {'S', 'Z'},
  {'SH', 'ZH'},
  {'CH', 'JH'},
  {'S', 'SH'},
  {'CH', 'SH'},
  {'TH', 'T'},
  {'TH', 'S'},
  {'TH', 'F'},
  {'DH', 'D'},
  {'DH', 'Z'},
  {'N', 'NG'},
  {'L', 'R'},
  {'L', 'N'},
];

bool isVowel(String phoneme) => _vowels.contains(phoneme);

String toIpa(String phoneme) => arpabetToIpa[phoneme] ?? phoneme.toLowerCase();

/// Removes the CMU stress digit: `AH0` becomes `AH`.
String stripStress(String phoneme) => phoneme.replaceAll(RegExp(r'[0-9]'), '');

/// Returns 1 for identical sounds, 0.6 for confusable sounds, 0.3 for sounds of
/// the same broad class (both vowels or both consonants) and 0 otherwise.
double phonemeSimilarity(String a, String b) {
  if (a == b) return 1;
  for (final group in _closeGroups) {
    if (group.contains(a) && group.contains(b)) return 0.6;
  }
  return isVowel(a) == isVowel(b) ? 0.3 : 0;
}
