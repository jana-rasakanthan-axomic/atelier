# Requirements Analysis Example: User Data Export

Worked example showing the extraction process applied to a real PRD.

> Referenced from [requirements-analysis.md](../requirements-analysis.md)

---

## Input PRD

```markdown
## User Story
As a user, I want to export my account data so I can keep a local backup.

## User Flow
1. User navigates to Settings > Privacy
2. User clicks "Export My Data" button
3. User sees modal: "Select format: CSV or JSON"
4. User selects CSV and clicks "Start Export"
5. User sees loading spinner: "Preparing your export..."
6. When ready, user sees "Download" button
7. User clicks Download and receives file

## Technical Notes
- Should support 100k users
- Exports should complete within reasonable time
- Must be secure (users can only export their own data)
```

## Output: Analyzed Requirements

### Functional Requirements
- Export user account data to file
- Support CSV and JSON formats
- User selects format before starting export
- System provides download link when export completes
- Users can only export their own data (not other users')

### Non-Functional Requirements
- **Performance:** Handle 100k users without timeout
- **Performance:** Complete export within 60 seconds (reasonable time)
- **Security:** Users can only access their own data
- **Security:** Download links expire after 24 hours
- **Usability:** Show progress/status while export is running

### Constraints
- Must use existing authentication (user ID from JWT)
- Must follow existing data privacy policies
- No breaking changes to user API

### Out of Scope
- Scheduled/automated exports
- Export formats other than CSV/JSON (e.g., Excel)
- Bulk export for admins (multiple users at once)
- Custom field selection (exports all data)
