import 'package:flutter/material.dart';
import '/screens/auth/sign_in_page.dart';
import '/screens/auth/sign_up_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
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
            tabController: _tabController)
        : SignUpPage(
            onToggle: () => setState(() {
              isSignIn = true;
              _tabController.animateTo(0);
            }),
            tabController: _tabController);
  }
}
