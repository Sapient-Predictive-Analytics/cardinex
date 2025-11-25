# ECG Privacy Marketplace - Architecture Documentation

## Executive Summary

This document details the architecture of a privacy-preserving ECG data marketplace built on Cardano using Zero-Knowledge Proofs (ZKPs). The system enables patients to monetize their medical data while maintaining complete privacy, and allows ML/AI researchers to access verified, anonymized datasets for training algorithms.

## System Components

### 1. Off-Chain Components

#### 1.1 Proof Generator (Rust + Halo2)
**Purpose**: Generate zero-knowledge proofs about ECG data without revealing patient identity.

**Input**:
- ECG data (raw readings)
- Patient metadata (age, gender, conditions)
- Patient ID (hashed, never revealed)

**Output**:
- ZK proof (1-2 KB)
- Public inputs (what's proven)
- Data commitment (hash)

**Key Functions**:
```rust
analyze_ecg() -> ECGAnalysis
generate_proof() -> (proof_bytes, public_inputs)
encrypt_data() -> (encrypted_data, encryption_key)
```

#### 1.2 Client Libraries (TypeScript)

**Provider Client**:
```typescript
class DataProvider {
  async submitECGData(
    ecgData: ECGData,
    metadata: PatientMetadata
  ): Promise<TxHash>
  
  async withdrawPayment(datasetId: string): Promise<TxHash>
}
```

**Researcher Client**:
```typescript
class Researcher {
  async queryDatasets(
    criteria: SearchCriteria
  ): Promise<Dataset[]>
  
  async purchaseAccess(
    datasetId: string
  ): Promise<DecryptionKey>
}
```

#### 1.3 Data Storage (IPFS/Arweave)
Encrypted ECG data stored off-chain with on-chain references.

### 2. On-Chain Components (Cardano L1)

#### 2.1 Aiken Smart Contract

**Validator**: `ecg_marketplace.ak`

**Responsibilities**:
1. Verify ZK proofs via Halo2-Plutus
2. Manage dataset UTxOs
3. Handle payments (ADA)
4. Issue access tokens

**State Machine**:
```
┌─────────────┐
│  AVAILABLE  │ ──┐
└─────────────┘   │
       │          │ UpdatePrice
       │          │
       ├──────────┘
       │
       │ PurchaseAccess
       ▼
┌─────────────┐
│    SOLD     │
└─────────────┘
       │
       │ WithdrawPayment
       ▼
┌─────────────┐
│  WITHDRAWN  │
└─────────────┘
```

**Datum**:
```aiken
type MarketplaceDatum {
  commitment: ProofCommitment,
  status: DatasetStatus,
  access_token: Option<AccessToken>,
}
```

**Redeemers**:
- `SubmitProof`: Data provider submits new dataset
- `PurchaseAccess`: Researcher buys access
- `WithdrawPayment`: Provider withdraws funds
- `UpdatePrice`: Provider updates price

#### 2.2 Halo2-Plutus Verifier (Deployed by IOG)

**Purpose**: Verify Halo2 ZK proofs on-chain.

**Interface**:
```
verify(
  proof: ByteArray,
  public_inputs: List<FieldElement>,
  vk_hash: ByteArray
) -> Bool
```

**Integration**: Called by Aiken validator via reference input pattern.

## Data Models

### ECG Data Structure

```typescript
interface ECGData {
  readings: number[];        // Heart signal over time
  sampleRate: number;        // Hz (e.g., 250 Hz)
  duration: number;          // seconds
  deviceId: string;          // Measurement device
  timestamp: Date;           // When measured
  patientIdHash: Buffer;     // Hash of patient ID (never revealed)
}
```

### Patient Metadata (Binned)

```typescript
interface PatientMetadata {
  gender: 'Male' | 'Female' | 'Other';
  ageBin: '0-20' | '20-40' | '40-60' | '60-80' | '80+';
  geography: 'NA' | 'SA' | 'EU' | 'AS' | 'AF' | 'OC';
  conditions: {
    diabetes: boolean;
    hypertension: boolean;
    heartDisease: boolean;
    obesity: boolean;
    smoking: boolean;
  };
}
```

### ECG Analysis Results

```typescript
interface ECGAnalysis {
  hasArrhythmia: boolean;
  hasTachycardia: boolean;
  hasBradycardia: boolean;
  hasAbnormalQRS: boolean;
  qualityScore: number;      // 0-100
}
```

## Privacy Guarantees

### What's Hidden (Zero-Knowledge)

1. **Patient Identity**
   - No name, SSN, or identifying information
   - Only irreversible hash used internally

2. **Raw ECG Data**
   - Never stored on-chain
   - Encrypted off-chain
   - Only decryption key released after purchase

3. **Exact Metadata**
   - Exact age → Age bin
   - Exact location → Geographic region
   - Never reveals precise information

### What's Revealed (Public Inputs)

1. **ECG Properties**
   - Has arrhythmia: Yes/No
   - Has tachycardia: Yes/No
   - Quality score: 0-100

2. **Binned Metadata**
   - Gender category
   - Age range
   - Geographic region
   - Condition flags

3. **Data Commitment**
   - Hash of encrypted data (for verification)

### ZK Proof Guarantees

The Halo2 proof cryptographically proves:

```
∃ (ecg_data, patient_id, encryption_key) such that:

1. ecg_data correctly produces the claimed ECG analysis
   e.g., analyze_ecg(ecg_data) = {has_arrhythmia: true, ...}

2. patient_id correctly bins to claimed metadata
   e.g., bin_age(patient_id.age) = "40-60"

3. data_commitment = Hash(ecg_data || encryption_key)

WITHOUT revealing (ecg_data, patient_id, encryption_key)
```

## Security Model

### Threat Model

**Actors**:
1. Data Providers (patients)
2. Researchers (data consumers)
3. Malicious actors

**Assets to Protect**:
1. Patient identity
2. Raw medical data
3. Payment integrity
4. Proof validity

### Security Properties

#### 1. Privacy (Zero-Knowledge)
**Property**: Patient identity and raw data remain hidden.

**Mechanism**: ZK proofs prove properties without revealing data.

**Attack**: Malicious researcher tries to de-anonymize patient.

**Defense**: No identifying information in public inputs; only bins.

#### 2. Authenticity
**Property**: Proofs are valid and not forged.

**Mechanism**: Halo2-Plutus verifier checks cryptographic proof.

**Attack**: Attacker submits fake proof claiming false properties.

**Defense**: Proof verification fails on-chain; transaction rejected.

#### 3. Payment Integrity
**Property**: Correct payment flows from researcher to provider.

**Mechanism**: Aiken validator enforces payment in ADA.

**Attack**: Researcher tries to purchase without paying.

**Defense**: Validator checks payment output; rejects if missing.

#### 4. Data Availability
**Property**: After purchase, researcher can access data.

**Mechanism**: Access token with decryption key issued on-chain.

**Attack**: Provider refuses to provide decryption key.

**Defense**: Decryption key committed in original proof; verifiable.

### Known Limitations

1. **Front-running**: Researchers could see pending transactions.
   - *Mitigation*: Use commit-reveal scheme.

2. **Sybil attacks**: One patient creates multiple fake datasets.
   - *Mitigation*: Require stake or reputation system.

3. **Data quality**: Fake ECG data passed off as real.
   - *Mitigation*: Quality scores, community ratings.

## Performance Analysis

### Off-Chain (Proof Generation)

**Hardware**: Modern laptop (8 cores, 16GB RAM)

**Timing**:
- ECG analysis: ~100ms
- Halo2 proof generation: ~2-5 seconds
- Data encryption: ~50ms

**Total**: ~5 seconds per dataset

**Scalability**: Parallelizable; can generate 100s of proofs/minute.

### On-Chain (Verification)

**Blockchain**: Cardano L1

**Resources**:
- Execution units: ~1-2M (estimated)
- Memory units: ~500K (estimated)
- Transaction size: ~5 KB

**Cost**: ~1-2 ADA per verification

**Throughput**: Limited by Cardano block size (~90KB/block, 20s blocks)
- Estimate: ~100-200 verifications per block
- ~300-600 verifications per minute

**Optimization**: Batch verifications to reduce costs.

## Economic Model

### Pricing

**Provider sets price**: e.g., 5 ADA per dataset

**Marketplace fee**: 0.5% (optional, for maintenance)

**Researcher pays**: 5.025 ADA (5 + 0.025 fee)

**Provider receives**: 5 ADA

### Revenue Streams

1. **Data Providers (Patients)**
   - Earn ADA for each dataset sold
   - Passive income from medical data
   - Control over who purchases

2. **Marketplace Operator**
   - Small fee per transaction
   - Optional premium features

3. **Researchers**
   - Access to verified, privacy-preserving datasets
   - No need to recruit patients directly
   - Lower cost than traditional studies

### Market Size (Estimated)

**Potential Providers**: 1M patients with wearable ECG devices

**Potential Researchers**: 10K ML researchers + 1K pharma companies

**Average Price**: 5 ADA per dataset

**Market Cap**: 1M datasets × 5 ADA = 5M ADA

**Transaction Volume**: 100K purchases/year = 500K ADA/year

## Comparison with Alternatives

### vs. Traditional Medical Studies

| Aspect | Traditional | ECG Privacy dApp |
|--------|-------------|------------------|
| **Patient Recruitment** | Slow, expensive | Fast, global |
| **Privacy** | IRB, consent forms | Cryptographic ZK proofs |
| **Cost** | $50-100 per patient | 5 ADA (~$2-10) |
| **Time** | Months | Minutes |
| **Data Quality** | Variable | Verified on-chain |

### vs. Midnight Network (Future)

| Aspect | Current (Cardano L1) | Midnight (2026) |
|--------|---------------------|-----------------|
| **Maturity** | Available now | Q1-Q3 2026 |
| **Language** | Halo2 (Rust) | Compact (TypeScript) |
| **Ease** | Manual integration | Out-of-the-box |
| **Performance** | 1-2 ADA/proof | TBD (likely lower) |
| **Privacy** | Selective disclosure | Full privacy layer |

**Recommendation**: Start with Cardano L1 now, migrate to Midnight when mature.

## Regulatory Compliance

### HIPAA (US)

**Requirement**: No PHI (Protected Health Information) disclosed.

**Compliance**: ✓ No patient names, SSNs, or exact ages on-chain.

**Note**: Still requires Business Associate Agreement (BAA) for data handling.

### GDPR (EU)

**Requirement**: Data minimization, right to erasure.

**Compliance**: 
- ✓ Only binned data on-chain
- ✓ Raw data stored off-chain (can be deleted)
- ✓ Blockchain only contains hashes

**Caveat**: Blockchain immutability conflicts with "right to be forgotten".
- *Solution*: Only commitments on-chain, actual data off-chain.

### FDA (Medical Devices)

**Requirement**: If used for diagnosis, requires FDA approval.

**Status**: This is a data marketplace, not a diagnostic tool.

**Action**: Ensure researchers comply with regulations for AI/ML models.

## Roadmap

### Q4 2025 (Current)
- [x] Architecture design
- [x] Prototype Aiken validator
- [x] Prototype Halo2 proof generator
- [ ] Connect to Halo2-Plutus verifier

### Q1 2026
- [ ] Testnet deployment
- [ ] Client library (TypeScript)
- [ ] Basic UI for providers/researchers
- [ ] Integration testing

### Q2 2026
- [ ] Security audit
- [ ] Gas optimization
- [ ] Mainnet deployment
- [ ] Community testing

### Q3 2026
- [ ] Midnight integration (when launched)
- [ ] Advanced features (reputation, batching)
- [ ] Mobile app
- [ ] Partnerships with wearable device companies

## Future Enhancements

1. **Multi-Modal Data**
   - Extend beyond ECG to other medical data
   - Blood pressure, glucose, sleep, etc.

2. **Reputation System**
   - Track provider data quality
   - Researcher ratings

3. **Machine Learning Integration**
   - On-chain model verification
   - Proof that model was trained on claimed datasets

4. **Cross-Chain**
   - Bridge to Ethereum for DeFi liquidity
   - Integration with other medical data protocols

5. **DAO Governance**
   - Community controls fees
   - Data standards voting

## Conclusion

This architecture provides a practical, privacy-preserving solution for medical data marketplaces on Cardano. By leveraging ZK proofs, it protects patient identity while enabling valuable medical research.

**Key Innovations**:
1. First medical data marketplace with on-chain ZK verification
2. Cardano-native using Aiken (easier than Plutus)
3. Selective disclosure via Halo2 proofs
4. Economic incentives for data providers

**Next Steps**:
1. Connect to deployed Halo2-Plutus verifier
2. Test on Cardano testnet
3. Security audit before mainnet

---

**Version**: 0.1.0  
**Last Updated**: November 2025  
**Authors**: [Your Team]  
**License**: MIT (Prototype)
