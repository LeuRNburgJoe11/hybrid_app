import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope stores the state of all your providers
    const ProviderScope(
      child: MyHybridApp(),
    ),
  );
}