import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../widgets/logo_tambour.dart';
import 'widgets/login_form.dart';
import 'widgets/inscription_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TamBourColors.background,
      body: Column(
        children: [
          Container(
            color: TamBourColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(children: [
                    const LogoTamBour(taille: 32).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    const Text('VOYAGEZ AU BON RYTHME', style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                      fontWeight: FontWeight.w600, letterSpacing: 2.6, color: TamBourColors.gold)),
                    const SizedBox(height: 20),
                  ])),
                TabBar(
                  controller: _tabController,
                  indicatorColor: TamBourColors.gold, indicatorWeight: 3,
                  labelColor: Colors.white, unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
                  tabs: const [Tab(text: 'Connexion'), Tab(text: 'Inscription')]),
              ]),
            ),
          ),
          Expanded(child: TabBarView(controller: _tabController, children: const [LoginForm(), InscriptionForm()])),
        ],
      ),
    );
  }
}
