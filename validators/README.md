# Cardinex On-Chain Validators

**DRAFT VERSION - MVP IN DEVELOPMENT**  
**NOT AUDITED - DO NOT USE IN PRODUCTION**

This directory contains the Aiken smart contract validators for the Cardinex privacy-preserving medical data marketplace.

## Directory Structure

```
on-chain/
├── aiken.toml                           # Aiken project configuration
├── lib/
│   └── types.ak                         # Type definitions
└── validators/
    └── cardinex_marketplace.ak          # Main marketplace validator
```

## Overview

The Cardinex validators implement a marketplace for privacy-preserving ECG datasets where:

1. **Healthcare providers** submit proof commitments with zero-knowledge proofs
2. **ML researchers** purchase access to datasets that meet their criteria
3. **Payments** flow automatically via smart contracts
4. **Privacy** is maintained cryptographically throughout

## Type Definitions (`lib/types.ak`)

Core data types used throughout the validators:

- `Gender`, `AgeBin`, `GeographyRegion` - Binned demographic categories
- `MedicalConditions` - Boolean flags for patient conditions
- `ECGAnalysis` - Verified properties of ECG data
- `ProofCommitment` - On-chain commitment to dataset + proof
- `MarketplaceDatum` - UTxO state for each dataset
- `MarketplaceRedeemer` - Actions that can be performed
- `Halo2Proof` - Zero-knowledge proof wrapper

## Main Validator (`validators/cardinex_marketplace.ak`)

State machine with three states:

- **Available**: Dataset listed and can be purchased
- **Sold**: Dataset purchased, access token issued
- **Withdrawn**: Provider has withdrawn payment (terminal state)

### Redeemers (Actions)

**SubmitProof**
- Healthcare provider submits new dataset with ZK proof
- Validates: proof correctness, commitment structure, provider signature
- Requires: Halo2-Plutus verifier integration

**PurchaseAccess { researcher_pubkey }**
- Researcher purchases dataset
- Validates: payment to provider, researcher signature, access token creation
- Transitions: Available → Sold

**WithdrawPayment**
- Provider withdraws payment after sale
- Validates: dataset is sold, provider signature, payment flows
- Requires: Sold status

**UpdatePrice { new_price }**
- Provider updates dataset price
- Validates: dataset available, price reasonable (0.1-1000 ADA), provider signature
- Requires: Available status

## Building

```bash
# Install Aiken
curl -sSfL https://install.aiken-lang.org | bash

# Check syntax
aiken check

# Build validators
aiken build

# Run tests
aiken test
```

Output will be in `plutus.json` containing the compiled validators.

## Integration Points

### Halo2-Plutus Verifier

The validator integrates with the Halo2-Plutus verifier deployed on Cardano mainnet (November 2024). The integration points are marked in the code:

```aiken
fn verify_halo2_proof(proof: Halo2Proof, commitment: ProofCommitment) -> Bool {
  // NOTE: Integration with deployed Halo2-Plutus verifier required
  // This would call the verifier smart contract on Cardano mainnet
  // ...
}
```

For production deployment, implement:
1. Reference input pattern to include verifier output
2. Public input encoding for BLS12-381 field elements
3. Proof extraction from transaction metadata

### Public Inputs Encoding

Public inputs are encoded as field elements for the Halo2 verifier:

```aiken
[
  has_arrhythmia,      // 0x00 or 0x01
  has_tachycardia,     // 0x00 or 0x01
  has_bradycardia,     // 0x00 or 0x01
  has_abnormal_qrs,    // 0x00 or 0x01
  quality_score,       // 0-100 as 32-byte integer
  gender,              // 0x00, 0x01, 0x02
  age_bin,             // 0x00-0x04
  diabetes,            // 0x00 or 0x01
  hypertension,        // 0x00 or 0x01
  heart_disease,       // 0x00 or 0x01
]
```

These must match exactly between off-chain proof generation and on-chain verification.

## Testing

Current tests are placeholders. Production deployment requires:

- Unit tests for each redeemer
- Property-based tests for state transitions
- Integration tests with Halo2 verifier
- Adversarial tests (double-purchase, etc.)

## Security Considerations

**⚠️ This is MVP code and has NOT been audited. Do not use in production.**

Known limitations:
1. Halo2 verifier integration is placeholder
2. No formal verification performed
3. Gas costs not optimized
4. Limited test coverage
5. Access control relies on signature checks (standard but should be audited)

Before mainnet deployment:
- Complete Halo2 integration
- Formal security audit
- Adversarial testing
- Gas optimization
- Comprehensive test suite

## Transaction Examples

### Submit Dataset

```
Input:  User UTxO (payment)
Output: Script UTxO (dataset) + Change
Datum:  MarketplaceDatum { Available, commitment, None }
Redeemer: SubmitProof
Metadata: Halo2 proof bytes
```

### Purchase Dataset

```
Input:  Script UTxO (dataset) + Researcher UTxO (payment)
Output: Script UTxO (dataset + token) + Provider UTxO (payment) + Change
Datum:  MarketplaceDatum { Sold, commitment, Some(token) }
Redeemer: PurchaseAccess { researcher_pubkey }
```

### Withdraw Payment

```
Input:  Script UTxO (sold dataset)
Output: Provider UTxO (payment)
Redeemer: WithdrawPayment
```

## Next Steps

1. Complete Halo2-Plutus verifier integration
2. Deploy to Cardano preprod testnet
3. Integration testing with off-chain components
4. Security audit
5. Gas optimization
6. Mainnet deployment

## Resources

- [Aiken Documentation](https://aiken-lang.org/)
- [Cardano Developer Portal](https://developers.cardano.org/)
- [Halo2-Plutus Verifier](https://github.com/input-output-hk/halo2-plutus-verifier)
- [Cardinex Lightpaper](../../LIGHTPAPER.md)

## License

MIT License - See LICENSE file

Copyright (c) 2025 Sapient Predictive Analytics Pte Ltd

---

**Status**: Pre-Alpha / Proof of Concept  
**Last Updated**: November 2025
