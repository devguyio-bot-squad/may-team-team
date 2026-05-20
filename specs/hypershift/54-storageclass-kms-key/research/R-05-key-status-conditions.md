# R-05: Key-Related Status Conditions in HyperShift

## Existing Key-Related Conditions

| Condition Type | Platform | Purpose |
|---------------|----------|---------|
| `ValidAWSKMSConfig` | AWS | Validates etcd encryption KMS key + IAM role |
| `ValidAzureKMSConfig` | Azure | Validates Azure Key Vault encryption key |

Defined in `api/hypershift/v1beta1/hostedcluster_conditions.go:159-165`.

No conditions exist for: root volume encryption keys, GCP KMS, IBM Cloud KMS, or StorageClass KMS keys.

## Validation Pattern (AWS KMS)

Set in CPO controller `validateAWSKMSConfig` (`hostedcontrolplane_controller.go:2915`):

| Scenario | Status | Reason |
|----------|--------|--------|
| KMS not configured | `Unknown` | `StatusUnknown` |
| Cannot assume KMS IAM role | `False` | `InvalidIAMRole` |
| KMS `Encrypt` call fails | `False` | `AWSError` |
| KMS `Encrypt` succeeds | `True` | `AsExpected` |

**Active probe**: Actually calls AWS KMS `Encrypt` API to verify the key works.

## Bubble-Up Pattern

1. CPO sets condition on `HostedControlPlane.Status.Conditions`
2. HC controller copies condition to `HostedCluster.Status.Conditions` with adjusted `ObservedGeneration`

Code in `hostedcluster_controller.go:862-882`:
```go
validKMSConfig := meta.FindStatusCondition(hcp.Status.Conditions, string(hyperv1.ValidAWSKMSConfig))
if validKMSConfig != nil {
    validKMSConfig.ObservedGeneration = hcluster.Generation
    meta.SetStatusCondition(&hcluster.Status.Conditions, *validKMSConfig)
}
```

## KMS Conditions Do NOT Affect Availability

`ValidAWSKMSConfig` and `ValidAzureKMSConfig` are independent signals — they do not gate `Available` or `Degraded` conditions.

## Expected Healthy States

In `support/conditions/conditions.go:51-63`:
- AWS with KMS configured → `ValidAWSKMSConfig = True`
- AWS without KMS → `ValidAWSKMSConfig = Unknown`

## Applicability to StorageClass KMS Key

The existing KMS conditions perform **active probes** (call KMS API). For the StorageClass KMS key, HyperShift only propagates the ARN to ClusterCSIDriver — it doesn't call KMS directly. Options:

1. **No new condition** — propagation is a simple reconcile; failures surface as ClusterCSIDriver/StorageClass events in the guest cluster
2. **Propagation confirmation condition** — confirm the ARN was successfully written to ClusterCSIDriver (lighter than an active probe)
3. **Reuse active probe pattern** — call KMS `Encrypt` like the etcd encryption validation does (heavier, requires IAM permissions)

Given the existing pattern and user preference for status reporting (Q-08), option 2 or 3 is appropriate. Research existing key status condition patterns to decide.

## Reason Constants Available

| Constant | Value | Usage |
|----------|-------|-------|
| `StatusUnknownReason` | `"StatusUnknown"` | Feature not configured |
| `AsExpectedReason` | `"AsExpected"` | Validation succeeded |
| `InvalidIAMRoleReason` | `"InvalidIAMRole"` | Role assumption failed |
| `AWSErrorReason` | `"AWSError"` | AWS API call failed |
