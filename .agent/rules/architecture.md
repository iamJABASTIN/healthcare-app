---
trigger: always_on
---

These rules enforce strict adherence to your specific implementation of MVVM with Flutter and Firebase.

1. Architectural Pattern: Strict MVVM
You must adhere to the Model-View-ViewModel pattern. No Logic in UI. No Widgets in Logic.

M - Model (lib/data/models/): Pure data classes. Must include fromJson and toJson for Firebase interaction.

V - View (lib/views/): UI code only. Passive interface. Listens to ViewModel.

VM - ViewModel (lib/view_models/): Business logic, state management, and Firebase calls.


2. Directory & File Mandates

Do not invent new root directories. Place files strictly according to this map:

Component,Path,Naming Convention
Models,lib/data/models/,[feature]_model.dart
View Models,lib/view_models/,[feature]_view_model.dart
Screens (Pages),lib/views/screens/,[feature]_screen.dart or [feature]_view.dart
Widgets (Reusable),lib/views/widgets/,[component_name].dart
Themes/Constants,lib/core/themes/,"app_theme.dart, app_colors.dart"


Note: If a feature has multiple screens (e.g., Auth, Profile), create a sub-folder inside lib/views/screens/ (e.g., lib/views/screens/auth/).

3. Coding Standards & Workflow
A. The Model Layer

All models must be immutable (final fields).

Must include a factory constructor factory ClassName.fromMap(Map<String, dynamic> map) or fromJson.

B. The ViewModel Layer

Extend ChangeNotifier (unless using a different state manager, assume native Provider/ChangeNotifier based on standard MVVM).

Expose public getters for state variables (e.g., bool get isLoading => _isLoading;).

Handle all exceptions (try-catch) here, not in the View.

Firebase Rule: All Firebase/Firestore logic resides here. Never call FirebaseAuth or FirebaseFirestore directly inside a View.

C. The View Layer

Screens: Use Consumer or Provider of to listen to the ViewModel.

Widgets: Should be stateless whenever possible.

Navigation: Trigger navigation based on ViewModel state changes or callbacks.

4. Interaction Flow Example
When implementing a new feature (e.g., "Book Appointment"), follow this order:

Create Model: lib/data/models/appointment_model.dart

Create ViewModel: lib/view_models/appointment_view_model.dart (Handle booking logic).

Create View: lib/views/screens/booking_screen.dart (Bind UI to ViewModel).

5. Forbidden Patterns ❌
No MVC: Do not create a controllers folder. Use view_models.

No Logic in UI: Do not perform calculations or database calls inside build() methods.

No Mixed Responsibilities: Do not put Widget code inside a ViewModel file.

