#!/bin/bash

# GHP (GitHub Provider) Startup Script

set -e

NAMESPACE="ghp"
TIMEOUT=600  # 10 minutes timeout for operations
HELM_RELEASE="ghp"
AUTH_FILE="./testdata/gh-auth.yaml"
CHART_PATH="./chart"

echo "========================================="
echo "Starting GHP Installation Process"
echo "========================================="

# Function to wait for condition with timeout
wait_for_condition() {
    local condition_func=$1
    local description=$2
    local timeout=$3
    local check_interval=5
    local elapsed=0
    
    echo "Waiting for: $description"
    
    while ! eval "$condition_func" && [ $elapsed -lt $timeout ]; do
        echo "   Still waiting... (${elapsed}s/${timeout}s)"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo "Timeout waiting for: $description"
        return 1
    fi
    
    echo "Ready: $description"
    return 0
}

# Function to check if all deployments are ready
check_deployments_ready() {
    local expected_deployments=(
        "ghp-collaborator-controller"
        "ghp-repo-controller" 
        "ghp-runnergroup-controller"
        "ghp-teamrepo-controller"
        "ghp-workflow-controller"
    )
    
    for deploy in "${expected_deployments[@]}"; do
        # Check if deployment exists
        if ! kubectl get deployment "$deploy" -n "$NAMESPACE" >/dev/null 2>&1; then
            echo "   Deployment $deploy not found"
            return 1
        fi
        
        # Get deployment status in a more reliable way
        local status=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        local ready_replicas=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        local desired_replicas=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
        
        # Handle empty values
        ready_replicas=${ready_replicas:-0}
        desired_replicas=${desired_replicas:-1}
        
        echo "   Checking $deploy: ready=$ready_replicas, desired=$desired_replicas, available=$status"
        
        # Check if deployment is available and has the right number of ready replicas
        if [ "$status" != "True" ] || [ "$ready_replicas" -ne "$desired_replicas" ] || [ "$ready_replicas" -eq 0 ]; then
            echo "   Deployment $deploy not ready yet"
            return 1
        fi
    done
    
    echo "   All deployments are ready"
    return 0
}

# Function to check if all RestDefinitions are ready
check_restdefinitions_ready() {
    local expected_rds=(
        "ghp-collaborator"
        "ghp-repo"
        "ghp-runnergroup"
        "ghp-teamrepo"
        "ghp-workflow"
    )
    
    for rd in "${expected_rds[@]}"; do
        if ! kubectl get restdefinitions.swaggergen.krateo.io "$rd" -n "$NAMESPACE" >/dev/null 2>&1; then
            echo "   RestDefinition $rd not found"
            return 1
        fi
        
        local ready=$(kubectl get restdefinitions.swaggergen.krateo.io "$rd" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
        
        echo "   Checking RestDefinition $rd: ready=$ready"
        
        if [ "$ready" != "True" ]; then
            echo "   RestDefinition $rd not ready yet"
            return 1
        fi
    done
    
    echo "   All RestDefinitions are ready"
    return 0
}

# Function to check if all GitHub CRDs exist
check_github_crds_exist() {
    local expected_crds=(
        "bearerauths.github.krateo.io"
        "collaborators.github.krateo.io"
        "repoes.github.krateo.io"
        "runnergroups.github.krateo.io"
        "teamrepoes.github.krateo.io"
        "workflows.github.krateo.io"
    )
    
    for crd in "${expected_crds[@]}"; do
        if ! kubectl get crd "$crd" >/dev/null 2>&1; then
            echo "   CRD $crd not found"
            return 1
        fi
    done
    
    echo "   All GitHub CRDs exist"
    return 0
}

# Validate prerequisites
echo "Step 0: Validating prerequisites"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed or not in PATH"
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Error: kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if auth file exists
if [ ! -f "$AUTH_FILE" ]; then
    echo "Error: Authentication file not found at $AUTH_FILE"
    exit 1
fi

echo "Prerequisites validated"

# Step 1: Create namespace if it doesn't exist
echo ""
echo "Step 1: Ensuring namespace exists"
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    kubectl create namespace "$NAMESPACE"
    echo "Namespace $NAMESPACE created"
else
    echo "Namespace $NAMESPACE already exists"
fi

# Step 2: Install Helm chart
echo ""
echo "Step 2: Installing Helm chart"

# Check if release already exists
if helm list -n "$NAMESPACE" | grep -q "$HELM_RELEASE"; then
    echo "Helm release $HELM_RELEASE already exists. Upgrading..."
    helm upgrade "$HELM_RELEASE" "$CHART_PATH" -n "$NAMESPACE"
    echo "Helm chart upgraded"
else
    echo "Installing new Helm release..."
    helm install "$HELM_RELEASE" "$CHART_PATH" -n "$NAMESPACE"
    echo "Helm chart installed"
fi

# Step 3: Wait for deployments to be ready
echo ""
echo "Step 3: Waiting for deployments to be ready"
if wait_for_condition "check_deployments_ready" "all GHP deployments to be ready" $TIMEOUT; then
    echo ""
    echo "Deployment Status:"
    kubectl get deployments -n "$NAMESPACE"
else
    echo "Failed: Deployments did not become ready within timeout"
    echo ""
    echo "Current deployment status:"
    kubectl get deployments -n "$NAMESPACE"
    echo ""
    echo "Pod status:"
    kubectl get pods -n "$NAMESPACE"
    exit 1
fi

# Step 4: Wait for GitHub CRDs to be created
echo ""
echo "Step 4: Waiting for GitHub CRDs to be created"
if wait_for_condition "check_github_crds_exist" "all GitHub CRDs to be created" $TIMEOUT; then
    echo ""
    echo "GitHub CRDs Status:"
    kubectl get crds | grep github || echo "No GitHub CRDs found"
else
    echo "Failed: GitHub CRDs were not created within timeout"
    echo ""
    echo "Current CRDs:"
    kubectl get crds | grep -E "(github|krateo)" || echo "No relevant CRDs found"
    exit 1
fi

# Step 5: Wait for RestDefinitions to be ready
echo ""
echo "Step 5: Waiting for RestDefinitions to be ready"
if wait_for_condition "check_restdefinitions_ready" "all RestDefinitions to be ready" $TIMEOUT; then
    echo ""
    echo "RestDefinitions Status:"
    kubectl get restdefinitions.swaggergen.krateo.io -n "$NAMESPACE"
else
    echo "Failed: RestDefinitions did not become ready within timeout"
    echo ""
    echo "Current RestDefinitions status:"
    kubectl get restdefinitions.swaggergen.krateo.io -n "$NAMESPACE" || echo "No RestDefinitions found"
    echo ""
    echo "Detailed status of RestDefinitions:"
    kubectl get restdefinitions.swaggergen.krateo.io -n "$NAMESPACE" -o wide
    exit 1
fi

# Step 6: Apply authentication configuration
echo ""
echo "Step 6: Applying GitHub authentication configuration"
echo "Applying auth file: $AUTH_FILE"

if kubectl apply -f "$AUTH_FILE"; then
    echo "Authentication configuration applied successfully"
else
    echo "Failed to apply authentication configuration"
    exit 1
fi

# Final verification

echo ""
echo "Final System Status:"
echo ""

echo "Namespace:"
kubectl get namespace "$NAMESPACE"

echo ""
echo "Deployments:"
kubectl get deployments -n "$NAMESPACE"

echo ""
echo "Pods:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "RestDefinitions:"
kubectl get restdefinitions.swaggergen.krateo.io -n "$NAMESPACE"

echo ""
echo "GitHub CRDs:"
kubectl get crds | grep github

echo ""
echo "Authentication Resources:"
kubectl get bearerauths.github.krateo.io -A 2>/dev/null || echo "No BearerAuth resources found yet"

echo ""
echo "GHP installation and configuration completed successfully!"
echo ""