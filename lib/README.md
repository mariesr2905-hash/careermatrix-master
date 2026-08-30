# Career Matrix — Phase 2: Authentication Module

Self-contained auth module built to drop into the existing Career Matrix
Flutter project **without** touching your current dashboards, theme,
navigation, or Blue & White design.

---

## 1. What's in this package

```
lib/
├── config/
│   └── auth_colors.dart          (fallback palette — see Step 3)
├── models/
│   ├── user_model.dart
│   └── auth_response_model.dart
├── services/
│   ├── auth_service.dart         (mocked now, JWT/Node-ready later)
│   └── storage_service.dart      (SharedPreferences session persistence)
├── repositories/
│   └── auth_repository.dart
├── providers/
│   └── auth_provider.dart        (ChangeNotifier auth state)
├── routes/
│   └── auth_routes.dart          (route map to merge into MaterialApp)
├── widgets/auth/
│   ├── custom_text_field.dart
│   ├── primary_button.dart
│   ├── social_login_button.dart  (Google/LinkedIn placeholders)
│   └── logout_button.dart        (drop into an existing dashboard)
└── screens/auth/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── role_selection_screen.dart
    ├── forgot_password_screen.dart
    ├── otp_verification_screen.dart
    ├── reset_password_screen.dart
    └── auth_wrapper.dart         (session gate / auto-redirect)
```

**Every file above is NEW.** Nothing in this module overwrites an
existing file.

---

## 2. Files you must modify in the existing project

Only two existing files need edits, and both are additive:

### `pubspec.yaml`
Add these dependencies (versions are current as of writing — adjust to
whatever your project's other packages already resolve to):

```yaml
dependencies:
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  http: ^1.2.2          # not called yet, but wired in for Phase 3 backend
```

Run `flutter pub get` after editing.

### `lib/main.dart`
Two small additions — do **not** remove anything already there.

**a) Wrap the app in `AuthProvider`:**

```dart
import 'package:provider/provider.dart';
import 'package:career_matrix/providers/auth_provider.dart'; // adjust import path/package name

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const CareerMatrixApp(), // your existing root widget, unchanged
    ),
  );
}
```
> If `main.dart` already has a `MultiProvider`, just add
> `ChangeNotifierProvider(create: (_) => AuthProvider())` to its
> `providers: [...]` list instead of nesting a new one.

**b) Point the app's `home`/initial route at `AuthWrapper`, passing in
your existing dashboard widget unchanged:**

```dart
import 'package:career_matrix/screens/auth/auth_wrapper.dart';
import 'package:career_matrix/routes/auth_routes.dart';

MaterialApp(
  // ...existing theme, title, etc. — untouched
  home: AuthWrapper(dashboard: const YourExistingDashboardScreen()),
  routes: {
    ...authRoutes,        // merge in, existing routes map stays as-is
    '/dashboard': (_) => const YourExistingDashboardScreen(),
    // ...your other existing routes
  },
)
```

`AuthWrapper` checks for a saved session on launch, shows a small
loading spinner while it does, then either shows your dashboard or
`LoginScreen` — your dashboard code is never modified.

---

## 3. One design note (fallback colors)

`lib/config/auth_colors.dart` defines a Blue & White palette so these
screens compile and look correct standalone. Career Matrix already has
its own theme/colors file. Before final merge:

1. Open your existing theme constants file.
2. Find/replace `AuthColors.` → your existing color class name across
   `lib/screens/auth/**` and `lib/widgets/auth/**`.
3. Delete `lib/config/auth_colors.dart`.

If your existing color names differ, this is a 2-minute find/replace —
no visual redesign needed since the palette already matches your Blue
& White system.

---

## 4. Adding "Logout" to your existing dashboard

Nothing about your dashboard layout changes. Just drop one widget in
wherever a logout action already belongs, e.g. in an AppBar or Drawer:

```dart
import 'package:career_matrix/widgets/auth/logout_button.dart';

AppBar(
  actions: const [LogoutIconButton()],
)

// or inside a Drawer / settings list:
const LogoutListTile()
```

Both show a confirmation dialog, clear the session, and route back to
`LoginScreen`.

---

## 5. Session management behavior (already implemented)

- **Stay logged in after restart:** `AuthWrapper` calls
  `AuthProvider.tryAutoLogin()` on launch, which reads the persisted
  token/user from `StorageService` (SharedPreferences).
- **Auto redirect on session expiry:** `StorageService.isSessionValid()`
  compares the stored expiry timestamp against `DateTime.now()`. If a
  protected screen or service later detects a 401 from the real
  backend, call `context.read<AuthProvider>().handleSessionExpired()`
  to force the redirect immediately.

---

## 6. Backend readiness (Phase 3, not built yet)

`lib/services/auth_service.dart` currently returns mocked responses so
every screen is fully demoable offline. Each method already has the
real `http` call written out in a comment directly above the mock
logic — swapping to the Node.js + Express + MongoDB backend is a
delete-mock / uncomment-real operation, method by method. No other
layer (repository, provider, or any screen) needs to change, since
they only depend on `AuthRepository`'s public API.

`AppConstants.baseUrl` and the `*Endpoint` constants in
`lib/utils/app_constants.dart` are the only values to update once the
backend's real host/paths are known.

---

## 7. Scope confirmation

- ✅ Login, Register, Forgot Password (OTP → Reset), Role Selection,
  Logout, Session persistence/expiry — all built.
- ✅ Clean architecture: screens → providers → repositories → services
  → models, with `utils`/`config`/`widgets`/`routes` support layers.
- ✅ Zero backend calls made; `AuthService` is fully mocked and
  clearly marked for the future Node/Express/MongoDB + JWT swap.
- ✅ No existing dashboard, theme, or navigation file was altered —
  only `pubspec.yaml` and `main.dart` need the additive edits above.
