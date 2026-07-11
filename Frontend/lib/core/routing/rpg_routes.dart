/// Path constants for RPG Companion [GoRouter] routes.
abstract final class RpgRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';

  static bool isAuthPath(String location) =>
      location == login || location == register;
}
