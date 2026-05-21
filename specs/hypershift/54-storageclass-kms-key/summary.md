# Summary — Export KMS Key ARN for Initial StorageClass in HyperShift

## Artifact Inventory

| Artifact | Location | Count |
|----------|----------|-------|
| Questions (Q-NN) | idea-honing.md | 11 (Q-01 to Q-11) |
| Research topics (R-NN) | research/ | 5 (R-01 to R-05) |
| Requirements (CATEGORY-NN) | [kms.md](../../requirements/kms.md), [cli.md](../../requirements/cli.md) | 9 (KMS-01 to KMS-07, CLI-01 to CLI-02) |
| Acceptance criteria (AC-NN) | design.md | 10 (AC-01 to AC-10) |
| Design decisions (D-NN) | design.md | 3 (D-01 to D-03) |
| Stories (STORY-NN) | plan.md | 4 (STORY-01 to STORY-04) |

## Design Overview

The feature adds a `StorageKMSKeyARN` field to `AWSPlatformSpec` on the HostedCluster API, enabling ROSA HCP customers to specify a customer-managed KMS key (or alias) for encrypting default StorageClass PVCs. The propagation chain is:

**HostedCluster → HC controller → HostedControlPlane → HCCO → ClusterCSIDriver → CSI operator → StorageClass → PVC (encrypted)**

Key architectural decisions:
- **D-01:** Field placed directly on `AWSPlatformSpec` (not nested struct)
- **D-02:** CEL validation with alias ARN support, matching downstream ClusterCSIDriver CRD
- **D-03:** Active KMS probe in HCCO (not CPO) — StorageARN trust policy requires HCP namespace context

## Story Sequence

| Story | Title | Requirements | ACs |
|-------|-------|-------------|-----|
| STORY-01 | API field + CEL validation | KMS-01, KMS-05, KMS-07 | AC-01, AC-05, AC-08 |
| STORY-02 | HC → HCP → ClusterCSIDriver propagation | KMS-02, KMS-03, KMS-04 | AC-02, AC-03, AC-04 |
| STORY-03 | HCCO KMS validation + condition | KMS-06 | AC-06, AC-07 |
| STORY-04 | CLI flag + E2E test | CLI-01, CLI-02 | AC-09, AC-10 |

Dependency chain: STORY-01 → STORY-02 → STORY-03 → STORY-04

## Requirements by Domain

- **KMS** (7 requirements): API field, encryption propagation, day-2 mutability, clearing, format validation, status condition, backward compatibility
- **CLI** (2 requirements): HCP CLI and dev CLI flag support

## Areas for Further Refinement

- **IAM credential mechanism in HCCO:** The exact code path for assuming the StorageARN role in the HCCO needs investigation during STORY-03 implementation (the `ebs-cloud-credentials` provisioning mechanism is the starting point)
- **E2E test infrastructure:** STORY-04's E2E test requires a KMS key and appropriate IAM permissions in the test account — test infrastructure setup should be planned before STORY-04 begins
