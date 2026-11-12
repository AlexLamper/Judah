import 'package:material_ui/material_ui.dart';

import '../data/verses.dart';

class TopicPicker extends StatelessWidget {
  const TopicPicker({
    super.key,
    required this.topics,
    required this.selected,
    required this.onChanged,
  });

  final List<Topic> topics;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in topics)
          FilterChip(
            label: Text(t.label),
            selected: selected.contains(t.id),
            onSelected: (on) {
              final next = {...selected};
              on ? next.add(t.id) : next.remove(t.id);
              onChanged(next);
            },
          ),
      ],
    );
  }
}
