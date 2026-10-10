import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
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
      backgroundColor: YoBusColors.background,
      body: Column(
        children: [
          Container(
            color: YoBusColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(children: [
                    RichText(text: const TextSpan(children: [
                      TextSpan(text: 'Yô', style: TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                      TextSpan(text: 'Bus', style: TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w900, color: YoBusColors.gold)),
                    ])).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 6),
                    Text("Voyagez serein à travers la Côte d'Ivoire",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.white.withOpacity(0.75)),
                      textAlign: TextAlign.center).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 20),
                  ])),
                TabBar(
                  controller: _tabController,
                  indicatorColor: YoBusColors.gold, indicatorWeight: 3,
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
