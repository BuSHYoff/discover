import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/avatar.dart';
import 'package:discover/core/theme/app_theme.dart';

class CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final Passion passion;

  const CommentsSheet({super.key, required this.post, required this.passion});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _textCtrl  = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending    = false;

  // Future re-créé après chaque mutation (ajout de commentaire).
  late Future<List<CommunityComment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = CommunityService.fetchComments(
      widget.post.id,
      passionId: widget.passion.id,
    );
  }

  Future<void> _refresh() async {
    final future = CommunityService.fetchComments(
      widget.post.id,
      passionId: widget.passion.id,
    );
    setState(() { _commentsFuture = future; });
    await future;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.selectionClick();
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      await CommunityService.addComment(
        widget.post.id,
        text,
        passionId: widget.passion.id,
      );
      if (mounted) await _refresh();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq          = MediaQuery.of(context);
    final safeBottom  = mq.padding.bottom;
    final keyboardH   = mq.viewInsets.bottom;
    // Le sheet ne monte jamais au-delà du niveau de la toolbar (72pt)
    // — même alignement que les titres de l'app
    const toolbarHeight = 72.0;
    final maxHeight     = mq.size.height - keyboardH - toolbarHeight;
    final sheetHeight   = (mq.size.height * 0.78).clamp(0.0, maxHeight);

    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardH),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            height: sheetHeight,
            color: AppColors.cream,
            child: FutureBuilder<List<CommunityComment>>(
              future: _commentsFuture,
              builder: (context, snap) {
                final comments = snap.data ?? [];
                return Column(children: [

                  // ── Handle ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // ── Header ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(children: [
                      Text('Commentaires',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('${comments.length}',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primary)),
                      ),
                    ]),
                  ),

                  Container(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06)),

                  // ── Liste ───────────────────────────────────────────────
                  Expanded(
                    child: snap.hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Erreur : ${snap.error}',
                                style: GoogleFonts.firaSansCondensed(
                                    fontSize: 13, color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                            ))
                        : comments.isEmpty &&
                                snap.connectionState == ConnectionState.waiting
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: primary, strokeWidth: 2))
                            : comments.isEmpty
                                ? RefreshIndicator(
                                    color: primary,
                                    onRefresh: _refresh,
                                    child: ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        const SizedBox(height: 80),
                                        Center(
                                          child: Text(
                                              'Sois le premier à commenter !',
                                              style: GoogleFonts
                                                  .firaSansCondensed(
                                                      fontSize: 14,
                                                      color: AppColors.inkSoft)),
                                        ),
                                      ],
                                    ),
                                  )
                            : RefreshIndicator(
                                color: primary,
                                onRefresh: _refresh,
                                child: ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                    20, 12, 20, 12),
                                itemCount: comments.length,
                                itemBuilder: (_, i) {
                                  final c = comments[i];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Avatar(
                                            initials: c.authorInitials,
                                            colorHex: c.authorColor,
                                            size: 34),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(c.authorName,
                                                    style: GoogleFonts
                                                        .firaSansCondensed(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors.ink)),
                                                const SizedBox(width: 6),
                                                Text(c.timeAgo,
                                                    style: GoogleFonts
                                                        .firaSansCondensed(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .inkSoft)),
                                              ]),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(14),
                                                    bottomLeft:
                                                        Radius.circular(14),
                                                    bottomRight:
                                                        Radius.circular(14),
                                                  ),
                                                  border: Border.all(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.06)),
                                                ),
                                                child: Text(c.text,
                                                    style: GoogleFonts
                                                        .firaSansCondensed(
                                                            fontSize: 13,
                                                            color: AppColors.ink,
                                                            height: 1.4)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              ),
                  ),

                  // ── Barre de saisie — toujours visible, colle au bas ────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(
                              color: Colors.black.withValues(alpha: 0.07))),
                    ),
                    padding: EdgeInsets.fromLTRB(
                        16, 10, 16, keyboardH > 0 ? 10 : safeBottom + 10),
                    child: Row(children: [
                      const Avatar(
                          initials: 'ME',
                          colorHex: '#2D5A3D',
                          size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _textCtrl,
                            focusNode:  _focusNode,
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 13.5, color: AppColors.ink),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Ajouter un commentaire…',
                              hintStyle: GoogleFonts.firaSansCondensed(
                                  fontSize: 13.5,
                                  color: AppColors.inkSoft
                                      .withValues(alpha: 0.6)),
                            ),
                            onSubmitted: (_) => _sendComment(),
                            textInputAction: TextInputAction.send,
                            maxLines: null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendComment,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: _sending
                                ? primary.withValues(alpha: 0.5)
                                : primary,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
