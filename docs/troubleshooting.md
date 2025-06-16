# Troubleshooting

## Summary

- [Summary](#summary)
- [Checking RestDefinitions](#checking-restdefinitions)
- [Checking CRDs](#checking-crds)
- [Checking controllers](#checking-controllers)
- [Resources](#resources)
  - [Repo](#repo)
    - [Squash Merge Commit Message and Title](#squash-merge-commit-message-and-title)
      - [Valid Combinations](#valid-combinations)
    - [Wiki and Private Repositories](#wiki-and-private-repositories)
    - [`private` and `visibility` fields](#private-and-visibility-fields)
  - [Collaborator](#collaborator)
    - [Note on Organization Base Permissions](#note-on-organization-base-permissions)
  - [Workflow](#workflow)
    - [Wrong input fields set](#wrong-input-fields-set)

## Checking RestDefinitions

To check that the `restdefinitions` for the GitHub provider are correctly installed in the Kubernetes cluster, you can run the following command:
```sh
kubectl get restdefinition -n <YOUR_NAMESPACE>
```

You should see output similar to this:
```sh
NAME               READY
ghp-collaborator   True
ghp-repo           True
ghp-runnergroup    True
ghp-teamrepo       True
ghp-workflow       True
```

Note: if you confifure to install just a subset of `restdefinitions`, you may not see all of the above `restdefinitions`.

Note: the prefix `ghp-` came from the Helm release name and therefore may differ in your case.

## Checking CRDs

To check that the Custom Resource Definitions (CRDs) for the GitHub provider are installed in the Kubernetes cluster, you can run the following command:
```sh
kubectl get crds | grep github
```

If the CRDs are installed, you should see output similar to this:
```sh
bearerauths.github.kog.krateo.io                    2025-06-12T16:24:23Z
collaborators.github.kog.krateo.io                  2025-06-12T16:24:23Z
repoes.github.kog.krateo.io                         2025-06-12T16:24:23Z
runnergroups.github.kog.krateo.io                   2025-06-12T16:24:24Z
teamrepoes.github.kog.krateo.io                     2025-06-12T16:24:23Z
workflows.github.kog.krateo.io                      2025-06-12T16:24:24Z
```

Note: if you configure to install just a subset of `restdefinitions`, you may not see all of the above CRDs.

## Checking controllers

You can check the status of the controllers by running:
```sh
until kubectl get deployment github-provider-<RESOURCE>-controller -n <YOUR_NAMESPACE> &>/dev/null; do
  echo "Waiting for <RESOURCE> controller deployment to be created..."
  sleep 5
done
kubectl wait deployments github-provider-<RESOURCE>-controller --for condition=Available=True --namespace <YOUR_NAMESPACE> --timeout=300s
```

Make sure to replace `<RESOURCE>` to one of the resources supported by the chart, such as `repo`, `collaborator`, `teamrepo`, `workflow` or `runnergroup`, and `<YOUR_NAMESPACE>` with the namespace where you installed the chart.

## Resources

### Repo

#### Squash Merge Commit Message and Title

When configuring `squash_merge_commit_message` and `squash_merge_commit_title` fields, you must use a valid combination according to the [GitHub API documentation](https://docs.github.com/rest/repos/repos#create-an-organization-repository).

##### Valid Combinations

| `squash_merge_commit_title` | `squash_merge_commit_message` |
|-----------------------------|-------------------------------|
| `PR_TITLE`                  | `PR_BODY`                     |
| `PR_TITLE`                  | `BLANK`                       |
| `PR_TITLE`                  | `COMMIT_MESSAGES`             |
| `COMMIT_OR_PR_TITLE`        | `COMMIT_MESSAGES`             |

Make sure to avoid any combinations outside of the above to prevent API errors or unexpected behavior.

#### Wiki and Private Repositories

When enabling the wiki for a repository (using the `has_wiki: true` field in the Repo CR), you must ensure that the repository is public if your organization does not have a GitHub Pro, GitHub Team, GitHub Enterprise Cloud, or GitHub Enterprise Server plan.
The `has_wiki` field should be set to `true` only for public repositories unless your organization has the appropriate GitHub plan that allows wikis in private repositories.

[GitHub Docs](https://docs.github.com/en/communities/documenting-your-project-with-wikis/adding-or-editing-wiki-pages) state:
> Who can use this feature? Wikis are available in public repositories with GitHub Free and GitHub Free for organizations, and in public and private repositories with GitHub Pro, GitHub Team, GitHub Enterprise Cloud and GitHub Enterprise Server. For more information, see GitHub’s plans.

The combination of `has_wiki: true` and the fact that the repo is private will result in an error.
Wiki will not be enabled and the controller will be constantly see discrepancy between the desired state and the actual state of the repository.

#### `private` and `visibility` fields

When setting the `private` and `visibility` fields in the Repo CR, you must ensure that they are consistent with each other.
The `private` field is a boolean that indicates whether the repository is private or not, while the `visibility` field is a string that can be set to either `public`, `private`.
The field `private` is set to `false` by default.

### Collaborator

When configuring the `permissions` field for collaborators, ensure you're using one of the valid permission levels:

| Valid Permission Levels |
|-------------------------|
| `admin`                 |
| `maintain`              |
| `push`                  |
| `triage`                |
| `pull`                  |

#### Note on Organization Base Permissions

If the organization's "Base permissions" are set to `read`, and you attempt to add a collaborator (who is already a member of the organization) to a repository with `pull` permissions **as the initial permission**, the collaborator may **not** appear in the repository's collaborators list.
Practically this is just a visual choice of the GitHub UI, as the collaborator does have `pull` access to the repository.
Instead, an external collaborator with `pull` permissions will still be visible in the list with the `Pending Invite` label.

On the other hand, if you first add the collaborator with a higher permission level (e.g., `push`), and then downgrade the permission to `pull`, the collaborator **will** be visible in the list in the GitHub UI.

This behavior is related to how GitHub handles permission inheritance from organization-level settings.

### Workflow

#### Wrong input fields set

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
```

This error can be seen by setting the annotation `krateo.io/connector-verbose: "true"` in the Workflow CR and checking the logs of the workflow controller.
To resolve this issue, ensure that the `inputs` field in your Workflow CR only contains keys that are defined in the workflow file. 
Remove any extraneous fields that do not match the workflow's input definitions.
