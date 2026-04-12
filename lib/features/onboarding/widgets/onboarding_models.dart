import 'package:flutter/material.dart';

class OnboardingChoice {
  final String label;
  final IconData icon;
  final String subtitle;
  const OnboardingChoice(this.label, this.icon, this.subtitle);
}

class OnboardingUniverseChoice {
  final String label;
  final IconData icon;
  final Color  bgColor;
  final Color  textColor;
  const OnboardingUniverseChoice(this.label, this.icon, this.bgColor, this.textColor);
}
