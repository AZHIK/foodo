/// ── pos/ ───────────────────────────────────────────────────────────
///
/// Feature: Point-of-sale — cart, checkout, payment, receipt,
/// offline sale queue.
///
/// Populated in Stage 3 (POS core UI + local tables).
///
/// ## Three-layout responsive pattern (start here when doing other screens)
///
/// `pos_screen.dart` is the reference implementation of the
/// one-screen/three-layouts split:
///
///     screens/
///       pos_screen.dart              state + breakpoint dispatch only
///       pos/
///         pos_mobile_layout.dart     <600px
///         pos_tablet_layout.dart     600-899px
///         pos_desktop_layout.dart    >=900px
///     widgets/
///       pos_layout_model.dart        data + callbacks handed to a layout
///       pos_catalog_view.dart        pieces shared by all three layouts
///       pos_cart_view.dart           (density chosen by the caller)
///
/// Rules that keep the three tiers from drifting apart:
/// 1. The screen owns *all* state and business maths and exposes it as one
///    immutable model object. Layouts are pure presentation and hold only
///    view state that is meaningful for their form factor (e.g. the phone's
///    Browse/Cart tab index).
/// 2. Anything that would otherwise be copy-pasted between layouts lives in
///    `widgets/` with a density/variant parameter — never duplicated per
///    tier, or the tiers silently diverge in behaviour.
/// 3. Dispatch on `MediaQuery` width (`context.isMobile/isTablet/isDesktop`),
///    not on local constraints, so a screen's tier always agrees with the
///    tier `MainShell` used to pick its own chrome — the shell's rail/sidebar
///    eats enough width to cross a breakpoint otherwise.
/// 4. Tablet and desktop share a skeleton and differ in density; the phone
///    tier is the only structural break. Swapping the whole widget tree at
///    900px mid-resize is what made resizing unstable before.
/// 5. Grids and panels size from real available space (min tile width, a
///    proportional cart column), so each layout stays correct across its
///    whole width range instead of being tuned for one device.
const String _posReadme = '';
