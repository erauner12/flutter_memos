import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/providers/chat_overlay_providers.dart';
import 'package:flutter_memos/screens/chat_screen.dart'; // Reuse existing ChatScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatOverlay extends ConsumerWidget {
  const ChatOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showChat = ref.watch(chatOverlayVisibleProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = screenWidth * 0.85; // Use 85% of the screen width

    // Calculate the safe area padding on the left/right
    final safePadding = MediaQuery.of(context).padding;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250), // Slightly faster animation
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      left: showChat ? 0 : -overlayWidth, // Slide from left
      width: overlayWidth,
      child: GestureDetector(
        // Add gesture detector for swipe-to-close
        onHorizontalDragUpdate: (details) {
          // If user swipes left with enough negative delta, close overlay
          const swipeThreshold = -10.0; // Minimum negative movement to trigger close
          if (details.delta.dx < swipeThreshold) {
            ref.read(chatOverlayVisibleProvider.notifier).state = false;
            if (kDebugMode) {
              print('[ChatOverlay] Swipe detected, closing chat overlay.');
            }
          }
        },
        child: Container(
          // Use Container for background color and shadow
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 1.0,
                offset: const Offset(2.0, 0.0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Embed the existing ChatScreen
              // Add padding to account for potential safe area intrusion by the overlay itself
              Positioned.fill(
                left: safePadding.left, // Apply safe area padding if needed
                right: safePadding.right,
                top: safePadding.top,
                bottom: safePadding.bottom,
                child: const ChatScreen(),
              ),

              // Close button positioned within safe area
              Positioned(
                // Adjust top position to be below status bar
                top: safePadding.top + 10,
                // Adjust left position to be inside the overlay, respecting safe area
                left: safePadding.left + 10,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(chatOverlayVisibleProvider.notifier).state = false;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 20,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
