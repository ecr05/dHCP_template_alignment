# dHCP_template_alignment

This repository provides all scripts required for aligning surfaces (derived from the dHCP structural pipeline) to the dHCP surface template space

This needs to be done in three steps:

1) Estimation and application of a rotational transform between MNI space and HCP FS_LR space
2) Estimation of a non-linear transform between each surface's native space and template space using MSM
3) Resampling of native surfaces into template surface topology (the FS_LR32k space) 

# Environment Setup
Before running any scripts please set an environment variable $SURF2TEMPLATE as the path to the top level of this directory

# Pre-processing that has been done for you
For the first step the rotational transformation between MNI space and HCP FS_LR space is given in the folder rotational_transforms. The scripts used to do this can be found (for reference) in the  pre_rotation folder

# Running surface to template alignment

Therefore, to run alignment to template, all that is required is to run the surface_to_template_alignment/align_to_template.sh script. This applies the rotation rotational_transforms/week40_toFS_LR_rot.L.txt (or rotational_transforms/week40_toFS_LR_rot.R.txt ) to the surfaces; then aligns non-linearly using MSM [1][2], before finally resampling all Native surfaces and data onto the template surface topology (creating a new data folder fsaverage_LR32k in the process)
