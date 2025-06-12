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


## Workflow

### Wrong input fields set

In your workflow file, you are able to set arbitrary input fields, like:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
      version:
        description: 'Version to deploy'
        required: false
        default: 'latest'
        type: string
      debug_enabled:
        description: 'Enable debug mode'
        required: false
        default: false
        type: boolean
      custom_message:
        description: 'Custom message for this run'
        required: false
        type: string
jobs:
  dispatch-job:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    - name: Display inputs
      run: |
        echo "Running workflow with the following inputs:"
        echo "Environment: ${{ github.event.inputs.environment }}"
        echo "Version: ${{ github.event.inputs.version }}"
        echo "Debug enabled: ${{ github.event.inputs.debug_enabled }}"
        echo "Custom message: ${{ github.event.inputs.custom_message }}"
```

If in the Workflow CR you set the `inputs` field to something like this:

```yaml
spec:
  authenticationRefs:
    bearerAuthRef: bearer-gh-ref
  owner: krateoplatformops-test
  repo: workflow-tester
  workflow_id: test.yaml   # Can be the workflow file name
  ref: main                # branch or tag name
  inputs:
    environment: production
    version: "v1.2.3"
    debug_enabled: "false"
    custom_message: "Test from Krateo"
    field_not_in_workflow: "This field is not in the workflow file"
```

The workflow will not be triggered at all and you will receive an error like this when trying to dispatch the workflow:

```json
{
  "message": "Unexpected inputs provided: [\"field_not_in_workflow\"]",
  "documentation_url": "https://docs.github.com/rest/actions/workflows#create-a-workflow-dispatch-event",
  "status": "422"
}

This error can be seen by setting the annotation `krateo.io/connector-verbose: "true"` in the Workflow CR and checking the logs of the workflow controller.
To resolve this issue, ensure that the `inputs` field in your Workflow CR only contains keys that are defined in the workflow file. 
Remove any extraneous fields that do not match the workflow's input definitions.
```
