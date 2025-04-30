// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:go_router/go_router.dart';
// import 'package:revboostapp/routing/app_router.dart';

// class VerifyEmailPage extends StatefulWidget {
//   const VerifyEmailPage({Key? key}) : super(key: key);

//   @override
//   State<VerifyEmailPage> createState() => _VerifyEmailPageState();
// }

// class _VerifyEmailPageState extends State<VerifyEmailPage> {
//   bool _isVerifying = true;
//   bool _isSuccess = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _verifyEmailFromLink();
//   }

//   Future<void> _verifyEmailFromLink() async {
//     final uri = Uri.base;
//     final oobCode = uri.queryParameters['oobCode'];
//     final mode = uri.queryParameters['mode'];

//     if (mode == 'verifyEmail' && oobCode != null) {
//       try {
//         await FirebaseAuth.instance.checkActionCode(oobCode);
//         await FirebaseAuth.instance.applyActionCode(oobCode);
//         await FirebaseAuth.instance.currentUser?.reload();

//         setState(() {
//           _isVerifying = false;
//           _isSuccess = true;
//         });

//         await Future.delayed(const Duration(seconds: 3));
//         if (!mounted) return;
//         context.go(AppRoutes.dashboard);

//       } catch (e) {
//         setState(() {
//           _isVerifying = false;
//           _error = 'Verification failed: ${e.toString()}';
//         });
//       }
//     } else {
//       setState(() {
//         _isVerifying = false;
//         _error = 'Invalid or missing verification code.';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isVerifying) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_isSuccess) {
//       return const Scaffold(
//         body: Center(child: Text("✅ Email verified! Redirecting...")),
//       );
//     }
//     return Scaffold(
//       body: Center(child: Text("❌ $_error")),
//     );
//   }
// }
