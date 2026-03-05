import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/admin_dashboard_screen.dart';
import 'package:frontend/screens/student/student_login_screen.dart';

import 'widgets/semseat_theme.dart';
import 'api/status_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SemSeat API Test',
      theme: SemSeatTheme.theme,
      home: AdminDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ApiStatusPage extends StatefulWidget {
  const ApiStatusPage({super.key});

  @override
  State<ApiStatusPage> createState() => _ApiStatusPageState();
}

class _ApiStatusPageState extends State<ApiStatusPage> {
  String _statusText = 'Press the button to check API status.';
  bool _isLoading = false;

  Future<void> _checkApiStatus() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking...';
    });

    try {
      final data = await StatusApi.getStatus();

      if (!mounted) return;

      setState(() {
        _statusText = const JsonEncoder.withIndent('  ').convert(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Error while calling API:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SemSeat – API Status Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _checkApiStatus,
              child: Text(_isLoading ? 'Checking...' : 'Check API Status'),
            ),
            const SizedBox(height: 16),
            Text(
              'Response from /api/status:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusText,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
