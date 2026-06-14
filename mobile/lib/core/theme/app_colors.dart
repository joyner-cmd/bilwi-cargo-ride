import 'package:flutter/material.dart';

/// Paleta de marca: Azul Caribe, Verde Turquesa y Blanco.
class AppColors {
  // Marca
  static const Color azulCaribe = Color(0xFF0A6EBD);
  static const Color azulProfundo = Color(0xFF064273);
  static const Color azulNoche = Color(0xFF052B49);
  static const Color turquesa = Color(0xFF1BC5BD);
  static const Color verdeAgua = Color(0xFF7FE3DC);
  static const Color verdeMenta = Color(0xFFE5F8F6);

  // Fondos
  static const Color arena = Color(0xFFF6F8FA);
  static const Color arenaSuave = Color(0xFFFAFBFC);
  static const Color borde = Color(0xFFE7EDF1);

  // Estado
  static const Color exito = Color(0xFF2E9E5B);
  static const Color exitoSuave = Color(0xFFE4F5EC);
  static const Color alerta = Color(0xFFE53935);
  static const Color alertaSuave = Color(0xFFFDECEC);
  static const Color advertencia = Color(0xFFF9A825);

  // Texto
  static const Color grisTexto = Color(0xFF5C6F7A);
  static const Color grisSuave = Color(0xFF94A3B0);

  // Gradiente de marca
  static const LinearGradient gradienteMarca = LinearGradient(
    colors: [azulCaribe, azulProfundo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteHero = LinearGradient(
    colors: [azulNoche, azulProfundo, azulCaribe],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
