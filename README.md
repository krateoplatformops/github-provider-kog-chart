# GitHub Provider Helm Chart

This is a [Helm Chart](https://helm.sh/docs/topics/charts/) that deploys the Krateo GitHub Provider leveraging the [Krateo OASGen Provider](https://github.com/krateoplatformops/oasgen-provider) and using [OpenAPI Specifications (OAS) of the GitHub API](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.2022-11-28.yaml).
This provider allows you to manage GitHub resources such as repositories, collaborators, and workflow runs using the Krateo platform.

> [!NOTE]  
> This chart is going to replace the [original Krateo github-provider](https://github.com/krateoplatformops/github-provider) in the future. 

## Summary

- [Summary](#summary)
- [How to Install](#how-to-install)
- [Supported Resources](#supported-resources)
  - [Resource Details](#resource-details)
    - [Repo](#repo)
    - [Collaborator](#collaborator)
    - [TeamRepo](#teamrepo)
    - [Workflow](#workflow)
- [Configuration](#configuration)
- [Chart Structure](#chart-structure)
- [Requirements](#requirements)

## How to install

To install the chart, use the following commands:

```sh
helm repo add krateo https://charts.krateo.io
helm repo update krateo
helm install github-provider krateo/github-provider-kog
```

## Supported resources

This chart supports the following resources and operations:

| Resource     | Get  | Create | Update | Delete |
|--------------|------|--------|--------|--------|
| Collaborator | ✅   | ✅     | ✅     | ✅     |
| Repo         | ✅   | ✅     | ✅     | ✅     |
| TeamRepo     | ✅   | ✅     | ✅     | ✅     |
| Workflow     | ✅   | ✅     | 🚫 Not applicable    | 🚫 Not applicable     |


> [!NOTE]  
> 🚫 *"Not applicable"* indicates that the operation is not supported because it probably does not make sense for the resource type.  For example, GitHub Workflow runs are typically not updated or deleted directly; they are triggered and if a new run is needed, a new workflow run is created.

The resources listed above are Custom Resources (CRs) defined in the `github.krateo.io` API group. They are used to manage GitHub resources in a Kubernetes-native way, allowing you to create, update, and delete GitHub resources using Kubernetes manifests.

### Resource details

#### Repo

The `Repo` resource allows you to create, update, and delete GitHub repositories. You can specify the repository name, description, visibility (public or private), and other settings that can be seen in the [GitHub API documentation](https://docs.github.com/en/rest/repos?apiVersion=2022-11-28) and the selected OpenAPI Specification in the `/assets` folder of this chart.
An example of a Repo resource is:
```yaml
apiVersion: github.krateo.io/v1alpha1
kind: Repo
metadata:
  name: test-repo1
  namespace: ghp
  annotations:
    krateo.io/connector-verbose: "true"
spec:
  authenticationRefs:
    bearerAuthRef: bearer-gh-ref
  org: krateoplatformops-test
  name: test-repo1
  description: A short description of the repository set by Krateo
  visibility: public
  has_issues: true
```

#### Collaborator 

The `Collaborator` resource allows you to add or remove collaborators from a GitHub repository. You can specify the username of the collaborator and the permission level among `admin`, `pull`, `push`, `maintain`, and `triage`.

An example of a Collaborator resource is:
```yaml
apiVersion: github.krateo.io/v1alpha1
kind: Collaborator
metadata:
  name: add-collaborator
  namespace: ghp
  annotations:
    krateo.io/connector-verbose: "true"
spec:
  authenticationRefs:
    bearerAuthRef: bearer-gh-ref
  owner: krateoplatformops-test
  repo: collaborator-tester
  username: vicentinileonardo
  permission: pull
```

#### TeamRepo

The `TeamRepo` resource allows you to manage team access to GitHub repositories. You can specify the `team_slug`, repository name, and permission level among `admin`, `pull`, `push`, `maintain`, and `triage`.

> [!NOTE]
> The `TeamRepo` resource is not a standard GitHub resource but allows you to manage team access to repositories in a way that is consistent with the other resources in this chart.

An example of a TeamRepo resource is:
```yaml
apiVersion: github.krateo.io/v1alpha1
kind: TeamRepo
metadata:
  name: test-teamrepo
  namespace: ghp
  annotations:
    krateo.io/connector-verbose: "true"
spec:
  authenticationRefs:
    bearerAuthRef: bearer-gh-ref
  org: krateoplatformops-test
  owner: krateoplatformops-test
  team_slug: testteam
  repo: teamrepo-tester
  permission: pull
```

#### Workflow

The `Workflow` resource allows you to trigger workflow runs in a GitHub repository. You can specify the repository name, workflow file name, and any input parameters required by the workflow. 

An example of a Workflow resource is:
```yaml
apiVersion: github.krateo.io/v1alpha1
kind: Workflow
metadata:
  name: workflow-tester
  namespace: ghp
  annotations:
    krateo.io/connector-verbose: "true"
spec:
  authenticationRefs:
    bearerAuthRef: bearer-gh-ref
  owner: krateoplatformops-test
  repo: workflow-tester
  workflow_id: test.yaml
  ref: main
  inputs:
    environment: development
    version: "v1.2.3"
    debug_enabled: "false"
    custom_message: "Test 04/06 at 13:42 from Krateo"
```

## Configuration

You can customize the chart by modifying the `values.yaml` file. For instance, you can select which resources the provider should support in the oncoming installation by setting the `restdefinitions` field in the `values.yaml` file. The default configuration enables all resources supported by the chart.

## Chart structure

Main components of the chart:

- **/assets** folder: Contains the selected OpenAPI Specification files for the GitHub API.

- **ConfigMaps**: Refer directly to the OpenAPI Specification content.

- **Deployment**: Deploys a [plugin](https://github.com/krateoplatformops/github-rest-dynamic-controller-plugin) that is used as a proxy for the GitHub API to resolve some inconsistencies in the OpenAPI Specification. The spacific endpoins managed by the plugin are described in the [plugin README](https://github.com/krateoplatformops/github-rest-dynamic-controller-plugin/blob/main/README.md)

- **Service**: Exposes the plugin to the cluster.

- **/samples** folder: Contains example resources for each supported resource type as seen in this README. These examples demonstrate how to create and manage GitHub resources using the Krateo OASGen Provider.


## Requirements

Krateo OASGen Provider should be installed in your cluster. Follow the related Helm Chart [README](https://github.com/krateoplatformops/oasgen-provider-chart) for installation instructions.
