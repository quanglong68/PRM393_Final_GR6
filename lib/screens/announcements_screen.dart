import 'package:flutter/material.dart';
import 'package:second_brain_core/second_brain_core.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key, required this.store});

  final FinalFirestore store;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Stream<List<Announcement>> _announcements;

  @override
  void initState() {
    super.initState();
    _announcements = widget.store.watchAnnouncements();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo hệ thống')),
    body: StreamBuilder<List<Announcement>>(
      stream: _announcements,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() {
                _announcements = widget.store.watchAnnouncements();
              }),
              child: const Text('Không tải được thông báo. Thử lại'),
            ),
          );
        }
        final items = snapshot.data;
        if (items == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có thông báo.'));
        }
        return ListView(
          children: [
            for (final item in items)
              ListTile(title: Text(item.title), subtitle: Text(item.body)),
          ],
        );
      },
    ),
  );
}
