# Figma → Flutter Pixel-Perfect Implementation Skill

## Purpose

This skill guides an AI agent to **professionally read Figma designs
using the MCP server** and convert them into **pixel‑perfect Flutter UI
implementations**.

The skill ensures: - Accurate extraction of design specifications -
Correct mapping to existing design tokens in the codebase - Creation of
missing tokens when necessary - Layout validation for responsiveness and
consistency

------------------------------------------------------------------------

# Skill Intent

The purpose of this skill is to help the agent:

1.  Fetch design specifications from **Figma using the MCP server**
2.  Interpret the design structure professionally
3.  Match Figma tokens with the project's **existing Flutter design
    system**
4.  Ensure **pixel‑perfect UI implementation**
5.  Maintain **design consistency across the codebase**

This skill does **NOT generate arbitrary UI**.\
It strictly follows **Figma as the single source of truth**.

------------------------------------------------------------------------

# Preconditions

Before executing the skill, ensure:

-   A valid **Figma component link** is provided
-   MCP server access is available
-   The project contains design tokens such as:

Example:

    utils/style/app_colors.dart
    utils/style/app_typography.dart

------------------------------------------------------------------------

# Execution Workflow

## Step 1 --- Fetch Figma Component

Using the MCP server:

-   Retrieve the component metadata
-   Extract:
    -   Layout structure
    -   Spacing
    -   Colors
    -   Typography
    -   Dimensions
    -   Constraints
    -   Border radius
    -   Icon assets

The agent must treat the Figma node as the **exact design
specification**.

------------------------------------------------------------------------

## Step 2 --- Extract Design Specifications

The agent must collect the following properties:

### Layout

-   padding
-   margins
-   spacing between elements
-   alignment
-   layout direction

### Dimensions

-   width
-   height
-   min/max constraints

### Colors

-   background colors
-   text colors
-   border colors

### Typography

-   font family
-   font size
-   font weight
-   line height
-   letter spacing

### Components

-   icons
-   buttons
-   input fields
-   containers

------------------------------------------------------------------------

# Step 3 --- Match Design Tokens With Code

The agent must search the codebase for predefined tokens.

### Colors

Check for matches in:

    AppColors

Example file:

    utils/style/app_colors.dart

### Typography

Check for matches in:

    AppTypography

Example file:

    utils/style/app_typography.dart

------------------------------------------------------------------------

# Step 4 --- Handle Missing Tokens

If a Figma color or typography value **does not exist in the codebase**:

The agent must:

1.  Highlight the missing token
2.  Create a new token definition

Example:

### Missing Color

Figma color:

    #4A90E2

Generated token:

``` dart
static const Color primaryBlue = Color(0xFF4A90E2);
```

### Missing Typography

Example:

``` dart
static const TextStyle titleMedium =
    TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
```

The new token must follow **project naming conventions**.

------------------------------------------------------------------------

# Step 5 --- Generate Flutter Layout

The agent must convert the component into Flutter widgets while
preserving:

-   exact spacing
-   correct alignment
-   correct typography
-   correct colors

Preferred widgets:

-   `Row`
-   `Column`
-   `Stack`
-   `Expanded`
-   `Flexible`
-   `Padding`
-   `SizedBox`
-   `Container`
-   `IconButton`

Avoid unnecessary wrappers.

------------------------------------------------------------------------

# Step 6 --- Ensure Pixel Accuracy

Before finalizing the implementation:

The agent must validate:

-   spacing accuracy
-   layout hierarchy
-   alignment consistency
-   correct dimensions
-   correct border radius
-   correct font styles

------------------------------------------------------------------------

# Step 7 --- Responsive Layout Validation

The UI must remain correct across devices.

Check:

-   small phones
-   large phones
-   tablets

Techniques:

-   flexible layouts
-   avoiding hard‑coded sizes
-   using `Expanded` where appropriate

------------------------------------------------------------------------

# Output Requirements

The final output must include:

### 1 --- Token Mapping Report

Example:

    Color Mapping
    -------------
    Figma: #4A90E2 → AppColors.primaryBlue

    Typography Mapping
    ------------------
    Figma: 18px / SemiBold → AppTypography.titleMedium

------------------------------------------------------------------------

### 2 --- New Tokens (if required)

If missing tokens were created, provide:

    New Color Tokens
    New Typography Tokens

------------------------------------------------------------------------

### 3 --- Flutter Implementation

Provide a **clean Flutter widget implementation**.

The code must:

-   use project tokens
-   follow Flutter best practices
-   maintain pixel accuracy

------------------------------------------------------------------------

# Final Rules

The agent must always:

-   Treat **Figma as the design source of truth**
-   Use **existing design tokens whenever possible**
-   Create **new tokens when missing**
-   Maintain **pixel‑perfect layout**
-   Avoid arbitrary design decisions
