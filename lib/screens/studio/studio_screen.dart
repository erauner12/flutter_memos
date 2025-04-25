import 'package:flutter/cupertino.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with actual Studio UI later
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Studio'),
      ),
      child: Center(
        child: Text('Studio Placeholder'),
      ),
    );
  }
}
