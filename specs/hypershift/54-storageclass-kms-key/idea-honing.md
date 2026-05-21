# Idea Honing — StorageClass KMS Key for HyperShift

Requirements clarification through structured Q&A.

## Q-01: What is the scope of the KMS key — per StorageClass or per CSI driver?

**Answer:** One KMS key ARN, scoped to the EBS CSI driver via `ClusterCSIDriver.spec.driverConfig.aws.kmsKeyARN`. The CSI operator handles propagating it to the default StorageClass(es). No per-StorageClass targeting is needed — the existing CSI operator mechanism handles that. (Source: OCPSTRAT-1679 description, user context, enhancement PR #1163)

## Q-02: Should customers be able to update the KMS key ARN after cluster creation (day-2), or is this install-time only?

**Answer:** Yes, the field should be mutable day-2. The CSI operator already supports this — it deletes and recreates the StorageClass with the new key. Side effects: existing PVs keep their original key (if that key is later disabled in AWS, those volumes become inaccessible — document this). Brief StorageClass gap during rotation is safe on 4.13+ (Kubernetes handles pending PVCs). Running pods with mounted volumes are unaffected.

## Q-03: Should the KMS key ARN be validated before propagation?

**Answer:** Yes, follow whatever ARN validation pattern already exists in HyperShift (e.g., the NodePool rootVolume KMS key ARN validation). Research needed to identify the existing validation approach.

## Q-04: Should the KMS key ARN field be optional or required for AWS HostedClusters?

**Answer:** Optional. When not set, existing behavior is preserved (AWS default encryption). Only propagated to ClusterCSIDriver when explicitly provided.

## Q-05: Should clearing the KMS key ARN (setting it back to empty) revert the StorageClass to AWS default encryption?

**Answer:** Yes, if ClusterCSIDriver supports clearing the field to revert to default encryption. Research needed to confirm this behavior.

## Q-06: Are there any RBAC or permission considerations for who can set the KMS key ARN?

**Answer:** Standard HostedCluster RBAC — no special permissions needed. If the cluster's IAM role lacks KMS access, volume provisioning will fail at the AWS level, not at the API level.

## Q-07: Does the KMS key ARN need to be propagated to any other component beyond ClusterCSIDriver?

**Answer:** Likely only ClusterCSIDriver, but research needed to confirm no other components (hypershift-operator, monitoring, status conditions) need awareness of the key.

## Q-08: Should the KMS key ARN be surfaced in the HostedCluster status or conditions?

**Answer:** Yes. Add a `ValidAWSStorageKMSConfig` condition following the `ValidAWSKMSConfig` pattern: CPO assumes the `StorageARN` role via `AssumeRoleWithWebIdentity`, calls KMS `Encrypt` to probe the key, and sets the condition on HCP status. The HC controller bubbles it up to HostedCluster status. No additional IAM permissions needed — the `StorageARN` role must already have KMS access for the feature to work. Additionally, generic storage operator degradation already propagates via the CVO chain (ClusterOperator "storage" → ClusterVersion → HCP → HC), providing a secondary signal.

## Q-09: Is the HCP CLI in scope for this epic?

**Answer:** Yes, three CLI surfaces are in scope: the HyperShift API, the HCP CLI (productized), and the HyperShift dev CLI. Research needed to find precedence for how other fields were added across all three.

## Q-10: Are there any specific testing requirements beyond standard unit and e2e tests?

**Answer:** Yes, needs an e2e test that creates a cluster with a KMS key ARN, creates a PVC, and verifies the resulting EBS volume is encrypted with the specified key. Unit tests for API validation and reconcile logic as well.

## Q-11: What backport strategy is expected?

**Answer:** Follow the standard OpenShift z-stream backport process. Backporting is OUT OF SCOPE for this epic. A separate OCPSTRAT will be created for the backport effort after the feature lands on `main`. Target for this epic: `main` branch only.
