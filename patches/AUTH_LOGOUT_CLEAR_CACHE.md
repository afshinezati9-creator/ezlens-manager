# Clear cache on logout

In `auth_provider.dart` (or wherever you call logout / clearSession):

```dart
import 'package:ezlens_manager/core/cache/local_cache_service.dart';

Future<void> logout() async {
  // ... existing token clear ...
  await LocalCacheService.instance.clearAllEzLensCache();
}
```

Do **not** clear cache on app restart — only on explicit logout.
