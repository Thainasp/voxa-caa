import 'package:flutter/material.dart';

/// Observer global usado pela Home para saber quando ela está (ou deixa de
/// estar) visível, e assim travar a orientação horizontal somente nela.
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();
