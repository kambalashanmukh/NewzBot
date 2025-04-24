import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = await authService.signInWithEmail(
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () async {
                final user = await authService.registerWithEmail(
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}