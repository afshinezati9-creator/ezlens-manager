import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/providers.dart';
import '../notifications/notification_poller.dart';
import '../notifications/notification_service.dart';

final notificationPollerProvider = Provider<NotificationPoller>((ref) {
  return NotificationPoller(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class SecurityServicesHost extends ConsumerStatefulWidget {
  final Widget child;
  const SecurityServicesHost({super.key, required this.child});
  @override
  ConsumerState<SecurityServicesHost> createState() =>
      _SecurityServicesHostState();
}

class _SecurityServicesHostState extends ConsumerState<SecurityServicesHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      ref.read(notificationPollerProvider).start();
    });
  }

  @override
  void dispose() {
    try {
      ref.read(notificationPollerProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
