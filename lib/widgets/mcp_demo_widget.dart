import 'package:flutter/material.dart';
import 'package:flutter_memos/services/mcp_service.dart';

class McpDemoWidget extends StatefulWidget {
  const McpDemoWidget({Key? key}) : super(key: key);

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
      return const Center(
        child: Text('No memos found', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      if (isPinned)
                        const Text(
                          '📌 Pinned',
                          style: TextStyle(fontSize: 12, color: Color(0xFF0079BF)),
                        ),
                      if (isArchived)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            '🗄️ Archived',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
      return const Center(
        child: Text('No tags found', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag['name'] ?? '',
            style: const TextStyle(color: Color(0xFF333333)),
          ),
        );
      }).toList(),
    );
  }

  Widget _renderUsers(dynamic data) {
    if (data == null || data['users'] == null || data['users'].isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['nickname'] ?? 'User',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                'ID: $id',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Select a data type to fetch',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Fetching Demo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC4C3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleFetchData('memos'),
                    child: const Text('Fetch Memos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0079BF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleFetchData('tags'),
                    child: const Text('Fetch Tags'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AAC44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
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
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: _renderContent(),
            ),
          ],
        ),
      ),
    );
  }
}