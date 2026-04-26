import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';

class _ServerData {
  final String flag;
  final String country;
  final String city;
  final int ping;
  final String id;

  const _ServerData({
    required this.flag,
    required this.country,
    required this.city,
    required this.ping,
    required this.id,
  });
}

const _servers = [
  _ServerData(flag: '🇳🇱', country: 'Нидерланды', city: 'Amsterdam', ping: 31, id: 'nl'),
  _ServerData(flag: '🇩🇪', country: 'Германия', city: 'Frankfurt', ping: 24, id: 'de'),
  _ServerData(flag: '🇫🇮', country: 'Финляндия', city: 'Helsinki', ping: 18, id: 'fi'),
  _ServerData(flag: '🇺🇸', country: 'США', city: 'New York', ping: 87, id: 'us'),
  _ServerData(flag: '🇬🇧', country: 'Великобритания', city: 'London', ping: 45, id: 'gb'),
  _ServerData(flag: '🇯🇵', country: 'Япония', city: 'Tokyo', ping: 142, id: 'jp'),
  _ServerData(flag: '🇸🇬', country: 'Сингапур', city: 'Singapore', ping: 115, id: 'sg'),
  _ServerData(flag: '🇨🇭', country: 'Швейцария', city: 'Zurich', ping: 38, id: 'ch'),
  _ServerData(flag: '🇸🇪', country: 'Швеция', city: 'Stockholm', ping: 22, id: 'se'),
  _ServerData(flag: '🇨🇦', country: 'Канада', city: 'Toronto', ping: 96, id: 'ca'),
  _ServerData(flag: '🇦🇺', country: 'Австралия', city: 'Sydney', ping: 178, id: 'au'),
  _ServerData(flag: '🇫🇷', country: 'Франция', city: 'Paris', ping: 42, id: 'fr'),
];

class GeoBottomSheet extends HookConsumerWidget {
  const GeoBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedId = useState('nl');

    final filtered = _servers.where((s) {
      final q = searchQuery.value.toLowerCase();
      return q.isEmpty || s.country.toLowerCase().contains(q) || s.city.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: mc.s1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: mc.b1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: mc.b2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выбор локации',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mc.text,
                  ),
                ),
                const Gap(12),
                // Search
                TextField(
                  controller: searchController,
                  onChanged: (v) => searchQuery.value = v,
                  style: TextStyle(fontSize: 14, color: mc.text),
                  decoration: InputDecoration(
                    hintText: 'Поиск страны...',
                    hintStyle: TextStyle(color: mc.t3),
                    prefixIcon: Icon(Icons.search, size: 18, color: mc.t3),
                    filled: true,
                    fillColor: mc.s2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: mc.b1, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: mc.b1, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: mc.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ],
            ),
          ),

          // Server list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Gap(6),
              itemBuilder: (context, index) {
                final s = filtered[index];
                final isSelected = s.id == selectedId.value;
                return GestureDetector(
                  onTap: () {
                    selectedId.value = s.id;
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? mc.accentDim : mc.s2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? mc.accent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(s.flag, style: const TextStyle(fontSize: 22)),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.country, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: mc.text)),
                              const Gap(2),
                              Text(s.city, style: TextStyle(fontSize: 11, color: mc.t3)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, size: 16, color: mc.accent)
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _pingBgColor(s.ping, mc),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${s.ping} мс',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _pingTextColor(s.ping, mc),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _pingBgColor(int ping, MokyThemeData mc) {
    if (ping < 50) return mc.greenDim;
    if (ping < 100) return const Color(0xFFFFB347).withValues(alpha: 0.12);
    return mc.redDim;
  }

  Color _pingTextColor(int ping, MokyThemeData mc) {
    if (ping < 50) return mc.green;
    if (ping < 100) return const Color(0xFFFFB347);
    return mc.red;
  }
}

// Legacy ServersPage kept for compatibility but redirects to GeoBottomSheet
class ServersPage extends ConsumerWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show as bottom sheet immediately and pop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GeoBottomSheet(),
      );
    });
    return const SizedBox();
  }
}
