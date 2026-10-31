enum ExerciseLevel {
  basic('Cơ bản'),
  intermediate('Trung bình'),
  advanced('Nâng cao');

  const ExerciseLevel(this.label);
  final String label;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.text,
    required this.level,
    required this.focus,
  });

  final String id;
  final String title;
  final String text;
  final ExerciseLevel level;

  /// ARPAbet sounds this exercise trains.
  final Set<String> focus;
}

const List<Exercise> exerciseCatalog = [
  Exercise(
    id: 'greet-1',
    title: 'Chào hỏi',
    text: 'Good morning. How are you today?',
    level: ExerciseLevel.basic,
    focus: {'G', 'UH', 'NG'},
  ),
  Exercise(
    id: 'intro-1',
    title: 'Giới thiệu bản thân',
    text: 'My name is Anna and I live in a small city.',
    level: ExerciseLevel.basic,
    focus: {'M', 'N', 'L'},
  ),
  Exercise(
    id: 'th-voiceless',
    title: 'Âm /θ/ trong "think"',
    text: 'I think three thin thieves thanked Thomas.',
    level: ExerciseLevel.basic,
    focus: {'TH'},
  ),
  Exercise(
    id: 'th-voiced',
    title: 'Âm /ð/ trong "this"',
    text: 'This is the mother of that brother.',
    level: ExerciseLevel.basic,
    focus: {'DH'},
  ),
  Exercise(
    id: 'ship-sheep',
    title: '/ɪ/ và /i/: ship - sheep',
    text: 'The sheep on the ship will sleep in the big green bin.',
    level: ExerciseLevel.basic,
    focus: {'IH', 'IY'},
  ),
  Exercise(
    id: 'bad-bed',
    title: '/æ/ và /ɛ/: bad - bed',
    text: 'The man said the black cat sat on my red bed.',
    level: ExerciseLevel.basic,
    focus: {'AE', 'EH'},
  ),
  Exercise(
    id: 'final-t-d',
    title: 'Âm cuối /t/ và /d/',
    text: 'The old cat had a good night and a hot bed.',
    level: ExerciseLevel.basic,
    focus: {'T', 'D'},
  ),
  Exercise(
    id: 'final-s-z',
    title: 'Âm cuối /s/ và /z/',
    text: 'She buys books and bags for her friends and cats.',
    level: ExerciseLevel.basic,
    focus: {'S', 'Z'},
  ),
  Exercise(
    id: 'final-k-g',
    title: 'Âm cuối /k/ và /g/',
    text: 'The big dog took my black bag back to the park.',
    level: ExerciseLevel.basic,
    focus: {'K', 'G'},
  ),
  Exercise(
    id: 'sh-s',
    title: '/ʃ/ và /s/',
    text: 'She sells fresh fish and sea shells at the shop.',
    level: ExerciseLevel.intermediate,
    focus: {'SH', 'S'},
  ),
  Exercise(
    id: 'ch-jh',
    title: '/tʃ/ và /dʒ/',
    text: 'Jack chose cheap orange juice for the children.',
    level: ExerciseLevel.intermediate,
    focus: {'CH', 'JH'},
  ),
  Exercise(
    id: 'l-r',
    title: '/l/ và /r/',
    text: 'The little rabbit really loves red and yellow rice.',
    level: ExerciseLevel.intermediate,
    focus: {'L', 'R'},
  ),
  Exercise(
    id: 'v-w',
    title: '/v/ và /w/',
    text: 'We have very warm weather in every valley.',
    level: ExerciseLevel.intermediate,
    focus: {'V', 'W'},
  ),
  Exercise(
    id: 'p-f',
    title: '/f/ và /p/',
    text: 'Five happy people found a perfect coffee place.',
    level: ExerciseLevel.intermediate,
    focus: {'F', 'P', 'B'},
  ),
  Exercise(
    id: 'vowel-long',
    title: 'Nguyên âm /u/ và /ʊ/',
    text: 'The good cook took a blue spoon from the school room.',
    level: ExerciseLevel.intermediate,
    focus: {'UW', 'UH'},
  ),
  Exercise(
    id: 'diphthong',
    title: 'Nguyên âm đôi',
    text: 'I know the boy found a nice brown boat by the lake.',
    level: ExerciseLevel.intermediate,
    focus: {'AY', 'OW', 'OY', 'AW', 'EY'},
  ),
  Exercise(
    id: 'r-er',
    title: 'Âm /ɝ/ và /r/',
    text: 'Her first nurse learned a word from the early bird.',
    level: ExerciseLevel.advanced,
    focus: {'ER', 'R'},
  ),
  Exercise(
    id: 'zh-z',
    title: 'Âm /ʒ/ và /z/',
    text: 'Usually the zoo measures the treasure with pleasure.',
    level: ExerciseLevel.advanced,
    focus: {'ZH', 'Z'},
  ),
  Exercise(
    id: 'n-ng',
    title: '/n/ và /ŋ/',
    text: 'The young king is singing a long song in the evening.',
    level: ExerciseLevel.advanced,
    focus: {'NG', 'N'},
  ),
  Exercise(
    id: 'clusters',
    title: 'Cụm phụ âm',
    text: 'The strong student asked the best questions in class.',
    level: ExerciseLevel.advanced,
    focus: {'S', 'T', 'K', 'R'},
  ),
  Exercise(
    id: 'vowels-open',
    title: 'Nguyên âm /ɑ/, /ʌ/, /ɔ/',
    text: 'My mother often walks across the hot sunny lawn.',
    level: ExerciseLevel.advanced,
    focus: {'AA', 'AH', 'AO'},
  ),
  Exercise(
    id: 'h-y-m',
    title: 'Âm /h/, /j/, /m/',
    text: 'Your happy mom helps young men at home each year.',
    level: ExerciseLevel.advanced,
    focus: {'HH', 'Y', 'M'},
  ),
  Exercise(
    id: 'daily-talk',
    title: 'Hội thoại hằng ngày',
    text: 'Could you tell me where the nearest train station is?',
    level: ExerciseLevel.advanced,
    focus: {'SH', 'R', 'T'},
  ),
];

Exercise exerciseById(String id) =>
    exerciseCatalog.firstWhere((exercise) => exercise.id == id);

/// Exercises training [weakPhonemes], most relevant first. Weak sounds are
/// given in priority order and the exercises in [excludeIds] are skipped.
List<Exercise> recommendExercises(
  List<String> weakPhonemes, {
  Set<String> excludeIds = const {},
  int limit = 3,
}) {
  final picked = <Exercise>[];
  for (final phoneme in weakPhonemes) {
    for (final exercise in exerciseCatalog) {
      if (exercise.focus.contains(phoneme) &&
          !excludeIds.contains(exercise.id) &&
          !picked.contains(exercise)) {
        picked.add(exercise);
        if (picked.length == limit) return picked;
      }
    }
  }
  return picked;
}
