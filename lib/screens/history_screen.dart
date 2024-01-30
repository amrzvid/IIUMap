import 'package:flutter/material.dart';
import 'package:flutter_iiumap/provider/auth_provider.dart';
import 'package:flutter_iiumap/screens/welcome_screen.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("IIUMap"),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
              onPressed: () async {
                ap.signOut().then(
                      (value) => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomeScreen(),
                          ),
                          (route) => false),
                    );
              },
              icon: const Icon(Icons.logout),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
              )),
        ],
      ),
    );
  }
}
