# KMS Key Management

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| KMS-01 | The HyperShift API MUST allow customers to specify an optional KMS key ARN for encrypting the default StorageClass PVCs on AWS HostedClusters | must-have | #54/Q-01, #54/Q-04 |
| KMS-02 | When a KMS key ARN is specified, PVCs created by the default StorageClass MUST be encrypted with the specified key | must-have | #54/Q-01, #54/Q-07 |
| KMS-03 | The KMS key ARN MUST be mutable after cluster creation (day-2 operation) | must-have | #54/Q-02 |
| KMS-04 | When the KMS key ARN is cleared, the default StorageClass MUST revert to AWS default encryption | must-have | #54/Q-05 |
| KMS-05 | The system MUST validate the KMS key ARN format and reject invalid values with a clear error message | must-have | #54/Q-03 |
| KMS-06 | The system MUST report the validity of a configured StorageClass KMS key via a dedicated status condition on the HostedCluster | must-have | #54/Q-08 |
| KMS-07 | When no KMS key ARN is specified, existing default StorageClass behavior MUST be preserved | must-have | #54/Q-04 |
