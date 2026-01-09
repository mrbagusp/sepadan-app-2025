# Sepadan MVP - Blueprint

## Overview

Sepadan is a Christian faith-based matchmaking application designed for mobile platforms using Flutter and Firebase. This document outlines the project's architecture, features, and implementation plan, serving as a single source of truth for the development process.

## Implemented Features (v1)

### Core & Foundation

- **Firebase Integration**: Core Firebase services are set up.
- **Authentication**: User authentication with Email/Password and Google Sign-In is functional.
- **Navigation**: Routing is managed by `go_router`, including protected routes and redirects.
- **Theming**: A basic theme provider is in place for light/dark mode.
- **State Management**: `provider` is used for state management, with `ChangeNotifier` as the primary pattern.

### STEP 1: Profile Flow

- **Profile Model**: `UserProfile` and `UserPreferences` data models are defined in accordance with the specifications.
- **Profile Screen (UI/UX)**: A comprehensive screen for creating and editing user profiles has been implemented.
  - Modern UI with `Card` and `ListView` for better visual structure.
  - An interactive 6-slot photo grid for managing profile pictures (add/remove).
  - Form fields for all required data points (`name`, `age`, `gender`, `aboutMe`, `faithAnswer`).
  - A dedicated section for updating the user's geolocation.
- **State & Logic**: All profile-related business logic is encapsulated in `ProfileNotifier`.
  - Handles state for loading, errors, and user data.
  - Manages image picking from the gallery.
  - Manages image uploading to Firebase Storage.
  - Handles location updates using the `geolocator` package.
- **CRITICAL: Profile Completion Enforcement**: The application now enforces profile completion.
  - A `isProfileComplete` getter has been added to the `UserProfile` model.
  - `go_router` contains a redirect rule that checks if the user's profile is complete after login.
  - If the profile is incomplete, the user is **forcefully redirected** to the profile screen and **blocked** from accessing other parts of the app (e.g., Match, Chat).

---

## Current Plan: STEP 2 - Match (Swipe) System

This section outlines the plan for the next development phase.

### 1. Match Screen UI

- **Card-based Swiping**: Implement a central UI element, likely using a package like `swipe_cards`, to display potential matches as dismissible cards.
- **User Information**: Each card will display the other user's primary photo, name, age, and a snippet of their "About Me."
- **Action Buttons**: Include clear UI buttons for "Like" and "Pass" as an alternative to swiping.

### 2. Backend & Logic (`MatchService`)

- **Complex Firestore Query**: Implement the core logic to fetch potential matches. This query must:
  - Exclude the current user's own profile.
  - Exclude users that have already been liked, passed, or matched with.
  - Filter results based on the current user's preferences (`ageMin`, `ageMax`, `preferredGender`).
- **Distance Filtering (Haversine)**: After fetching profiles from Firestore, perform a client-side filter to exclude users who are outside the `maxDistanceKm` preference. This requires implementing the Haversine formula.
- **Swipe Actions**: 
  - **Like**: Record the "like" action in a sub-collection (e.g., `users/{uid}/likes/{likedUid}`).
  - **Pass**: Record the "pass" action to prevent a user from being shown again (`users/{uid}/passes/{passedUid}`).
- **Mutual Like Detection**: After a "like" action, check if the other user has already liked the current user. If so, trigger the `createMatch` function.
- **Create Match**: 
  - Create a new document in the `/matches` collection.
  - The document will contain `users: [uid1, uid2]` and a `createdAt` timestamp.

### 3. State Management (`MatchNotifier`)

- Create a `MatchNotifier` to manage the state of the match screen.
- It will hold the list of potential profiles to be displayed.
- It will call methods from `MatchService` to fetch profiles and handle swipe actions.
- It will manage loading and empty/error states (e.g., "No more profiles found").

