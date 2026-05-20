# R-02: ClusterCSIDriver API and DriverConfig

## ClusterCSIDriver Spec Structure

```
ClusterCSIDriverSpec
├── OperatorSpec (inline: LogLevel, OperatorLogLevel, ManagementState)
├── StorageClassState (StorageClassStateName)
└── DriverConfig (CSIDriverConfigSpec)
    ├── DriverType (CSIDriverType)
    ├── AWS → AWSCSIDriverConfigSpec
    │   ├── KMSKeyARN (string, omitempty)
    │   └── EFSVolumeMetrics (*AWSEFSVolumeMetrics)
    ├── Azure → AzureCSIDriverConfigSpec
    ├── GCP → GCPCSIDriverConfigSpec
    ├── IBMCloud → IBMCloudCSIDriverConfigSpec
    └── VSphere → VSphereCSIDriverConfigSpec
```

Source: `vendor/github.com/openshift/api/operator/v1/types_csi_cluster_driver.go`

## AWSCSIDriverConfigSpec.KMSKeyARN

```go
type AWSCSIDriverConfigSpec struct {
    KMSKeyARN string `json:"kmsKeyARN,omitempty"`
    EFSVolumeMetrics *AWSEFSVolumeMetrics `json:"efsVolumeMetrics,omitempty"`
}
```

- Plain string with `omitempty` — no pointer, no required marker
- Setting to empty string is equivalent to omitting (reverts to AWS default encryption)
- No CEL rule preventing removal (unlike etcd backup which has `kmsKeyARN cannot be removed once set`)

## Current State in HyperShift

- `ReconcileClusterCSIDriver` only sets `OperatorSpec` fields (LogLevel, ManagementState)
- **Zero references** to `.DriverConfig`, `AWSCSIDriverConfigSpec`, or `CSIDriverConfigSpec` in any non-vendor HyperShift code
- The HCCO never touches `DriverConfig` — it's currently unmanaged by HyperShift
- `CreateOrUpdate` preserves existing fields not explicitly set, so any guest-cluster CSI config is left intact

## Clearing Behavior

Setting `KMSKeyARN` to empty string (or omitting it) effectively clears it. The CSI operator in the guest cluster will then recreate the StorageClass without a KMS key, reverting to AWS default encryption. No special "removal prevention" exists on this field.

## Key Finding

The `ClusterCSIDriver.Spec.DriverConfig.AWS.KMSKeyARN` field already exists in the vendored API and supports clearing. HyperShift just needs to start setting it during reconciliation.
