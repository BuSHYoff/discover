import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:discover/core/services/proposals_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/onboarding/screens/onboarding_screen.dart';

class ProposePassionScreen extends StatefulWidget {
  const ProposePassionScreen({super.key});

  @override
  State<ProposePassionScreen> createState() => _ProposePassionScreenState();
}

class _ProposePassionScreenState extends State<ProposePassionScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _autreController = TextEditingController();
  final _resourcesController = TextEditingController();

  String? _selectedCategory;

  static const List<String> _categories = [
    'Arts créatifs',
    'Sport & Plein air',
    'Musique',
    'Technologie',
    'Culture & Histoire',
    'Autre',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _autreController.dispose();
    _resourcesController.dispose();
    super.dispose();
  }

  bool get _isAutreSelected => _selectedCategory == 'Autre';

  bool _sending = false;

  bool _validate() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    if (_selectedCategory == null) return false;
    if (_isAutreSelected && _autreController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();

    if (!_validate()) {
      _showSnackbar('Merci de remplir tous les champs obligatoires.', isError: true);
      return;
    }

    setState(() => _sending = true);

    final category = _isAutreSelected
        ? 'Autre — ${_autreController.text.trim()}'
        : _selectedCategory!;
    final country   = _countryController.text.trim();
    final resources = _resourcesController.text.trim();

    try {
      await ProposalsService.submit(
        name:        _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category:    category,
        country:     country.isNotEmpty ? country : null,
        resources:   resources.isNotEmpty ? resources : null,
      );

      if (!mounted) return;
      _showSnackbar('Proposition envoyée ! Merci', isError: false);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _showSnackbar('Erreur lors de l\'envoi. Réessaie.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.firaSansCondensed(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Proposer une passion'),
                    TextSpan(
                      text: '.',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: !_isLoggedIn
          ? _GuestBody(onCreateAccount: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            })
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Une passion qui n\'est pas encore dans l\'app ? '
                      'Partage-la avec nous et on l\'ajoutera peut-être !',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkSoft,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Nom ──────────────────────────────────────────────
                    _SectionLabel(label: 'Nom *'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _nameController,
                      hint: 'Ex. Origami, Escalade, Brassage maison…',
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 24),

                    // ── Description ──────────────────────────────────────
                    _SectionLabel(label: 'Description *'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _descriptionController,
                      hint:
                          'Décris cette passion en quelques phrases : en quoi ça consiste, pourquoi c\'est intéressant…',
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 24),

                    // ── Catégorie ────────────────────────────────────────
                    _SectionLabel(label: 'Catégorie *'),
                    const SizedBox(height: 10),
                    _CategoryChips(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (cat) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = cat;
                          if (cat != 'Autre') _autreController.clear();
                        });
                      },
                    ),

                    if (_isAutreSelected) ...[
                      const SizedBox(height: 12),
                      _SectionLabel(label: 'Précisez la catégorie *'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _autreController,
                        hint: 'Ex. Bien-être, Sciences, Bricolage…',
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Pays d'origine ───────────────────────────────────
                    _SectionLabel(label: 'Pays d\'origine'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _countryController,
                      hint: 'Ex. Japon, France… (optionnel)',
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 24),

                    // ── Ressources ───────────────────────────────────────
                    _SectionLabel(label: 'Ressources'),
                    const SizedBox(height: 4),
                    Text(
                      'Sites, livres, chaînes YouTube… (optionnel)',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _resourcesController,
                      hint: 'Ex. youtube.com/watch?v=…, "Le livre de l\'origami"…',
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),

            // ── Submit button ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Envoyer la proposition',
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GUEST BODY ───────────────────────────────────────────────────────────────

class _GuestBody extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestBody({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline_rounded, color: primary, size: 30),
          ),
          const SizedBox(height: 24),
          Text(
            'Une idée de passion ?',
            style: GoogleFonts.firaSansCondensed(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Crée un compte pour soumettre tes suggestions et contribuer à faire grandir la communauté Discover.',
            style: GoogleFonts.firaSansCondensed(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreateAccount,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Créer un compte',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.firaSansCondensed(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.inkSoft,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── STYLED TEXT FIELD ────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: GoogleFonts.firaSansCondensed(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.firaSansCondensed(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.inkSoft.withValues(alpha: 0.55),
            height: 1.4,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── CATEGORY CHIPS ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected == cat;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? primary : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected
                    ? primary
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
