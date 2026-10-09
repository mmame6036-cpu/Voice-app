import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'services/user_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic>? _foundUser;
  bool _isSearching = false;
  String _statusMessage = 'Search users by their unique ID';

  Future<void> _handleSearch() async {
    final queryId = _searchController.text.trim();
    if (queryId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _statusMessage = 'Searching...';
    });

    final result = await _userService.searchUser(queryId);

    setState(() {
      _isSearching = false;
      if (result != null) {
        _foundUser = result;
        _statusMessage = '';
      } else {
        _statusMessage = 'User not found with ID: $queryId';
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Direct Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter User ID (e.g. 1000, 1001)',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  IconButton(
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9A7)),
                          )
                        : const Icon(Icons.arrow_forward, color: Color(0xFF00C9A7)),
                    onPressed: _handleSearch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Results or Status
            if (_foundUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
                ),
                child: Row(
                  children: [

CircleAvatar(
                      backgroundColor: const Color(0xFF00C9A7),
                      child: Text(
                        (_foundUser!['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!['name'] ?? 'User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'User ID: ${_foundUser!['userId']}',
                          style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        // Start Chat Action
                      },
                      child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
