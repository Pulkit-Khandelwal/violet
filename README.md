# VIOLET: Volumetric Image registration via Optimization and Learning for Efficient image Translation

## Overview
Inter-modality image registration is challenging due to the lack of robust energy functions that can handle contrast differences across modalities. VIOLET addresses this by reformulating inter-modality registration as an intra-modality problem via image synthesis. VIOLET jointly optimizes: a 3D diffusion-based generative model for image translation, and a classical diffeomorphic registration algorithm based on log-domain demons. This joint framework preserves geometric structure during translation and produces realistic synthesized target images that enable more accurate alignment without requiring perfectly paired training data.

### Credits
The translation module is adapted from the open-source project [CT2MRI](https://github.com/MICV-yonsei/CT2MRI/tree/main). We sincerely thank the original authors for making their code publicly available. It works beautifully and served as the foundation for our translation component! We have modified parts of the code to fit our use case while maintaining the overall structure and intent of the original repository. Please cite the [CT2MRI](https://micv-yonsei.github.io/ct2mri2024/) if you use or adapt the translation module in your own work.

For the registration module, VIOLET supports both [Greedy](https://sites.google.com/view/greedyreg/about) and [FireANTs](https://github.com/rohitrango/FireANTs) registration backends.

### Installation
Clone this repository!
```
git clone git@github.com:Pulkit-Khandelwal/violet.git
cd violet
```

I created a Python virtual environment and installed the dependencies from [here](https://github.com/MICV-yonsei/CT2MRI/blob/main/environment.yml) and if any packages are missing, then simply install them using `pip`. The original CT2MRI code uses Weights & Biases (wandb) for experiment tracking. VIOLET supports the same setup.

### Data preparation
This step ensures that the images serving as the two modalities are coarsely aligned using affine registration. Please see the folder `preprocess`.
Use the script `preprocess_register_affine.sh`. We perform this step using Greedy via label-based registration in our case. For other modalities where it makes sense, you may use intensity-based registration. After registration, verify that all images share the same dimensions, orientation, and resolution before proceeding. You can also enforce consistency using the script: `preprocess_orientation_resolution`.

### Training and testing
Start with the training scripts located in: `/shell/train/`.

Before running, familiarize yourself with the individual scripts that `violet_main.sh` calls.
This script alternates between: `violet_perform_translation.sh` and `violet_perform_registration.sh`.

`baseline.sh`: performs translation once, followed by registration once, without alternating back-and-forth refinement.

## Citations
+ Khandelwal, Pulkit, et al. "VIOLET: Volumetric Image registration via Optimization and Learning for Efficient image Translation." International Workshop on Simulation and Synthesis in Medical Imaging. Cham: Springer Nature Switzerland, 2025.
+ Choo, Kyobin, et al. "Slice-consistent 3d volumetric brain ct-to-mri translation with 2d brownian bridge diffusion model." International Conference on Medical Image Computing and Computer-Assisted Intervention. Cham: Springer Nature Switzerland, 2024.
