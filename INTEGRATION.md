# Halo2-Aiken Integration Guide

This document explains how the Halo2 ZK proof generator integrates with the Aiken smart contract validator.

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        OFF-CHAIN (User)                          │
│                                                                   │
│  1. ECG Data + Patient Metadata                                  │
│     ↓                                                             │
│  2. Halo2 Proof Generator (Rust)                                 │
│     • Analyzes ECG data                                          │
│     • Bins patient metadata                                      │
│     • Generates ZK proof                                         │
│     • Creates public inputs                                      │
│     ↓                                                             │
│  3. Output: (proof_bytes, public_inputs, commitment)             │
│                                                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ Submit to blockchain
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ON-CHAIN (Cardano L1)                          │
│                                                                   │
│  4. Transaction with:                                            │
│     • Proof bytes (in metadata or reference input)               │
│     • Public inputs (in datum)                                   │
│     • Commitment hash                                            │
│     ↓                                                             │
│  5. Halo2-Plutus Verifier (Deployed on Cardano)                  │
│     • Verifies ZK proof is valid                                 │
│     • Checks public inputs match                                 │
│     • Returns: Valid / Invalid                                   │
│     ↓                                                             │
│  6. Aiken Marketplace Validator                                  │
│     • Calls Halo2 verifier                                       │
│     • If valid: Accept proof commitment                          │
│     • Store in UTxO with datum                                   │
│     • Make available for purchase                                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Integration Points

### 1. Proof Generation (Off-chain)

**File**: `off-chain/proof-generator/src/main.rs`

```rust
// Generate proof
let (proof_bytes, public_inputs) = generate_proof(
    ecg_data,
    patient_metadata,
    patient_id
)?;

// Create commitment
let commitment = ProofCommitment {
    proof_hash: blake2b_256(&proof_bytes),
    ecg_analysis: public_inputs.ecg_analysis,
    patient_metadata: public_inputs.patient_metadata,
    data_reference: ipfs_cid,
    provider_key: user_pubkey_hash,
    price: 5_000_000, // 5 ADA
    submitted_at: current_time(),
};
```

### 2. On-chain Verification (Aiken)

**File**: `on-chain/validators/ecg_marketplace.ak`

```aiken
// In the validator
fn verify_halo2_proof(
  proof: Halo2Proof,
  commitment: ProofCommitment
) -> Bool {
  
  // 1. Encode public inputs for Halo2
  let public_inputs = encode_public_inputs(commitment)
  
  // 2. Call Halo2-Plutus verifier
  //    This is the KEY integration point
  halo2_plutus_verifier.verify(
    proof.proof_bytes,
    public_inputs,
    proof.vk_hash
  )
}
```

## Halo2-Plutus Verifier Reference

The Halo2-Plutus verifier was deployed to Cardano mainnet in November 2024 by Input Output Research (IOR).

### Verifier Address
```
# This would be the actual address of the deployed verifier
# To be obtained from IOG documentation
addr_test1... (testnet)
addr1...      (mainnet)
```

### Calling the Verifier

The Halo2-Plutus verifier exposes a verification function that takes:

**Inputs:**
- `proof_bytes`: The Halo2 proof (serialized)
- `public_inputs`: List of field elements (public data)
- `verification_key_hash`: Hash of the circuit's verification key

**Output:**
- `Bool`: True if proof is valid, False otherwise

### Integration in Aiken

Currently, Aiken doesn't have direct bindings to the Halo2-Plutus verifier (as of November 2025). There are two approaches:

#### Option A: Reference Input Pattern (Recommended)

```aiken
validator {
  fn ecg_marketplace(datum, redeemer, context) -> Bool {
    
    // Get Halo2 verifier as reference input
    expect Some(verifier_input) = 
      list.find(context.transaction.reference_inputs, is_halo2_verifier)
    
    // Extract verification result from verifier's datum
    expect halo2_datum: Halo2VerificationDatum = verifier_input.datum
    
    // Check if this proof was verified
    let proof_hash = blake2b_256(extract_proof(context))
    let is_verified = list.any(
      halo2_datum.verified_proofs,
      fn(p) { p == proof_hash }
    )
    
    // Continue with business logic if verified
    is_verified && other_checks(datum, redeemer, context)
  }
}
```

#### Option B: Two-Transaction Pattern

**Transaction 1**: Submit proof to Halo2 verifier
- Input: User's UTxO
- Output: Halo2 verifier UTxO with verified proof commitment
- Scripts: Halo2-Plutus verifier

**Transaction 2**: Submit to marketplace
- Input: Halo2 verifier UTxO (reference input)
- Output: Marketplace UTxO with dataset
- Scripts: Aiken marketplace validator (checks reference)

This is more complex but provides stronger guarantees.

## Public Inputs Format

The public inputs must be formatted as field elements for Halo2. Each input is a value in the BLS12-381 scalar field.

### Encoding Scheme

```rust
// In Rust (off-chain)
pub fn encode_public_inputs(commitment: &ProofCommitment) -> Vec<Fr> {
    vec![
        // ECG Analysis (5 elements)
        Fr::from(commitment.ecg_analysis.has_arrhythmia as u64),
        Fr::from(commitment.ecg_analysis.has_tachycardia as u64),
        Fr::from(commitment.ecg_analysis.has_bradycardia as u64),
        Fr::from(commitment.ecg_analysis.has_abnormal_qrs as u64),
        Fr::from(commitment.ecg_analysis.quality_score as u64),
        
        // Patient Metadata (8 elements)
        Fr::from(commitment.patient_metadata.gender as u64),
        Fr::from(commitment.patient_metadata.age_bin as u64),
        Fr::from(commitment.patient_metadata.geography as u64),
        Fr::from(commitment.patient_metadata.diabetes as u64),
        Fr::from(commitment.patient_metadata.hypertension as u64),
        Fr::from(commitment.patient_metadata.heart_disease as u64),
        Fr::from(commitment.patient_metadata.obesity as u64),
        Fr::from(commitment.patient_metadata.smoking as u64),
        
        // Data commitment (1 element, truncated to field)
        bytes_to_field_element(&commitment.data_commitment),
    ]
}
```

```aiken
// In Aiken (on-chain)
fn encode_public_inputs(commitment: ProofCommitment) -> List<ByteArray> {
  [
    // Same encoding as Rust, but as ByteArrays
    encode_bool(commitment.ecg_analysis.has_arrhythmia),
    encode_bool(commitment.ecg_analysis.has_tachycardia),
    // ... etc
  ]
}
```

**Critical**: The encoding must match EXACTLY between off-chain and on-chain.

## Data Flow Example

### Step-by-Step: Alice Submits ECG Data

**1. Alice runs proof generator locally:**

```bash
$ ./ecg-proof-generator \
    --ecg-file alice_ecg.dat \
    --age-bin 2 \
    --gender 1 \
    --diabetes true \
    --output proof.json

✓ ECG analyzed: Arrhythmia detected, Quality: 87
✓ Proof generated: 1.2 KB
✓ Public inputs: 14 field elements
✓ Data commitment: 0x7f8e9d...
```

**2. Alice submits to Cardano:**

```typescript
// Using a Cardano client library
const tx = await lucid
  .newTx()
  .payToContract(marketplaceAddress, {
    inline: {
      commitment: {
        proof_hash: proofHash,
        ecg_analysis: {
          has_arrhythmia: true,
          // ... other fields
        },
        patient_metadata: {
          gender: "Female",
          age_bin: "Age40To60",
          // ...
        },
        price: 5_000_000n,
        // ...
      },
      status: "Available"
    }
  })
  .attachMetadata(674, { proof: proofBytes }) // Proof in metadata
  .complete();

const signedTx = await tx.sign().complete();
await signedTx.submit();
```

**3. Validator verifies on-chain:**

The Aiken validator:
1. Extracts proof from transaction metadata
2. Extracts public inputs from datum
3. Calls Halo2-Plutus verifier
4. If valid, accepts the UTxO
5. Dataset now available for purchase

**4. Bob (researcher) queries:**

```typescript
// Query marketplace for datasets
const datasets = await lucid.utxosAt(marketplaceAddress);

// Filter by criteria
const matching = datasets.filter(utxo => {
  const datum = utxo.datum;
  return datum.commitment.ecg_analysis.has_arrhythmia === true
    && datum.commitment.patient_metadata.diabetes === true
    && datum.commitment.patient_metadata.age_bin === "Age40To60"
    && datum.status === "Available";
});

console.log(`Found ${matching.length} matching datasets`);
```

**5. Bob purchases access:**

```typescript
const tx = await lucid
  .newTx()
  .collectFrom([dataset_utxo], {
    PurchaseAccess: { researcher_pubkey: bobPubKeyHash }
  })
  .payToAddress(aliceAddress, 5_000_000n) // Pay Alice
  .complete();

// After purchase, Bob receives decryption key to access anonymized ECG data
```

## Current Limitations & Workarounds

### Limitation 1: No Direct Halo2 Bindings in Aiken

**Status**: As of November 2025, there's no official Aiken library to directly call the Halo2-Plutus verifier.

**Workaround**: Use reference input pattern or implement custom bridging logic.

**Future**: IOG/Aiken team may release official bindings in 2026.

### Limitation 2: Proof Size

Halo2 proofs can be 1-2 KB, which may exceed transaction metadata limits.

**Workaround**: Store proof off-chain (IPFS) and only submit proof hash + verification result.

### Limitation 3: Verification Costs

On-chain ZK verification consumes significant execution units.

**Status**: The Halo2-Plutus verifier uses optimized cryptographic primitives, but costs are still ~1-2 ADA per verification.

**Workaround**: Batch verifications or use reference input pattern to amortize costs.

## Testing Strategy

### Off-chain Tests

```bash
cd off-chain/proof-generator
cargo test
```

Tests:
- ECG analysis algorithms
- Proof generation
- Public input encoding
- Commitment calculation

### On-chain Tests

```bash
cd on-chain
aiken test
```

Tests:
- Datum encoding/decoding
- Validator logic (with mocked verifier)
- Payment verification
- Access token issuance

### Integration Tests

Full end-to-end test on testnet:
1. Generate proof off-chain
2. Submit to testnet
3. Verify on-chain
4. Purchase flow
5. Verify researcher receives decryption key

## Next Steps for Development

### Phase 1: Prototype (Current)
- [x] Design architecture
- [x] Implement Aiken validator structure
- [x] Implement Halo2 proof generator structure
- [ ] Connect to Halo2-Plutus verifier (IOG docs)
- [ ] Test on testnet

### Phase 2: Integration
- [ ] Implement reference input pattern
- [ ] Build TypeScript client library
- [ ] Add off-chain data storage (IPFS)
- [ ] Create UI for data providers
- [ ] Create UI for researchers

### Phase 3: Production
- [ ] Security audit
- [ ] Gas optimization
- [ ] Mainnet deployment
- [ ] Documentation & tutorials

## Resources

- [Halo2-Plutus Verifier (IOG)](https://github.com/input-output-hk/halo2-plutus-verifier)
- [Aiken Documentation](https://aiken-lang.org/)
- [Cardano Developer Portal](https://developers.cardano.org/)
- [Proof of Innocence Example](https://github.com/ErgoAi/proof-of-innocence) (Similar architecture)

## Questions for IOG/Community

1. What's the recommended pattern for calling Halo2-Plutus verifier from Aiken?
2. Are there plans for official Aiken bindings?
3. What are the current gas costs for proof verification?
4. Can proofs be batched for efficiency?
5. Best practices for storing large proofs?

---

**Last Updated**: November 2025  
**Status**: Prototype / Proof of Concept  
**Contact**: [Your Team]
