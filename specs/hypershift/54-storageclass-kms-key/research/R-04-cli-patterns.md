# R-04: HCP CLI and HyperShift Dev CLI Patterns

## CLI Architecture

Both CLIs share the same underlying code:
- **HCP CLI (productized)**: `product-cli/` — binary name `hcp`
- **HyperShift dev CLI**: `cmd/` — binary name `hypershift`

Both delegate to `cmd/cluster/aws/create.go` for AWS cluster creation.

## Flag Binding Pattern

```
bindCoreOptions(opts, flags)     ← shared by both CLIs (all KMS flags here)
├── HCP CLI: opts.Credentials.BindProductFlags(flags)   ← --role-arn, --sts-creds
└── Dev CLI: BindDeveloperOptions adds --iam-json, --single-nat-gateway, --aws-creds (deprecated)
```

Adding a flag to `bindCoreOptions` exposes it in **both CLIs** automatically.

## Existing KMS Flags

| Flag | Struct Field | API Spec Path |
|------|-------------|---------------|
| `--kms-key-arn` | `RawCreateOptions.EtcdKMSKeyARN` | `HostedCluster.Spec.SecretEncryption.KMS.AWS.ActiveKey.ARN` |
| `--root-volume-kms-key` | `RawCreateOptions.RootVolumeEncryptionKey` | `NodePool.Spec.Platform.AWS.RootVolume.EncryptionKey` |

## Wiring Pattern (Etcd KMS as Example)

1. CLI flag `--kms-key-arn` → `RawCreateOptions.EtcdKMSKeyARN`
2. Passed to IAM creation → creates KMS provider IAM role with KMS permissions
3. IAM output → `results.KMSKeyARN` and `results.KMSProviderRoleARN`
4. `ApplyPlatformSpecifics` → builds `HostedCluster.Spec.SecretEncryption.KMS.AWS`

## What to Add

1. New field in `RawCreateOptions`: e.g., `StorageKMSKeyARN string`
2. New flag in `bindCoreOptions`: e.g., `--storage-kms-key-arn`
3. Wire in `ApplyPlatformSpecifics` to set the new field on `HostedCluster.Spec.Platform.AWS` (or wherever the API field lives)
4. No IAM role creation needed — the existing `StorageARN` role in `AWSRolesRef` should already have KMS permissions (needs verification)

## NodePool Create Commands

Both CLIs also have standalone nodepool create commands under `cmd/nodepool/aws/create.go` and `product-cli/cmd/nodepool/aws/create.go`. The StorageClass KMS key is cluster-level, not nodepool-level, so no nodepool changes needed.
