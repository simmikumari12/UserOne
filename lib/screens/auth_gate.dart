import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'map_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthAction() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();
    User? user;

    if (_isRegisterMode) {
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        setState(() {
          _errorMessage = 'Email, password, and display name are required.';
          _isBusy = false;
        });
        return;
      }
      user = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
    } else {
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Email and password are required.';
          _isBusy = false;
        });
        return;
      }
      user = await _authService.signInWithEmailAndPassword(email, password);
    }

    if (user != null) {
      await _firestoreService.ensureUserProfile(
        user: user,
        displayName: displayName.isNotEmpty ? displayName : user.displayName,
      );
    } else {
      setState(() {
        _errorMessage = 'Unable to sign in. Please try again.';
      });
    }

    setState(() {
      _isBusy = false;
    });
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final user = await _authService.signInAnonymously();
    if (user != null) {
      await _firestoreService.ensureUserProfile(user: user);
    } else {
      setState(() {
        _errorMessage = 'Anonymous sign-in failed. Please try again.';
      });
    }

    setState(() {
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MapScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('ARQuest Sign In'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                if (_isRegisterMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isBusy ? null : _handleAuthAction,
                  child: _isBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isRegisterMode ? 'Register' : 'Sign In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorMessage = null;
                          });
                        },
                  child: Text(_isRegisterMode
                      ? 'Already have an account? Sign in'
                      : 'Create new account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isBusy ? null : _handleAnonymousSignIn,
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
