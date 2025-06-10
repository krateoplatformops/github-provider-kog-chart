# GitHub Provider Helm Chart

This is a [Helm Chart](https://helm.sh/docs/topics/charts/) that deploys the Krateo GitHub Provider leveraging the [Krateo OASGen Provider](https://github.com/krateoplatformops/oasgen-provider) and using [OpenAPI Specifications (OAS) of the GitHub API](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.2022-11-28.yaml).

> [!NOTE]  
> This chart is going to replace the [original Krateo github-provider](https://github.com/krateoplatformops/github-provider) in the future. 

It includes ConfigMaps to store the OAS content, a Deployment to run the application, and a Service to expose it.


## How to install

To install the chart, use the following command:

```sh
helm repo add krateo https://charts.krateo.io
helm repo update krateo
helm install github-provider krateo/github-provider-kog
```

## Supported resources

This chart supports the following resources:

| Resource     | Get  | Create | Update | Delete |
|--------------|------|--------|--------|--------|
| Collaborator | ✅   | ✅     | ✅     | ✅     |
| Repo         | ✅   | ✅     | ✅     | ✅     |
| TeamRepo     | ✅   | ✅     | ✅     | ✅     |
| Workflow     | ✅   | ✅     | 🚫 Not applicable    | 🚫 Not applicable     |


**Note:**  
🚫 *"Not applicable"* indicates that the operation is not supported because it probably does not make sense for the resource type.  
For example, GitHub Workflow runs are typically not updated or deleted directly; they are triggered and if a new run is needed, a new workflow run is created.

## Configuration

You can customize the chart by modifying the `values.yaml` file. This file contains default configuration values, including server URLs and other parameters.

## Resources




- **ConfigMaps**: Store the OpenAPI Specification content.
  - `configmap-collaborator.yaml`: Contains the collaborator API specifications.
  - `configmap-repo.yaml`: Contains the repo API specifications.
  - `configmap-teamrepo.yaml`: Contains the teamrepo API specifications.
  - `configmap-workflow.yaml`: Contains the workflow API specifications.
- **Deployment**: Manages the application instances.
- **Service**: Exposes the application to the network.

## Usage

After installation, you can access the application using the service created by this chart. The server URLs defined in the OAS will be templated and utilized by the application.

## Requirements

`oasgen-provider-chart` should be installed in your cluster. Follow the [README](https://github.com/krateoplatformops/oasgen-provider-chart) for installation instructions.
