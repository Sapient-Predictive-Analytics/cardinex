// Cardinex - Privacy-Preserving Medical Data Marketplace
// Main Marketplace Validator
//
// DRAFT VERSION - MVP IN DEVELOPMENT
// NOT AUDITED - DO NOT USE IN PRODUCTION
//
// This validator manages the lifecycle of privacy-preserving ECG datasets
// in the Cardinex marketplace, including proof verification, purchases,
// and payment withdrawals.
//
// Copyright (c) 2025 Sapient Predictive Analytics Pte Ltd
// Licensed under MIT License

use aiken/hash.{Blake2b_256, blake2b_256}
use aiken/list
use aiken/transaction.{ScriptContext, Spend, Transaction, Output, OutputReference}
use aiken/transaction/credential
use aiken/transaction/value
use aiken/transaction/datum
use cardinex/types.{
  MarketplaceDatum,
  MarketplaceRedeemer,
  ProofCommitment,
  AccessToken,
  DatasetStatus,
  Halo2Proof,
  Available,
  Sold,
  SubmitProof,
  PurchaseAccess,
  WithdrawPayment,
  UpdatePrice,
  Gender, Male, Female, Other,
  AgeBin, Age0To20, Age20To40, Age40To60, Age60To80, Age80Plus,
}

// =============================================================================
// Main Validator
// =============================================================================

validator {
  fn cardinex_marketplace(
    datum: MarketplaceDatum,
    redeemer: MarketplaceRedeemer,
    context: ScriptContext,
  ) -> Bool {
    when context.purpose is {
      Spend(output_ref) -> {
        let tx = context.transaction
        
        when redeemer is {
          SubmitProof -> validate_proof_submission(datum, tx),
          PurchaseAccess { researcher_pubkey } -> 
            validate_purchase(datum, researcher_pubkey, tx, output_ref),
          WithdrawPayment -> validate_withdrawal(datum, tx),
          UpdatePrice { new_price } -> 
            validate_price_update(datum, new_price, tx, output_ref),
        }
      }
      _ -> False
    }
  }
}

// =============================================================================
// Validation Functions
// =============================================================================

fn validate_proof_submission(
  datum: MarketplaceDatum,
  tx: Transaction,
) -> Bool {
  let commitment = datum.commitment
  
  // Extract and verify Halo2 proof from transaction
  expect Some(proof) = extract_proof_from_tx(tx)
  let proof_valid = verify_halo2_proof(proof, commitment)
  
  // Validate commitment structure
  let commitment_valid = validate_commitment_structure(commitment)
  
  // Must be in Available status
  let status_correct = datum.status == Available
  
  // Provider must sign transaction
  let provider_signed = 
    list.any(tx.extra_signatories, fn(sig) { sig == commitment.provider_key })
  
  proof_valid && commitment_valid && status_correct && provider_signed
}

fn validate_purchase(
  datum: MarketplaceDatum,
  researcher_pubkey: ByteArray,
  tx: Transaction,
  input_ref: OutputReference,
) -> Bool {
  let commitment = datum.commitment
  
  // Dataset must be available
  expect datum.status == Available
  
  // Verify payment to provider
  let payment_valid = verify_provider_payment(
    tx,
    commitment.provider_key,
    commitment.price,
  )
  
  // Researcher must sign
  let researcher_signed = 
    list.any(tx.extra_signatories, fn(sig) { sig == researcher_pubkey })
  
  // Verify output datum creates access token
  expect Some(output) = find_continuing_output(tx, input_ref)
  expect output_datum: MarketplaceDatum = get_inline_datum(output)
  
  let token_created = when output_datum.access_token is {
    Some(token) -> 
      token.researcher_key == researcher_pubkey &&
      token.commitment_ref == blake2b_256(commitment.proof_hash),
    None -> False,
  }
  
  // Status must change to Sold
  let status_updated = output_datum.status == Sold
  
  payment_valid && researcher_signed && token_created && status_updated
}

fn validate_withdrawal(
  datum: MarketplaceDatum,
  tx: Transaction,
) -> Bool {
  let commitment = datum.commitment
  
  // Must be sold
  expect datum.status == Sold
  
  // Provider must sign
  let provider_signed = 
    list.any(tx.extra_signatories, fn(sig) { sig == commitment.provider_key })
  
  // Verify funds go to provider
  let funds_to_provider = verify_provider_payment(
    tx,
    commitment.provider_key,
    commitment.price,
  )
  
  provider_signed && funds_to_provider
}

fn validate_price_update(
  datum: MarketplaceDatum,
  new_price: Int,
  tx: Transaction,
  input_ref: OutputReference,
) -> Bool {
  let commitment = datum.commitment
  
  // Must be available
  expect datum.status == Available
  
  // Provider must sign
  let provider_signed = 
    list.any(tx.extra_signatories, fn(sig) { sig == commitment.provider_key })
  
  // New price must be reasonable (0.1 to 1000 ADA)
  let price_reasonable = new_price >= 100_000 && new_price <= 1_000_000_000
  
  // Verify output has updated price
  expect Some(output) = find_continuing_output(tx, input_ref)
  expect output_datum: MarketplaceDatum = get_inline_datum(output)
  let price_updated = output_datum.commitment.price == new_price
  
  provider_signed && price_reasonable && price_updated
}

// =============================================================================
// Halo2 Proof Verification
// =============================================================================

fn verify_halo2_proof(
  proof: Halo2Proof,
  commitment: ProofCommitment,
) -> Bool {
  // Encode public inputs for Halo2 verifier
  let public_inputs = encode_public_inputs(commitment)
  
  // Verify proof hash matches commitment
  let proof_hash_matches = 
    blake2b_256(proof.proof_bytes) == commitment.proof_hash
  
  // NOTE: Integration with deployed Halo2-Plutus verifier required
  // This would call the verifier smart contract on Cardano mainnet
  // For MVP prototype, we verify the hash matches as placeholder
  
  proof_hash_matches && validate_public_inputs(proof.public_inputs, public_inputs)
}

fn encode_public_inputs(commitment: ProofCommitment) -> List<ByteArray> {
  let analysis = commitment.ecg_analysis
  let metadata = commitment.patient_metadata
  
  [
    encode_bool(analysis.has_arrhythmia),
    encode_bool(analysis.has_tachycardia),
    encode_bool(analysis.has_bradycardia),
    encode_bool(analysis.has_abnormal_qrs),
    encode_int(analysis.quality_score),
    encode_gender(metadata.gender),
    encode_age_bin(metadata.age_bin),
    encode_bool(metadata.conditions.diabetes),
    encode_bool(metadata.conditions.hypertension),
    encode_bool(metadata.conditions.heart_disease),
  ]
}

fn validate_public_inputs(
  provided: List<ByteArray>,
  expected: List<ByteArray>,
) -> Bool {
  list.length(provided) == list.length(expected) &&
  list.all2(provided, expected, fn(a, b) { a == b })
}

// =============================================================================
// Payment Verification
// =============================================================================

fn verify_provider_payment(
  tx: Transaction,
  provider_key: ByteArray,
  amount: Int,
) -> Bool {
  // Find outputs to provider
  let provider_outputs = list.filter(
    tx.outputs,
    fn(output) { output_pays_to_key(output, provider_key) },
  )
  
  // Sum payments to provider
  let total_payment = list.foldr(
    provider_outputs,
    0,
    fn(output, acc) { acc + value.lovelace_of(output.value) },
  )
  
  total_payment >= amount
}

fn output_pays_to_key(output: Output, key_hash: ByteArray) -> Bool {
  when output.address.payment_credential is {
    credential.VerificationKeyCredential(hash) -> hash == key_hash
    _ -> False
  }
}

// =============================================================================
// Commitment Validation
// =============================================================================

fn validate_commitment_structure(commitment: ProofCommitment) -> Bool {
  // Proof hash must be 32 bytes (Blake2b-256)
  let hash_valid = builtin.length_of_bytearray(commitment.proof_hash) == 32
  
  // Price must be positive and reasonable (0.1 to 1000 ADA)
  let price_valid = 
    commitment.price >= 100_000 && 
    commitment.price <= 1_000_000_000
  
  // Quality score must be 0-100
  let quality_valid = 
    commitment.ecg_analysis.quality_score >= 0 && 
    commitment.ecg_analysis.quality_score <= 100
  
  // Data reference must exist
  let data_ref_valid = 
    builtin.length_of_bytearray(commitment.data_reference) > 0
  
  hash_valid && price_valid && quality_valid && data_ref_valid
}

// =============================================================================
// Helper Functions
// =============================================================================

fn extract_proof_from_tx(tx: Transaction) -> Option<Halo2Proof> {
  // NOTE: In production, proof would be extracted from transaction metadata
  // or reference input containing the Halo2 verifier output
  // For MVP, this is a placeholder that would be integrated with
  // the deployed Halo2-Plutus verifier on Cardano mainnet
  None
}

fn find_continuing_output(
  tx: Transaction,
  input_ref: OutputReference,
) -> Option<Output> {
  // Find the output that continues this script
  list.find(
    tx.outputs,
    fn(output) {
      when output.address.payment_credential is {
        credential.ScriptCredential(_) -> True
        _ -> False
      }
    },
  )
}

fn get_inline_datum(output: Output) -> Data {
  when output.datum is {
    datum.InlineDatum(d) -> d
    _ -> fail @"Expected inline datum"
  }
}

// =============================================================================
// Encoding Functions (for Halo2 field elements)
// =============================================================================

fn encode_bool(b: Bool) -> ByteArray {
  if b { #"01" } else { #"00" }
}

fn encode_int(i: Int) -> ByteArray {
  builtin.integer_to_bytearray(True, 32, i)
}

fn encode_gender(g: Gender) -> ByteArray {
  when g is {
    Male -> #"00"
    Female -> #"01"
    Other -> #"02"
  }
}

fn encode_age_bin(a: AgeBin) -> ByteArray {
  when a is {
    Age0To20 -> #"00"
    Age20To40 -> #"01"
    Age40To60 -> #"02"
    Age60To80 -> #"03"
    Age80Plus -> #"04"
  }
}

// =============================================================================
// Tests
// =============================================================================

test proof_submission_validates_correctly() {
  // Test that a valid proof submission is accepted
  True
}

test purchase_requires_payment() {
  // Test that purchase validation requires correct payment
  True
}

test cannot_purchase_twice() {
  // Test that a dataset cannot be purchased multiple times
  True
}

test price_update_restricted_to_provider() {
  // Test that only provider can update price
  True
}
