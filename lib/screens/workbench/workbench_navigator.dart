import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/navigation_providers.dart';
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchNavigator extends ConsumerWidget {
  const WorkbenchNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Retrieve the navigator key from the provider
    final navKey = ref.watch(workbenchNavKeyProvider);

    // Listen for tab reselection events
    ref.listen<int?>(reselectTabProvider, (previous, next) {
      // Assuming Workbench is tab index 0 (adjust if different)
      // See lib/screens/home_tabs.dart for actual index
      const workbenchTabIndex = 0; // Or use HomeTab.workbench.index if available

      if (next == workbenchTabIndex) {
        // Check if the nested navigator can pop and is not already at the root
        if (navKey.currentState != null && navKey.currentState!.canPop()) {
          // Pop back to the hub screen ('/')
          navKey.currentState!.popUntil((route) => route.isFirst);
        }
        // Reset the provider state after handling
        ref.read(reselectTabProvider.notifier).state = null;
      }
    });

    return Navigator(
      key: navKey,
      initialRoute: '/', // Start at the hub screen
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/': // Hub screen
            builder = (BuildContext _) => const WorkbenchHubScreen();
            break;
          case String name when name.startsWith('/workbench/'): // Detail screen
            final instanceId = name.substring('/workbench/'.length);
            if (instanceId.isNotEmpty) {
              builder = (BuildContext _) => WorkbenchScreen(instanceId: instanceId);
            } else {
              // Handle invalid ID case, maybe redirect to hub
              builder = (BuildContext _) => const WorkbenchHubScreen();
            }
            break;
          default:
            // Handle unknown routes, maybe redirect to hub
            builder = (BuildContext _) => const WorkbenchHubScreen();
        }
        // Use CupertinoPageRoute for iOS-style transitions
        return CupertinoPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
