# Release Notes Style Guide

Write clear, user-facing release notes for Cornell Library catalog users and staff.

## Categories

Group entries into these sections, in this order:

1. 🚀 Features
2. 🐛 Bug Fixes
3. 🦮 Accessibility
4. 🧰 Maintenance
5. 📚 Documentation

## PR Template
Use the developer completed PR Template for reference on each PR ( .github/pull_request_template.md )

## Category Mapping from PR Template

Use the PR body section `## 🔖 Type of Change` and map checked boxes ( "[X]" ):

- `feature`       -> 🚀 Features
- `bug`           -> 🐛 Bug Fixes
- `accessibility` -> 🦮 Accessibility
- `maintenance`   -> 🧰 Maintenance
- `documentation` -> 📚 Documentation

If multiple boxes are checked, choose the category in this priority order:

1. `feature`
2. `bug`
3. `accessibility`
4. `maintenance`
5. `documentation`

If no type is clear, place the entry under 🧰 Maintenance and mark it as inferred.

## Entry Format

Use this bullet format:

- `<concise user-facing change>` by @`<author>` in #`<pr_number>` (`<jira_links_if_present>`)

Jira links (<jira_links_if_present>) come from `## 🔗 Related Issues` and must use full markdown links:
- Similar to this example: [DACCESS-901](https://culibrary.atlassian.net/browse/DACCESS-901)

If multiple Jira tickets are present, include all of them in the same bullet, comma-separated.

## Style Rules

- Use present tense and action verbs: Add, Fix, Improve, Update.
- Keep each bullet concise and specific (target 10-100 characters for the change description).
- Prefer plain language over internal implementation details.
- Keep emojis only in section headers (not every bullet) so notes stay easy to scan.
- Include all relevant PRs found in the comparison.
- Only include Jira tickets that match `DACCESS-\d+`.
- Deduplicate overlapping PRs: if multiple PRs deliver one user-visible outcome, write one combined bullet and cite all PR numbers/tickets.
- Order entries inside each section by user impact: highest impact first, then medium, then minor/internal.
