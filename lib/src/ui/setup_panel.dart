part of '../../main.dart';

class _SetupPanel extends ConsumerStatefulWidget {
  const _SetupPanel({required this.houses});

  final List<House> houses;

  @override
  ConsumerState<_SetupPanel> createState() => _SetupPanelState();
}

class _SetupPanelState extends ConsumerState<_SetupPanel> {
  final _houseController = TextEditingController();

  @override
  void dispose() {
    _houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              title: 'House setup',
              icon: Icons.maps_home_work_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _houseController,
                    decoration: const InputDecoration(
                      labelText: 'House name',
                      hintText: 'A1, Villa 3, Krishna Home',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    final name = _houseController.text.trim();
                    if (name.isEmpty) return;
                    HapticFeedback.selectionClick();
                    ref.read(ledgerProvider.notifier).addHouse(name);
                    _houseController.clear();
                  },
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final house in widget.houses)
                  InputChip(
                    avatar: const Icon(Icons.home_outlined, size: 18),
                    label: Text(house.name),
                    onDeleted: () {
                      HapticFeedback.mediumImpact();
                      ref.read(ledgerProvider.notifier).removeHouse(house.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
