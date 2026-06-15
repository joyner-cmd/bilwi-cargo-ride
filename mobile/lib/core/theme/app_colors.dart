import 'package:flutter/material.dart';

/// Paleta de marca: Rosa Caribe, Coral y Blanco.
///
/// Nota: los nombres siguen siendo "azulCaribe" etc. por compatibilidad con
/// referencias existentes, pero los valores ahora son rosa/coral.
class AppColors {
  // Marca (rosa coral)
  static const Color azulCaribe = Color(0xFFE63E5C);     // rosa principal
  static const Color azulProfundo = Color(0xFFB91C4B);   // rosa profundo
  static const Color azulNoche = Color(0xFF3D0C1A);      // burdeos oscuro (texto)
  static const Color turquesa = Color(0xFFFF6B7E);       // coral (acento)
  static const Color verdeAgua = Color(0xFFFFB5C0);      // rosa claro
  static const Color verdeMenta = Color(0xFFFFE5EB);     // rosa muy claro

  // Fondos
  static const Color arena = Color(0xFFFFF6F8);
  static const Color arenaSuave = Color(0xFFFFFAFB);
  static const Color borde = Color(0xFFFADADE);

  // Estado
  static const Color exito = Color(0xFF2E9E5B);
  static const Color exitoSuave = Color(0xFFE4F5EC);
  static const Color alerta = Color(0xFFD32F2F);
  static const Color alertaSuave = Color(0xFFFDECEC);
  static const Color advertencia = Color(0xFFF9A825);

  // Texto
  static const Color grisTexto = Color(0xFF6B4751);
  static const Color grisSuave = Color(0xFFA08891);

  // Gradiente de marca
  static const LinearGradient gradienteMarca = LinearGradient(
    colors: [azulCaribe, azulProfundo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteHero = LinearGradient(
    colors: [Color(0xFFD63057), Color(0xFFB91C4B), Color(0xFF8B1538)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
