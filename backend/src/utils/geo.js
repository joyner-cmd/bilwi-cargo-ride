/** Distancia Haversine en kilometros entre dos puntos {lat,lng}. */
export function haversineKm(aLat, aLng, bLat, bLng) {
  const R = 6371; // radio terrestre km
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const lat1 = toRad(aLat);
  const lat2 = toRad(bLat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

const toRad = (deg) => (deg * Math.PI) / 180;

/** Estima duracion en minutos asumiendo velocidad urbana promedio en Bilwi. */
export function estimateMinutes(distanceKm, avgKmh = 22) {
  return (distanceKm / avgKmh) * 60;
}
