# Architecture Rules

## Presentation Layer File Boundaries

- Page files must stay as route-level composition roots. A page file should own navigation, provider wiring, and high-level layout only.
- Do not keep many private child views in one page file. When a page grows beyond a small composition surface, split child views into feature-local folders.
- Prefer feature-slice structure before type-only structure. A top-level `widgets/` folder must not become a bucket for every child view in the feature.
- For `lib/presentations/<feature>/pages/*_page.dart`, move reusable or section-level UI into one of these folders:
  - `lib/presentations/<feature>/widgets/` for shared UI pieces used by multiple pages or sections.
  - `lib/presentations/<feature>/sections/` for large page sections that are specific to one feature page.
  - `lib/presentations/<feature>/dialogs/` for feature-specific dialog content and dialog launch helpers.
- Dialogs must be classified before implementation:
  - Global dialogs that can be reused across features belong under `lib/core/dialog/` or a shared UI package/module, not under a feature folder.
  - Feature-specific dialogs belong under `lib/presentations/<feature>/dialogs/`.
  - A page file may open a dialog, but should not define large dialog UI inline.
  - Dialog services/controllers should live outside widgets when they coordinate app-level decisions, navigation, or cross-feature state.
- Keep private widget classes inside a page file only when they are trivial and tightly coupled to that page. As a practical limit, page-local child widgets should stay small and few; large forms, setting groups, tables, charts, or hardware-control panels must be extracted.
- View files should not own domain or data orchestration. They may call ViewModel/usecase methods, but business rules and persistence decisions belong in ViewModels, usecases, repositories, or services.
- If a feature has multiple independent flows, each flow should get its own page/section/widget file rather than being appended to an existing page file.

## Navigation Rules

- Use the app-level router for page navigation.
- Do not create feature navigation with `Navigator.of(context).push(MaterialPageRoute(...))` unless there is a documented reason that the route must stay outside the app router.
- Presentation code should navigate through `GoRouter` routes exposed by `appRouterProvider` or a route helper.
- Pages that require parameters must define typed route argument classes instead of passing loose maps or relying on widget-local state.
- Route guards must cover nested paths, not only top-level paths.
- Dialog dismissal may use `Navigator.pop` for the dialog context, but page-to-page navigation should remain router-managed.
- Router-managed navigation keeps route ownership, shell wrappers, transitions, deep links, and guard behavior consistent.

## Localization Rules

- All user-visible UI text must be localized when the feature is implemented.
- Do not ship hardcoded Chinese, Japanese, or English UI strings in pages, sections, widgets, dialogs, route fallback pages, empty states, error banners, or button labels.
- Add keys to all supported ARB files at the same time. The current supported locales are Chinese, English, and Japanese.
- Run Flutter l10n generation after ARB changes.
- Brand names and external protocol identifiers may remain literal only when they are not translated in product copy.
- Print labels shown to users or printed for customers/operators should also use localization keys unless they are external fixed codes.
- If a string needs placeholders, define placeholder metadata in the ARB files when adding the key.

## Settings Feature Structure

- `settings_page.dart` must remain the settings route shell only: section selection, top-level layout, and dispatch to section widgets.
- Settings child views such as business info, system settings, machine info, printer settings, cash machine settings, dialogs, and detail pages must be split out of `settings_page.dart`.
- Suggested structure:
  - `lib/presentations/settings/pages/` for the settings route shell and rare settings-level pages that are not owned by a single section.
  - `lib/presentations/settings/sections/<section>/` for major settings tabs or panels and their section-local widgets.
  - `lib/presentations/settings/sections/<section>/pages/` for detail pages owned by one section.
  - `lib/presentations/settings/widgets/` only for reusable settings UI shared by multiple sections, such as cells, cards, toggles, rows, and field editors.
  - `lib/presentations/settings/dialogs/` for settings-only modal UI.
- Settings must reuse global dialogs from `lib/core/dialog/` when the dialog is generic, such as confirmation, alert, loading, or destructive-action prompts.
- New settings functionality must not add another large private widget block to `settings_page.dart`; create a section/widget/dialog file first.
- Section-specific widgets must live beside their section, not in `settings/widgets/`. For example, printer tiles belong under `settings/sections/machine/widgets/`, not under the shared settings widgets folder.
- Section-owned pages must live beside their section. For example, shop info detail belongs under `settings/sections/business_info/pages/`, not under top-level `settings/pages/`.
- Business operations that are only launched from settings but have their own API, usecases, state, and pages should be treated as standalone presentation features. For example, cash register closure belongs under `lib/presentations/cash_register_closure/`, while settings should only contain the navigation cell that opens it.

## Riverpod ViewModel Usage

- Use Riverpod providers as dependency wiring and lifecycle boundaries.
- Prefer Riverpod naming that describes behavior, such as `Controller`, `State`, and `Providers`, instead of a generic `ViewModel` suffix.
- Controllers should expose immutable UI state and intent methods. They should not become a service locator facade for unrelated flows.
- Prefer feature-specific controllers for independent flows. Do not force unrelated settings subflows into one monolithic settings controller.
- For one-shot operations with no long-lived UI state, call an application usecase from a page or small controller provider instead of adding methods to a broad page ViewModel.
- Keep global mutable app state providers minimal and explicit. If a controller mirrors a global provider, document why the duplication exists and guard against update loops.
- Provider files should wire dependencies and expose derived state. Controller files should contain user intents and state transitions. State files should contain immutable state models only.

## Checkout Coordination

- Menu/POS, payment, and printing are independent features. They must not call each other's controllers or ViewModels directly.
- Cross-feature checkout sequencing belongs to `lib/application/checkout/` and is owned by `CheckoutCoordinator`.
- The coordinator may transfer immutable outputs between features and enforce macro ordering: menu draft -> order submission -> payment -> local completion -> print request.
- Menu/POS owns cart editing and only hands an immutable `CheckoutDraft` to the coordinator. It must not construct payment sessions or print jobs.
- Payment owns terminal/network transaction state and only reports a terminal `PaymentResult` to the coordinator. It must not open print dialogs or clear menu state.
- Printing owns print execution, retry, skip, and printer-specific progress. It accepts an application-level `PrintJobRequest` and must not mutate payment or menu state.
- Presentation pages may observe checkout state for navigation or display, but cross-feature persistence and sequencing decisions must remain in the coordinator.
- Checkout route models belong under `lib/application/checkout/models/`; presentation route aliases may be kept temporarily during migration.
- Printing input models belong under `lib/application/printing/models/`, not inside payment or print-dialog widgets.
- Transaction-unknown states must never advance to printing. Only a confirmed successful payment may produce a print request.

## Settings Controller Implementation Roadmap

- Treat the top-level settings controller as a shell controller, not as the owner of every settings subflow.
- Rename or model the top-level settings state/controller as `SettingsShellState` and `SettingsShellController` when the next larger settings refactor is made.
- The settings shell controller may own:
  - the selected settings section,
  - settings initialization,
  - shared settings snapshot refresh,
  - simple shared error state for shell-level failures.
- Section controllers should be introduced by business boundary and lifecycle, not by page count alone.
- Add a section controller when a section has any of these:
  - independent loading, saving, or error state,
  - complex form draft state or validation,
  - device interaction or polling,
  - calls to independent APIs or usecases,
  - state that should survive section-local rebuilds but not become global app state,
  - logic that should be unit-tested without the full settings shell.
- Simple display-only sections should stay as section widgets and should not get controllers prematurely.
- Candidate split order:
  - First split machine settings into `MachineSettingsState`, `MachineSettingsController`, and `machine_settings_providers.dart`, because it owns cash machine, printer, device checks, and hardware-related state.
  - Keep business info as UI-only until it gains editable form state or independent API calls.
  - Keep system settings in the shell controller while it remains simple; split it only when it gains independent validation or save lifecycle.
  - Keep cash register closure as an independent presentation feature, not as a settings section controller.
- Target shape:
  - `settings/state/settings_shell_state.dart`
  - `settings/controllers/settings_shell_controller.dart`
  - `settings/providers/settings_providers.dart`
  - `settings/sections/machine/state/machine_settings_state.dart`
  - `settings/sections/machine/controllers/machine_settings_controller.dart`
  - `settings/sections/machine/providers/machine_settings_providers.dart`

## UI Foundation Implementation Roadmap

- Build a lightweight UI foundation before continuing to add many feature pages.
- The goal is consistency and speed, not a large generic component library.
- Global UI primitives belong under `lib/core/ui/`.
- Business-specific widgets must stay in their feature folders.
- Do not put feature semantics into global UI components.

### UI Tokens

- Define stable design tokens first:
  - `lib/core/ui/theme/app_spacing.dart`
  - `lib/core/ui/theme/app_radius.dart`
  - `lib/core/ui/theme/app_durations.dart`
  - `lib/core/ui/app_colors.dart` or a ThemeExtension when color roles grow.
- Page and feature widgets should avoid raw spacing, radius, duration, and color literals when a token exists.
- Prefer `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` inside reusable UI components.

### Core UI Components

- Start with a small set of reusable UI shells:
  - `lib/core/ui/components/app_card.dart`
  - `lib/core/ui/components/app_section_header.dart`
  - `lib/core/ui/components/app_list_cell.dart`
  - `lib/core/ui/components/app_action_button.dart`
  - `lib/core/ui/components/app_empty_state.dart`
  - `lib/core/ui/components/app_error_banner.dart`
  - `lib/core/ui/components/app_confirm_dialog.dart`
  - `lib/core/ui/components/app_loading_overlay.dart`
- These components should be low-business-meaning building blocks.
- They may define layout, typography, color roles, loading affordances, and common interaction states.
- They must not call feature usecases, repositories, or feature controllers.

### Feature Widgets

- Keep business widgets in feature folders, even if they are visually reusable.
- Examples that must stay feature-local:
  - cash register closure payment pie,
  - printer settings tile,
  - cash machine settings tile,
  - order cart item,
  - payment status hero.
- If two features need the same visual shell, extract only the shell into `core/ui/components`, not the business widget.

### Adoption Order

- Use Settings as the first adoption target.
- Replace settings-local shells with core UI components in this order:
  - `settings_section_card.dart` -> `AppCard` and `AppSectionHeader`.
  - `settings_navigation_row.dart` -> `AppListCell`.
  - `settings_info_row.dart` -> `AppListCell` or a small shared `AppInfoRow` if needed.
  - repeated error banners -> `AppErrorBanner`.
  - repeated confirmation dialogs -> `AppConfirmDialog` or `core/dialog` helpers.
- After Settings is stable, gradually apply the same primitives to payment, POS, and cash register closure pages.

### Rules

- New pages should use core UI primitives before creating page-local versions of cards, list cells, headers, empty states, and error banners.
- Creating a new global UI component requires at least two realistic call sites or a clear design-system primitive role.
- Do not block business delivery waiting for a complete design system; add primitives incrementally when repeated UI patterns appear.
