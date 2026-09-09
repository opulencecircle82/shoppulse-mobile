class Shop {
  final String id;
  final String shopName;
  final String? logoUrl;
  final String primaryColorHex;
  final String accentColorHex;
  final String mobileAppFontFamily;
  final bool mandatoryLiveCamera;
  final bool watermarkShowLogo;
  final bool watermarkShowTimestamp;
  final bool watermarkShowGps;
  final int geofenceRadiusMeters;

  const Shop({
    required this.id,
    required this.shopName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.mobileAppFontFamily,
    required this.mandatoryLiveCamera,
    required this.watermarkShowLogo,
    required this.watermarkShowTimestamp,
    required this.watermarkShowGps,
    required this.geofenceRadiusMeters,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      shopName: json['shop_name'] as String? ?? 'ShopPulse',
      logoUrl: json['logo_url'] as String?,
      primaryColorHex: json['primary_color_hex'] as String? ?? '#0F172A',
      accentColorHex: json['accent_color_hex'] as String? ?? '#10B981',
      mobileAppFontFamily: json['mobile_app_font_family'] as String? ?? 'Inter',
      mandatoryLiveCamera: json['mandatory_live_camera'] as bool? ?? true,
      watermarkShowLogo: json['watermark_show_logo'] as bool? ?? true,
      watermarkShowTimestamp: json['watermark_show_timestamp'] as bool? ?? true,
      watermarkShowGps: json['watermark_show_gps'] as bool? ?? true,
      geofenceRadiusMeters: (json['geofence_radius_meters'] as num?)?.toInt() ?? 150,
    );
  }
}
