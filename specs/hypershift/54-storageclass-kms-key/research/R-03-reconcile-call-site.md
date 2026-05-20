# R-03: ReconcileClusterCSIDriver Call Site

## Call Chain

```
Reconcile() [resources.go:336]
  → fetches full HostedControlPlane from mgmt cluster
  → reconcileStorageAndMisc(ctx, log, hcp, releaseImage) [resources.go:452]
    → checks IsStorageAndCSIManaged(hcp) (true for AWS)
    → reconcileStorage(ctx, hcp) [resources.go:3416]
      → switch hcp.Spec.Platform.Type → determines driver names
      → for AWS: driverNames = [AWSEBSCSIDriver]
      → CreateOrUpdate loop:
        → storage.ReconcileClusterCSIDriver(driver) [resources.go:3455]
```

## Data Available at Call Site

The `reconcileStorage` method has `hcp *hyperv1.HostedControlPlane` with full access to:
- `hcp.Spec.Platform.Type` (already used for driver name dispatch)
- `hcp.Spec.Platform.AWS` (Region, RolesRef, CloudProviderConfig, ResourceTags, etc.)
- Other code in the same file already accesses `hcp.Spec.Platform.AWS` extensively (e.g., `reconcileCloudCredentialSecrets` reads `AWS.Region` and `AWS.RolesRef.StorageARN`)

## What Needs to Change

1. **Add a new field** to the HostedCluster/HostedControlPlane API for the StorageClass KMS key ARN
2. **Modify `ReconcileClusterCSIDriver`** signature to accept the HCP or the KMS key ARN
3. **Set `driver.Spec.DriverConfig`** with `DriverType: AWSDriverType` and `AWS.KMSKeyARN` when the field is provided
4. **Update the call site** in `reconcileStorage` to pass the KMS key from `hcp.Spec.Platform.AWS`

## Pattern for Platform-Specific Config

The call site already dispatches on platform type. The KMS key propagation would naturally fit inside the existing `case hyperv1.AWSPlatform:` block, or the reconcile function itself could be made platform-aware.

## Manifest Construction

`manifests.ClusterCSIDriver(name)` creates a bare `ClusterCSIDriver` with only `ObjectMeta.Name` set to the driver name (e.g., `ebs.csi.aws.com`). The reconcile function populates the spec fields.
