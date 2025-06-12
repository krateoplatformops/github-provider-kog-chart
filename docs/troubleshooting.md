# Troubleshooting

## Squash Merge Commit Message and Title

When configuring `squash_merge_commit_message` and `squash_merge_commit_title` fields, you must use a valid combination according to the [GitHub API documentation](https://docs.github.com/rest/repos/repos#create-an-organization-repository).

### Valid Combinations

| `squash_merge_commit_title` | `squash_merge_commit_message` |
|-----------------------------|-------------------------------|
| `PR_TITLE`                  | `PR_BODY`                     |
| `PR_TITLE`                  | `BLANK`                       |
| `PR_TITLE`                  | `COMMIT_MESSAGES`             |
| `COMMIT_OR_PR_TITLE`        | `COMMIT_MESSAGES`             |

Make sure to avoid any combinations outside of the above to prevent API errors or unexpected behavior.
