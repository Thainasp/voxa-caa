import 'package:flutter/material.dart';

/// Observer global usado pela Home para saber quando ela está (ou deixa de
/// estar) visível, e assim travar a orientação horizontal somente nela.
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Rotas em que o botão de emergência NÃO aparece (antes do login).
const Set<String> routesWithoutEmergencyButton = {
  '/',
  '/welcome',
  '/login',
  '/register',
  '/forgot-password',
  '/new-password',
  '/terms',
};

/// Acompanha a rota do topo da pilha para decidir se o botão de emergência
/// global deve aparecer. Rotas sem nome (MaterialPageRoute das telas internas)
/// contam como telas de uso do app e mostram o botão.
class TopRouteTracker extends NavigatorObserver {
  final ValueNotifier<String?> topRouteName = ValueNotifier<String?>('/');

  void _update(Route<dynamic>? route) {
    if (route == null || route is PopupRoute) return;
    topRouteName.value = route.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _update(newRoute);
}

final TopRouteTracker topRouteTracker = TopRouteTracker();
