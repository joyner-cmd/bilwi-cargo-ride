/**
 * Calculo de tarifa. Se basa en parametros del tipo de servicio (tabla service_types)
 * mas un factor por hora (demanda) y por carga.
 *
 * tarifa = base + per_km*km + per_min*min, acotada por min_fare, * surge * cargo
 */
export function computeFare({
  baseFare,
  perKm,
  perMin,
  minFare,
  distanceKm,
  durationMin,
  surge = 1,
  cargoFactor = 1,
}) {
  const raw = baseFare + perKm * distanceKm + perMin * durationMin;
  const withFactors = raw * surge * cargoFactor;
  const final = Math.max(minFare, withFactors);
  // Redondeo a cordobas enteros (NIO no usa centavos en la practica diaria).
  return Math.round(final);
}

/** Factor de demanda segun la hora local (horas pico en Bilwi). */
export function surgeForHour(hour) {
  // Pico manana 6-8, tarde 16-19
  if ((hour >= 6 && hour < 8) || (hour >= 16 && hour < 19)) return 1.25;
  // Madrugada (recargo nocturno)
  if (hour >= 22 || hour < 5) return 1.2;
  return 1;
}

/** Factor por tamano de carga declarado. */
export function cargoFactorFor(size) {
  switch (size) {
    case 'small':
      return 1;
    case 'medium':
      return 1.2;
    case 'large':
      return 1.5;
    case 'xlarge':
      return 2;
    default:
      return 1;
  }
}
