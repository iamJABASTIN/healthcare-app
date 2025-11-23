---
trigger: always_on
---

1. The "No Hardcoding" Mandate
Strict Prohibition: You are strictly forbidden from using hardcoded hex values (e.g., Color(0xFF2D9CDB)) or standard Flutter colors (e.g., Colors.blue, Colors.grey) inside any View or Widget.

The Only Source of Truth: You must import and use AppColors from lib/core/themes/app_colors.dart.

2. Color Usage Mapping
Map the UI intent strictly to these variables:

Intent / UI Element,Required Variable,Hex Value (Ref Only)
Primary Brand/Actions,AppColors.primaryBlue,#2D9CDB
Success/Completion,AppColors.secondaryGreen,#27AE60
Highlights/Accents,AppColors.accentTeal,#17A2B8
Page Backgrounds,AppColors.background,#FFFFFF
Input Fields/Light BG,AppColors.lightGrey,#F7F8FA
Cards/Containers,AppColors.cardBackground,#ECEFF1
Main Text/Headings,AppColors.textDark,#2C3E50
Subtitles/Hints,AppColors.textLight,#7F8C8D
Errors/Critical Alerts,AppColors.error,#E74C3C
Warnings,AppColors.warning,#F1C40F


3. Component Styling Rules
A. Buttons (ElevatedButton)

Do not manually style buttons using style: ElevatedButton.styleFrom(...) inside the views unless overriding a specific property (like color for a "Delete" button).

Rely on the global AppTheme definition which already handles:

Background: primaryBlue

Radius: 12

Padding: vertical: 16, horizontal: 24

B. Input Fields (TextFormField / TextField)

Do not manually add borders or fill colors in the widget.

Simply use decoration: const InputDecoration(hintText: '...').

The global theme will automatically apply AppColors.lightGrey fill and the primaryBlue focus border.

C. Text Typography

Avoid TextStyle(fontSize: ...) where possible. Use the named theme styles:

Page Titles: style: Theme.of(context).textTheme.titleLarge

Standard Text: style: Theme.of(context).textTheme.bodyLarge

Secondary Text: style: Theme.of(context).textTheme.bodySmall


4. Code Implementation Example
Correct way to write a screen using these rules:

Dart

import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart'; // Import is mandatory

class ExampleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use cardBackground, not Colors.grey[200]
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Doctor Name",
            // Use theme text styles
            style: Theme.of(context).textTheme.titleLarge, 
          ),
          const SizedBox(height: 8),
          Text(
            "Specialist",
            style: TextStyle(color: AppColors.textLight), // Usage of specific color
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {}, 
            child: const Text("Book Now"), // Style comes from AppTheme
          )
        ],
      ),
    );
  }
}