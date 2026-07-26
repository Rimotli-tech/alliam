# Alliam Platform UI Contract

This is a mandatory design and implementation constraint for every new UI slice.

Alliam's desktop/web and mobile experiences may share a design language without
sharing every widget or composition. Do not automatically shrink a desktop
screen into a mobile screen, and do not automatically enlarge a mobile screen
for desktop.

## Surface terminology

Use these labels when discussing and implementing a UI slice:

- **SH — Shared:** The same widget and interaction belong on every supported
  surface. Layout may adapt, but its role and composition remain materially the
  same.
- **VP — Variant Pair:** The same product capability belongs on both surfaces,
  but desktop/web and mobile require separately composed widgets.
- **DW — Desktop/Web only:** Pointer/keyboard-first UI intended only for wide
  web or desktop layouts.
- **MN — Mobile Native only:** Touch-first UI intended only for Android and
  iOS, often involving native device behavior.
- **CW — Compact Web:** A mobile or narrow browser. It usually follows the
  mobile composition, but must not assume access to native-only capabilities.
- **RS — Responsive Shared:** One shared widget whose internal arrangement
  changes only because of available width.

## Default surface meanings

- **Desktop/Web** means Flutter Web in a wide browser or a future desktop
  build, generally pointer- and keyboard-first.
- **Mobile** means native Android and iOS, touch-first.
- **Compact Web** is treated as a separate capability context whenever native
  behavior, browser limitations, or install state matters.

## Required decision before implementation

Before building a requested UI slice, explicitly state:

1. **Surface ownership:** SH, VP, DW, MN, CW, or RS.
2. **Shared contract:** data, state, actions, tokens, and accessibility behavior
   that must remain consistent.
3. **Desktop composition:** widgets or interactions used only on desktop/web.
4. **Mobile composition:** widgets or interactions used only on mobile.
5. **Compact-web fallback:** required whenever the mobile design depends on a
   native capability.

No slice should be implemented until this classification is made.

## Implementation constraints

- Share domain logic, state models, repositories, audio contracts, validation,
  analytics events, and design tokens wherever possible.
- Split presentation widgets when navigation, information density, input
  method, orientation, focus behavior, or available space materially differs.
- Do not use screen width alone to infer native platform capability.
- Use platform, capability, and width checks deliberately.
- Do not place desktop-only controls in a mobile tree and merely hide them
  visually; avoid building them on that surface.
- Do not force mobile-native interaction patterns onto compact web when the
  browser cannot support them reliably.
- Preserve Alliam's approved colours, typography, shadows, icon language, and
  feedback semantics across variants.

## Slice handoff format

Every future UI-slice response should begin with a concise declaration:

> **Surface decision:** VP — shared behavior and state, separately composed
> desktop/web and mobile widgets. Compact web follows the mobile composition
> with browser-safe fallbacks.

The exact classification may differ, but the decision must always be stated.

