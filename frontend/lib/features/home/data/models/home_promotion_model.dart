class HomePromotionModel {
  final int id;
  final String kind;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String iconKey;

  const HomePromotionModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.iconKey,
  });

  factory HomePromotionModel.fromJson(Map<String, dynamic> json) {
    return HomePromotionModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      kind: json['kind']?.toString() ?? 'offer',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      ctaLabel: json['cta_label']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
    );
  }
}
