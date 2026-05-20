---
epic_issue: 54
project: hypershift
jira: OCPSTRAT-1679
---

# Export KMS Key ARN for Initial StorageClass in HyperShift

## Problem

For ROSA HCP clusters on AWS, customers need to specify a custom KMS key ARN to encrypt PVCs created by the default StorageClass. Currently:

- Direct StorageClass edits are reverted by the CSI driver operator
- The workaround (setting CSIClusterDriver spec.storageClassState to Unmanaged) is brittle — it loses managed lifecycle and requires handling future incompatible changes

## Existing Infrastructure

The CSI operator already supports `ClusterCSIDriver.spec.driverConfig.aws.kmsKeyARN` (introduced via openshift/enhancements#1163, STOR-870). When set, the CSI operator propagates the KMS key into the default StorageClass automatically.

## Proposed Solution

HyperShift needs to:
1. Add a KMS key ARN field to the HostedCluster API (AWS platform spec)
2. Update `ReconcileClusterCSIDriver` in `control-plane-operator/hostedclusterconfigoperator/controllers/resources/storage/reconcile.go` to propagate the KMS key ARN into `driver.Spec.DriverConfig.AWS.KMSKeyARN` in the guest cluster

The CSI operator in the guest cluster handles the rest — no CSI operator changes needed.

## References

- Jira: OCPSTRAT-1679
- Enhancement: openshift/enhancements#1163
- Related story: STOR-870
- Existing KMS key pattern for volumes: hypershift/api/hypershift/v1beta1/nodepool_types.go#L910
- Reconcile code: hypershift/control-plane-operator/hostedclusterconfigoperator/controllers/resources/storage/reconcile.go

## Scope

- Platform: AWS only
- Architecture: x86-64 and ARM (ROSA-HCP multi-arch)
- Deployment: Hosted Control Planes only
- Backport: 4.14+ (all supportable ROSA-HCP versions)
