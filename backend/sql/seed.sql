-- ============================================================
--  Datos de referencia (tipos de servicio + tarifas en NIO)
--  Las cuentas demo se crean en src/scripts/db-setup.js (bcrypt).
-- ============================================================

INSERT INTO service_types
  (code, name, description, vehicle_type, base_fare, per_km, per_min, min_fare, allows_stops, sort_order)
VALUES
  ('ride',        'Carrera Particular', 'Transporte de personas tipo taxi',          'particular',     25, 12, 1.5, 35, false, 1),
  ('moto',        'Moto Rapida',        'Traslado individual en motocicleta',        'moto',           15,  8, 1.0, 20, false, 2),
  ('acarreo',     'Acarreo Express',    'Refrigeradoras, cocinas, camas, muebles',   'acarreo',        80, 18, 2.0, 120, true,  3),
  ('camioneta',   'Camioneta',          'Carga mediana y mudanzas pequenas',         'camioneta',     100, 20, 2.0, 150, true,  4),
  ('mudanza',     'Mudanza',            'Mudanzas completas, varias paradas',        'camion_pequeno',180, 28, 3.0, 300, true,  5),
  ('comercial',   'Transporte Comercial','Negocios, ferreterias, distribuidores',    'camion_mediano',250, 32, 3.0, 400, true,  6),
  ('construccion','Materiales de Construccion','Arena, bloques, cemento, hierro',     'camion_mediano',300, 35, 3.0, 500, true,  7)
ON CONFLICT (code) DO NOTHING;
