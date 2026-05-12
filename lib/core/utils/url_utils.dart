import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Construit l'URL de recherche Amazon FR pour un matériel donné.
/// Ex: passionName="Basse électrique", materialName="Cordes débutant"
/// → https://www.amazon.fr/s?k=Basse+%C3%A9lectrique+Cordes+d%C3%A9butant
Uri buildAmazonSearchUri(String passionName, String materialName) {
  return Uri.https('www.amazon.fr', '/s', {'k': '$passionName $materialName'});
}

Future<void> launchAmazonSearch(
    BuildContext context, String passionName, String materialName) async {
  final uri = buildAmazonSearchUri(passionName, materialName);
  final ok  = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir Amazon')),
    );
  }
}

Future<void> launchExternalUrl(BuildContext context, String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien invalide')),
      );
    }
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
    );
  }
}
