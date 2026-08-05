# Flutter Test Suite Guide (Unit + Integration) 🧪📱

Scope: **Unit tests** + **Integration tests** for a Flutter mobile app. (Widget tests intentionally excluded.)

\---

## 0\) Goals \& non-goals 🎯

### Goals

* High confidence in **business logic** and **critical user flows**
* Fast feedback in CI
* Deterministic, non-flaky tests

### Non-goals

* Pixel-perfect UI validation (golden/widget tests)

\---

## 1\) Test Architecture 🏗️

### 1.1 Test pyramid (practical)

* **Unit tests (70–90%)**: pure Dart logic, fast, isolated
* **Integration tests (10–30%)**: full app flows, fewer, higher cost

### 1.2 Architectural assumptions (recommended)

Your app will be easier to test if it follows:

* **Dependency Injection (DI)**: services passed via constructors/providers
* **Pure domain logic**: use-cases and validators have no platform dependencies
* **Ports \& adapters**: repositories depend on interfaces, not concrete API clients

### 1.3 Folder structure (mirrors `lib/`)

```
lib/
  features/
    auth/
    catalog/
    cart/

test/
  features/
    auth/
    catalog/
    cart/
  helpers/
    fakes.dart
    mocks.dart
    fixtures/
      user.json
      products.json
    test\_di.dart

integration\_test/
  smoke\_test.dart
  login\_flow\_test.dart
  checkout\_flow\_test.dart
```

\---

## 2\) Needed packages 📦

### Minimum (unit)

* `flutter\_test` (built-in)
* `mocktail` (recommended) or `mockito`

### Commonly needed (depending on your stack)

* State management:

  * BLoC/Cubit: `bloc\_test`

* HTTP layer:

  * Dio: `http\_mock\_adapter` (or interceptor-based doubles)

* Utilities:

  * `fake\_async` (control timers)
  * `clock` (inject time)

### Integration

* `integration\_test` (official)

> Keep your test deps minimal. More libs → more flakiness surface.

\---

## 3\) Guide: How to build Unit tests ✅

### 3.1 What to unit-test (priority order)

1. **Use-cases / interactors**
2. **Validation \& parsing rules**
3. **State logic** (Cubit/BLoC/Notifier state transitions)
4. **Repository orchestration** (remote vs cache fallback)
5. **Error mapping** (exceptions → failures)

### 3.2 A repeatable unit test template

Use **AAA** (Arrange / Act / Assert) or **Given-When-Then**.

**Naming**

* File: `\*\_test.dart`
* Description: `given X when Y then Z`

**Template**

```dart
test('given ... when ... then ...', () async {
  // Arrange

  // Act

  // Assert
});
```

### 3.3 Determinism rules (unit)

* No real network
* No real disk I/O (unless you isolate a filesystem adapter)
* No reliance on system time; inject a time provider (`Clock`)

\---

## 4\) Guide: How to build Integration tests 🔁

Integration tests validate **real app wiring**: routes, DI, state, and runtime behavior.

### 4.1 What to cover (minimum set)

* **Smoke**: app launches and shows first screen
* **Auth**: login success + failure (mock/fake backend)
* **Primary flow**: browse → details → add-to-cart → checkout (or similar)
* **Session restore**: after restart (if required)
* **Deep links**: open a details screen (if supported)

### 4.2 Integration test structure

* One file per scenario:

  * `login\_flow\_test.dart`
  * `checkout\_flow\_test.dart`

### 4.3 Deterministic integration testing (critical)

To avoid flakiness:

* Use a **fake backend** (preferred) OR an HTTP interceptor with fixtures
* Seed predictable data (fixtures)
* Wait for UI conditions, not timeouts

### 4.4 Running integration tests

* Locally:

  * `flutter test integration\_test/login\_flow\_test.dart`
* CI:

  * Emulator/simulator job for integration stage
  * Keep integration tests short and few

\---

## 5\) Guide for mocking 🎭

### 5.1 What is mocking?

A **mock** is a programmable stand-in that can:

* Return controlled outputs
* Verify interactions (calls/params/order)

Use mocking when:

* You must validate **calls and parameters**
* The dependency is slow/non-deterministic (network/DB/platform)
* You want precise error simulation (timeouts/500s)

### 5.2 Mocktail basics

```dart
class MockAuthRepo extends Mock implements AuthRepository {}

final repo = MockAuthRepo();

when(() => repo.login(any(), any()))
  .thenAnswer((\_) async => User(id: '1'));
```

If you use custom types with `any()`:

```dart
setUpAll(() {
  registerFallbackValue(LoginRequest(email: '', password: ''));
});
```

\---

## 6\) Guide for faking 🧩

### 6.1 What is a fake?

A **fake** is a lightweight implementation with deterministic behavior,
often using in-memory state.

Use fakes when:

* You want stable behavior without specifying every interaction
* Many tests rely on the same dependency behavior
* The contract is simple and benefits from “stateful realism”

### 6.2 Fake example (in-memory repository)

```dart
class FakeAuthRepository implements AuthRepository {
  User? \_user;

  @override
  Future<User> login(String email, String password) async {
    if (email == 'a@b.com' \&\& password == '123') {
      \_user = User(id: '1');
      return \_user!;
    }
    throw AuthException.invalidCredentials();
  }
}
```

\---

## 7\) When to use mocking vs faking ⚖️

### Decision table

|You need…|Prefer|
|-|-|
|Verify exact calls/parameters/order|**Mock**|
|Simple deterministic behavior + less brittle tests|**Fake**|
|Many tests depend on same dependency behavior|**Fake**|
|Simulate rare/precise errors (timeouts/500s)|**Mock**|
|Avoid over-specifying implementation details|**Fake**|

### Rules of thumb

* **Domain layer:** prefer fakes or pure objects; minimize mocks
* **Data layer:** mock remote/cache data sources or use fakes if simple
* **Integration:** prefer fake backend/fixtures over heavy mocking

\---

## 8\) Best Practices ✅

* **Test boundaries, not internals**: public APIs > private details
* **One behavior per test**: failures should be obvious
* **Use fixtures**: readable JSON / known objects in `test/helpers/fixtures`
* **No real network**: ever (unit/integration)
* **Control time**: inject clock or use `fake\_async`
* **Keys for integration**: add stable widget keys for fields/buttons
* **CI discipline**:

  * PR: `flutter analyze` + `flutter test --coverage`
  * Main/nightly: integration tests on emulator

\---

## 9\) Examples 🧪

### 9.1 Unit test example: Use-case with mocked repo

```dart
import 'package:flutter\_test/flutter\_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository repo;
  late LoginUseCase useCase;

  setUp(() {
    repo = MockAuthRepository();
    useCase = LoginUseCase(repo);
  });

  test('given valid credentials when login then returns user', () async {
    // Arrange
    when(() => repo.login('a@b.com', '123'))
        .thenAnswer((\_) async => User(id: '1'));

    // Act
    final user = await useCase.execute('a@b.com', '123');

    // Assert
    expect(user.id, '1');
    verify(() => repo.login('a@b.com', '123')).called(1);
    verifyNoMoreInteractions(repo);
  });

  test('given invalid credentials when login then throws', () async {
    when(() => repo.login(any(), any()))
        .thenThrow(AuthException.invalidCredentials());

    expect(
      () => useCase.execute('x@y.com', 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });
}
```

### 9.2 Unit test example: Fake repo (less brittle)

```dart
import 'package:flutter\_test/flutter\_test.dart';

void main() {
  test('fake repo supports login success path', () async {
    final repo = FakeAuthRepository();
    final useCase = LoginUseCase(repo);

    final user = await useCase.execute('a@b.com', '123');

    expect(user.id, '1');
  });
}
```

### 9.3 Integration test example: login flow skeleton

```dart
import 'package:flutter\_test/flutter\_test.dart';
import 'package:integration\_test/integration\_test.dart';
import 'package:my\_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow - success', (tester) async {
    app.main(); // ensure main() uses test DI when environment=test
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.tap(find.byKey(const Key('loginButton')));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });
}
```

\---

## 10\) Test DI wiring (critical) 🔌

### Recommended approach

Add a test entry mode that swaps production dependencies with test doubles.

Options:

* Manual constructor injection from `main()`

**Pattern**

* `lib/bootstrap.dart` wires dependencies
* `test/helpers/test\_di.dart` provides test wiring
* Integration tests run app in **test environment** with a fake backend

\---

## Appendix: Suggested keys for integration tests 🔑

* `emailField`, `passwordField`, `loginButton`
* `homeScreen`, `catalogList`, `productItem\_<id>`
* `addToCartButton`, `cartScreen`, `checkoutButton`

