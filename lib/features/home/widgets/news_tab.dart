import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:discover/core/models/news_article.dart';
import 'package:discover/core/services/news_service.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEWS TAB — Onglet Actualités de la CommunityScreen
// Charge les 20 dernières actus pour une passion via le backend (cache 30 min).
// ─────────────────────────────────────────────────────────────────────────────

class NewsTab extends StatefulWidget {
  /// L'ID Firestore de la passion. Le backend résout le nom pour la query.
  final String passionId;
  /// Affiché dans l'écran vide. Pas envoyé au backend.
  final String passionName;
  const NewsTab({
    super.key,
    required this.passionId,
    required this.passionName,
  });

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab>
    with AutomaticKeepAliveClientMixin {
  List<NewsArticle>? _articles;
  bool _loading = true;
  bool _error   = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final articles = await NewsService.fetchNews(
        widget.passionId,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loading  = false;
        _error    = articles.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _articles = []; _loading = false; _error = true; });
    }
  }

  Future<void> _open(NewsArticle article) async {
    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 60)  return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'Il y a ${diff.inHours} h';
    if (diff.inDays    < 30)  return 'Il y a ${diff.inDays} j';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return 'Il y a $months mois';
    final years = (diff.inDays / 365).floor();
    return years == 1 ? 'Il y a 1 an' : 'Il y a $years ans';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error || _articles == null || _articles!.isEmpty) {
      return _EmptyNews(passionName: widget.passionName, onRetry: _load);
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _articles!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _NewsCard(
          article:  _articles![i],
          timeAgo:  _timeAgo(_articles![i].publishedAt),
          onTap:    () => _open(_articles![i]),
        ),
      ),
    );
  }
}

// ── Carte article ─────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsArticle  article;
  final String       timeAgo;
  final VoidCallback onTap;

  const _NewsCard({
    required this.article,
    required this.timeAgo,
    required this.onTap,
  });

  String? _faviconUrl() {
    try {
      final base = article.sourceUrl.isNotEmpty ? article.sourceUrl : article.url;
      final domain = Uri.parse(base).host;
      if (domain.isEmpty) return null;
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary    = Theme.of(context).colorScheme.primary;
    final faviconUrl = _faviconUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Contenu principal ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + temps
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source.isNotEmpty
                              ? article.source
                              : 'Google Actualités',
                          style: GoogleFonts.firaSansCondensed(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Titre
                  Text(
                    article.title,
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lire l'article
                  Row(
                    children: [
                      Text(
                        'Lire l\'article',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: primary),
                    ],
                  ),
                ],
              ),
            ),

            // ── Favicon ─────────────────────────────────────────────────────
            if (faviconUrl != null) ...[
              const SizedBox(width: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  faviconUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty / erreur ────────────────────────────────────────────────────────────

class _EmptyNews extends StatelessWidget {
  final String passionName;
  final VoidCallback onRetry;
  const _EmptyNews({required this.passionName, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.newspaper_rounded, color: primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune actualité trouvée',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune actu récente pour "$passionName".\nTire vers le bas pour réessayer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary,
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
