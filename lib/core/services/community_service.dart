import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:discover/features/home/widgets/community_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY SERVICE
// Posts     : community/{postId}          — stocke uniquement authorId
// Comments  : community/{postId}/comments — stocke uniquement authorId
// Auteurs   : résolus depuis users/{uid} via cache en mémoire
// Images    : Cloudinary
// ─────────────────────────────────────────────────────────────────────────────

class CommunityService {
  static final _db = FirebaseFirestore.instance;

  static const _cloudName    = 'draevgkjl';
  static const _uploadPreset = 'discover_unsigned';

  // ── Cache utilisateurs (uid → données) ───────────────────────────────────
  static final Map<String, Map<String, dynamic>> _userCache = {};

  static void clearUserCache() {
    _userCache.clear();
  }

  static Future<Map<String, dynamic>> _getUser(String uid) async {
    if (uid.isEmpty) return {};
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      _userCache[uid] = data;
      return data;
    } catch (_) {
      return {};
    }
  }

  /// Précharge un lot d'UIDs en parallèle.
  static Future<void> _prefetchUsers(Iterable<String> uids) async {
    final toLoad = uids.where((id) => id.isNotEmpty && !_userCache.containsKey(id)).toSet();
    if (toLoad.isEmpty) return;
    await Future.wait(toLoad.map(_getUser));
  }

  // ── Helpers affichage ────────────────────────────────────────────────────

  static String _name(Map<String, dynamic> u) =>
      (u['username'] as String?)?.trim().isNotEmpty == true
          ? u['username'] as String
          : 'Utilisateur';

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String _color(Map<String, dynamic> u, String uid) {
    if (u['profileColor'] != null) return u['profileColor'] as String;
    const colors = [
      '#4CAF8A', '#5B8ED6', '#E07B54',
      '#9B6DB5', '#D4896A', '#2D5A3D',
    ];
    final idx = uid.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  static CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('community');

  static User? get _me => FirebaseAuth.instance.currentUser;

  // ── Mise à jour des stats de tendance ─────────────────────────────────────
  // Incrémente / décrémente directement passions_stats/{passionId}.
  // scoreDelta = likesDelta×3 + commentsDelta×2 + postsDelta×1

  static Future<void> _updateStats(
    String passionId, {
    int postsDelta    = 0,
    int likesDelta    = 0,
    int commentsDelta = 0,
  }) async {
    if (passionId.isEmpty) return;
    final scoreDelta =
        likesDelta * 3 + commentsDelta * 2 + postsDelta * 1;
    final updates = <String, dynamic>{};
    if (postsDelta    != 0) updates['postsCount']    = FieldValue.increment(postsDelta);
    if (likesDelta    != 0) updates['likesCount']    = FieldValue.increment(likesDelta);
    if (commentsDelta != 0) updates['commentsCount'] = FieldValue.increment(commentsDelta);
    if (scoreDelta    != 0) updates['trendScore']    = FieldValue.increment(scoreDelta);
    if (updates.isEmpty) return;
    await _db
        .collection('passions_stats')
        .doc(passionId)
        .set(updates, SetOptions(merge: true));
  }

  // ── Upload Cloudinary ────────────────────────────────────────────────────

  static Future<String> _uploadImage({
    required File imageFile,
    required String folder,
  }) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder']        = folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final body     = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${streamed.statusCode}\n$body');
    }
    return (jsonDecode(body) as Map<String, dynamic>)['secure_url'] as String;
  }

  // ── Posts ─────────────────────────────────────────────────────────────────

  /// Stream des posts d'une passion. Les infos auteur sont résolues
  /// depuis la collection users via le cache.
  static Stream<List<CommunityPost>> streamPosts(String passionId) {
    final uid = _me?.uid ?? '';
    return _posts
        .where('passionId', isEqualTo: passionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          // Précharge tous les auteurs en une seule passe
          await _prefetchUsers(
              snap.docs.map((d) => d.data()['authorId'] as String? ?? ''));

          return Future.wait(snap.docs.map((doc) async {
            final authorId = doc.data()['authorId'] as String? ?? '';
            final u        = await _getUser(authorId);
            final name     = _name(u);
            return CommunityPost.fromDoc(
              snap:           doc,
              currentUid:     uid,
              authorName:     name,
              authorInitials: _initials(name),
              authorColor:    _color(u, authorId),
            );
          }));
        });
  }

  /// Crée un post : stocke seulement authorId (pas de dénormalisation).
  static Future<void> addPost({
    required String passionId,
    required File   imageFile,
    required String caption,
  }) async {
    final user = _me;
    if (user == null) return;

    final imageUrl = await _uploadImage(
      imageFile: imageFile,
      folder: 'community/$passionId',
    );

    await _posts.add({
      'passionId':    passionId,
      'authorId':     user.uid,
      'imageUrl':     imageUrl,
      'caption':      caption,
      'likeCount':    0,
      'commentCount': 0,
      'likedBy':      [],
      'createdAt':    FieldValue.serverTimestamp(),
    });

    await _updateStats(passionId, postsDelta: 1);
  }

  /// Like / unlike avec transaction — impossible d'aller en négatif.
  static Future<void> toggleLike(
    String postId,
    bool isNowLiked,
    String passionId,
  ) async {
    final uid = _me?.uid;
    if (uid == null) return;

    bool didChange = false;
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap    = await tx.get(ref);
      final likedBy = List<String>.from(snap.data()?['likedBy'] ?? []);
      final already = likedBy.contains(uid);

      if (isNowLiked && !already) {
        likedBy.add(uid);
        tx.update(ref, {'likedBy': FieldValue.arrayUnion([uid]), 'likeCount': likedBy.length});
        didChange = true;
      } else if (!isNowLiked && already) {
        likedBy.remove(uid);
        tx.update(ref, {'likedBy': FieldValue.arrayRemove([uid]), 'likeCount': likedBy.length});
        didChange = true;
      }
    });

    if (didChange) {
      await _updateStats(passionId, likesDelta: isNowLiked ? 1 : -1);
    }
  }

  /// Supprime un post et déduit sa contribution des stats de tendance.
  static Future<void> deletePost(String postId) async {
    final uid = _me?.uid;
    if (uid == null) return;

    // On lit le post avant de le supprimer pour connaître ses compteurs
    final snap      = await _posts.doc(postId).get();
    final data      = snap.data();
    final passionId = data?['passionId'] as String? ?? '';
    final likes     = (data?['likeCount']    as num?)?.toInt() ?? 0;
    final comments  = (data?['commentCount'] as num?)?.toInt() ?? 0;

    await _posts.doc(postId).delete();

    await _updateStats(
      passionId,
      postsDelta:    -1,
      likesDelta:    -likes,
      commentsDelta: -comments,
    );
  }

  /// Met à jour la description et/ou l'image d'un post.
  static Future<void> updatePost({
    required String postId,
    required String passionId,
    required String caption,
    File? newImageFile,
  }) async {
    final uid = _me?.uid;
    if (uid == null) return;

    final Map<String, dynamic> updates = {'caption': caption};
    if (newImageFile != null) {
      updates['imageUrl'] = await _uploadImage(
        imageFile: newImageFile,
        folder: 'community/$passionId',
      );
    }
    await _posts.doc(postId).update(updates);
  }

  /// Signale un post — ajoute l'UID dans reportedBy et incrémente reportCount.
  static Future<void> reportPost(String postId) async {
    final uid = _me?.uid;
    if (uid == null) return;
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap       = await tx.get(ref);
      final reportedBy = List<String>.from(snap.data()?['reportedBy'] ?? []);
      if (!reportedBy.contains(uid)) {
        tx.update(ref, {
          'reportedBy': FieldValue.arrayUnion([uid]),
          'reportCount': FieldValue.increment(1),
        });
      }
    });
  }

  // ── Posts de l'utilisateur courant ───────────────────────────────────────

  /// Stream des posts publiés par l'utilisateur connecté, triés par date.
  static Stream<List<CommunityPost>> streamMyPosts() {
    final uid = _me?.uid;
    if (uid == null) return const Stream.empty();

    return _posts
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
          final u    = await _getUser(uid);
          final name = _name(u);
          final posts = snap.docs.map((doc) => CommunityPost.fromDoc(
            snap:           doc,
            currentUid:     uid,
            authorName:     name,
            authorInitials: _initials(name),
            authorColor:    _color(u, uid),
          )).toList();
          // Tri côté client — évite l'index composite Firestore (authorId + createdAt)
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  // ── Commentaires ──────────────────────────────────────────────────────────

  /// Stream des commentaires. Infos auteur résolues depuis users.
  static Stream<List<CommunityComment>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .asyncMap((snap) async {
          await _prefetchUsers(
              snap.docs.map((d) => d.data()['authorId'] as String? ?? ''));

          return Future.wait(snap.docs.map((doc) async {
            final authorId = doc.data()['authorId'] as String? ?? '';
            final u        = await _getUser(authorId);
            final name     = _name(u);
            return CommunityComment.fromDoc(
              snap:           doc,
              authorName:     name,
              authorInitials: _initials(name),
              authorColor:    _color(u, authorId),
            );
          }));
        });
  }

  /// Ajoute un commentaire — stocke seulement authorId.
  static Future<void> addComment(String postId, String text, String passionId) async {
    final user = _me;
    if (user == null || text.trim().isEmpty) return;

    final batch      = _db.batch();
    final commentRef = _posts.doc(postId).collection('comments').doc();

    batch.set(commentRef, {
      'authorId':  user.uid,
      'text':      text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(postId), {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();

    await _updateStats(passionId, commentsDelta: 1);
  }
}

// Firestore rules à ajouter :
// allow update: if request.auth != null && (
//   request.auth.uid == resource.data.authorId ||
//   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['reportedBy', 'reportCount'])
// );
