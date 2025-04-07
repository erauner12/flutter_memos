import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/services/mcp_service.dart';

class McpDemoWidget extends StatefulWidget {
  const McpDemoWidget({super.key});

  @override
  State<McpDemoWidget> createState() => _McpDemoWidgetState();
}

class _McpDemoWidgetState extends State<McpDemoWidget> {
  final McpService _mcpService = McpService();

  dynamic _data;
  bool _loading = false;
  String? _error;

  Future<void> _handleFetchData(String type) async {
    setState(() {
      _loading = true;
      _data = null;
      _error = null;
    });

    try {
      print('Fetching $type via MCP');

      final response = await _mcpService.fetchFromMcp(type);

      setState(() {
        _data = response['data'];
        _loading = false;
      });

      print('MCP fetch $type successful: $response');
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch $type: ${e.toString()}';
        _loading = false;
      });

      print('Error fetching $type via MCP: $e');
    }
  }

  Widget _renderMemos(dynamic data) {
    if (data == null || data['memos'] == null || data['memos'].isEmpty) {
      return Center(
        child: Text(
          'No memos found',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final memos = data['memos'] as List;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: memos.length,
      itemBuilder: (context, index) {
        final memo = memos[index];
        final id = memo['name'].toString().split('/').last;
        final isPinned = memo['pinned'] == true;
        final isArchived = memo['state'] == 'ARCHIVED';

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo['content'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: $id',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (isPinned)
                        Text(
                          '📌 Pinned',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      if (isArchived)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '🗄️ Archived',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _renderTags(dynamic data) {
    if (data == null || data['tags'] == null || data['tags'].isEmpty) {
      return Center(
        child: Text(
          'No tags found',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final tags = data['tags'] as List;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map<Widget>((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag['name'] ?? '',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _renderUsers(dynamic data) {
    if (data == null || data['users'] == null || data['users'].isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final users = data['users'] as List;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final id = user['name'].toString().split('/').last;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['nickname'] ?? 'User',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'ID: $id',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _renderContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CupertinoActivityIndicator(), // Use CupertinoActivityIndicator
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _error!,
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(
                context,
              ), // Use Cupertino color
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Select a data type to fetch',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: CupertinoColors.secondaryLabel.resolveFrom(
                context,
              ), // Use Cupertino color
            ),
          ),
        ),
      );
    }

    // Determine content type and render accordingly
    if (_data.containsKey('memos')) {
      return _renderMemos(_data);
    } else if (_data.containsKey('tags')) {
      return _renderTags(_data);
    } else if (_data.containsKey('users')) {
      return _renderUsers(_data);
    } else {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            _data.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace Card with Container
    return Container(
      margin: const EdgeInsets.all(8.0), // Add margin similar to Card
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Fetching Demo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                // Replace ElevatedButton with CupertinoButton.filled
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // Use specific colors or theme primary
                  // backgroundColor: const Color(0xFFDC4C3E), // Example color
                  // foregroundColor: CupertinoColors.white,
                  onPressed: () => _handleFetchData('memos'),
                  child: const Text('Fetch Memos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // backgroundColor: const Color(0xFF0079BF),
                  // foregroundColor: CupertinoColors.white,
                  onPressed: () => _handleFetchData('tags'),
                  child: const Text('Fetch Tags'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // backgroundColor: const Color(0xFF5AAC44),
                  // foregroundColor: CupertinoColors.white,
                  onPressed: () => _handleFetchData('users'),
                  child: const Text('Fetch Users'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground.resolveFrom(
                context,
              ), // Use Cupertino color
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(
                  context,
                ), // Use Cupertino color
              ),
            ),
            child: _renderContent(),
          ),
        ],
      ),
    );
  }
}
