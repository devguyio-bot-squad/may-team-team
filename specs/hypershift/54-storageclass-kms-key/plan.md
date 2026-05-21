# Story Breakdown — Export KMS Key ARN for Initial StorageClass in HyperShift

## Checklist

- [ ] STORY-01: Add StorageKMSKeyARN API field with CEL validation
- [ ] STORY-02: Propagate KMS key through HC → HCP → ClusterCSIDriver
- [ ] STORY-03: HCCO KMS key validation and condition reporting
- [ ] STORY-04: CLI flag and end-to-end test

---

## STORY-01: Add StorageKMSKeyARN API field with CEL validation

**Title:** Add StorageKMSKeyARN field to AWSPlatformSpec with CEL validation

**Objective:** Introduce the `StorageKMSKeyARN` field on the HyperShift API so that customers can specify a KMS key or alias ARN for default StorageClass encryption. CEL admission validation ensures only well-formed ARNs are accepted. This story lays the foundation for all subsequent stories.

**Implementation Guidance:**
- Add `StorageKMSKeyARN string` to `AWSPlatformSpec` in `api/hypershift/v1beta1/aws.go` with CEL validation rule, MaxLength=2048, `+optional`, and `omitempty`
- Add `ValidAWSStorageKMSConfig` condition type constant in `api/hypershift/v1beta1/hostedcluster_conditions.go`
- Register the new condition in `ExpectedHCConditions` in `support/conditions/conditions.go` — expected state `ConditionUnknown` when not configured
- Run `make generate` to regenerate CRDs, deepcopy, and client code

**Test Requirements:**
- Unit tests for CEL validation: valid key ARN accepted, valid alias ARN accepted, invalid formats rejected (missing prefix, wrong partition, malformed key ID, exceeds MaxLength, trailing characters)
- Unit test: `ExpectedHCConditions` returns `ConditionUnknown` for `ValidAWSStorageKMSConfig` when no storage KMS is configured
- Verify CRD generation succeeds with the new field

**Integration:** Foundational story — all subsequent stories depend on this API type. After this story, the field exists on the CRD but is not yet propagated or acted upon.

**Demo:** Create or update a HostedCluster with `storageKMSKeyARN` set to a valid ARN — the API accepts it. Set an invalid ARN — the API rejects with a clear error message. Clusters without the field are unaffected.

**Requirements:** KMS-01, KMS-05, KMS-07
**Acceptance Criteria:** AC-01, AC-05, AC-08
**Dependencies:** —

---

## STORY-02: Propagate KMS key through HC → HCP → ClusterCSIDriver

**Title:** Mirror storageKMSKeyARN to HCP and propagate to ClusterCSIDriver

**Objective:** Wire the full propagation chain so that a KMS key ARN set on a HostedCluster reaches the guest cluster's ClusterCSIDriver, causing the CSI operator to configure the default StorageClass with the customer's key. This delivers the core encryption functionality.

**Implementation Guidance:**
- HC controller: add `storageKMSKeyARN` to the existing `AWSPlatformSpec` field mirroring from HostedCluster to HostedControlPlane
- HCCO `reconcileStorage`: read `hcp.Spec.Platform.AWS.StorageKMSKeyARN` and pass to `ReconcileClusterCSIDriver`
- `ReconcileClusterCSIDriver`: when KMS key is non-empty, set `driver.Spec.DriverConfig` with `DriverType: AWSDriverType` and `AWS.KMSKeyARN`; when empty, clear `DriverConfig` to revert to AWS default encryption
- The CSI operator handles StorageClass configuration from ClusterCSIDriver — no changes needed downstream

**Test Requirements:**
- Unit tests for HC controller: verify `storageKMSKeyARN` mirrored from HC to HCP
- Unit tests for `ReconcileClusterCSIDriver`: verify `DriverConfig.AWS.KMSKeyARN` set when non-empty, cleared when empty (covers day-2 update and clear scenarios, plus downgrade safety)
- Unit tests for mirroring: verify field round-trips correctly for both key ARNs and alias ARNs

**Integration:** Depends on STORY-01 (API type). After this story, setting the field on a HostedCluster causes PVCs in the guest cluster to be encrypted with the customer's key. Day-2 key rotation and clearing work end-to-end. Note: encryption is wired but unvalidated until STORY-03 lands — a syntactically valid but inaccessible key will cause opaque PVC provisioning failures until the condition probe surfaces the issue.

**Demo:** Set `storageKMSKeyARN` on a HostedCluster → verify ClusterCSIDriver in the guest cluster has `driverConfig.aws.kmsKeyARN` set → create a PVC → verify the EBS volume is encrypted with the specified key. Update the ARN → new PVCs use the new key. Clear the ARN → new PVCs use default encryption.

**Requirements:** KMS-02, KMS-03, KMS-04
**Acceptance Criteria:** AC-02, AC-03, AC-04
**Dependencies:** STORY-01

---

## STORY-03: HCCO KMS key validation and condition reporting

**Title:** Add ValidAWSStorageKMSConfig condition with active KMS probe in HCCO

**Objective:** Provide fast, actionable feedback on whether the configured KMS key is valid and accessible by adding an active validation probe in the HCCO and surfacing the result as a status condition on the HostedCluster.

**Implementation Guidance:**
- Add `validateAWSStorageKMSConfig` function in the HCCO resources controller
- When `storageKMSKeyARN` is empty: set condition `Unknown` / `StatusUnknown` with message `"Storage KMS is not configured"`
- When non-empty: assume the `StorageARN` role (using the same credential mechanism that provisions `ebs-cloud-credentials`), call KMS `Encrypt` with a test payload
- On success: set `True` / `AsExpected` with message `"Storage KMS key is valid and accessible"`
- On failure: set `False` with `AWSError` or `InvalidIAMRole` reason; message MUST include the failing ARN, the AWS error code/message, and a remediation hint
- HC controller: add bubble-up logic for `ValidAWSStorageKMSConfig` from HCP to HC status (follow the `ValidAWSKMSConfig` pattern — copy only if present on HCP)

**Test Requirements:**
- Unit tests for validation function: mock KMS client to test all condition states (Unknown, True, False/AWSError, False/InvalidIAMRole)
- Unit tests for condition messages: verify failing ARN and remediation hint included in False condition messages
- Unit test for HC controller: verify condition bubbled from HCP to HC status

**Integration:** Depends on STORY-01 (condition constant) and STORY-02 (HC→HCP mirroring required for end-to-end validation). Completes the feedback loop — after this story, users get fast, actionable status on whether their KMS key is valid.

**Demo:** Set a valid, accessible KMS key ARN → `ValidAWSStorageKMSConfig=True` appears on HostedCluster status. Set a key ARN with insufficient permissions → condition shows `False` with a message explaining the issue and how to fix it. Remove the key → condition reverts to `Unknown`.

**Requirements:** KMS-06
**Acceptance Criteria:** AC-06, AC-07
**Dependencies:** STORY-01, STORY-02

---

## STORY-04: CLI flag and end-to-end test

**Title:** Add --storage-volumes-kms-key CLI flag and E2E test

**Objective:** Expose the storage KMS key ARN configuration through both CLIs and validate the complete feature end-to-end, from CLI flag to encrypted EBS volumes.

**Implementation Guidance:**
- Add `StorageKMSKeyARN string` field to `RawCreateOptions`
- Add `--storage-volumes-kms-key` flag in `bindCoreOptions` (automatically exposed in both HCP and dev CLIs)
- Wire in `ApplyPlatformSpecifics` to set `HostedCluster.Spec.Platform.AWS.StorageKMSKeyARN`
- Write E2E test exercising the full chain: create cluster with flag → verify condition True → create PVC → verify EBS encryption via AWS API → update key → verify new PVCs → clear key → verify default encryption

**Test Requirements:**
- Unit tests for CLI: verify `--storage-volumes-kms-key` parsed correctly, wired to HostedCluster spec
- E2E test: full lifecycle test covering happy path (creation + PVC encryption), key rotation, key clearing, and condition verification
- E2E regression: cluster created without the flag behaves identically to before

**Integration:** Depends on STORY-01 (API type), STORY-02 (propagation), and STORY-03 (validation). This is the final story — after completion, the full feature is delivered and verified.

**Demo:** Run `hcp create cluster aws --storage-volumes-kms-key <ARN>` → cluster created with storage encryption → PVCs encrypted with customer key → condition confirms validity. Run with dev CLI (`hypershift create cluster aws --storage-volumes-kms-key <ARN>`) → same result.

**Requirements:** CLI-01, CLI-02
**Acceptance Criteria:** AC-09, AC-10
**Dependencies:** STORY-01, STORY-02, STORY-03
