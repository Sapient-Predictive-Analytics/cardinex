# Cardinex – ZK-Private Cardiology AI - please vote for us in Fund-15🙏

Cardiology AI relies on rich ECG and PPG datasets, but hospitals face a crucial limitation: sharing physiological data often means exposing patient identities or sensitive clinical histories. Even with anonymisation, health providers remain concerned about regulatory risk, cross-border compliance, and the permanent nature of digital data leakage. This prevents clinics from contributing to shared datasets, and locks advanced AI models away from the medical teams that need them most.

![Cardinex](https://github.com/Sapient-Predictive-Analytics/cardinex/blob/main/media/cardinexFlow_branded.png)

Cardinex addresses this barrier by introducing a privacy-preserving AI layer built on Cardano. The core idea is simple: clinics retain full control of their raw ECG/PPG data, while zero-knowledge proofs (ZKPs) allow external parties to verify dataset quality, consent, and integrity without ever seeing patient identities. At the same time, Sapient’s proprietary cardiology AI can analyse encrypted data, opening a path to collaborative diagnostic research that previously required trust or disclosure.

### User/ML Client/Clinic via API and ZK-Engine
From the clinic’s perspective, the workflow remains straightforward. Records remain in internal storage. A small, local application performs signal preprocessing, produces metadata summaries, and runs a ZK proof generator. Only the proof and non-identifying hashes are submitted to Cardano. There is no transfer of raw signals and no point where patient identity becomes visible to external researchers or buyers.

For AI researchers, Cardinex provides the opposite half of the puzzle: access to data that is mathematically guaranteed to meet certain criteria. Researchers can browse dataset summaries on-chain—compiled from cryptographically verified metadata—knowing that each item has passed strict private validation checks. Once purchased, decryption keys or access tokens can be released through an off-chain workflow tied to the on-chain transaction, enabling secure retrieval of anonymised ECG/PPG bundles that meet the verified criteria.

This creates a trusted marketplace where each party participates without compromising the other:
* Clinics retain custody of their raw data and comply with local regulations.
* Researchers gain reliable, structured cardiology datasets with verified provenance.
* Patients never have their identity exposed.
* Cardano becomes the privacy-assurance layer for cross-clinic medical AI collaboration.

Cardinex makes use of [Aiken](https://github.com/aiken-lang/aiken)-based smart contracts on Cardano for dataset registration, proof verification, and payment interaction. These contracts interact with off-chain ZK components capable of expressing constraints such as:
* demographic category validation,
* consent validity checks,
* dataset size thresholds,
* verification that metadata summaries accurately represent the underlying encrypted records,
* lineage and integrity checks for auditability.
  
This separation of concerns—proof generation off-chain, verification on-chain—plays to Cardano’s strengths and keeps the system efficient even with modest transaction volumes.

For developers and ecosystem builders, Cardinex offers a reusable blueprint: a lightweight ZK integration architecture using Cardano for provenance, access control, and settlement. For Cardano itself, this demonstrates a high-value enterprise use case in regulated healthcare, showcasing how zero-knowledge proofs can enable new categories of dApps beyond DeFi and NFTs.

[Sapient Predictive Analytics](https://sapientswarm.com/) brings extensive experience in AI and data science, allowing the consortium to focus the Catalyst-funded effort on the privacy infrastructure, ZK circuits, and Cardano integration—while leveraging our existing cardiology AI models for realistic prototyping. The result is a credible pathway toward real adoption: clinics can finally collaborate on stronger AI without exposing sensitive patient data, and Cardano becomes the network that guarantees privacy, consent, and integrity across borders.

All code is released under an MIT license, enabling Cardano developers, ZK researchers, Midnight teams, and enterprise partners to reuse or extend it without friction. The architecture is modular, so circuits, provers, or identity frameworks (DIDs, VCs, or upcoming Midnight primitives) can be swapped in as the ecosystem evolves. This reduces long-term maintenance costs while ensuring the prototype remains relevant as Cardano’s privacy stack matures.

Cardinex aims to deliver a working prototype demonstrating the full workflow—from clinic data preparation to proof generation, on-chain verification, and controlled AI analysis access. This grant will enable the research, engineering, and ecosystem integration needed to validate the model and prepare for real-world deployment with partner clinics.
