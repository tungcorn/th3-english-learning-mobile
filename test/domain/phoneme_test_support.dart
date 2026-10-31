import 'package:english_pronunciation/domain/phoneme/phoneme_dictionary.dart';

/// Small excerpt of CMUdict with the words used by the scoring tests.
PhonemeDictionary testDictionary() => PhonemeDictionary(
  parseCmuDict('''
the DH AH
the(2) DH AH1
the(3) DH IY1
think TH IH1 NG K
sink S IH1 NG K
thin TH IH1 N
tin T IH1 N
ship SH IH1 P
sheep SH IY1 P
this DH IH1 S
is IH1 Z
my M AY1
best B EH1 S T
bet B EH1 T
four F AO1 R
cats K AE1 T S
cat K AE1 T
like L AY1 K
milk M IH1 L K
very V EH1 R IY0
good G UH1 D
wood W UH1 D
foreign F AO1 R AH0 N # comment
'''),
);
