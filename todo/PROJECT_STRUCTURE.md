# To-Do App Project Structure

This document serves as a source of truth for the project structure of the To-Do App. It should be updated whenever there are major structural changes to the project.

## Root Directory Structure

```
todo/
├── android/           # Android platform-specific files
├── ios/               # iOS platform-specific files
├── linux/             # Linux platform-specific files
├── macos/             # macOS platform-specific files
├── windows/           # Windows platform-specific files
├── web/               # Web platform-specific files
├── build/             # Compiled files (auto-generated)
├── .dart_tool/        # Dart tool configuration (auto-generated)
├── images/            # Image assets
│   ├── appicon.jpeg   # App icon image
│   ├── person.jpeg    # Person image used in the app
│   └── task.svg       # Task SVG icon
├── lib/               # Main source code directory
├── test/              # Test files
│   └── widget_test.dart # Widget tests
├── .flutter-plugins   # Flutter plugins configuration (auto-generated)
├── .flutter-plugins-dependencies # Plugin dependencies (auto-generated)
├── .metadata          # Flutter metadata (auto-generated)
├── analysis_options.yaml # Dart analysis options
├── pubspec.lock       # Dependency lock file (auto-generated)
├── pubspec.yaml       # Flutter/Dart dependencies
└── README.md          # Project documentation
```

## Lib Directory Structure

```
lib/
├── controllers/       # GetX controllers
│   └── task_controller.dart   # Task management controller
├── db/                # Database related files
│   └── db_helper.dart         # SQLite database helper
├── models/            # Data models
│   └── task.dart              # Task model
├── services/          # Service files
│   ├── notification_services.dart  # Notification management
│   └── theme_services.dart         # Theme management
├── ui/                # UI related files
│   ├── pages/         # App screens
│   │   ├── add_task_page.dart      # Add task screen
│   │   ├── home_page.dart          # Home screen
│   │   └── notification_screen.dart # Notification screen
│   ├── widgets/       # Reusable UI components
│   │   ├── button.dart             # Custom button widget
│   │   ├── input_field.dart        # Custom input field widget
│   │   └── task_tile.dart          # Task item widget
│   ├── size_config.dart  # Responsive sizing utilities
│   └── theme.dart        # App theme configuration
└── main.dart          # App entry point
```

## Dependencies

The app uses several packages for different functionalities:

- **State Management**:
  - get: ^4.3.8 (GetX for state management, routing, etc.)
  - get_storage: ^2.0.3 (for persistent storage)

- **UI Components**:
  - google_fonts: ^5.1.0
  - date_picker_timeline: ^1.2.3
  - flutter_staggered_animations: ^1.0.0
  - flutter_svg: ^2.0.7

- **Local Storage**:
  - sqflite: ^2.0.0+4 (SQLite database)

- **Notifications**:
  - flutter_local_notifications: ^15.1.0+1
  - timezone: ^0.9.2
  - flutter_timezone: ^1.0.7
  - rxdart: ^0.27.2

- **Utilities**:
  - intl: ^0.18.1 (for date formatting)
  - typed_data: ^1.3.2

- **Development Dependencies**:
  - flutter_launcher_icons: ^0.13.1
  - flutter_lints: ^2.0.2

## Architecture Overview

The app follows a layered architecture with clear separation of concerns:

1. **Presentation Layer** (UI folders): Contains all UI components, pages, and widgets.

2. **Business Logic Layer** (Controllers): Implements the application logic and state management using GetX controllers.

3. **Data Layer**:
   - **Models**: Define data structures for the application.
   - **Services**: Handle specific services like notifications and theme.
   - **Database**: Manages local data persistence using SQLite.

The app uses GetX for state management, dependency injection, and navigation. 