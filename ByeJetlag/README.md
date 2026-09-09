# Bye JetLag – iOS App (SwiftUI)

## Project Structure

```
ByeJetLag/
├── App/
│   ├── ByeJetLagApp.swift       ← @main entry point + onboarding gate
│   └── AppTheme.swift           ← Colors, design tokens
├── Models/
│   ├── Models.swift             ← Trip, FlightLeg, TimelineBlock, UserProfile, AppState, BlockType
│   └── Airport.swift            ← Airport model + AirportStore (loads global_airports.json)
├── Views/
│   ├── Components/
│   │   └── Components.swift     ← PrimaryButton, CardView, TimelineBlockRow, BlockDetailModal,
│   │                               RescheduleSheet, StepProgressBar, EmptyStateView, AirportRow, etc.
│   ├── Onboarding/
│   │   ├── OnboardingView.swift ← Tutorial/Guide (first launch + modal from info banner)
│   │   └── SplashView.swift     ← Plain splash screen with logo + tagline
│   ├── Home/
│   │   └── HomeView.swift       ← Travel Plans list, FAB, trip cards, profile/guide access
│   ├── AddFlight/
│   │   ├── AddFlightView.swift  ← Multi-step flow: Route → Itinerary → Personalization → Loading
│   │   └── AirportPickerView.swift ← Searchable airport picker (uses global_airports.json)
│   ├── Schedule/
│   │   └── ScheduleView.swift   ← Vertical timeline, block tap → detail modal, reschedule
│   └── Profile/
│       └── ProfileView.swift    ← Profile settings, edit profile, toggles, legal links
└── Resources/
    └── global_airports.json    ← 9061 airports database (copy your file here)
```

## Setup in Xcode

1. Create a new Xcode project → iOS → App → **SwiftUI** lifecycle
2. Name it **ByeJetLag**, Bundle ID: `com.yourname.byejetlag`
3. Copy all `.swift` files from this project into matching folders
4. Add `global_airports.json` to the project (drag into Resources group, check "Add to target")
5. Add `logo.png` to `Assets.xcassets` (name it exactly `logo`)
6. Set deployment target to **iOS 17+** (uses `navigationDestination(item:)`)

## Key Design Decisions

- **No UIKit** – pure SwiftUI throughout
- **No TabView** – NavigationStack only; Profile via sheet from top-right button, Guide via info banner
- **Onboarding gate** – `@AppStorage("hasSeenOnboarding")` controls first-launch flow
- **Airport search** – `AirportStore.shared` loads JSON once, filters reactively
- **Block generation** – `AppState.generateBlocks(for:)` creates the full jet lag schedule
- **Colors**: Primary `#FFB547`, Accent `#4A90E2`, Background `#F9F9F9`
- **Dark mode** – uses semantic colors (`Color(.systemBackground)`, etc.) throughout

## iOS 17 APIs Used

- `navigationDestination(item:)` for trip → schedule navigation
- `ContentUnavailableView.search(text:)` for empty search state
- `.searchable(placement: .navigationBarDrawer)` for airport search

## Notes

- `SplashView.swift` is the LaunchScreen replacement — wire it in `Assets.xcassets` → LaunchScreen
  or use it as the initial view briefly before the onboarding/home gate
- The `EditProfileView` shows SwiftUI binding annotations (matching the design's code annotations)
- Reschedule is limited to 2 times per trip (UI shows warning; enforcement can be added to AppState)
