# R-01: Existing KMS/ARN Patterns in HyperShift API

## KMS Key Fields Inventory

| Field | API Path | Validation | Purpose |
|-------|----------|------------|---------|
| `Volume.EncryptionKey` | `nodePool.spec.platform.aws.rootVolume.encryptionKey` | `MaxLength=2048` only | Node root volume encryption |
| `AWSKMSKeyEntry.ARN` | `hostedCluster.spec.secretEncryption.kms.aws.activeKey.arn` | `Pattern=^arn:`, `MaxLength=2048` | Etcd secret encryption |
| `AWSKMSAuthSpec.AWSKMSRoleARN` | `hostedCluster.spec.secretEncryption.kms.aws.auth.awsKms` | `MaxLength=2048` only | KMS auth role |
| `HCPEtcdBackupS3.KMSKeyARN` | `hcpEtcdBackup.spec.storage.s3.kmsKeyARN` | Full CEL regex + immutable | Etcd backup S3 encryption |
| `AWSSharedVPCRolesRef` ARNs | `hostedCluster.spec.platform.aws.sharedVPC.rolesRef.*` | Full IAM ARN regex | SharedVPC IAM roles |

## Three Validation Levels

1. **No validation** — `Volume.EncryptionKey`, most `AWSRolesRef` role ARNs. Accept any string.
2. **Minimal prefix** — `AWSKMSKeyEntry.ARN` uses `Pattern=^arn:` (must start with "arn:").
3. **Full CEL regex** — Etcd backup types use `^arn:(aws|aws-cn|aws-us-gov):kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$`. SharedVPC uses full IAM role ARN regex.

## Validation Approach

Per `.claude/rules/webhook-validation.md`, new validation MUST use CEL rules, not webhooks. The etcd backup types are the gold standard for KMS ARN validation in this codebase.

## HostedCluster AWS Platform Spec

`AWSPlatformSpec` (`api/hypershift/v1beta1/aws.go:329-433`) contains: `Region`, `CloudProviderConfig`, `ServiceEndpoints`, `RolesRef`, `ResourceTags`, `EndpointAccess`, `AdditionalAllowedPrincipals`, `MultiArch`, `SharedVPC`. No KMS key fields currently exist at this level.

## Key Finding

There is no existing field on the HostedCluster spec for StorageClass KMS encryption. A new field needs to be added — likely to `AWSPlatformSpec` or a new storage-related section of the spec.
