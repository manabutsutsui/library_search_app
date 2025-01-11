import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'create_account_mailaddress.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'create_username.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/account_page/home_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  l10n.registerWithEmail,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateAccountMailaddressPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildButton(
                  l10n.registerWithGoogle,
                  onPressed: () async {
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      final GoogleSignInAccount? googleUser =
                          await googleSignIn.signIn();

                      if (googleUser == null) return;

                      final GoogleSignInAuthentication googleAuth =
                          await googleUser.authentication;
                      final credential = GoogleAuthProvider.credential(
                        accessToken: googleAuth.accessToken,
                        idToken: googleAuth.idToken,
                      );

                      final UserCredential userCredential = await FirebaseAuth
                          .instance
                          .signInWithCredential(credential);

                      if (userCredential.user != null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.googleRegistrationComplete)),
                        );

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const CreateUserNamePage(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.registrationFailed}: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildButton(
                  l10n.registerWithApple,
                  onPressed: () async {
                    try {
                      final appleCredential =
                          await SignInWithApple.getAppleIDCredential(
                        scopes: [
                          AppleIDAuthorizationScopes.email,
                          AppleIDAuthorizationScopes.fullName,
                        ],
                      );

                      final oauthCredential =
                          OAuthProvider("apple.com").credential(
                        idToken: appleCredential.identityToken,
                        accessToken: appleCredential.authorizationCode,
                      );

                      final userCredential = await FirebaseAuth.instance
                          .signInWithCredential(oauthCredential);
                      if (mounted && userCredential.user != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.appleRegistrationComplete)),
                        );
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const CreateUserNamePage(),
                        ),
                        (route) => false,
                      );
                    } catch (e) {
                      if (e is SignInWithAppleAuthorizationException) {
                        switch (e.code) {
                          case AuthorizationErrorCode.canceled:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.loginCanceled)),
                            );
                            break;
                          case AuthorizationErrorCode.failed:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.signInFailed)),
                            );
                            break;
                          case AuthorizationErrorCode.invalidResponse:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.invalidResponse)),
                            );
                            break;
                          case AuthorizationErrorCode.notHandled:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.signInNotHandled)),
                            );
                            break;
                          case AuthorizationErrorCode.unknown:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.unknownError)),
                            );
                            break;
                          case AuthorizationErrorCode.notInteractive:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.notInteractive)),
                            );
                            break;
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    l10n.loginHere,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
