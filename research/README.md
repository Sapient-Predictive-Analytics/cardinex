Core open datasets in cardiology

A. ECG / Arrhythmia datasets

These are mostly accessible via PhysioNet, a central hub for physiological data.

MIT-BIH Arrhythmia DatabaseThe grand-daddy of ECG ML. 48 half-hour, 2-lead Holter recordings from 47 subjects, beat-level annotations, used in hundreds of arrhythmia papers. 

MIT-BIH Atrial Fibrillation & other PhysioNet ECG setsSeparate long-term AFib recordings and other rhythm-focused datasets (AF, malignant ventricular ectopy, etc.) – all with expert labels. 

PTB-XL (most complete)

~21k 12-lead ECGs from ~19k patients, 10-second recordings, labeled by up to two cardiologists with 71 diagnostic, rhythm and form labels.

It’s currently the largest freely accessible clinical 12-lead ECG dataset and widely used as a modern benchmark. https://physionet.org/content/ptb-xl/1.0.3/

PhysioNet / Computing-in-Cardiology Challenge datasetsEach Challenge (e.g. 2020) bundles multi-center ECG datasets with standardized tasks such as multi-label rhythm & diagnosis classification. Great for benchmarking and seeing how state-of-the-art models are evaluated. https://physionet.org/content/challenge-2020/1.0.2/

Kaggle ECG Arrhythmia Classification DatasetCombines several PhysioNet arrhythmia sets into preprocessed train/test CSVs – handy if you want to prototype quickly without raw WFDB wrangling. https://www.kaggle.com/datasets/sadmansakib7/ecg-arrhythmia-classification-dataset

Wearable Arrhythmia DatabaseOpen-access 30-second ECG segments (sinus + atrial + ventricular arrhythmias) recorded via wearables, with cardiologist annotations – nice if you’re interested in consumer devices. https://link.springer.com/article/10.1007/s40846-020-00554-3

B. Imaging datasets (MRI + echo etc.)

We already mentioned Cardiac Atlas Project (CAP) – a standardized database of cardiac MRI exams + models. Here’s what else is big and open:

Cardiac MRI (CMR)

ACDC – Automated Cardiac Diagnosis Challenge

Cine MRI from real clinical exams; manual segmentation of LV cavity, myocardium, and RV; labels for several cardiac pathologies.

One of the most popular open CMR datasets for segmentation and diagnosis. https://www.creatis.insa-lyon.fr/Challenge/acdc/databases.html

M&Ms – Multi-Centre, Multi-Vendor, Multi-Disease CMR

Designed specifically to test generalization across scanners, centers, and pathologies; widely used for robust segmentation research. https://www.ub.edu/mnms/

Sunnybrook Cardiac Data (LV Segmentation Challenge)Classic CMR dataset with LV cavity labels; often used for left-ventricular segmentation / EF estimation benchmarks. 

https://www.kaggle.com/datasets/salikhussaini49/sunnybrook-cardiac-mri

OCMR – Ohio State Cardiac MRI Raw Data (AWS Open Data)Multi-coil k-space cine MRI data, open access on AWS Registry of Open Data. Ideal if you want to play with reconstruction, compressed sensing, or generative MRI super-resolution. 

UK Biobank Cardiac MRI

UK Biobank has CMR for tens of thousands of participants, making it the largest cardiac imaging cohort; frequently used for deep learning and population-level phenotyping. https://pmc.ncbi.nlm.nih.gov/articles/PMC7899275

Echocardiography (ultrasound)

EchoNet-Dynamic (Stanford)~10k apical 4-chamber echo videos with expert EF, volumes and LV segmentation masks; a standard dataset for echo video deep learning. https://aimi.stanford.edu/datasets/echonet-dynamic-cardiac-ultrasound

EchoNet-LVH (Stanford)12k echo videos + expert annotations to study left-ventricular hypertrophy; dataset + open-source model available. https://echonet.github.io/lvh/

CAMUS – 2D Echo Segmentation500 patients, 2- and 4-chamber views, manual contours of LV, myocardium and left atrium at ED/ES; one of the largest open 2D echo segmentation datasets. https://www.creatis.insa-lyon.fr/Challenge/camus

For arrhythmia / ECG

MIT-BIH Arrhythmia – small but historic and extremely well-documented; great to start with simple arrhythmia classification, beat segmentation, etc. https://physionet.org/content/mitdb/1.0.0/

PTB-XL – the modern go-to; larger, multi-label, 12-lead, with recommended train/test splits. If you want something that still fits on a laptop but is “real world”, use this.

For cardiac imaging

ACDC – standard MRI segmentation + diagnosis challenge set; like MNIST for cine CMR. 

EchoNet-Dynamic – standard echo video dataset with ready-made baselines from the original Stanford paper.

CAMUS – if you like still images / ED+ES frames and segmentation.

Top choices per modality:

ECG: PTB-XL

Echo: EchoNet-Dynamic

CMR: ACDC

Cutting-edge players & ecosystems

Totally non-exhaustive, but these names pop up a lot in deep cardiology ML:

Stanford University (AIMI / EchoNet group) – EchoNet-Dynamic & EchoNet-LVH datasets and models at the frontier of automated echo analysis. 

UK Biobank community (Imperial, Oxford, etc.) – huge body of work around population-scale CMR and automated pipelines for segmentation and quality control. 

Cardiac Atlas Project consortium – originally from University of Auckland and collaborators; big on statistical atlases, modeling, and now digital twins. 

Emory / Georgia Tech / PhysioNet crowd – Gari Clifford and collaborators have been central to ECG databases and PhysioNet/CinC Challenges. 

MIC / DKFZ (Germany) – creators of nnU-Net, which is used everywhere for medical image segmentation, including CMR and echo. 

MONAI consortium (NVIDIA, NIH, King’s College London, etc.) – driving standardization for deep learning in medical imaging via the MONAI framework. https://github.com/Project-MONAI/MONAI

Recent reviews if you want a birds-eye view:

“Deep Learning in Cardiology” (general overview of ECG & imaging ML) arXiv

“Deep Learning for Cardiovascular Imaging: A Review” (JAMA Cardiology) Ovid

“Artificial Intelligence in Cardiology: Hope for the Future…” and “Artificial Intelligence in Cardiovascular Imaging” cover current use cases and limitations. 

Open-source tools commonly used for Python/PyTorch

Imaging / CMR / Echo

MONAI – PyTorch-based framework specifically for medical imaging (augmentation, 3D nets, pipelines). 

nnU-Net – self-configuring segmentation; you drop in a dataset like ACDC or CAMUS, and it configures the U-Net pipeline for you. 

TorchIO – great for medical image loading, patching, augmentations (MRI/CT/CMR). Medium

SimpleITK – the workhorse for medical image IO and basic processing; plays nicely with NumPy and PyTorch. Wikipedia

ECG / Arrhythmia

torch_ecg – an open-source deep learning framework for ECG in PyTorch; includes models, data loaders, and utilities tailored to PhysioNet-style datasets. https://github.com/DeepPSP/torch_ecg

BrainFlow (if you ever move to live streaming from devices). https://github.com/brainflow-dev/brainflow

Turning images into matrices / tables

You explicitly like this, so:

PyRadiomics – extracts standardized radiomics features (shape, first order, texture matrices like GLCM, GLRLM, etc.) from segmentations; works on 2D/3D, returns NumPy arrays / tables you can feed into scikit-learn or deep models. https://pyradiomics.readthedocs.io/en/latest

How to build a pipeline:MRI/echo → segmentation with MONAI/nnU-Net → PyRadiomics → tabular features → classical ML / survival models / explainable models.

How to get started – a concrete roadmap

You said: supervised ML and things like GANs/Deep RL. I’d start with supervised, then layer in generative methods.

Here’s a pragmatic sequence:

Step 1 – Pick one “playground” dataset per modality

ECG: PTB-XL (modern, multi-label, 12-lead) https://www.nature.com/articles/s41597-020-0495-6

Imaging: ACDC for CMR and/or EchoNet-Dynamic for echo videos. https://pubmed.ncbi.nlm.nih.gov/29994302

Step 2 – Baseline supervised model (arrhythmia detection)

Project idea (1–2 weeks of effort for a first version):

Load PTB-XL via PhysioNet tools or the provided CSV meta files. 

Train:

A straightforward 1D CNN / ResNet on 12-lead ECG (PyTorch or Keras).

Or use/extend a model from torch_ecg for multi-label classification. 

Evaluate using macro F1 / AUROC for diagnostic superclasses (as recommended in PTB-XL paper). Link above.

Document everything in a clean repo + notebook.

This gives you:

A fully working clinical-ish ECG classifier.

Codebase ready to extend with:

self-supervised pretraining on unlabeled ECGs.

interpretability (Grad-CAM on ECG, spectral attribution).

Comparison to PhysioNet Challenge leaderboard approaches.

Step 3 – Imaging + “image → matrix/table” pipeline

Pick ACDC or CAMUS depending on whether you fancy MRI or echo.

A nice, self-contained project:

Use nnU-Net or MONAI to train a segmentation model for LV/LVM/RV (ACDC) or LV/LA (CAMUS). https://github.com/MIC-DKFZ/nnUNet

From segmentations, compute:

Simple volumetric metrics: EDV, ESV, EF, wall thickness.

Radiomics features using PyRadiomics → you get a feature table per patient. 

Build:

A supervised model predicting the disease class (ACDC has diagnosis labels).

Or a regression model for EF / LV mass as a sanity check.

You’ll practice exactly what you said you like: codifying images into matrices/tables, building classical ML models, and verifying that these features make clinical sense (great conversations with your cardiologist relative).

Step 4 – Enter the land of GANs & advanced deep learning

Once you have supervised baselines, here’s where generative/advanced methods fit naturally:

GANs / diffusion for data augmentation or super-resolution

Train a GAN or SRResNet/SRGAN on CAMUS or CMR images to generate high-res or artifact-free images, then show that your downstream segmentation / classification performance improves on low-quality subsets. There’s already work doing SR on CAMUS-like echo images that you can reproduce/extend. https://arxiv.org/abs/2507.23027

Self-supervised learning on ECG / CMR

Use contrastive learning on raw ECG or MRI to learn representations, then fine-tune for arrhythmia detection or EF prediction. (torch_ecg already has an SSL module in its roadmap/docs). https://deep-psp.tech/torch-ecg-docs-dev/CHANGELOG.html

Reinforcement learningRL is less common for pure diagnosis, more for:

Active learning (deciding which studies to send to human for labeling).

Optimization of scanning protocols or view selection.This is usually a second-stage project once you’re comfortable with supervised baselines and have access to more complex lab workflows.

Step 5 – Plug into the community

To avoid reinventing wheels and to get collaborators:

Follow or participate in PhysioNet/Computing-in-Cardiology Challenges, which are nearly always ECG or hemodynamics related and require open-source code submissions. https://moody-challenge.physionet.org/2021

Watch MICCAI / STACOM cardiac challenges (ACDC, M&Ms, CAMUS). They often release new data, code, and benchmarks. https://pubmed.ncbi.nlm.nih.gov/29994302

Using real ZK-private lab data

One technical solution allows access to real clinical data:

Make sure everything is done within proper ethics / IRB and data-use frameworks.

Aim for this pattern:

Prototype + publish on public datasets (MIT-BIH, PTB-XL, ACDC, EchoNet, etc.).

Once your lab is convinced the model is interesting, propose a project using their data under a formal protocol (anonymization, secure storage, explicit “research only” scope).

Use their data mainly for external validation and robustness testing, not as the only training set (reduces risk, improves generalization).