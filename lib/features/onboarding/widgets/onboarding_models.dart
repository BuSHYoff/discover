import 'package:flutter/material.dart';

class OnboardingChoice {
  final String label;
  final String emoji;
  final String subtitle;
  const OnboardingChoice(this.label, this.emoji, this.subtitle);
}

class OnboardingUniverseChoice {
  final String label;
  final String emoji;
  final Color  bgColor;
  final Color  textColor;
  const OnboardingUniverseChoice(this.label, this.emoji, this.bgColor, this.textColor);
}
