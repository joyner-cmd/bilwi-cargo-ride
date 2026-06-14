import '../config/app_config.dart';

String money(num? value) {
  if (value == null) return '${AppConfig.currency}0';
  return '${AppConfig.currency}${value.round()}';
}

String km(num? value) => value == null ? '-' : '${value.toStringAsFixed(1)} km';

String minutes(num? value) => value == null ? '-' : '${value.round()} min';

String stars(num? avg, int? count) {
  final a = (avg ?? 0).toStringAsFixed(1);
  return count == null ? a : '$a ($count)';
}
