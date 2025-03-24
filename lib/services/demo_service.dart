import 'package:flutter/material.dart';

/// This class contains all the demo functionality that was removed from the UI
/// but might be needed in the future.
class DemoService {
  // MCP Integration Demo functionality
  static Widget buildMCPIntegrationDemo({required BuildContext context}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0079BF),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/mcp');
        },
        child: const Text('MCP Integration Demo'),
      ),
    );
  }
  
  // Assistant Chat functionality - partially implemented
  static Widget buildAssistantChat({required BuildContext context}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC4C3E),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        child: const Text('Assistant Chat'),
      ),
    );
    
    // TODO: Implement full Assistant Chat functionality when requirements are finalized
  }
  
  // Filter Demo functionality
  static Widget buildFilterDemo({required BuildContext context}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/filter-demo');
        },
        child: const Text('Filter Demo'),
      ),
    );
  }
  
  // Riverpod Demo functionality
  static Widget buildRiverpodDemo({required BuildContext context}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/riverpod-demo');
        },
        child: const Text('Riverpod Demo'),
      ),
    );
  }
  
  // Riverpod Codegen Test functionality
  static Widget buildRiverpodCodegenTest({required BuildContext context}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF673AB7),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/codegen-test');
        },
        child: const Text('Riverpod Codegen Test'),
      ),
    );
  }
}