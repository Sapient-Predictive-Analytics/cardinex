// Cardinex - Privacy-Preserving Medical Data Marketplace
// Type Definitions for Smart Contract Validators
//
// DRAFT VERSION - MVP IN DEVELOPMENT
// NOT AUDITED - DO NOT USE IN PRODUCTION
//
// Copyright (c) 2025 Sapient Predictive Analytics Pte Ltd
// Licensed under MIT License

use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}

// =============================================================================
// Patient Metadata Types (Binned for Privacy)
// =============================================================================

pub type Gender {
  Male
  Female
  Other
}

pub type AgeBin {
  Age0To20
  Age20To40
  Age40To60
  Age60To80
  Age80Plus
}

pub type GeographyRegion {
  NorthAmerica
  SouthAmerica
  Europe
  Asia
  Africa
  Oceania
}

pub type MedicalConditions {
  diabetes: Bool,
  hypertension: Bool,
  heart_disease: Bool,
  obesity: Bool,
  smoking: Bool,
}

// =============================================================================
// ECG Analysis and Proof Commitment Types
// =============================================================================

pub type ECGAnalysis {
  has_arrhythmia: Bool,
  has_tachycardia: Bool,
  has_bradycardia: Bool,
  has_abnormal_qrs: Bool,
  quality_score: Int,
}

pub type PatientMetadata {
  gender: Gender,
  age_bin: AgeBin,
  geography: GeographyRegion,
  conditions: MedicalConditions,
}

pub type ProofCommitment {
  proof_hash: ByteArray,
  ecg_analysis: ECGAnalysis,
  patient_metadata: PatientMetadata,
  data_reference: ByteArray,
  provider_key: Hash<Blake2b_224, VerificationKey>,
  price: Int,
  submitted_at: Int,
}

// =============================================================================
// Marketplace State Types
// =============================================================================

pub type AccessToken {
  commitment_ref: ByteArray,
  researcher_key: Hash<Blake2b_224, VerificationKey>,
  encrypted_decryption_key: ByteArray,
  purchased_at: Int,
}

pub type DatasetStatus {
  Available
  Sold
  Expired
}

pub type MarketplaceDatum {
  commitment: ProofCommitment,
  status: DatasetStatus,
  access_token: Option<AccessToken>,
}

pub type MarketplaceRedeemer {
  SubmitProof
  PurchaseAccess { researcher_pubkey: ByteArray }
  WithdrawPayment
  UpdatePrice { new_price: Int }
}

// =============================================================================
// Zero-Knowledge Proof Types (Halo2 Integration)
// =============================================================================

pub type Halo2Proof {
  proof_bytes: ByteArray,
  public_inputs: List<ByteArray>,
  vk_hash: ByteArray,
}

pub type VerificationResult {
  Valid
  Invalid { reason: ByteArray }
}
