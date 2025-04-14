# TODO App with Flutter

A simple TODO app built using Flutter that helps you manage your tasks efficiently.

## Features

- Add tasks with due dates.
- Mark tasks as completed.
- Delete tasks you no longer need.
- Set task priorities.
- Receive local notifications for upcoming tasks.

## Screenshots

<img src="1.png" alt="Light Theme homepage" width="400">
<img src="2.png" alt="Dark Theme homepage" width="400">
<img src="3.png" alt="Add Task Page" width="400">

## Getting Started

Follow these instructions to get the project up and running on your local machine.

### Prerequisites

- Flutter SDK
- Android/iOS Emulator or Physical Device

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/todo-app-flutter.git
   ```

2. Navigate to the project directory:

   ```bash
   cd todo
   ```

3. Install the dependencies:

   ```bash
   flutter pub get
   ```

4. Start the Iphone Simulator

   ```bash
   open -a Simulator
   ```


5. Run the app:

   ```bash
   flutter devices
   flutter run -d <device_id>
   ```

6. Run in real device:
   for debug
   ```bash
   open ios/Runner.xcworkspace
   flutter devices
   flutter run -d <device-id>
   ```

   for real build
   ```bash
   open ios/Runner.xcworkspace
   flutter build ios
   ```
   In xcode, set the runner to debug(won't work if disconnect) or release(will work even disconnect)

