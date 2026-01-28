// import 'package:flutter/material.dart';
// import 'sign_in_page.dart';
// import 'sign_up_page.dart';

// class AuthPage extends StatefulWidget {
//   @override
//   _AuthPageState createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   bool isSignIn = true;

//   @override
//   Widget build(BuildContext context) {
//     return isSignIn
//         ? SignInPage(onToggle: () => setState(() => isSignIn = false))
//         : SignUpPage(onToggle: () => setState(() => isSignIn = true));
//   }
// }

// import 'package:flutter/material.dart';
// import '/screens/auth/sign_in_page.dart';
// import '/screens/auth/sign_up_page.dart';

// class AuthPage extends StatefulWidget {
//   final VoidCallback toggleDarkMode;
//   final bool isDarkMode;

//   const AuthPage({
//     super.key,
//     required this.toggleDarkMode,
//     required this.isDarkMode,
//   });

//   @override
//   _AuthPageState createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   bool isSignIn = true;

//   @override
//   Widget build(BuildContext context) {
//     return isSignIn
//         ? SignInPage(
//           onToggle: () => setState(() => isSignIn = false),
//           toggleDarkMode: widget.toggleDarkMode,
//           isDarkMode: widget.isDarkMode,
//         )
//         : SignUpPage(
//           onToggle: () => setState(() => isSignIn = true),
//           toggleDarkMode: widget.toggleDarkMode,
//           isDarkMode: widget.isDarkMode,
//         );
//   }
// }


import 'package:flutter/material.dart';
import '/screens/auth/sign_in_page.dart';
import '/screens/auth/sign_up_page.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const AuthPage({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool isSignIn = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          isSignIn = _tabController.index == 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isSignIn
        ? SignInPage(
            onToggle: () => setState(() {
              isSignIn = false;
              _tabController.animateTo(1);
            }),
            toggleDarkMode: widget.toggleDarkMode,
            isDarkMode: widget.isDarkMode,
            tabController: _tabController,
          )
        : SignUpPage(
            onToggle: () => setState(() {
              isSignIn = true;
              _tabController.animateTo(0);
            }),
            toggleDarkMode: widget.toggleDarkMode,
            isDarkMode: widget.isDarkMode,
            tabController: _tabController,
          );
  }
}