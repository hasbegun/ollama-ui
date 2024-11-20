// lib/bloc/theme_state.dart

import 'package:flutter/material.dart';

abstract class ThemeState {
  final ThemeData themeData;

  ThemeState(this.themeData);
}

class LightThemeState extends ThemeState {
  LightThemeState() : super(ThemeData.light());
}

class DarkThemeState extends ThemeState {
  DarkThemeState() : super(ThemeData.dark());
}
