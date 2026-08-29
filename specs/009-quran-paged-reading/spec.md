# Feature Specification: Quran Paged Reading

**Feature Branch**: `009-quran-paged-reading`

**Created**: 2026-08-26

**Status**: Draft

**Input**: User description: "Update the Surah Reading screen from continuous scrolling to a paged, physical-Mushaf-style experience: 604 fixed pages matching the standard Madani Mushaf, navigated by horizontal swipe (right-to-left advances, left-to-right goes back), crossing surah boundaries seamlessly at the first/last page of a surah, with a jump-to-page-or-Juz control, and per-page vertical scroll only when a user's font size makes that page's text overflow the screen. No reading-progress persistence in this phase."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read a Surah Page by Page (Priority: P1)

A user taps a Surah from the Surah list and lands on that surah's first Mushaf page, rendered with their saved font family and size, with the page's number (1–604) visible. Swiping right-to-left moves to the next page; swiping left-to-right moves to the previous page.

**Why this priority**: This is the core value of the feature — replacing continuous scrolling with the page-by-page Mushaf experience is the entire point of this update. Nothing else in this feature matters if this doesn't work.

**Independent Test**: Open any Surah from the Surah list, confirm its first page renders with a visible page number, then swipe right-to-left and left-to-right and confirm the page changes accordingly with the correct content and page number each time.

**Acceptance Scenarios**:

1. **Given** the user taps a Surah card, **When** the Surah Reading screen opens, **Then** it renders that surah's first Mushaf page, using the user's saved font family and size, with the page's Mushaf number (1–604) visible on screen.
2. **Given** the user is viewing a page that is not the last page of the Quran, **When** they swipe right-to-left, **Then** the next Mushaf page is shown with its own page number.
3. **Given** the user is viewing a page that is not the first page of the Quran, **When** they swipe left-to-right, **Then** the previous Mushaf page is shown with its own page number.
4. **Given** the same page is opened on separate occasions, **When** it renders, **Then** it always shows the same page number for the same content (page numbering is stable and consistent).

---

### User Story 2 - Cross Surah Boundaries Seamlessly (Priority: P1)

A user reading the last page of a surah swipes forward and continues directly into the first page of the next surah, with no interstitial screen or extra step. The same applies in reverse at the start of a surah.

**Why this priority**: Without this, paging would dead-end at every surah boundary — a jarring break in an otherwise continuous reading flow, and explicitly called out as a required edge case. It's inseparable from User Story 1's core swiping behavior and equally foundational to the paged-reading experience.

**Independent Test**: Navigate to the last page of any surah that is not the 114th, swipe right-to-left once more, and confirm the very next page shown is the first page of the following surah. Separately, navigate to the first page of any surah that is not the 1st, swipe left-to-right, and confirm the previous surah's last page is shown.

**Acceptance Scenarios**:

1. **Given** the user is on the last Mushaf page of a surah that is not the final surah (114), **When** they swipe right-to-left, **Then** the first page of the next surah is shown immediately, with no intermediate screen.
2. **Given** the user is on the first Mushaf page of a surah that is not the first surah (1), **When** they swipe left-to-right, **Then** the last page of the previous surah is shown immediately, with no intermediate screen.
3. **Given** the user is on the very last page of the Quran (page 604), **When** they swipe right-to-left, **Then** no further page change occurs (there is nothing beyond the last page).
4. **Given** the user is on the very first page of the Quran (page 1), **When** they swipe left-to-right, **Then** no further page change occurs (there is nothing before the first page).

---

### User Story 3 - Jump Directly to a Page or Juz (Priority: P2)

From the Surah Reading screen, a user opens a jump control and either types a page number or selects a Juz (1–30), landing directly on that page without swiping through everything in between.

**Why this priority**: A meaningful convenience on top of the core paging experience (User Stories 1–2) — valuable but not required for paging itself to work, and naturally builds on it.

**Independent Test**: From the Surah Reading screen, open the jump control, enter a specific page number (e.g., 250), confirm the screen navigates directly to that page. Repeat by selecting a Juz number instead, and confirm it navigates to that Juz's starting page.

**Acceptance Scenarios**:

1. **Given** the user is on the Surah Reading screen, **When** they open the jump control and enter a valid page number, **Then** the screen navigates directly to that page.
2. **Given** the user is on the Surah Reading screen, **When** they open the jump control and select a Juz number, **Then** the screen navigates directly to that Juz's first page.
3. **Given** the jump control is open, **When** the user enters a page number outside the valid range (1–604), **Then** the system prevents the invalid entry from being submitted rather than navigating to a nonexistent page.

---

### User Story 4 - Keep Reading When Larger Text Overflows a Page (Priority: P3)

A user with an increased font size opens a page whose text no longer fits the visible screen area. The page keeps its exact Mushaf ayah boundaries (nothing is pushed onto an adjacent page), but the user can scroll vertically within that single page to reach all of its text.

**Why this priority**: An accessibility and usability safeguard for users with larger font settings — important, but a narrower edge case that depends on User Story 1 already working and only manifests for a subset of font-size configurations.

**Independent Test**: Increase the font size to its largest available setting, navigate to a page with a relatively high ayah/word count, and confirm that although the text extends beyond the visible screen, every word remains reachable by scrolling vertically, and the page boundary (which ayahs belong to this page) is unchanged from the default font size.

**Acceptance Scenarios**:

1. **Given** a page's text exceeds the visible screen area at the user's current font size, **When** the user views that page, **Then** the page becomes vertically scrollable and all of its text remains reachable.
2. **Given** a page is vertically scrollable due to font overflow, **When** the user compares its ayah content to the same page at the default font size, **Then** the set of ayahs on that page is identical — only the font size changed, not the page boundary.
3. **Given** a page's text fits within the visible screen area, **When** the user views that page, **Then** no vertical scrolling is needed or offered.

---

### Edge Cases

- What happens if the user rapidly swipes multiple times in succession? Each swipe MUST resolve to a stable, correct final page — no skipped, duplicated, or out-of-order page states.
- What happens when a surah's last page and the next surah's first page are the very same physical Mushaf page (a surah does not start at the top of a fresh page)? Paging still MUST move ayah-by-content-correctly onto the next surah's content per the fixed page boundaries; page number continuity is preserved as normal sequential paging (this is not a special case beyond the fixed page boundaries already defined).
- What happens if the user opens the Surah Reading screen while offline? Content renders normally since Quran text is bundled with the app and available offline (no network dependency for reading).
- What happens if the user changes font size or family while on a given page? The page stays on the same content (same page number), re-rendering with the new font settings, re-evaluating whether that page now needs vertical scrolling.
- What happens if the user backgrounds and resumes the app mid-reading? Since this phase has no reading-progress persistence, resuming after a full app restart returns to the entry point (Surah list), not the last-viewed page.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Surah Reading screen MUST render Quran content as fixed, discrete pages matching the standard 604-page Madani Mushaf layout, rather than one continuously scrolling surah.
- **FR-002**: Each page MUST always contain the same fixed set of ayahs (the same start and end point), independent of the user's font family or font size.
- **FR-003**: An ayah MUST never be split across two pages — every ayah on a page MUST render there in full.
- **FR-004**: The system MUST display each page's Mushaf page number (1–604) visibly while that page is on screen.
- **FR-005**: Opening a Surah from the Surah list MUST navigate to that surah's first Mushaf page.
- **FR-006**: Swiping right-to-left on the Surah Reading screen MUST advance to the next sequential Mushaf page; swiping left-to-right MUST return to the previous sequential Mushaf page.
- **FR-007**: When the current page is the last page of a surah (and that surah is not the final surah, 114), advancing MUST continue directly into the first page of the next surah, with no interstitial screen or additional confirmation step.
- **FR-008**: When the current page is the first page of a surah (and that surah is not the first surah, 1), going back MUST show the last page of the previous surah, with no interstitial screen or additional confirmation step.
- **FR-009**: Attempting to advance past page 604 or go back before page 1 MUST leave the user on that same boundary page (no navigation occurs, no error is shown).
- **FR-010**: The Surah Reading screen MUST offer a jump control that allows the user to navigate directly to any page (1–604) by entering its number, or to any Juz (1–30) by selecting it — navigating directly to that Juz's first page.
- **FR-011**: The jump control MUST reject or prevent submission of a page number outside the valid 1–604 range.
- **FR-012**: Pages MUST render using the user's currently saved Quran font family and size (per the existing font settings feature).
- **FR-013**: When a page's rendered text exceeds the visible screen area at the user's current font size, that page MUST become vertically scrollable while keeping its ayah boundary unchanged; pages that fit within the screen MUST NOT offer vertical scrolling.
- **FR-014**: The Surah Reading screen MUST continue to work fully offline, consistent with the Quran content already being bundled with the app.
- **FR-015**: This phase MUST NOT persist or restore the user's last-viewed page across app sessions; each visit to the Surah Reading screen starts from the entry point's first page (the tapped surah's first page, or the jump target when arriving via a jump).

### Key Entities

- **Mushaf Page**: One of the 604 fixed pages of the standard Madani Mushaf layout. Has a page number (1–604) and a fixed, ordered set of ayahs (each identified by its surah and ayah-within-surah number) that always belong to that page regardless of display settings.
- **Ayah** *(existing entity, unchanged in meaning)*: A single verse, now additionally understood to belong to exactly one Mushaf Page.
- **Juz**: *(existing entity)* One of the 30 traditional reading-division sections; each Juz's first page is a valid jump target.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can move from any Mushaf page to an adjacent one via a single swipe, with the new page fully rendered in under 1 second.
- **SC-002**: 100% of surah-to-surah transitions reached by swiping past a surah's last page (or before its first page) land on the correct adjacent surah's boundary page, with zero intermediate screens shown.
- **SC-003**: A user can reach any of the 604 pages from the Surah Reading screen in at most 2 actions (open jump control, submit a page number or Juz selection) instead of swiping page-by-page.
- **SC-004**: At the largest available font size, 100% of a page's ayah text remains reachable through vertical scrolling, with zero words cut off or inaccessible.
- **SC-005**: Across repeated visits to the same page number, the exact same set of ayahs is shown every time — page content is fully deterministic.

## Assumptions

- Page-to-ayah mapping follows the standard Madani Mushaf's fixed 604-page layout (the same layout used by the widely distributed King Fahd Complex Mushaf print), which is the layout already reflected in the updated bundled Quran content assets for this feature.
- "Reading-progress persistence" (returning to the last-viewed page automatically) is explicitly out of scope for this phase, per the feature description; the Surah Reading screen always opens at the entry point's first page.
- The jump control's exact presentation (e.g., a bottom sheet vs. another surface) is a UI/implementation detail left to the design/implementation phase; this spec only requires that the capability (jump to page number or Juz) exists and is reachable from the Surah Reading screen.
- Two screen affordances mentioned as visual placeholders for this phase — an audio/listen control and additional page-level actions (e.g., share, tafseer) — are acknowledged as present in the UI but explicitly carry no functional behavior in this phase; their behavior is deferred to a future update.
- The Surah list and Juz tab (browsing entry points) are unchanged by this feature — only what happens after a surah/page is opened for reading changes.
- Existing per-surah font family/size preferences (from the prior font settings feature) continue to apply unchanged to paged rendering.
