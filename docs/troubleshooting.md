# Troubleshooting

## Repo

### Squash Merge Commit Message and Title

When configuring `squash_merge_commit_message` and `squash_merge_commit_title` fields, you must use a valid combination according to the [GitHub API documentation](https://docs.github.com/rest/repos/repos#create-an-organization-repository).

#### Valid Combinations

| `squash_merge_commit_title` | `squash_merge_commit_message` |
|-----------------------------|-------------------------------|
| `PR_TITLE`                  | `PR_BODY`                     |
| `PR_TITLE`                  | `BLANK`                       |
| `PR_TITLE`                  | `COMMIT_MESSAGES`             |
| `COMMIT_OR_PR_TITLE`        | `COMMIT_MESSAGES`             |

Make sure to avoid any combinations outside of the above to prevent API errors or unexpected behavior.

## Collaborator

When configuring the `permissions` field for collaborators, ensure you're using one of the valid permission levels:

| Valid Permission Levels |
|-------------------------|
| `admin`                 |
| `maintain`              |
| `push`                  |
| `triage`                |
| `pull`                  |

### Note on Organization Base Permissions

If the organization's "Base permissions" are set to `read`, and you attempt to add a collaborator to a repository with `pull` permissions **as the initial permission**, the collaborator may **not** appear in the repository's collaborators list.
Practically this is just a visual choice of the GitHub UI, as the collaborator does have `pull` access to the repository.

However, if you first add the collaborator with a higher permission level (e.g., `push`), and then downgrade the permission to `pull`, the collaborator **will** be visible in the list.

This behavior is related to how GitHub handles permission inheritance from organization-level settings.
