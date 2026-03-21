# Token File Schema

All token files use JSON and follow these conventions:

- Token names use `/` separators (matching Figma variable naming): `"color/base/paper"`
- Color values are hex strings: `"#FFFCF0"`
- Numeric values are plain numbers (no units): `32`, `0.5`
- Font weights are strings matching iOS conventions: `"Regular"`, `"Medium"`, `"SemiBold"`, `"Bold"`, `"ExtraBold"`, `"Light"`

## colors.json

```json
{
  "$schema": "imprint-design-tokens",
  "$version": 1,
  "lastSynced": "2026-03-21T14:30:00Z",
  "collections": {
    "base": {
      "description": "Core neutral palette",
      "modes": ["light", "dark"],
      "tokens": {
        "base/paper": {
          "description": "Main background",
          "light": "#FFFCF0",
          "dark": "#100F0F"
        },
        "base/primary": {
          "description": "Primary text",
          "light": "#100F0F",
          "dark": "#FFFCF0"
        }
      }
    },
    "accent": {
      "description": "Accent color families",
      "modes": ["light", "dark"],
      "tokens": {
        "accent/blue/subtle": {
          "light": "#4385BE",
          "dark": "#4385BE"
        }
      }
    }
  }
}
```

Each collection groups related tokens. The `modes` array declares which modes exist. Each token has a value per mode. Single-mode tokens (same in light and dark) still list both modes with the same value.

The `description` field on tokens is optional but encouraged — it maps to the Figma variable description.

## typography.json

```json
{
  "$schema": "imprint-design-tokens",
  "$version": 1,
  "lastSynced": "2026-03-21T14:30:00Z",
  "families": {
    "platypi": {
      "description": "Display / heading typeface",
      "weights": ["Light", "SemiBold", "ExtraBold"]
    },
    "jetbrains-mono": {
      "description": "Monospaced body typeface",
      "weights": ["Regular", "Medium", "SemiBold", "Bold"]
    }
  },
  "tokens": {
    "heading/page-title": {
      "family": "platypi",
      "weight": "SemiBold",
      "size": 32,
      "lineHeight": null,
      "letterSpacing": null,
      "description": "Main page titles"
    },
    "body/record-name": {
      "family": "jetbrains-mono",
      "weight": "SemiBold",
      "size": 14,
      "lineHeight": null,
      "letterSpacing": null,
      "description": "Record name in list rows"
    }
  }
}
```

The `families` section declares available font families and their installed weights. The `tokens` section defines semantic type styles, each referencing a family by key.

`lineHeight` and `letterSpacing` are nullable — `null` means "use system default".

## spacing.json

```json
{
  "$schema": "imprint-design-tokens",
  "$version": 1,
  "lastSynced": "2026-03-21T14:30:00Z",
  "tokens": {
    "spacing/xs": {
      "value": 4,
      "description": "Extra small spacing"
    },
    "spacing/sm": {
      "value": 8,
      "description": "Small spacing"
    },
    "spacing/md": {
      "value": 16,
      "description": "Medium spacing"
    },
    "spacing/lg": {
      "value": 24,
      "description": "Large spacing"
    },
    "spacing/xl": {
      "value": 32,
      "description": "Extra large / page horizontal padding"
    },
    "radius/sm": {
      "value": 4,
      "description": "Small corner radius (chips, tags)"
    },
    "radius/md": {
      "value": 8,
      "description": "Medium corner radius (cards, inputs)"
    },
    "radius/lg": {
      "value": 12,
      "description": "Large corner radius (menus, popovers)"
    },
    "radius/xl": {
      "value": 42,
      "description": "Sheet presentation corner radius"
    }
  }
}
```

Spacing tokens are single-value (no modes). The `value` is always in points (iOS logical pixels).

## components.json

```json
{
  "$schema": "imprint-design-tokens",
  "$version": 1,
  "lastSynced": "2026-03-21T14:30:00Z",
  "components": {
    "FilterChip": {
      "figmaNodeId": "123:456",
      "description": "Category filter pill in the horizontal bar",
      "properties": [
        {
          "name": "state",
          "type": "variant",
          "values": ["default", "selected"]
        },
        {
          "name": "label",
          "type": "text",
          "default": "Film"
        }
      ],
      "swiftFile": "Views/Components/MediaFilterBar.swift",
      "tokens": {
        "background.selected": "color/category/subtle",
        "background.default": "color/base/paper",
        "text.selected": "color/base/paper",
        "text.default": "color/category/bold",
        "font": "typography/body/filter-chip",
        "cornerRadius": "radius/sm",
        "paddingVertical": "spacing/xs",
        "paddingHorizontal": "spacing/sm"
      }
    }
  }
}
```

Component entries link Figma node IDs to Swift files and document which tokens each component uses. The `tokens` map uses dot-path keys for the visual property and token name values. This enables parity checking — we can verify that the Swift code actually uses the referenced tokens.

## Mapping Conventions: Figma → JSON → Swift

| Figma variable name | JSON token key | Swift generated code |
|---|---|---|
| `base/paper` | `base/paper` | `ImprintColors.paper` |
| `base/boldest` | `base/primary` | `ImprintColors.primary` |
| `accent/blue/subtle` | `accent/blue/subtle` | `ImprintColors.accentBlue` |
| `heading/page-title` | `heading/page-title` | `ImprintFonts.pageTitle` |
| `space/xl` | `spacing/xl` | `ImprintSpacing.xl` |

The JSON key matches the Figma variable name as closely as possible. The Swift name is derived by:
1. Taking the last path segment (or last two if needed for uniqueness)
2. Converting to camelCase
3. Prefixing with the enum name (`ImprintColors.`, `ImprintFonts.`, `ImprintSpacing.`)

When the mapping isn't obvious, add a `"swiftName"` override field to the token:

```json
"base/boldest": {
  "light": "#100F0F",
  "dark": "#FFFCF0",
  "swiftName": "primary"
}
```
