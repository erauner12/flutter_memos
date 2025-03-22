import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/filter_menu.dart';
import '../widgets/memo_list_item.dart';

class MemosScreen extends StatefulWidget {
  const MemosScreen({Key? key}) : super(key: key);

  @override
  State<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends State<MemosScreen> {
  bool loading = false;
  String? error;
  List<Memo> memos = [];

  // Filter keys similar to the react-native version
  String filterKey = 'inbox'; // default

  // A simple mapping from filterKey to V1State or tag
  V1State? _getStateFromFilter(String fk) {
    if (fk == 'inbox') return V1State.normal;
    if (fk == 'archive') return V1State.archived;
    return null;
  }

  String? _getTagFromFilter(String fk) {
    // If it's 'inbox' or 'archive' or 'all', no tags
    if (['inbox', 'archive', 'all'].contains(fk)) return null;
    return fk; // treat the filterKey as tag
  }

  @override
  void initState() {
    super.initState();
    _fetchMemos();
  }

  void _fetchMemos() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await ApiService.instance.listMemos(
        state: _getStateFromFilter(filterKey),
        tag: _getTagFromFilter(filterKey),
      );
      setState(() {
        memos = list;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _onSelectFilter(String newFilter) {
    setState(() {
      filterKey = newFilter;
    });
    _fetchMemos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Memos"),
        actions: [
          // We replicate FilterMenu as a popup
          FilterMenu(
            currentFilterKey: filterKey,
            onSelectFilter: _onSelectFilter,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    "Error: $error",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : memos.isEmpty
                  ? const Center(child: Text("No memos found."))
                  : ListView.builder(
                      itemCount: memos.length,
                      itemBuilder: (context, index) {
                        final memo = memos[index];
                        return MemoListItem(
                          memo: memo,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/memoDetail',
                              arguments: memo.id,
                            );
                          },
                          onArchive: _archiveMemo,
                          onDelete: _deleteMemo,
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/newMemo')
            .then((_) => _fetchMemos()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _archiveMemo(String memoId) async {
    setState(() {
      loading = true;
    });
    try {
      await ApiService.instance.updateMemo(memoId, state: V1State.archived);
      _fetchMemos();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _deleteMemo(String memoId) async {
    setState(() {
      loading = true;
    });
    try {
      await ApiService.instance.deleteMemo(memoId);
      _fetchMemos();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}