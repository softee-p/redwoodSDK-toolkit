---
name: rwsdk-frontend
description: >
  This skill should be used when the user has frontend layout, styling, or visual issues in a
  RedwoodSDK application. Trigger when the user mentions "fix layout", "mobile looks broken",
  "responsive design", "Tailwind not working", "CSS issues", "styling problems", "shadcn
  component looks wrong", "UI is off", or any visual/rendering complaint in an rwsdk project.
  Also trigger when the user asks about Tailwind v4 configuration in RSC, server component
  styling, dark mode setup, or wants to debug why components render differently on mobile vs
  desktop. Provides a mandatory 4-phase workflow (context gathering, visual testing, design
  solution, verification) that ensures thorough visual analysis before making any changes. Always
  use this skill instead of guessing at CSS fixes — it requires actually seeing the running app.
---

# RedwoodSDK Frontend Development

Fix frontend layout and styling issues in RedwoodSDK applications using a structured workflow that emphasizes visual testing and cross-skill knowledge integration.

## Workflow Overview

This skill enforces a mandatory 4-phase approach to ensure thorough analysis before making changes:

1. **Context Gathering** - Collect RedwoodSDK, Tailwind v4, and codebase knowledge
2. **Visual Testing** - Actually see the problems using browser automation
3. **Design Solution** - Create implementation plan based on visual evidence
4. **Verification Plan** - Plan for re-testing after changes

## Phase 1: Context Gathering (MANDATORY)

Before making any changes, gather comprehensive context from multiple sources:

### 1.1 Use rwsdk-docs Skill

Load the `rwsdk-docs` skill to get RedwoodSDK-specific knowledge:
- How Tailwind v4 works in React Server Components context
- RedwoodSDK styling patterns and best practices
- RSC hydration considerations for styling
- Server vs client component styling differences

### 1.2 Tailwind v4 & Styling Context

The `rwsdk-docs` skill also covers Tailwind v4 styling patterns. When reviewing styling issues, pay attention to:
- @theme inline pattern and CSS variable architecture
- Dark mode configuration
- Common Tailwind v4 errors to avoid (e.g., legacy `@apply` misuse, missing `@import "tailwindcss"`)
- shadcn/ui integration patterns (CSS variables, `cn()` utility)

**CRITICAL:** Cross-reference Tailwind v4 patterns with RSC architecture constraints from rwsdk-docs.

### 1.3 Explore the Codebase

Use Explore agents to find relevant code:
- Layout components and page structures
- Styling files (CSS, Tailwind config)
- Component usage of Tailwind classes
- Mobile-specific breakpoints and responsive utilities

## Phase 2: Visual Testing (MANDATORY)

Do NOT rely solely on code reading. Visually inspect the actual problems.

### 2.1 Run the Development Server

Start the dev server if not already running. Note the URL.

### 2.2 Use browser-use Skill

Load the `browser-use` skill to visually inspect layout issues:

```
Use browser-use to navigate to [dev-server-url] and test mobile layout
```

Test mobile viewports (iPhone, Android) to observe:
- Input field rendering and sizing
- Header layout and text overlap
- Page scrollability and white space issues
- Form field scroll behavior vs page scroll

### 2.3 Document Specific Issues

Create a detailed list of observed problems:
- Screenshot evidence or precise descriptions
- Affected components and their file paths
- Viewport sizes where issues occur
- Expected vs actual behavior

## Phase 3: Design Solution (MANDATORY)

With visual evidence and gathered context, design the fix.

### 3.1 Frontend Design Guidance

Apply these frontend best practices when designing the fix:
- **Mobile-first responsive design**: Start with mobile styles, add `sm:`, `md:`, `lg:` breakpoints for larger screens
- **Tailwind utility combinations**: Use `flex`, `grid`, `gap`, `min-w-0`, `overflow-hidden` to fix common layout issues
- **Component architecture**: Keep layout concerns in wrapper components, style concerns in leaf components
- **Accessibility**: Ensure interactive elements have visible focus states, sufficient contrast, and proper ARIA attributes

### 3.2 Create Implementation Plan

Design the solution based on:
- Visual testing results (what's actually broken)
- rwsdk-docs knowledge (RSC constraints and Tailwind v4 patterns)
- Frontend design best practices (see 3.1 above)

The plan should specify:
- Which files to modify
- Exact Tailwind classes or CSS changes needed
- Why each change fixes the observed problem
- RSC-specific considerations

## Phase 4: Verification Plan (MANDATORY)

Plan how to verify the fixes work.

### 4.1 Include browser-use Verification

The implementation plan MUST include re-testing with `browser-use`:
- Test same viewports that showed issues
- Verify each documented problem is resolved
- Check for new issues introduced by changes

### 4.2 Test Other Breakpoints

Plan to verify:
- Mobile (iPhone, Android sizes)
- Tablet
- Desktop

Ensure changes don't break layouts at other viewport sizes.

## Critical Rules

**DO NOT skip these steps:**
- rwsdk-docs (RSC context and Tailwind v4 patterns)
- browser-use (visual testing before and after)
- Frontend design guidance (mobile-first, accessibility)

**DO NOT just explore code without using the skills:**
- Skills provide specialized knowledge Claude doesn't have by default
- Reading code alone misses visual problems

**DO NOT create a plan without seeing the website running:**
- Visual inspection catches problems code reading misses
- Screenshots/descriptions provide concrete evidence for solutions

## Example Usage

User: "Fix mobile layout issues on my dashboard"

Correct approach:
1. Use rwsdk-docs skill → understand RSC styling constraints and Tailwind v4 patterns
2. Use Explore agents → find layout/styling files
3. Use browser-use skill → visually inspect mobile layout
4. Document: "Input fields compressed at 375px width, header text overlaps at 390px, page scrolls horizontally showing white space"
5. Apply frontend design guidance → mobile-first layout fixes
6. Create plan: "Update Header.tsx with flex-wrap, fix Input component min-width, add overflow-x-hidden to layout"
7. Include browser-use re-test in plan

Incorrect approach:
- ❌ Skip visual testing and guess problems from code
- ❌ Use only one skill instead of the required combination
- ❌ Make changes without seeing the actual rendered output
