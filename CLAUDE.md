# cpi_app — Flutter field-collector app

Offline-first mobile app for field staff collecting Consumer Price Index (CPI) price data for Belize's Statistical Institute (SIB). Talks to **`cpi_api`** (Flask backend, separate repo) over REST; a sibling **`cpi_portal`** (Quasar/Vue3, separate repo) is the HQ web dashboard consuming the same backend.

## Stack & versioning

- **Flutter 3.0.0**, pinned via **FVM** (`.fvm/fvm_config.json`, no flavors configured) — use `fvm flutter ...` / `fvm dart ...`, not a bare global Flutter install, or you risk running against the wrong SDK version. Dart SDK constraint `>=2.17.0 <3.0.0`.
- **State management: Riverpod 1.x** (`flutter_riverpod`, legacy `ChangeNotifierProvider` API, not the newer codegen/`AsyncNotifier` style). Four domain providers live in `lib/providers/`: `assignmentsProvider`, `outletsProvider`, `varietiesProvider`, `substitutionsProvider`. These providers *are* the service/repository layer — they call the API via `Global.dio`, read/write SQLite via `DBHelper`, and hold in-memory state, all in one place.
- `get` (GetX) is a declared dependency but effectively unused — don't reach for `Get.to`/`Get.put` patterns, this app doesn't use them (likely a leftover transitive dependency of a form-field package).
- HTTP: **Dio**. Local KV/session: **`get_storage`**. Offline relational cache: **`sqflite`**.
- Maps: Leaflet-based (`flutter_map` + `latlong2`), not Google Maps.

## How it talks to the backend

`Global.dio` (`lib/models/globals.dart`) is a single static Dio instance. The base URL is a **hardcoded Dart constant**:
```dart
static const apiBaseUrl = 'http://127.0.0.1:8080';
```
There is no dart-define, no build flavor, no per-environment config — switching between local/staging/prod means editing this line and rebuilding (README documents this, including the `10.0.2.2` Android-emulator-loopback tip). Auth header (`Authorization: Bearer <token>`) is attached **manually per request**, not via a Dio interceptor — token comes from `UserAuth().user()?.token`. Some call sites build the full URL with `${Global.apiBaseUrl}/...` and others rely on Dio's configured `baseUrl` with a relative path — both work, but be consistent with the surrounding code in whichever provider you're editing.

Endpoints called (add new ones to the matching provider in `lib/providers/`, matching `cpi_api/CLAUDE.md`'s inventory):

| Method | Path | Provider |
|---|---|---|
| POST | `/login` | `lib/helpers/auth.dart` |
| POST | `/user-fcm` | `lib/helpers/auth.dart` |
| GET | `/assignments/user-assignments/<userId>` | `assignments.dart` |
| GET | `/quality-assurance-assignment` | `assignments.dart` (HQ-role user path) |
| PUT | `/assignments-upload` | `assignments.dart` |
| PUT | `/quality-assurance-assignment` | `assignments.dart` (HQ-role user path) |
| POST | `/request-substitutions` | `assignments.dart` |
| GET | `/syncing` | `assignments.dart` |
| GET | `/varieties/user-varieties/<userId>` | `varieties.dart` |
| POST | `/varieties` | `varieties.dart` |
| GET | `/outlets/user-outlets/<userId>` | `outlets.dart` |
| POST / PUT | `/outlets` | `outlets.dart` |
| POST | `/substitutions` | `substitutions.dart` |

Error handling: every provider method catches `DioError` (status `401`/sometimes `403` → `HttpException('Not Authenticated!', 401)`, other errors → generic `HttpException`), and screens catch `HttpException` to force-logout on 401/403 or show a snackbar otherwise. Follow this pattern for new API calls rather than introducing a different error shape.

## Offline-first sync model — the core architectural fact of this app

Every domain provider loads from **sqflite** into memory on `initialize()`, writes local mutations to SQLite immediately (optimistic), and only talks to the network when the user taps "Sync" (`lib/screens/sync_screen.dart`).

- **Tables** (`lib/helpers/db.dart`): `outlet`, `assignment`, `variety`, `substitute`, plus an unused `syncs` table (schema exists, nothing reads/writes it — don't assume sync history is persisted anywhere).
- **Row-level sync-state flags** drive what gets included in each upload batch: `isUploaded`, `isEdited`, `isNew`, `failedAutoSync`, `isRejected`, `isApprovedByHQ`, `canSubstitute`, `requestSubstitute`, `isRequestUploaded`, `isSubstituted`.
- **Sync sequence** (`sync_screen.dart`): detect whether the CPI time period changed vs. the last local assignment's period. If new/no local data → wipe local substitutions/assignments and download fresh. Otherwise → upload in fixed order (outlets → varieties → substitutions → assignments → requested substitutions), then always download (outlets → assignments), then call `/syncing` to report completion. Preserve this ordering if you touch this flow — later steps assume earlier ones completed (e.g. substitutions reference outlet/variety IDs that must already be reconciled).
- **ID reconciliation**: new records get client-generated temp IDs; after upload, the server returns a `mobile_id` mapping old→new IDs, which then cascades into dependent `substitute` records (`updateNewOutletId`/`updateNewVarietyId`). If you add a new syncable entity, you need this same reconciliation step or dependent records will silently reference stale IDs.

## Auth/session

Token and user info (`id`, `username`, `email`, `areaId`, `token`, `userType`) are stored via `get_storage` — **unencrypted on-device storage**, not `flutter_secure_storage`/Keychain/Keystore. This is the current state, not a bug to silently patch — if this needs to change, it's a deliberate security decision to raise with the team, not a drive-by fix.

## Environment variables & secrets

No `.env`, no `flutter_dotenv`, no `--dart-define`. The only "environment switch" is the hardcoded `apiBaseUrl` constant above.

Firebase config (`lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) is **intentionally committed** — this is normal for Firebase client apps (these are client identifiers, not secrets; access is controlled server-side by Firebase security rules), not a credential leak. Don't flag these for removal or gitignore.

## Testing

Only `test/widget_test.dart` exists, and it's the **unmodified Flutter counter-app boilerplate** — it asserts on a counter UI that doesn't exist in this app and would fail if actually run. There is no real test coverage for providers, screens, or the DB layer.

## Known gaps

- No location permission (`ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`) declared in `android/app/src/main/AndroidManifest.xml` despite using `geolocator` — likely needs adding if location features are exercised on real devices.
- `EditAssignmentScreen` has no named route in `main.dart` — it's pushed directly via `MaterialPageRoute`, not by name like other screens.
- `ios/`'s bundle id referenced in `firebase_options.dart` (`com.example.cpiApp`) still looks like the Flutter scaffold default — verify against the real iOS bundle identifier before shipping iOS builds.
- `/outlets` route is registered twice in `main.dart`'s route map (harmless duplicate, not a bug worth chasing).
