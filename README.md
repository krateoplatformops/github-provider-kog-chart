# GitHub Provider Helm Chart

This is a [Helm Chart](https://helm.sh/docs/topics/charts/) that deploys the Krateo GitHub Provider leveraging the [Krateo OASGen Provider](https://github.com/krateoplatformops/oasgen-provider) and using [OpenAPI Specifications (OAS) of the GitHub API](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.2022-11-28.yaml).

> [!NOTE]  
> This chart is going to replace the [original Krateo github-provider](https://github.com/krateoplatformops/github-provider) in the future. 

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

### Resource details

#### Repo

Manage GitHub repositories.
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

Manage collaborators in a GitHub repository.
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









- **Repo**: Manage GitHub repositories, including creation, updates, and deletion.
- **TeamRepo**: Manage team access to GitHub repositories.
- **Workflow**: Manage GitHub workflow runs, in particular, triggering workflow runs.

## Configuration

You can customize the chart by modifying the `values.yaml` file. This file contains default configuration values, including server URLs and other parameters.

## Chart structure

The chart contains:

- **/assets** folder: Contains the selected OpenAPI Specification files for the GitHub API.

- **ConfigMaps**: Refer to the OpenAPI Specification content.

- **Deployment**: Deploys the plugin that is used as a proxy for the GitHub API to resolve some inconsistencies in the OpenAPI Specification.

- **Service**: Exposes the plugin to the cluster.

## Usage

After installation, you can access the application using the service created by this chart. The server URLs defined in the OAS will be templated and utilized by the application.

## Requirements

`oasgen-provider-chart` should be installed in your cluster. Follow the [README](https://github.com/krateoplatformops/oasgen-provider-chart) for installation instructions.
