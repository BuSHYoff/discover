import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/passion_proposal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROPOSALS SERVICE — `POST /passion-proposals` (et liste admin).
// ─────────────────────────────────────────────────────────────────────────────

class ProposalsService {
  ProposalsService._();

  /// Soumet une proposition de passion. Anonyme (auth: false) si pas connecté.
  static Future<PassionProposal> submit({
    required String name,
    required String description,
    required String category,
    String? country,
    String? resources,
  }) async {
    final body = <String, dynamic>{
      'name':        name,
      'description': description,
      'category':    category,
      if (country   != null && country.isNotEmpty)   'country':   country,
      if (resources != null && resources.isNotEmpty) 'resources': resources,
    };
    final json = await ApiClient.post<Map<String, dynamic>>(
      '/passion-proposals',
      body: body,
    );
    return PassionProposal.fromJson(json);
  }
}
