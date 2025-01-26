import 'package:flutter/material.dart';

const MaterialColor customRed = MaterialColor(
  _customRedPrimaryValue,
  <int, Color>{
    50: Color(0xFFFFEBEB),
    100: Color(0xFFFFC7C7),
    200: Color(0xFFFFA1A1),
    300: Color(0xFFFF7A7A),
    400: Color(0xFFFF5C5C),
    500: Color(_customRedPrimaryValue),
    600: Color(0xFFFF3B3B),
    700: Color(0xFFFF3232),
    800: Color(0xFFFF2929),
    900: Color(0xFFFF1B1B),
  },
);

const int _customRedPrimaryValue = 0xFFFF5757;
