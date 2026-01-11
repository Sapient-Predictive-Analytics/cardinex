## Cardinex: ZK-Private Cardiology AI
### A Fund-15 Use Case: Launch project to showcase Cardano Halo2 for Cardiology AI training data

![Cardinex](https://github.com/Sapient-Predictive-Analytics/cardinex/blob/main/media/cardinexFlow.png)

Cardinex is a proof-of-concept proposal in Fund for an MVP that demonstrates how sensitive medical data can be transformed into high-value AI training signals without exposing any personal patient information. Building on Cardano’s recently launched, frontier Halo2 zero-knowledge proof verification, Cardinex will enable cardiology clinics and hospitals we currently work with in Singapore, the United States, and Korea to contribute clinically meaningful datasets while remaining fully compliant with privacy, ethical, and regulatory constraints.

![Cardinex](https://github.com/Sapient-Predictive-Analytics/cardinex/blob/main/media/halo2cardinex.png)

Modern cardiovascular medicine produces vast volumes of data from ECG, PPG, echocardiography, and MRI systems, yet most of this information remains siloed inside institutions. Hospitals face considerable legal, reputational, and regulatory risks if they share patient data, even when stripped of obvious identifiers. At the same time, AI systems designed to detect early-stage disease, predict deterioration, or guide therapy require diverse, high-quality, real-world datasets that can only be obtained through large-scale collaboration across borders and providers. 

The Cardinex model reframes what is being shared. Clinics never transmit raw medical records or images. Instead, they process their data locally, extracting clinically relevant features, embeddings, and statistical summaries using approved algorithms. These outputs may include signal quality metrics, diagnostic labels, waveform characteristics, or latent representations suitable for machine learning. From these processed datasets, the clinic generates a Halo2 zero-knowledge proof that cryptographically attests to their authenticity, integrity, and compliance. The proof asserts that the data was derived from real patients, captured by real devices, processed using specified algorithms, passed quality thresholds, and contains no personally identifiable information, without revealing any of the underlying data itself.

![Cardinex](https://github.com/Sapient-Predictive-Analytics/cardinex/blob/main/media/ECG_class.jpg)
*Open source datasets exists, but their frequent use introduce bias and more independent data is needed to improve algorithm accuracy. The major obstacle to this is privacy risk.*

Cardinex establishes a new economic and governance model for medical data, starting with Sapient’s existing work in Cardiology. Clinics are no longer forced to choose between keeping data locked away or risking liability through sharing. Instead, they can participate in a transparent, cryptographically enforced marketplace that rewards high-quality data contributions while maintaining absolute patient confidentiality. Researchers and AI developers gain access to provably real, diverse, and compliant datasets without needing to negotiate complex data-sharing agreements or trust opaque intermediaries. Feasibility of this with real use cases would offer strong proof of concept for many other medical patient privacy problems. By anchoring medical truth on Cardano while keeping patient identities invisible, it points toward a future in which life-saving AI can be trained on the world’s data without compromising the rights of the people behind it.

The proposal can easily be seen in the Voting App searching for **Sapient** or **Cardinex** and the full use case request is available on [Catalyst Voices](https://reviews.projectcatalyst.io/proposal/1787)
