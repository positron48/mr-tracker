# Project Notes

## Overview

MR Tracker is a native macOS app for tracking GitLab merge requests from a private GitLab instance. The app is written in SwiftUI with SwiftData persistence and uses GitLab REST API v4 for read-only synchronization.

The app is intended for local/VPN access to GitLab. Authentication uses a GitLab Personal Access Token with `read_api` scope. The token is stored in Keychain; the base URL is stored in `UserDefaults`.

## Commands

- Run tests: `swift test`
- Build app bundle locally: `./make-app.sh`
- Build and install: `./make-app.sh release install`

The package requires macOS 15+ and full Xcode, not only Command Line Tools, because SwiftData `@Model` macro support comes from Xcode.

## Repository Layout

- `Package.swift`: Swift package definition.
- `Sources/MRTracker/MRTrackerApp.swift`: app entry point, main window, folder manager window, settings scene, shared SwiftData container.
- `Sources/MRTracker/Models/`: SwiftData models and domain enums/helpers.
- `Sources/MRTracker/Services/`: GitLab client, Keychain storage, URL parsing, link label generation.
- `Sources/MRTracker/ViewModels/AppModel.swift`: observable app state, sync orchestration, status transitions.
- `Sources/MRTracker/Views/`: SwiftUI UI components.
- `Tests/MRTrackerTests/`: unit tests for URL parsing, link labels, and MR chain sorting.

## Data Model

- `MergeRequest` is a SwiftData `@Model`.
  - GitLab identity: `projectPath` is URL-encoded for GitLab API `:id`, `iid` is the project-local MR number.
  - Branch relation: `sourceBranch` and `targetBranch` are used to detect MR chains.
  - Local status is stored as `statusRaw` and exposed as `status: MRStatus`.
  - `isArchived` is derived from status, manual archive flag, or archived parent group.
  - `isManuallyArchived` hides an MR when its folder is archived without changing its workflow status.
- `TaskGroup` is a SwiftData `@Model` used as a folder/task grouping MR.
  - `isArchived` hides the folder and its MR from the active list.
  - `activeMRs` filters out archived MR.
- `CustomLink` is attached either to an MR or to a group and displayed as a short chip.

When adding persistent SwiftData fields, prefer default property values so lightweight migration can handle existing stores.

## Status And Archive Rules

`MRStatus` values are:

- `created`
- `inReview`
- `approved`
- `onProd`
- `cancelled`

`onProd` and `cancelled` are archive statuses. A manually archived folder should not rewrite an MR status to `cancelled` or `onProd`; it should set `TaskGroup.isArchived` and, for non-archive MR inside it, `MergeRequest.isManuallyArchived`.

Restoring a folder from archive clears `TaskGroup.isArchived` and clears `isManuallyArchived` for MR in that folder. MR with archive statuses remain archived because their status still implies archive.

## MR Ordering

MR chains are detected by branch names:

- If MR A has `targetBranch == sourceBranch` of MR B, then A is merging into B.
- The UI should keep related MR contiguous, but still order MR top-down by freshness: newer MR above older MR.
- Across separate chains/items, newer GitLab update time (`gitlabUpdatedAt`, falling back to `createdAt`) wins.
- Draw only visual through-lines/arrows for chain links on the right side near the MR link area. Do not duplicate MR ids or branch names in connector labels.
- Arrow direction is separate from row order: use an up arrow when the lower MR merges into the upper MR, and a down arrow when the upper MR merges into the lower MR.

The sorting helper is `MRChainSorter.sorted(_:)`. Use it for active MR lists in groups and ungrouped sections.

## UI Notes

- Main screen is `ContentView`.
- Add MR bar stays at the top.
- Active groups render before ungrouped active MR.
- Archive section label is `Архив`.
- The folder manager window is opened with `openWindow(id: "folders")` and implemented in `FolderManagerView`.
- New folder creation remains in the main toolbar alert.
- Folder editing, archiving, and restoring are done in the separate folder manager window.
- If a folder contains non-archived MR, archiving it must show a warning that these MR will also be hidden.
- Archived folders must not appear in the MR context menu group list.

## GitLab Sync Behavior

`AppModel.refreshAll(context:)` refreshes only active MR and performs requests sequentially with throttling. `apply(snapshot:to:)` updates title, branches, GitLab state, approval, CI, unresolved comments, and GitLab updated time.

Automatic status transitions:

- GitLab `merged` moves MR to `onProd`.
- Approved MR moves from `created` or `inReview` to `approved`.
- Manual `cancelled` status is sticky and should not be overwritten by sync.

## Testing

Run `swift test` before finishing changes. Existing tests use Swift Testing (`import Testing`), not XCTest.
