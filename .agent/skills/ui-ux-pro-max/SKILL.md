---
name: UI/UX Pro Max
description: UI/UX design intelligence for NetLyra. 67 styles, 96 color palettes, 57 font pairings, 99 UX guidelines, and 25 chart types across 13 technology stacks.
---

- **Design System Generation (REQUIRED)**: Always start UI/UX work with `--design-system` search.
  ```bash
  python3 .shared/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system -p "NetLyra"
  ```
- **Context Preservation**: Use `--persist` to save the design system to `design-system/MASTER.md`.
- **Detailed Search**: Use `.shared/ui-ux-pro-max/scripts/search.py` with `--domain` for specific assets.
- **Stack Support**: Use `--stack html-tailwind` (or project stack) for implementation-specific guidelines.
- **Checklist**: Always verify output against the pre-delivery checklist.
