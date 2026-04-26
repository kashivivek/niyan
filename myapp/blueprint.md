# Project Blueprint

## Overview

This document outlines the architecture, features, and design of the property management application. The application is built with Flutter and Firebase, and it allows users to manage their properties, units, tenants, and financial transactions.

## Style, Design, and Features

### Authentication

*   **Firebase Authentication:** The application uses Firebase Authentication for user management. Users can register and log in with their email and password.
*   **Authentication Flow:** The application has a clear authentication flow, with separate screens for login and registration. The user is redirected to the appropriate screen based on their authentication state.
*   **Error Handling:** The authentication process includes robust error handling to provide clear feedback to the user in case of login or registration failures.

### Data Management

*   **Firestore Database:** The application uses Firestore as its primary database to store all data related to properties, units, tenants, and transactions.
*   **Data Models:** The application has a well-defined data model, with separate classes for each data entity (e.g., `PropertyModel`, `UnitModel`, `TenantModel`, `TransactionModel`).
*   **Database Service:** A dedicated `DatabaseService` class handles all interactions with the Firestore database, providing a clear and reusable API for data manipulation.

### User Interface

*   **Material Design:** The application follows the Material Design guidelines to provide a modern and intuitive user experience.
*   **Responsive Layout:** The UI is designed to be responsive and adapt to different screen sizes, ensuring a consistent experience across devices.
*   **Clear Navigation:** The application has a clear navigation structure, with a `BottomNavigationBar` to switch between the main screens.

### Features

*   **Property Management:** Users can add, edit, and view their properties. Each property can have multiple units.
*   **Unit Management:** Users can add, edit, and view units within a property. Each unit can be assigned a tenant.
*   **Tenant Management:** Users can add, edit, and view tenants. Each tenant is associated with a specific unit.
*   **Transaction Management:** Users can add and view financial transactions related to each unit, such as rent payments and expenses.

## Current Task: Initial Setup and Refactoring

### Plan

1.  **Resolve all analyzer warnings:** This includes fixing `library_private_types_in_public_api`, `use_build_context_synchronously`, `avoid_print`, and `prefer_const_declarations` warnings.
2.  **Improve code quality:** This includes refactoring the code to improve its structure, readability, and maintainability.
3.  **Add a `blueprint.md` file:** This file will serve as a single source of truth for the project's architecture, features, and design.

### Steps

*   [x] Fix `library_private_types_in_public_api` warnings in `add_property_screen.dart`, `add_transaction_screen.dart`, and `auth_screen.dart`.
*   [x] Fix `use_build_context_synchronously` warnings in `add_property_screen.dart`, `edit_property_screen.dart`, `login_screen.dart`, and `register_screen.dart`.
*   [x] Fix `avoid_print` warnings in `auth_service.dart` and `tool/setup_test_data.dart`.
*   [x] Fix `prefer_const_declarations` warnings in `tool/setup_test_data.dart`.
*   [x] Create `blueprint.md` file.
