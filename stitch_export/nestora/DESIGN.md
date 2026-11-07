---
name: Nestora
colors:
  surface: '#f5fbf2'
  surface-dim: '#d6dcd3'
  surface-bright: '#f5fbf2'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff5ec'
  surface-container: '#eaf0e6'
  surface-container-high: '#e4eae1'
  surface-container-highest: '#dee4db'
  on-surface: '#171d18'
  on-surface-variant: '#434843'
  inverse-surface: '#2c322c'
  inverse-on-surface: '#edf2e9'
  outline: '#737872'
  outline-variant: '#c3c8c1'
  surface-tint: '#506354'
  primary: '#1e3023'
  on-primary: '#ffffff'
  primary-container: '#344638'
  on-primary-container: '#9fb3a1'
  inverse-primary: '#b7ccb9'
  secondary: '#586156'
  on-secondary: '#ffffff'
  secondary-container: '#dce5d7'
  on-secondary-container: '#5e675c'
  tertiary: '#3b2811'
  on-tertiary: '#ffffff'
  tertiary-container: '#533e25'
  on-tertiary-container: '#c7a98a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d3e8d5'
  primary-fixed-dim: '#b7ccb9'
  on-primary-fixed: '#0e1f13'
  on-primary-fixed-variant: '#394b3d'
  secondary-fixed: '#dce5d7'
  secondary-fixed-dim: '#c0c9bc'
  on-secondary-fixed: '#161e15'
  on-secondary-fixed-variant: '#41493f'
  tertiary-fixed: '#feddbb'
  tertiary-fixed-dim: '#e1c1a0'
  on-tertiary-fixed: '#291804'
  on-tertiary-fixed-variant: '#58432a'
  background: '#f5fbf2'
  on-background: '#171d18'
  surface-variant: '#dee4db'
typography:
  headline-xl:
    fontFamily: Nunito Sans
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Nunito Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Nunito Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Nunito Sans
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Nunito Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Nunito Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Nunito Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Nunito Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system embodies a serene, natural, and premium approach to smart living. It is tailored for homeowners and smart living enthusiasts seeking seamless control over their environment without cognitive clutter or aggressive industrial aesthetics. 

The emotional signature is calming, intuitive, and reassuring. Moving away from the conventional cold, neon-tinged "tech" dashboards, the design employs a grounded organic minimalism—balancing clinical clarity with warm domestic tranquility. Crisp pure-white foundations are paired with botanical sage tones and soft earth accents to convey comfort, environmental mindfulness, and effortless luxury.

All interface copy and interactions are localized strictly in natural, refined Turkish, focusing on human-centric smart living terminology (e.g., "Yaşam Alanları", "Akıllı Senaryolar", "İklimlendirme").

## Colors

The palette is engineered around clean architectural daylight and organic accents:

- **Primary (`#344638`)**: Deep Forest Pine. Used for high-emphasis interactive states, primary actions, and focused brand touchpoints.
- **Secondary (`#DCE5D7`)**: Light Sage Green. Applied to active card containers, subtle highlight chips, toggled state fills, and calm feedback signals.
- **Tertiary (`#E9C9A8`)**: Warm Amber Clay. Reserved for energetic accents, heating/ambient light states, warm notifications, and subtle decorative contrasts.
- **Neutral Primary (`#292F29`)**: Deep Moss Charcoal. Primary typography, primary icons, and structural focus.
- **Neutral Secondary (`#777D73`)**: Soft Herb Gray. Secondary typography, inactive states, unit measures, and metadata.
- **Surface Canvas (`#FFFFFF`)**: Pure White base for main view backgrounds and floating interactive cards.
- **Secondary Surface (`#F5F7F4`)**: Soft Pale Mist. Used for grouped container backdrops, segmented controls, and secondary module foundations.
- **Borders (`#E8ECE6`)**: Soft Mineral Border. Micro-lines framing cards, dividers, and input boundaries to provide structure without heavy contrast.

## Typography

The type system is powered exclusively by Nunito Sans. The font's geometric architecture paired with soft, humanist curves balances technological legibility with friendly organic poise.

- Large values such as climate degrees (°C) and power meters use `headline-xl` with condensed tracking for immediate visual pickup.
- Section headers rely on `headline-md` in semi-bold to preserve an airy, domestic feeling without overpowering content.
- Turkish character sets (ç, ğ, ı, İ, ö, ş, ü) are fully supported with balanced vertical metrics, ensuring accents remain crisp against tight row heights.

## Layout & Spacing

The layout is built specifically for mobile viewports (optimized for 390x844pt screen dimensions) using a 4-column fluid mobile grid anchored by a 20px (`1.25rem`) safe outer margin.

- **Vertical Rhythm**: Built upon a 4pt/8pt sub-grid. Component padding scales predictably from `space-xs` (4px) to `space-xl` (32px).
- **Gutter Distribution**: Grid columns maintain a 16px (`1rem`) gutter, optimal for dual-column smart device tiles (e.g., Aydınlatma, Termostat, Güvenlik).
- **Safe Bounds**: Floating bottom navigation bars and fixed control widgets preserve a 24px bottom buffer to clear system gestures.

## Elevation & Depth

Visual hierarchy leverages pure white surfaces, soft borders, and delicate ambient shadows rather than stark contrast or dark skeuomorphism:

- **Base Layer (Flat)**: Pure `#FFFFFF` canvas, structured with `#F5F7F4` secondary bounding containers for room groupings.
- **Card Surfaces**: Pure `#FFFFFF` tiles bounded by an ultra-thin 1px `#E8ECE6` outline.
- **Ambient Soft Shadow**: Floating panels and active cards use an ambient tinted elevation: `box-shadow: 0px 8px 24px -4px rgba(41, 47, 41, 0.04), 0px 2px 6px -1px rgba(41, 47, 41, 0.02)`. This replaces muddy gray shadows with a faint olive-moss undertone.
- **Active State Elevation**: Toggled-on cards gently lift with `box-shadow: 0px 12px 28px -6px rgba(52, 70, 56, 0.08)` and transition to a soft `#DCE5D7` border or secondary fill.

## Shapes

The design system implements a soft, contemporary geometry designed to feel approachable and tactile:

- **Cards & Device Tiles**: 16px (`1rem`) border radius, creating a comfortable visual grouping for touch controls.
- **Outer Containers & Modals**: 24px (`1.5rem`) top radius on sheets and parent control boards.
- **Buttons, Chips & Inputs**: Fully rounded pill shapes (`9999px`) or soft 12px (`0.75rem`) rounded forms depending on hierarchy.

## Components

### Buttons
- **Primary Button**: Solid `#344638` background, `#FFFFFF` text (`label-lg`), height 52px, fully pill-rounded (9999px). Subdued touch states scale down slightly (98%) without color harshness.
- **Secondary Button**: `#F5F7F4` background, `#292F29` text, 1px `#E8ECE6` border, height 48px.
- **Ghost/Tertiary Action**: Transparent background, `#344638` text, used for dismiss actions and contextual links ("Tümünü Gör").

### Cards & Smart Tiles
- **Device Card**: Dual-column 160x150px cards. Pure `#FFFFFF` background, 1px `#E8ECE6` border, 16px corner radius. Features device icon top-left, toggle top-right, device name in `headline-sm`, and operational status in `body-sm` (`#777D73`).
- **Active Card**: Shifts background to a subtle blend with `#DCE5D7` (or keeps pure `#FFFFFF` with `#344638` highlighted icon and pill).

### Chips & Scenario Filters
- **Filter Chip**: Used for quick room filtering ("Salon", "Yatak Odası", "Mutfak"). 36px height, rounded-full, 12px horizontal padding.
  - *Inactive*: `#FFFFFF` background, 1px `#E8ECE6` border, `#777D73` text.
  - *Selected*: `#344638` background, `#FFFFFF` text, shadow ambient.

### Inputs & Sliders
- **Text & Search Input**: 48px height, `#F5F7F4` background, `#292F29` text, `#777D73` placeholder. Border transforms to 1px `#344638` on focus with no drop shadow.
- **Range Slider (Dimmer / Temperature)**: Thick 12px pill-track in `#E8ECE6`. Active fill in `#344638` (or `#E9C9A8` for heating), accompanied by a 28px circular white thumb with soft ambient elevation.

### Toggles, Checkboxes & Radios
- **Switch**: 52x30px pill container. Off-state `#E8ECE6` with white 24px knob. On-state `#344638` background with pure white thumb shifted smoothly.
- **Radio / Checkbox**: 22px rounded circles/squares with `#E8ECE6` inactive borders, filling `#344638` with white checkmark when selected.

### Smart Home Specific Components
- **Room Pill Indicator**: Mini status badges showing temperature ("22.5°C") or active bulbs ("4 Açık") using `#F5F7F4` surface with `#344638` text.
- **Sensor Stat Widget**: Stacked stat cards featuring large numerical readouts (`headline-lg`) paired with micro-labels (`label-sm`) in `#777D73`.