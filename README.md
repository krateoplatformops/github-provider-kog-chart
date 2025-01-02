# GitHub Provider Helm Chart

This Helm chart provides a template for deploying an application that utilizes OpenAPI Specifications (OAS). It includes ConfigMaps to store the OAS content, a Deployment to run the application, and a Service to expose it.

## Installation

To install the chart, use the following command:

```sh
helm install my-release ./chart
```

Replace `my-release` with your desired release name.

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
