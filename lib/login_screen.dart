import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Login / Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                          isDarkTheme
                              ? 'lib/Icons/whitelogo.png' // White logo for dark theme
                              : 'lib/Icons/blacklogo.png', // Black logo for light theme
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'NewzBot',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isRegistering)
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_isRegistering)
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    validator: (value) {
                      if (_isRegistering && (value != _passwordController.text)) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Text(_errorMessage!,
                            style: TextStyle(color: Colors.red)),
                        if (_errorMessage!.contains('not found'))
                          TextButton(
                            onPressed: () => setState(() => _isRegistering = true),
                            child: const Text('Create account instead?'),
                          )
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        User? user;
                        if (_isRegistering) {
                          user = await authService.registerWithEmail(
                            _emailController.text,
                            _passwordController.text,
                          );
                        } else {
                          user = await authService.signInWithEmail(
                            _emailController.text,
                            _passwordController.text,
                          );
                        }
                        if (user != null) Navigator.pop(context);
                      } on FirebaseAuthException catch (e) {
                        _handleAuthError(e, context);
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: _isLoading 
                     ? const CircularProgressIndicator()
                     : Text(_isRegistering ? 'Register' : 'Sign In'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = null;
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(_isRegistering
                      ? 'Already have an account? Sign In'
                      : 'Need an account? Register'),
                ),
                const Divider(thickness: 1),
                const SizedBox(height: 20),
                const Text('Or continue with'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: Image.asset(
                    'lib/Icons/google.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  onPressed: () async {
                    final user = await authService.signInWithGoogle();
                    if (user != null) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAuthError(FirebaseAuthException e, BuildContext context) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'Account not found. Create new account?';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'Email already registered. Try logging in.';
        break;
      default:
        message = 'Error: ${e.message}';
    }
    setState(() => _errorMessage = message);
  }
}