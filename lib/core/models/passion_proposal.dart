// Modèle PassionProposal — miroir backend/src/proposals/entities/passion-proposal.entity.ts

class PassionProposal {
  final String  id;
  final String  name;
  final String  description;
  final String  category;
  final String? country;
  final String? resources;
  final String? submittedBy;
  final DateTime? createdAt;

  const PassionProposal({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.country,
    this.resources,
    this.submittedBy,
    this.createdAt,
  });

  factory PassionProposal.fromJson(Map<String, dynamic> j) => PassionProposal(
    id:          j['id']          as String,
    name:        j['name']        as String? ?? '',
    description: j['description'] as String? ?? '',
    category:    j['category']    as String? ?? '',
    country:     j['country']     as String?,
    resources:   j['resources']   as String?,
    submittedBy: j['submittedBy'] as String?,
    createdAt:   j['createdAt'] is String ? DateTime.tryParse(j['createdAt'] as String) : null,
  );
}
