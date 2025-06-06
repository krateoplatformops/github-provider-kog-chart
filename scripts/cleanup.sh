#!/bin/bash

# GHP (GitHub Provider) Cleanup Script

set -e

NAMESPACE="ghp"
TIMEOUT=300  # 5 minutes timeout for operations

echo "========================================="
echo "Starting GHP Cleanup Process"
echo "========================================="

# Function to remove finalizers from a resource
remove_finalizers() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    echo "Removing finalizers from $resource_type/$resource_name"
    kubectl patch $resource_type $resource_name -n $namespace --type='merge' -p='{"metadata":{"finalizers":[]}}' 2>/dev/null || true
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local namespace=$2
    local timeout=$3
    
    echo "Waiting for $resource_type to be deleted..."
    kubectl wait --for=delete $resource_type --all -n $namespace --timeout=${timeout}s 2>/dev/null || true
}

# Step 1: Helm uninstall
echo "Step 1: Uninstalling Helm release 'ghp'"
if helm list -n $NAMESPACE | grep -q ghp; then
    helm uninstall ghp -n $NAMESPACE
    echo "Helm release 'ghp' uninstalled"
else
    echo "Helm release 'ghp' not found or already uninstalled"
fi

# Step 2: Remove RestDefinitions and their finalizers
echo ""
echo "Step 2: Cleaning up RestDefinitions"
REST_DEFINITIONS=$(kubectl get restdefinitions.swaggergen.krateo.io -n $NAMESPACE -o name 2>/dev/null || true)

if [ ! -z "$REST_DEFINITIONS" ]; then
    for rd in $REST_DEFINITIONS; do
        rd_name=$(basename $rd)
        echo "Processing RestDefinition: $rd_name"
        
        # Remove finalizers first
        remove_finalizers "restdefinitions.swaggergen.krateo.io" "$rd_name" "$NAMESPACE"
        
        # Delete the resource
        kubectl delete $rd -n $NAMESPACE --ignore-not-found=true
    done
    
    # Wait for RestDefinitions to be fully deleted
    wait_for_deletion "restdefinitions.swaggergen.krateo.io" "$NAMESPACE" "$TIMEOUT"
    echo "All RestDefinitions removed"
else
    echo "No RestDefinitions found in namespace $NAMESPACE"
fi

# Step 3: Remove GitHub CRDs
echo ""
echo "Step 3: Removing GitHub CRDs"
GITHUB_CRDS=(
    "bearerauths.github.krateo.io"
    "collaborators.github.krateo.io"
    "repoes.github.krateo.io"
    "runnergroups.github.krateo.io"
    "teamrepoes.github.krateo.io"
    "workflows.github.krateo.io"
)

for crd in "${GITHUB_CRDS[@]}"; do
    if kubectl get crd $crd >/dev/null 2>&1; then
        echo "Removing CRD: $crd"
        
        # First, try to delete all instances of this CRD
        crd_kind=$(echo $crd | cut -d'.' -f1)
        kubectl delete $crd_kind --all -A --ignore-not-found=true 2>/dev/null || true
        
        # Remove finalizers from CRD instances if they exist
        kubectl get $crd_kind -A -o name 2>/dev/null | while read resource; do
            if [ ! -z "$resource" ]; then
                resource_name=$(basename $resource)
                resource_ns=$(kubectl get $resource -o jsonpath='{.metadata.namespace}' 2>/dev/null || echo "")
                if [ ! -z "$resource_ns" ]; then
                    remove_finalizers "$crd_kind" "$resource_name" "$resource_ns"
                else
                    kubectl patch $resource --type='merge' -p='{"metadata":{"finalizers":[]}}' 2>/dev/null || true
                fi
            fi
        done
        
        # Now delete the CRD itself
        kubectl delete crd $crd --ignore-not-found=true
        echo "CRD $crd removed"
    else
        echo "CRD $crd not found"
    fi
done

# Step 4: Remove Deployments
echo ""
echo "Step 4: Removing GHP Deployments"
GHP_DEPLOYMENTS=(
    "ghp-collaborator-controller"
    "ghp-repo-controller"
    "ghp-runnergroup-controller"
    "ghp-teamrepo-controller"
    "ghp-workflow-controller"
)

for deploy in "${GHP_DEPLOYMENTS[@]}"; do
    if kubectl get deployment $deploy -n $NAMESPACE >/dev/null 2>&1; then
        echo "Removing deployment: $deploy"
        kubectl delete deployment $deploy -n $NAMESPACE --ignore-not-found=true
        echo "Deployment $deploy removed"
    else
        echo "Deployment $deploy not found"
    fi
done

# Wait for deployments to be fully terminated
echo "Waiting for deployments to terminate..."
wait_for_deletion "deployments" "$NAMESPACE" "$TIMEOUT"

# Step 5: Clean up any remaining resources in the namespace
echo ""
echo "Step 5: Cleaning up remaining resources in namespace $NAMESPACE"

# Remove any remaining pods
kubectl delete pods --all -n $NAMESPACE --ignore-not-found=true --force --grace-period=0 2>/dev/null || true

# Remove any remaining services
kubectl delete services --all -n $NAMESPACE --ignore-not-found=true 2>/dev/null || true

# Remove any remaining configmaps (except kube-root-ca.crt)
kubectl delete configmaps --all -n $NAMESPACE --ignore-not-found=true 2>/dev/null || true

# Remove any remaining secrets (except default service account token)
#kubectl get secrets -n $NAMESPACE -o name | grep -v default-token | xargs -r kubectl delete -n $NAMESPACE 2>/dev/null || true

# Step 6: Optional - Remove the namespace itself
#echo ""
#read -p "Do you want to remove the namespace '$NAMESPACE' entirely? (y/N): " -n 1 -r
#echo
#if [[ $REPLY =~ ^[Yy]$ ]]; then
#    echo "Removing namespace: $NAMESPACE"
#    kubectl delete namespace $NAMESPACE --ignore-not-found=true
#    echo "✓ Namespace $NAMESPACE removed"
#else
#    echo "ℹ Namespace $NAMESPACE preserved"
#fi

echo ""
echo "========================================="
echo "GHP Cleanup Process Completed"
echo "========================================="

# Verification
echo ""
echo "Verification:"
echo "Checking for remaining GitHub CRDs..."
remaining_crds=$(kubectl get crds | grep github || true)
if [ -z "$remaining_crds" ]; then
    echo "No GitHub CRDs found"
else
    echo "Remaining GitHub CRDs:"
    echo "$remaining_crds"
fi

if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo ""
    echo "Checking for remaining resources in namespace $NAMESPACE..."
    kubectl get all -n $NAMESPACE 2>/dev/null || echo "No resources found in namespace $NAMESPACE"
    
    echo ""
    echo "Checking for remaining RestDefinitions..."
    remaining_rd=$(kubectl get restdefinitions.swaggergen.krateo.io -n $NAMESPACE 2>/dev/null || true)
    if [ -z "$remaining_rd" ]; then
        echo "No RestDefinitions found"
    else
        echo "Remaining RestDefinitions:"
        echo "$remaining_rd"
    fi
fi

echo ""
echo "Cleanup script completed successfully!"