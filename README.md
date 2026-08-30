# Career Matrix — Frontend (Flutter)

An AI-powered career ecosystem connecting **Students, Alumni, Mentors, Companies,
and Admins** — career guidance, mentorship, skill-gap analysis, mock interviews,
opportunities, and a professional community, in one app.

This package is the **complete frontend UI**, wired end-to-end with mock/demo
data. No backend, so every screen works out of the box for demos and stakeholder
walkthroughs.

## Design system

- **Theme:** Professional Blue & White (light mode only, by design — dark mode
  is intentionally not offered as default, per project brief).
- Soft gradients (`#0E3A9E → #1957E0 → #3B82F6`), rounded 16–24px cards, subtle
  shadows, large readable type, and colored score gauges for the "signature"
  metrics (Career Health Score, Placement Readiness, Mentor Match %, etc).
- Every core feature is reachable within **2–3 taps** from the dashboard via
  the Quick Actions grid and the role-aware bottom navigation bar.
- Zero third-party packages — pure Flutter/Material (`cupertino_icons` only),
  so `flutter pub get` works offline / in restricted networks. Gauges and
  progress rings are hand-built with `CustomPainter`, no `fl_chart` dependency.

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x (Material 3). No API keys, no backend, no environment
config needed — everything is mock data in `lib/data/mock_data.dart`.

## App flow

```
Splash → Onboarding (3 slides) → Login / Register (role picker: Student,
Alumni, Mentor, Company, Admin) → Home Shell (role-aware bottom nav)
```

`lib/screens/dashboard/home_shell.dart` is the router: it swaps the bottom-nav
destinations and pages based on the signed-in role, so **one shell + five
dashboards** power the whole app instead of five separate navigation stacks.

## Screen map (20 required screens + shell)

| # | Screen | Path |
|---|--------|------|
| 1 | Splash | `screens/splash/splash_screen.dart` |
| 2 | Onboarding | `screens/onboarding/onboarding_screen.dart` |
| 3 | Login | `screens/auth/login_screen.dart` |
| 4 | Registration | `screens/auth/register_screen.dart` |
| 5 | Home Dashboard (router) | `screens/dashboard/home_shell.dart` |
| 6 | Student Dashboard | `screens/dashboard/student_dashboard.dart` |
| 7 | Alumni Dashboard | `screens/dashboard/alumni_dashboard.dart` |
| 8 | Mentor Dashboard | `screens/dashboard/mentor_dashboard.dart` |
| 9 | Company Dashboard | `screens/dashboard/company_dashboard.dart` |
| 10 | Admin Dashboard | `screens/dashboard/admin_dashboard.dart` |
| 11 | Career Recommendation (AI Career Compass) | `screens/career/career_recommendation_screen.dart` |
| 12 | Skill Gap Analysis (Skill Matrix) | `screens/skills/skill_gap_screen.dart` |
| 13 | Resume Hub | `screens/resume/resume_hub_screen.dart` |
| 14 | Job Portal | `screens/jobs/job_portal_screen.dart` |
| 15 | Internship Portal | `screens/internship/internship_portal_screen.dart` (opens Opportunity Center on the Internships tab) |
| 16 | Mock Interview Arena | `screens/interview/mock_interview_screen.dart` |
| 17 | Mentor Connect | `screens/mentor/mentor_connect_screen.dart` |
| 18 | Notifications | `screens/notifications/notifications_screen.dart` |
| 19 | User Profile | `screens/profile/profile_screen.dart` |
| 20 | Settings | `screens/settings/settings_screen.dart` |

Bonus screens built to fully cover the feature list:
- **Professional Community** — `screens/community/community_screen.dart`
  (forum posts, interview experiences, events)
- **Company Portal** — `screens/company/company_portal_screen.dart`
  (Find Candidates + Post a Job/Internship tabs)

## Unique / signature widgets

- `ScoreGauge` (`widgets/score_gauge.dart`) — circular gradient gauge used for
  Career Health Score, Placement Readiness, Mentor Match %, and interview
  averages.
- `SkillProgressBar` — linear skill bars with gap-highlighting (amber + alert
  icon when a skill is under-developed for the target role).
- `MentorCard` / `JobCard` (`widgets/listing_cards.dart`) — consistent premium
  cards for mentors, jobs, and internships with match-percentage badges.
- `AppBottomNav` — role-aware bottom navigation (max 5 destinations).

## Project structure

```
lib/
  main.dart
  theme/            # colors + ThemeData (blue & white, light only)
  models/           # plain Dart model classes (no codegen)
  data/             # mock_data.dart (demo content) + app_state.dart (role state)
  widgets/          # shared cards, gauges, nav bar, avatars, list tiles
  screens/
    splash/ onboarding/ auth/ dashboard/ career/ skills/ resume/
    jobs/ internship/ interview/ mentor/ community/ company/
    notifications/ profile/ settings/
```

## State management

Deliberately dependency-free: role/session state lives in a single
`ValueNotifier` in `data/app_state.dart`. This keeps the project runnable with
zero external packages. Swap in your preferred solution (Riverpod, Bloc,
Provider) when you wire up the real backend — the screens are already split
into small, focused widgets to make that migration straightforward.

## Next steps (not in this frontend-only pass)

- Connect Login/Register to a real auth backend.
- Replace `mock_data.dart` with live API data (career recommendations, jobs,
  mentors, notifications).
- Wire Resume upload/AI analysis and Mock Interview scoring to real AI
  services.
- Add real-time chat/booking for Mentor Connect sessions.
