import 'package:flutter/material.dart';

/// Chave de cores Fitzgerald modificada (RF03).
///
/// A classe de cada pictograma do catálogo ARASAAC vem pronta no campo `fitz`
/// de `assets/arasaac/catalogo_inicial.json` (gerado por
/// `BACKEND/arasaac_dataset/prepare_flutter_catalog.js` a partir das tags
/// gramaticais do ARASAAC).
abstract final class Fitzgerald {
  static const Color pessoa = Color(0xFFE8A900); // amarelo
  static const Color verbo = Color(0xFF2E9E4F); // verde
  static const Color descritor = Color(0xFF2F7FE0); // azul
  static const Color social = Color(0xFFC2408A); // rosa/roxo
  static const Color substantivo = Color(0xFFF08A3C); // laranja
  static const Color estrutural = Color(0xFF7D8A9E); // cinza

  static const Map<String, Color> _byClass = {
    'pessoa': pessoa,
    'verbo': verbo,
    'descritor': descritor,
    'social': social,
    'substantivo': substantivo,
    'estrutural': estrutural,
  };

  static Color colorFor(String? grammaticalClass) =>
      _byClass[grammaticalClass] ?? substantivo;
}
