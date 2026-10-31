import 'package:flutter/material.dart';

import '../../domain/phoneme/arpabet.dart';
import '../../domain/phoneme/phoneme_aligner.dart';
import '../../domain/phoneme/pronunciation_scorer.dart';
import '../theme.dart';

/// Shows one word with a tile per sound, marking those that went wrong.
class PhonemeStrip extends StatelessWidget {
  const PhonemeStrip({super.key, required this.result});

  final WordResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heard = result.recognizedWord;
    final subtitle = heard == null
        ? 'Chưa nghe thấy từ này'
        : heard == result.word
        ? null
        : 'Nghe thành "$heard"';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(result.word, style: textTheme.titleMedium),
        if (subtitle != null) Text(subtitle, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (final column in result.phonemes) _PhonemeTile(column: column),
          ],
        ),
      ],
    );
  }
}

class _PhonemeTile extends StatelessWidget {
  const _PhonemeTile({required this.column});

  final AlignedPhoneme column;

  @override
  Widget build(BuildContext context) {
    final status = column.status;
    final colors = phonemeColors(context, status);
    final expected = column.expected;
    final actual = column.actual;
    final label = expected == null ? '+${toIpa(actual!)}' : toIpa(expected);
    final detail = switch (status) {
      PhonemeStatus.correct || PhonemeStatus.extra => null,
      PhonemeStatus.missing => 'thiếu',
      PhonemeStatus.near || PhonemeStatus.wrong => toIpa(actual!),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          if (detail != null)
            Text(
              detail,
              style: TextStyle(color: colors.foreground, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
