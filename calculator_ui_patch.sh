#!/usr/bin/env bash
set -euo pipefail

# UI-only patch prompt.
# This script prints the patch request; it does not modify application code.

cat <<'PATCH_PROMPT'
PATCH REQUEST — MODIFY EXISTING CODE ONLY
DO NOT REBUILD OR REDESIGN THE CALCULATOR

You are modifying an EXISTING working calculator.

Apply ONLY these two UI corrections:
1. Fix the three top Mode Switch buttons.
2. Fix the existing "বিশেষ সতর্কতা!!" warning UI.

DO NOT:
- rewrite the calculator
- refactor unrelated code
- change calculation logic or formulas
- change state management
- change existing inputs or outputs
- change existing functionality
- remove features
- rename variables, functions, IDs, routes, or components unless absolutely required
- change unrelated styling

First inspect the existing implementation and identify the components/classes responsible for the Mode Switch and warning section. Modify only those parts.

============================================================
PATCH 01 — TOP MODE SWITCH
============================================================

Exactly three buttons:
1. Normal Mode
2. GroupLine Mode
3. Metric Mode

Desktop/tablet:
- one horizontal row
- three completely independent buttons
- NOT a connected segmented control
- equal widths
- equal heights
- 16px consistent horizontal gap
- no overlap, merged borders, negative margins, or inconsistent spacing
- align the entire row exactly with the main calculator content width

Use CSS Grid:

.mode-switch {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  width: 100%;
}

.mode-button {
  width: 100%;
  min-height: 46px;
  border-radius: 8px;
}

Do not size buttons from text content. GroupLine Mode must NOT become wider because its label is longer.

Visual target:

[ Normal Mode ]    [ GroupLine Mode ]    [ Metric Mode ]

NOT:

[ Normal Mode | GroupLine Mode | Metric Mode ]

Active state:
- Normal Mode remains active when the application state says so
- dark navy background
- white text
- same width/height/padding/position as inactive buttons

Inactive state:
- warm off-white/light cream background
- subtle light border
- muted dark-gray text

Do not change mode-switch functionality.

============================================================
PATCH 02 — "বিশেষ সতর্কতা!!" WARNING SECTION
============================================================

Find the existing "বিশেষ সতর্কতা!!" section.

Keep ALL existing warning text and functionality. Modify ONLY its visual styling.

Warning container:
- full available content width
- soft light-red/pink background
- thin red/pink border
- rounded corners
- comfortable internal padding

Use:
background: #FFF1F2;
border: 1px solid #F3A3AE;
border-radius: 12px;

Warning icon:
- proper UI warning icon, NOT an emoji
- circular
- deep red background
- white exclamation mark
- approximately 40–44px
- vertically centered with heading
- use the project's existing icon library if one exists
- do not add a new package unnecessarily

Warning header:
- icon and "বিশেষ সতর্কতা!!" on the SAME horizontal row
- heading is dark/deep red
- bold or semibold
- clearly visible
- Bengali
- vertically centered with icon

Existing warning description/content remains unchanged and should appear below the header if it already does.

Do NOT rewrite, remove, or add unnecessary warning text.

============================================================
RESPONSIVE BEHAVIOR
============================================================

Desktop/tablet:
- three Mode Switch buttons remain in one horizontal row

Mobile:
- adapt only if necessary
- no overlap
- no accidental adjacent clicks
- no merged buttons
- preserve clear spacing and equal visual treatment
- do not unnecessarily change existing mobile layout

============================================================
STRICT CHANGE BOUNDARY
============================================================

ONLY modify:
1. Mode Switch UI
2. "বিশেষ সতর্কতা!!" UI

Everything else remains untouched.

============================================================
FINAL VERIFICATION
============================================================

Verify:
[ ] Exactly 3 Mode buttons exist
[ ] Normal Mode exists
[ ] GroupLine Mode exists
[ ] Metric Mode exists
[ ] Equal button widths
[ ] Equal button heights
[ ] 16px consistent gaps
[ ] Buttons do not touch
[ ] Independent clickable elements
[ ] NOT a connected segmented control
[ ] Mode Switch aligns with calculator content width
[ ] Active state does not change dimensions
[ ] Existing mode-switch functionality works
[ ] Warning section still exists
[ ] Existing warning text is preserved
[ ] Light-red/pink warning background
[ ] Red/pink warning border
[ ] Red circular warning icon
[ ] White ! inside icon
[ ] Dark-red warning heading
[ ] Icon and heading horizontally aligned
[ ] No unrelated UI changed
[ ] No calculation logic changed
[ ] No formulas changed
[ ] No existing feature removed

AFTER IMPLEMENTATION:
Show exactly which files/components were modified and briefly explain only the changes made by this patch.

Do not provide a full rewrite of the application.
PATCH_PROMPT
