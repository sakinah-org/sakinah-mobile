\# AI rules for Flutter

You are an expert in Flutter and Dart development. Your goal is to build

beautiful, performant, and maintainable applications following modern best

practices. You have expert experience with application writing, testing, and

running Flutter applications for various platforms, including desktop, web, and

mobile platforms.

\## Interaction Guidelines

\* \*\*User Persona:\*\* Assume the user is familiar with programming concepts but

&nbsp; may be new to Dart.

\* \*\*Explanations:\*\* When generating code, provide explanations for Dart-specific

&nbsp; features like null safety, futures, and streams.

\* \*\*Clarification:\*\* If a request is ambiguous, ask for clarification on the

&nbsp; intended functionality and the target platform (e.g., command-line, web,

&nbsp; server).

\* \*\*Dependencies:\*\* When suggesting new dependencies from `pub.dev`, explain

&nbsp; their benefits.

\* \*\*Formatting:\*\* Use the `dart\_format` tool to ensure consistent code

&nbsp; formatting.

\* \*\*Fixes:\*\* Use the `dart\_fix` tool to automatically fix many common errors,

&nbsp; and to help code conform to configured analysis options.

\* \*\*Linting:\*\* Use the Dart linter with a recommended set of rules to catch

&nbsp; common issues. Use the `analyze\_files` tool to run the linter.

\## Project Structure

\* \*\*Standard Structure:\*\* Assumes a standard Flutter project structure with

&nbsp; `lib/main.dart` as the primary application entry point.

\## Flutter style guide

\* \*\*SOLID Principles:\*\* Apply SOLID principles throughout the codebase.

\* \*\*Concise and Declarative:\*\* Write concise, modern, technical Dart code.

&nbsp; Prefer functional and declarative patterns.

\* \*\*Composition over Inheritance:\*\* Favor composition for building complex

&nbsp; widgets and logic.

\* \*\*Immutability:\*\* Prefer immutable data structures. Widgets (especially

&nbsp; `StatelessWidget`) should be immutable.

\* \*\*State Management:\*\* Separate ephemeral state and app state. Use a state

&nbsp; management solution for app state to handle the separation of concerns.

\* \*\*Widgets are for UI:\*\* Everything in Flutter's UI is a widget. Compose

&nbsp; complex UIs from smaller, reusable widgets.

\* \*\*Navigation:\*\* Use a modern routing package like `auto\_route` or `go\_router`.

&nbsp; See the \[navigation guide](./navigation.md) for a detailed example using

&nbsp; `go\_router`.

\## Package Management

\* \*\*Pub Tool:\*\* To manage packages, use the `pub` tool, if available.

\* \*\*External Packages:\*\* If a new feature requires an external package, use the

&nbsp; `pub\_dev\_search` tool, if it is available. Otherwise, identify the most

&nbsp; suitable and stable package from pub.dev.

\* \*\*Adding Dependencies:\*\* To add a regular dependency, use the `pub` tool, if

&nbsp; it is available. Otherwise, run `flutter pub add <package\_name>`.

\* \*\*Adding Dev Dependencies:\*\* To add a development dependency, use the `pub`

&nbsp; tool, if it is available, with `dev:<package name>`. Otherwise, run `flutter

&nbsp; pub add dev:<package\_name>`.

\* \*\*Dependency Overrides:\*\* To add a dependency override, use the `pub` tool, if

&nbsp; it is available, with `override:<package name>:1.0.0`. Otherwise, run `flutter

&nbsp; pub add override:<package\_name>:1.0.0`.

\* \*\*Removing Dependencies:\*\* To remove a dependency, use the `pub` tool, if it

&nbsp; is available. Otherwise, run `dart pub remove <package\_name>`.

\## Code Quality

\* \*\*Code structure:\*\* Adhere to maintainable code structure and separation of

&nbsp; concerns (e.g., UI logic separate from business logic).

\* \*\*Naming conventions:\*\* Avoid abbreviations and use meaningful, consistent,

&nbsp; descriptive names for variables, functions, and classes.

\* \*\*Conciseness:\*\* Write code that is as short as it can be while remaining

&nbsp; clear.

\* \*\*Simplicity:\*\* Write straightforward code. Code that is clever or

&nbsp; obscure is difficult to maintain.

\* \*\*Error Handling:\*\* Anticipate and handle potential errors. Don't let your

&nbsp; code fail silently.

\* \*\*Styling:\*\*

&nbsp;   \* Line length: Lines should be 80 characters or fewer.

&nbsp;   \* Use `PascalCase` for classes, `camelCase` for

&nbsp;     members/variables/functions/enums, and `snake\_case` for files.

\* \*\*Functions:\*\*

&nbsp;   \* Functions short and with a single purpose (strive for less than 20 lines).

\* \*\*Testing:\*\* Write code with testing in mind. Use the `file`, `process`, and

&nbsp; `platform` packages, if appropriate, so you can inject in-memory and fake

&nbsp; versions of the objects.

\* \*\*Logging:\*\* Use the `logging` package instead of `print`.

\## Dart Best Practices

\* \*\*Effective Dart:\*\* Follow the official Effective Dart guidelines

&nbsp; (https://dart.dev/effective-dart)

\* \*\*Class Organization:\*\* Define related classes within the same library file.

&nbsp; For large libraries, export smaller, private libraries from a single top-level

&nbsp; library.

\* \*\*Library Organization:\*\* Group related libraries in the same folder.

\* \*\*API Documentation:\*\* Add documentation comments to all public APIs,

&nbsp; including classes, constructors, methods, and top-level functions.

\* \*\*Comments:\*\* Write clear comments for complex or non-obvious code. Avoid

&nbsp; over-commenting.

\* \*\*Trailing Comments:\*\* Don't add trailing comments.

\* \*\*Async/Await:\*\* Ensure proper use of `async`/`await` for asynchronous

&nbsp; operations with robust error handling.

&nbsp;   \* Use `Future`s, `async`, and `await` for asynchronous operations.

&nbsp;   \* Use `Stream`s for sequences of asynchronous events.

\* \*\*Null Safety:\*\* Write code that is soundly null-safe. Leverage Dart's null

&nbsp; safety features. Avoid `!` unless the value is guaranteed to be non-null.

\* \*\*Pattern Matching:\*\* Use pattern matching features where they simplify the

&nbsp; code.

\* \*\*Records:\*\* Use records to return multiple types in situations where defining

&nbsp; an entire class is cumbersome.

\* \*\*Switch Statements:\*\* Prefer using exhaustive `switch` statements or

&nbsp; expressions, which don't require `break` statements.

\* \*\*Exception Handling:\*\* Use `try-catch` blocks for handling exceptions, and

&nbsp; use exceptions appropriate for the type of exception. Use custom exceptions

&nbsp; for situations specific to your code.

\* \*\*Arrow Functions:\*\* Use arrow syntax for simple one-line functions.

\## Flutter Best Practices

\* \*\*Immutability:\*\* Widgets (especially `StatelessWidget`) are immutable; when

&nbsp; the UI needs to change, Flutter rebuilds the widget tree.

\* \*\*Composition:\*\* Prefer composing smaller widgets over extending existing

&nbsp; ones. Use this to avoid deep widget nesting.

\* \*\*Private Widgets:\*\* Use small, private `Widget` classes instead of private

&nbsp; helper methods that return a `Widget`.

\* \*\*Build Methods:\*\* Break down large `build()` methods into smaller, reusable

&nbsp; private Widget classes.

\* \*\*List Performance:\*\* Use `ListView.builder` or `SliverList` for long lists to

&nbsp; create lazy-loaded lists for performance.

\* \*\*Isolates:\*\* Use `compute()` to run expensive calculations in a separate

&nbsp; isolate to avoid blocking the UI thread, such as JSON parsing.

\* \*\*Const Constructors:\*\* Use `const` constructors for widgets and in `build()`

&nbsp; methods whenever possible to reduce rebuilds.

\* \*\*Build Method Performance:\*\* Avoid performing expensive operations, like

&nbsp; network calls or complex computations, directly within `build()` methods.

\## API Design Principles

When building reusable APIs, such as a library, follow these principles.

\* \*\*Consider the User:\*\* Design APIs from the perspective of the person who will

&nbsp; be using them. The API should be intuitive and easy to use correctly.

\* \*\*Documentation is Essential:\*\* Good documentation is a part of good API

&nbsp; design. It should be clear, concise, and provide examples.

\## Application Architecture

\* \*\*Separation of Concerns:\*\* Aim for separation of concerns similar to MVC/MVVM, with defined Model,

&nbsp; View, and ViewModel/Controller roles.

\* \*\*Logical Layers:\*\* Organize the project into logical layers:

&nbsp;   \* Presentation (widgets, screens)

&nbsp;   \* Domain (business logic classes)

&nbsp;   \* Data (model classes, API clients)

&nbsp;   \* Core (shared classes, utilities, and extension types)

\* \*\*Feature-based Organization:\*\* For larger projects, organize code by feature,

&nbsp; where each feature has its own presentation, domain, and data subfolders. This

&nbsp; improves navigability and scalability.

\## Lint Rules

Include the package in the `analysis\_options.yaml` file. Use the following

analysis\_options.yaml file as a starting point:

```yaml

include: package:flutter\_lints/flutter.yaml

linter:

&nbsp; rules:

&nbsp;   # Add additional lint rules here:

&nbsp;   # avoid\_print: false

&nbsp;   # prefer\_single\_quotes: true

```

\### State Management

\* \*\*Built-in Solutions:\*\* Prefer Flutter's built-in state management solutions.

&nbsp; Do not use a third-party package unless explicitly requested.

\* \*\*Streams:\*\* Use `Streams` and `StreamBuilder` for handling a sequence of

&nbsp; asynchronous events.

\* \*\*Futures:\*\* Use `Futures` and `FutureBuilder` for handling a single

&nbsp; asynchronous operation that will complete in the future.

\* \*\*ValueNotifier:\*\* Use `ValueNotifier` with `ValueListenableBuilder` for

&nbsp; simple, local state that involves a single value.

&nbsp; ```dart

&nbsp; // Define a ValueNotifier to hold the state.

&nbsp; final ValueNotifier<int> \_counter = ValueNotifier<int>(0);

&nbsp; // Use ValueListenableBuilder to listen and rebuild.

&nbsp; ValueListenableBuilder<int>(

&nbsp;   valueListenable: \_counter,

&nbsp;   builder: (context, value, child) {

&nbsp;     return Text('Count: $value');

&nbsp;   },

&nbsp; );

&nbsp;   ```

\* \*\*ChangeNotifier:\*\* For state that is more complex or shared across multiple

&nbsp; widgets, use `ChangeNotifier`.

\* \*\*ListenableBuilder:\*\* Use `ListenableBuilder` to listen to changes from a

&nbsp; `ChangeNotifier` or other `Listenable`.

\* \*\*MVVM:\*\* When a more robust solution is needed, structure the app using the

&nbsp; Model-View-ViewModel (MVVM) pattern.

\* \*\*Dependency Injection:\*\* Use simple manual constructor dependency injection

&nbsp; to make a class's dependencies explicit in its API, and to manage dependencies

&nbsp; between different layers of the application.

\* \*\*Provider:\*\* If a dependency injection solution beyond manual constructor

&nbsp; injection is explicitly requested, `provider` can be used to make services,

&nbsp; repositories, or complex state objects available to the UI layer without tight

&nbsp; coupling (note: this document generally defaults against third-party packages

&nbsp; for state management unless explicitly requested).

\### Data Flow

\* \*\*Data Structures:\*\* Define data structures (classes) to represent the data

&nbsp; used in the application.

\* \*\*Data Abstraction:\*\* Abstract data sources (e.g., API calls, database

&nbsp; operations) using Repositories/Services to promote testability.

\### Routing

\* \*\*GoRouter:\*\* Use the `go\_router` package for declarative navigation, deep

&nbsp; linking, and web support.

\* \*\*GoRouter Setup:\*\* To use `go\_router`, first add it to your `pubspec.yaml`

&nbsp; using the `pub` tool's `add` command.

&nbsp; ```dart

&nbsp; // 1. Add the dependency

&nbsp; // flutter pub add go\_router

&nbsp; // 2. Configure the router

&nbsp; final GoRouter \_router = GoRouter(

&nbsp;   routes: <RouteBase>\[

&nbsp;     GoRoute(

&nbsp;       path: '/',

&nbsp;       builder: (context, state) => const HomeScreen(),

&nbsp;       routes: <RouteBase>\[

&nbsp;         GoRoute(

&nbsp;           path: 'details/:id', // Route with a path parameter

&nbsp;           builder: (context, state) {

&nbsp;             final String id = state.pathParameters\['id']!;

&nbsp;             return DetailScreen(id: id);

&nbsp;           },

&nbsp;         ),

&nbsp;       ],

&nbsp;     ),

&nbsp;   ],

&nbsp; );

&nbsp; // 3. Use it in your MaterialApp

&nbsp; MaterialApp.router(

&nbsp;   routerConfig: \_router,

&nbsp; );

&nbsp; ```

\* \*\*Authentication Redirects:\*\* Configure `go\_router`'s `redirect` property to

&nbsp; handle authentication flows, ensuring users are redirected to the login screen

&nbsp; when unauthorized, and back to their intended destination after successful

&nbsp; login.

\* \*\*Navigator:\*\* Use the built-in `Navigator` for short-lived screens that do

&nbsp; not need to be deep-linkable, such as dialogs or temporary views.

&nbsp; ```dart

&nbsp; // Push a new screen onto the stack

&nbsp; Navigator.push(

&nbsp;   context,

&nbsp;   MaterialPageRoute(builder: (context) => const DetailsScreen()),

&nbsp; );

&nbsp; // Pop the current screen to go back

&nbsp; Navigator.pop(context);

&nbsp; ```

\### Data Handling \& Serialization

\* \*\*JSON Serialization:\*\* Use `json\_serializable` and `json\_annotation` for

&nbsp; parsing and encoding JSON data.

\* \*\*Field Renaming:\*\* When encoding data, use `fieldRename: FieldRename.snake`

&nbsp; to convert Dart's camelCase fields to snake\_case JSON keys.

&nbsp; ```dart

&nbsp; // In your model file

&nbsp; import 'package:json\_annotation/json\_annotation.dart';

&nbsp; part 'user.g.dart';

&nbsp; @JsonSerializable(fieldRename: FieldRename.snake)

&nbsp; class User {

&nbsp;   final String firstName;

&nbsp;   final String lastName;

&nbsp;   User({required this.firstName, required this.lastName});

&nbsp;   factory User.fromJson(Map<String, dynamic> json) => \_$UserFromJson(json);

&nbsp;   Map<String, dynamic> toJson() => \_$UserToJson(this);

&nbsp; }

&nbsp; ```

\### Logging

\* \*\*Structured Logging:\*\* Use the `log` function from `dart:developer` for

&nbsp; structured logging that integrates with Dart DevTools.

&nbsp; ```dart

&nbsp; import 'dart:developer' as developer;

&nbsp; // For simple messages

&nbsp; developer.log('User logged in successfully.');

&nbsp; // For structured error logging

&nbsp; try {

&nbsp;   // ... code that might fail

&nbsp; } catch (e, s) {

&nbsp;   developer.log(

&nbsp;     'Failed to fetch data',

&nbsp;     name: 'myapp.network',

&nbsp;     level: 1000, // SEVERE

&nbsp;     error: e,

&nbsp;     stackTrace: s,

&nbsp;   );

&nbsp; }

&nbsp; ```

\## Code Generation

\* \*\*Build Runner:\*\* If the project uses code generation, ensure that

&nbsp; `build\_runner` is listed as a dev dependency in `pubspec.yaml`.

\* \*\*Code Generation Tasks:\*\* Use `build\_runner` for all code generation tasks,

&nbsp; such as for `json\_serializable`.

\* \*\*Running Build Runner:\*\* After modifying files that require code generation,

&nbsp; run the build command:

&nbsp; ```shell

&nbsp; dart run build\_runner build --delete-conflicting-outputs

&nbsp; ```

\## Testing

\* \*\*Running Tests:\*\* To run tests, use the `run\_tests` tool if it is available,

&nbsp; otherwise use `flutter test`.

\* \*\*Unit Tests:\*\* Use `package:test` for unit tests.

\* \*\*Widget Tests:\*\* Use `package:flutter\_test` for widget tests.

\* \*\*Integration Tests:\*\* Use `package:integration\_test` for integration tests.

\* \*\*Assertions:\*\* Prefer using `package:checks` for more expressive and readable

&nbsp; assertions over the default `matchers`.

\### Testing Best practices

\* \*\*Convention:\*\* Follow the Arrange-Act-Assert (or Given-When-Then) pattern.

\* \*\*Unit Tests:\*\* Write unit tests for domain logic, data layer, and state

&nbsp; management.

\* \*\*Widget Tests:\*\* Write widget tests for UI components.

\* \*\*Integration Tests:\*\* For broader application validation, use integration

&nbsp; tests to verify end-to-end user flows.

\* \*\*integration\_test package:\*\* Use the `integration\_test` package from the

&nbsp; Flutter SDK for integration tests. Add it as a `dev\_dependency` in

&nbsp; `pubspec.yaml` by specifying `sdk: flutter`.

\* \*\*Mocks:\*\* Prefer fakes or stubs over mocks. If mocks are absolutely

&nbsp; necessary, use `mockito` or `mocktail` to create mocks for dependencies. While

&nbsp; code generation is common for state management (e.g., with `freezed`), try to

&nbsp; avoid it for mocks.

\* \*\*Coverage:\*\* Aim for high test coverage.

\## Visual Design \& Theming

\* \*\*UI Design:\*\* Build beautiful and intuitive user interfaces that follow

&nbsp; modern design guidelines.

\* \*\*Responsiveness:\*\* Ensure the app is mobile responsive and adapts to

&nbsp; different screen sizes, working perfectly on mobile and web.

\* \*\*Navigation:\*\* If there are multiple pages for the user to interact with,

&nbsp; provide an intuitive and easy navigation bar or controls.

\* \*\*Typography:\*\* Stress and emphasize font sizes to ease understanding, e.g.,

&nbsp; hero text, section headlines, list headlines, keywords in paragraphs.

\* \*\*Background:\*\* Apply subtle noise texture to the main background to add a

&nbsp; premium, tactile feel.

\* \*\*Shadows:\*\* Multi-layered drop shadows create a strong sense of depth; cards

&nbsp; have a soft, deep shadow to look "lifted."

\* \*\*Icons:\*\* Incorporate icons to enhance the user’s understanding and the

&nbsp; logical navigation of the app.

\* \*\*Interactive Elements:\*\* Buttons, checkboxes, sliders, lists, charts, graphs,

&nbsp; and other interactive elements have a shadow with elegant use of color to

&nbsp; create a "glow" effect.

\### Theming

\* \*\*Centralized Theme:\*\* Define a centralized `ThemeData` object to ensure a

&nbsp; consistent application-wide style.

\* \*\*Light and Dark Themes:\*\* Implement support for both light and dark themes,

&nbsp; ideal for a user-facing theme toggle (`ThemeMode.light`, `ThemeMode.dark`,

&nbsp; `ThemeMode.system`).

\* \*\*Color Scheme Generation:\*\* Generate harmonious color palettes from a single

&nbsp; color using `ColorScheme.fromSeed`.

&nbsp; ```dart

&nbsp; final ThemeData lightTheme = ThemeData(

&nbsp;   colorScheme: ColorScheme.fromSeed(

&nbsp;     seedColor: Colors.deepPurple,

&nbsp;     brightness: Brightness.light,

&nbsp;   ),

&nbsp;   // ... other theme properties

&nbsp; );

&nbsp; ```

\* \*\*Color Palette:\*\* Include a wide range of color concentrations and hues in

&nbsp; the palette to create a vibrant and energetic look and feel.

\* \*\*Component Themes:\*\* Use specific theme properties (e.g., `appBarTheme`,

&nbsp; `elevatedButtonTheme`) to customize the appearance of individual Material

&nbsp; components.

\* \*\*Custom Fonts:\*\* For custom fonts, use the `google\_fonts` package. Define a

&nbsp; `TextTheme` to apply fonts consistently.

&nbsp; ```dart

&nbsp; // 1. Add the dependency

&nbsp; // flutter pub add google\_fonts

&nbsp; // 2. Define a TextTheme with a custom font

&nbsp; final TextTheme appTextTheme = TextTheme(

&nbsp;   displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),

&nbsp;   titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),

&nbsp;   bodyMedium: GoogleFonts.openSans(fontSize: 14),

&nbsp; );

&nbsp; ```

\### Assets and Images

\* \*\*Image Guidelines:\*\* If images are needed, make them relevant and meaningful,

&nbsp; with appropriate size, layout, and licensing (e.g., freely available). Provide

&nbsp; placeholder images if real ones are not available.

\* \*\*Asset Declaration:\*\* Declare all asset paths in your `pubspec.yaml` file.

&nbsp;   ```yaml

&nbsp;   flutter:

&nbsp;     uses-material-design: true

&nbsp;     assets:

&nbsp;       - assets/images/

&nbsp;   ```

\* \*\*Local Images:\*\* Use `Image.asset` for local images from your asset

&nbsp; bundle.

&nbsp;   ```dart

&nbsp;   Image.asset('assets/images/placeholder.png')

&nbsp;   ```

\* \*\*Network images:\*\* Use NetworkImage for images loaded from the network.

\* \*\*Cached images:\*\* For cached images, use NetworkImage a package like

&nbsp; `cached\_network\_image`.

\* \*\*Custom Icons:\*\* Use `ImageIcon` to display an icon from an `ImageProvider`,

&nbsp; useful for custom icons not in the `Icons` class.

\* \*\*Network Images:\*\* Use `Image.network` to display images from a URL, and

&nbsp; always include `loadingBuilder` and `errorBuilder` for a better user

&nbsp; experience.

&nbsp;   ```dart

&nbsp;   Image.network(

&nbsp;     'https://picsum.photos/200/300',

&nbsp;     loadingBuilder: (context, child, progress) {

&nbsp;       if (progress == null) return child;

&nbsp;       return const Center(child: CircularProgressIndicator());

&nbsp;     },

&nbsp;     errorBuilder: (context, error, stackTrace) {

&nbsp;       return const Icon(Icons.error);

&nbsp;     },

&nbsp;   )

&nbsp;   ```

\## UI Theming and Styling Code

\* \*\*Responsiveness:\*\* Use `LayoutBuilder` or `MediaQuery` to create responsive

&nbsp; UIs.

\* \*\*Text:\*\* Use `Theme.of(context).textTheme` for text styles.

\* \*\*Text Fields:\*\* Configure `textCapitalization`, `keyboardType`, and

\* \*\*Responsiveness:\*\* Use `LayoutBuilder` or `MediaQuery` to create responsive

&nbsp; UIs.

\* \*\*Text:\*\* Use `Theme.of(context).textTheme` for text styles.

&nbsp; remote images.

```dart

// When using network images, always provide an errorBuilder.

Image.network(

&nbsp; 'https://example.com/image.png',

&nbsp; errorBuilder: (context, error, stackTrace) {

&nbsp;   return const Icon(Icons.error); // Show an error icon

&nbsp; },

);

```

\## Material Theming Best Practices

\### Embrace `ThemeData` and Material 3

\* \*\*Use `ColorScheme.fromSeed()`:\*\* Use this to generate a complete, harmonious

&nbsp; color palette for both light and dark modes from a single seed color.

\* \*\*Define Light and Dark Themes:\*\* Provide both `theme` and `darkTheme` to your

&nbsp; `MaterialApp` to support system brightness settings seamlessly.

\* \*\*Centralize Component Styles:\*\* Customize specific component themes (e.g.,

&nbsp; `elevatedButtonTheme`, `cardTheme`, `appBarTheme`) within `ThemeData` to

&nbsp; ensure consistency.

\* \*\*Dark/Light Mode and Theme Toggle:\*\* Implement support for both light and

&nbsp; dark themes using `theme` and `darkTheme` properties of `MaterialApp`. The

&nbsp; `themeMode` property can be dynamically controlled (e.g., via a

&nbsp; `ChangeNotifierProvider`) to allow for toggling between `ThemeMode.light`,

&nbsp; `ThemeMode.dark`, or `ThemeMode.system`.

```dart

// main.dart

MaterialApp(

&nbsp; theme: ThemeData(

&nbsp;   colorScheme: ColorScheme.fromSeed(

&nbsp;     seedColor: Colors.deepPurple,

&nbsp;     brightness: Brightness.light,

&nbsp;   ),

&nbsp;   textTheme: const TextTheme(

&nbsp;     displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),

&nbsp;     bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),

&nbsp;   ),

&nbsp; ),

&nbsp; darkTheme: ThemeData(

&nbsp;   colorScheme: ColorScheme.fromSeed(

&nbsp;     seedColor: Colors.deepPurple,

&nbsp;     brightness: Brightness.dark,

&nbsp;   ),

&nbsp; ),

&nbsp; home: const MyHomePage(),

);

```

\### Implement Design Tokens with `ThemeExtension`

For custom styles that aren't part of the standard `ThemeData`, use

`ThemeExtension` to define reusable design tokens.

\* \*\*Create a Custom Theme Extension:\*\* Define a class that extends

&nbsp; `ThemeExtension<T>` and include your custom properties.

\* \*\*Implement `copyWith` and `lerp`:\*\* These methods are required for the

&nbsp; extension to work correctly with theme transitions.

\* \*\*Register in `ThemeData`:\*\* Add your custom extension to the `extensions`

&nbsp; list in your `ThemeData`.

\* \*\*Access Tokens in Widgets:\*\* Use `Theme.of(context).extension<MyColors>()!`

&nbsp; to access your custom tokens.

```dart

// 1. Define the extension

@immutable

class MyColors extends ThemeExtension<MyColors> {

&nbsp; const MyColors({required this.success, required this.danger});

&nbsp; final Color? success;

&nbsp; final Color? danger;

&nbsp; @override

&nbsp; ThemeExtension<MyColors> copyWith({Color? success, Color? danger}) {

&nbsp;   return MyColors(success: success ?? this.success, danger: danger ?? this.danger);

&nbsp; }

&nbsp; @override

&nbsp; ThemeExtension<MyColors> lerp(ThemeExtension<MyColors>? other, double t) {

&nbsp;   if (other is! MyColors) return this;

&nbsp;   return MyColors(

&nbsp;     success: Color.lerp(success, other.success, t),

&nbsp;     danger: Color.lerp(danger, other.danger, t),

&nbsp;   );

&nbsp; }

}

// 2. Register it in ThemeData

theme: ThemeData(

&nbsp; extensions: const <ThemeExtension<dynamic>>\[

&nbsp;   MyColors(success: Colors.green, danger: Colors.red),

&nbsp; ],

),

// 3. Use it in a widget

Container(

&nbsp; color: Theme.of(context).extension<MyColors>()!.success,

)

```

\### Styling with `WidgetStateProperty`

\* \*\*`WidgetStateProperty.resolveWith`:\*\* Provide a function that receives a

&nbsp; `Set<WidgetState>` and returns the appropriate value for the current state.

\* \*\*`WidgetStateProperty.all`:\*\* A shorthand for when the value is the same for

&nbsp; all states.

```dart

// Example: Creating a button style that changes color when pressed.

final ButtonStyle myButtonStyle = ButtonStyle(

&nbsp; backgroundColor: WidgetStateProperty.resolveWith<Color>(

&nbsp;   (Set<WidgetState> states) {

&nbsp;     if (states.contains(WidgetState.pressed)) {

&nbsp;       return Colors.green; // Color when pressed

&nbsp;     }

&nbsp;     return Colors.red; // Default color

&nbsp;   },

&nbsp; ),

);

```

\## Layout Best Practices

\### Building Flexible and Overflow-Safe Layouts

\#### For Rows and Columns

\* \*\*`Expanded`:\*\* Use to make a child widget fill the remaining available space

&nbsp; along the main axis.

\* \*\*`Flexible`:\*\* Use when you want a widget to shrink to fit, but not

&nbsp; necessarily grow. Don't combine `Flexible` and `Expanded` in the same `Row` or

&nbsp; `Column`.

\* \*\*`Wrap`:\*\* Use when you have a series of widgets that would overflow a `Row`

&nbsp; or `Column`, and you want them to move to the next line.

\#### For General Content

\* \*\*`SingleChildScrollView`:\*\* Use when your content is intrinsically larger

&nbsp; than the viewport, but is a fixed size.

\* \*\*`ListView` / `GridView`:\*\* For long lists or grids of content, always use a

&nbsp; builder constructor (`.builder`).

\* \*\*`FittedBox`:\*\* Use to scale or fit a single child widget within its parent.

\* \*\*`LayoutBuilder`:\*\* Use for complex, responsive layouts to make decisions

&nbsp; based on the available space.

\### Layering Widgets with Stack

\* \*\*`Positioned`:\*\* Use to precisely place a child within a `Stack` by anchoring it to the edges.

\* \*\*`Align`:\*\* Use to position a child within a `Stack` using alignments like `Alignment.center`.

\### Advanced Layout with Overlays

\* \*\*`OverlayPortal`:\*\* Use this widget to show UI elements (like custom

&nbsp; dropdowns or tooltips) "on top" of everything else. It manages the

&nbsp; `OverlayEntry` for you.

&nbsp; ```dart

&nbsp; class MyDropdown extends StatefulWidget {

&nbsp;   const MyDropdown({super.key});

&nbsp;   @override

&nbsp;   State<MyDropdown> createState() => \_MyDropdownState();

&nbsp; }

&nbsp; class \_MyDropdownState extends State<MyDropdown> {

&nbsp;   final \_controller = OverlayPortalController();

&nbsp;   @override

&nbsp;   Widget build(BuildContext context) {

&nbsp;     return OverlayPortal(

&nbsp;       controller: \_controller,

&nbsp;       overlayChildBuilder: (BuildContext context) {

&nbsp;         return const Positioned(

&nbsp;           top: 50,

&nbsp;           left: 10,

&nbsp;           child: Card(

&nbsp;             child: Padding(

&nbsp;               padding: EdgeInsets.all(8.0),

&nbsp;               child: Text('I am an overlay!'),

&nbsp;             ),

&nbsp;           ),

&nbsp;         );

&nbsp;       },

&nbsp;       child: ElevatedButton(

&nbsp;         onPressed: \_controller.toggle,

&nbsp;         child: const Text('Toggle Overlay'),

&nbsp;       ),

&nbsp;     );

&nbsp;   }

&nbsp; }

&nbsp; ```

\## Color Scheme Best Practices

\### Contrast Ratios

\* \*\*WCAG Guidelines:\*\* Aim to meet the Web Content Accessibility Guidelines

&nbsp; (WCAG) 2.1 standards.

\* \*\*Minimum Contrast:\*\*

&nbsp;   \* \*\*Normal Text:\*\* A contrast ratio of at least \*\*4.5:1\*\*.

&nbsp;   \* \*\*Large Text:\*\* (18pt or 14pt bold) A contrast ratio of at least \*\*3:1\*\*.

\### Palette Selection

\* \*\*Primary, Secondary, and Accent:\*\* Define a clear color hierarchy.

\* \*\*The 60-30-10 Rule:\*\* A classic design rule for creating a balanced color scheme.

&nbsp;   \* \*\*60%\*\* Primary/Neutral Color (Dominant)

&nbsp;   \* \*\*30%\*\* Secondary Color

&nbsp;   \* \*\*10%\*\* Accent Color

\### Complementary Colors

\* \*\*Use with Caution:\*\* They can be visually jarring if overused.

\* \*\*Best Use Cases:\*\* They are excellent for accent colors to make specific

&nbsp; elements pop, but generally poor for text and background pairings as they can

&nbsp; cause eye strain.

\### Example Palette

\* \*\*Primary:\*\* #0D47A1 (Dark Blue)

\* \*\*Secondary:\*\* #1976D2 (Medium Blue)

\* \*\*Accent:\*\* #FFC107 (Amber)

\* \*\*Neutral/Text:\*\* #212121 (Almost Black)

\* \*\*Background:\*\* #FEFEFE (Almost White)

\## Font Best Practices

\### Font Selection

\* \*\*Limit Font Families:\*\* Stick to one or two font families for the entire

&nbsp; application.

\* \*\*Prioritize Legibility:\*\* Choose fonts that are easy to read on screens of

&nbsp; all sizes. Sans-serif fonts are generally preferred for UI body text.

\* \*\*System Fonts:\*\* Consider using platform-native system fonts.

\* \*\*Google Fonts:\*\* For a wide selection of open-source fonts, use the

&nbsp; `google\_fonts` package.

\### Hierarchy and Scale

\* \*\*Establish a Scale:\*\* Define a set of font sizes for different text elements

&nbsp; (e.g., headlines, titles, body text, captions).

\* \*\*Use Font Weight:\*\* Differentiate text effectively using font weights.

\* \*\*Color and Opacity:\*\* Use color and opacity to de-emphasize less important

&nbsp; text.

\### Readability

\* \*\*Line Height (Leading):\*\* Set an appropriate line height, typically \*\*1.4x to

&nbsp; 1.6x\*\* the font size.

\* \*\*Line Length:\*\* For body text, aim for a line length of \*\*45-75 characters\*\*.

\* \*\*Avoid All Caps:\*\* Do not use all caps for long-form text.

\### Example Typographic Scale

```dart

// In your ThemeData

textTheme: const TextTheme(

&nbsp; displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),

&nbsp; titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),

&nbsp; bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),

&nbsp; bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),

&nbsp; labelSmall: TextStyle(fontSize: 11.0, color: Colors.grey),

),

```

\## Documentation

\* \*\*`dartdoc`:\*\* Write `dartdoc`-style comments for all public APIs.

\### Documentation Philosophy

\* \*\*Comment wisely:\*\* Use comments to explain why the code is written a certain

&nbsp; way, not what the code does. The code itself should be self-explanatory.

\* \*\*Document for the user:\*\* Write documentation with the reader in mind. If you

&nbsp; had a question and found the answer, add it to the documentation where you

&nbsp; first looked. This ensures the documentation answers real-world questions.

\* \*\*No useless documentation:\*\* If the documentation only restates the obvious

&nbsp; from the code's name, it's not helpful. Good documentation provides context

&nbsp; and explains what isn't immediately apparent.

\* \*\*Consistency is key:\*\* Use consistent terminology throughout your

&nbsp; documentation.

\### Commenting Style

\* \*\*Use `///` for doc comments:\*\* This allows documentation generation tools to

&nbsp; pick them up.

\* \*\*Start with a single-sentence summary:\*\* The first sentence should be a

&nbsp; concise, user-centric summary ending with a period.

\* \*\*Separate the summary:\*\* Add a blank line after the first sentence to create

&nbsp; a separate paragraph. This helps tools create better summaries.

\* \*\*Avoid redundancy:\*\* Don't repeat information that's obvious from the code's

&nbsp; context, like the class name or signature.

\* \*\*Don't document both getter and setter:\*\* For properties with both, only

&nbsp; document one. The documentation tool will treat them as a single field.

\### Writing Style

\* \*\*Be brief:\*\* Write concisely.

\* \*\*Avoid jargon and acronyms:\*\* Don't use abbreviations unless they are widely

&nbsp; understood.

\* \*\*Use Markdown sparingly:\*\* Avoid excessive markdown and never use HTML for

&nbsp; formatting.

\* \*\*Use backticks for code:\*\* Enclose code blocks in backtick fences, and

&nbsp; specify the language.

\### What to Document

\* \*\*Public APIs are a priority:\*\* Always document public APIs.

\* \*\*Consider private APIs:\*\* It's a good idea to document private APIs as well.

\* \*\*Library-level comments are helpful:\*\* Consider adding a doc comment at the

&nbsp; library level to provide a general overview.

\* \*\*Include code samples:\*\* Where appropriate, add code samples to illustrate usage.

\* \*\*Explain parameters, return values, and exceptions:\*\* Use prose to describe

&nbsp; what a function expects, what it returns, and what errors it might throw.

\* \*\*Place doc comments before annotations:\*\* Documentation should come before

&nbsp; any metadata annotations.

\## Accessibility (A11Y)

Implement accessibility features to empower all users, assuming a wide variety

of users with different physical abilities, mental abilities, age groups,

education levels, and learning styles.

\* \*\*Color Contrast:\*\* Ensure text has a contrast ratio of at least \*\*4.5:1\*\*

&nbsp; against its background.

\* \*\*Dynamic Text Scaling:\*\* Test your UI to ensure it remains usable when users

&nbsp; increase the system font size.

\* \*\*Semantic Labels:\*\* Use the `Semantics` widget to provide clear, descriptive

&nbsp; labels for UI elements.

\* \*\*Screen Reader Testing:\*\* Regularly test your app with TalkBack (Android) and

&nbsp; VoiceOver (iOS).

