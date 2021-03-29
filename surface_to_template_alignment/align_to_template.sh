#!/bin/bash

# script to align native surfaces with template space & resample native surfaces with template topology
# output: native giftis resampled with template topology

Usage() {
    echo "align_to_template.sh <topdir> <subjid> <session> <age> <volumetric template> <surface template> <pre_rotation> <outdir>  <config> <script dir> < MSM bin> <wb bin>"
    echo " script to align native surfaces with template space & resample native surfaces with template topology "
    echo " input args: "
    echo " topdir: top directory where subject directories are located "
    echo " subjid : subject id "
    echo " session: subject scan session "
    echo " age: in weeks gestation - this will determine which week of the spatio-temporal template the data will first mapped to"
    echo " template volume: template T2 40 week volume "
    echo " surface template: path to the top level directory of the dHCP surface template"
    echo " pre_rotation : txt file containing rotational transform between MNI and FS_LR space (i.e. file rotational_transforms/week40_toFS_LR_rot.%hemi%.txt  ) "
    echo " outdir : base directory where output will be sent "
    echo " config : base config file "
    echo " script dir: path to scripts"
    echo " MSM bin: msm binary"
    echo " wb bin : workbench binary"
    echo "mirtk bin : mirtk binary "
    echo "output: 1) surface registrations; 2)  native giftis resampled with template topology "
}

if [ "$#" -lt 11  ]; then
echo "$#"
   Usage
   exit
fi

topdir=$1;shift
subjid=$1;shift
session=$1;shift
age=$1;shift
templatevolume=$1;shift
templatespherepath=$1;shift
pre_rotation=$1;shift
outdir=$1; shift
config=$1; shift
SURF2TEMPLATE=$1;shift
MSMBIN=$1; shift
WB_BIN=$1; shift
mirtk_BIN=$1; shift

mkdir -p $outdir $outdir/volume_dofs $outdir/surface_transforms

############# define paths to variables #######################

native_volume=${topdir}/sub-${subjid}/ses-$session/anat/sub-${subjid}_ses-${session}_T2w_restore_brain.nii.gz

# native spheres
native_sphereL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_left_sphere.surf.gii
native_sphereR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_right_sphere.surf.gii

echo native spheres $native_sphere_L $native_sphere_R

# native spheres rotated into FS_LR space
native_rot_sphereL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_left_sphere.rot.surf.gii
native_rot_sphereR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_right_sphere.rot.surf.gii

# native data
native_dataL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_left_sulc.shape.gii
native_dataR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_right_sulc.shape.gii

# surface template files - assumes directory structure consistent with dHCP surface template
templatesphereL=$templatespherepath/dHCP.week40.L.sphere.surf.gii
templatesphereR=$templatespherepath/dHCP.week40.R.sphere.surf.gii
templatedataL=$templatespherepath/dHCP.week40.L.sulc.shape.gii
templatedataR=$templatespherepath/dHCP.week40.R.sulc.shape.gii

# pre-rotations
pre_rotationL=$(echo ${pre_rotation} |  sed "s/%hemi%/L/g")
pre_rotationR=$(echo ${pre_rotation} |  sed "s/%hemi%/R/g")


# rotate left and right hemispheres into approximate alignment with MNI space
echo ${SURF2TEMPLATE}/surface_to_template_alignment/pre_rotation.sh $native_volume $native_sphereL $templatevolume $pre_rotationL $outdir/volume_dofs/${subjid}-${session}.dof ${native_rot_sphereL} $mirtk_BIN $WB_BIN
${SURF2TEMPLATE}/surface_to_template_alignment/pre_rotation.sh $native_volume $native_sphereL $templatevolume $pre_rotationL $outdir/volume_dofs/${subjid}-${session}.dof ${native_rot_sphereL}  $mirtk_BIN $WB_BIN
${SURF2TEMPLATE}/surface_to_template_alignment/pre_rotation.sh $native_volume $native_sphereR $templatevolume $pre_rotationR $outdir/volume_dofs/${subjid}-${session}.dof ${native_rot_sphereR}  $mirtk_BIN $WB_BIN


# run msm non linear alignment to template for left and right hemispheres

for hemi in L R; do

    if [ "$hemi" == "L" ]; then
       inmesh=$native_rot_sphereL
       refmesh=$templatesphereL
       refdata=$templatedataL
       indata=$native_dataL
       outname=$outdir/surface_transforms/sub-${subjid}_ses-${session}_left_

    else
       inmesh=$native_rot_sphereR
       refmesh=$templatesphereR
       indata=$native_dataR
       refdata=$templatedataR
       outname=$outdir/surface_transforms/sub-${subjid}_ses-${session}_right_
    fi

    if [ ! -f ${outname}sphere.reg.surf.gii ]; then
	     echo  ${MSMBIN}  --conf=${config}  --inmesh=${inmesh}  --refmesh=${refmesh} --indata=${indata} --refdata=${refdata} --out=${outname} --verbose
	      ${MSMBIN}  --conf=${config}  --inmesh=${inmesh}  --refmesh=${refmesh} --indata=${indata} --refdata=${refdata} --out=${outname} --verbose
    fi

    mv ${outname}sphere.reg.surf.gii ${outname}sphere.reg40.surf.gii
    # the output sphere represents the full warp from Native to 40 week template space - save this
    cp ${outname}sphere.reg40.surf.gii ${topdir}/sub-${subjid}/ses-$session/anat/Native/

done

# now resample template topology on native surfaces - output in fsaverage_LR32k directory

mkdir -p ${topdir}/sub-${subjid}/ses-$session/anat/fsaverage_LR32k

nativedir=${topdir}/sub-${subjid}/ses-$session/anat/Native
fs_LRdir=${topdir}/sub-${subjid}/ses-$session/anat/fsaverage_LR32k

for hemi in left right; do

    # first copy the template sphere to the subjects fsaverage_LR32k
    # Each subject's template space sphere IS the template! following HCP form.

    if [ "$hemi" == "left" ]; then
	     template=$templatespherepath/dHCP.week40.L.sphere.surf.gii
       templatewhite=$templatespherepath/dHCP.week40.L.white.surf.gii
    else
	     template=$templatespherepath/dHCP.week40.R.sphere.surf.gii
       templatewhite=$templatespherepath/dHCP.week40.R.white.surf.gii
    fi

    cp $template $fs_LRdir/sub-${subjid}_ses-${session}_${hemi}_sphere.32k_fs_LR.surf.gii

    transformed_sphere=$outdir/surface_transforms/sub-${subjid}_ses-${session}_${hemi}_sphere.reg40.surf.gii

    # resample surfaces
    for surf in pial white midthickness inflated very_inflated; do
	   ${WB_BIN} -surface-resample $nativedir/sub-${subjid}_ses-${session}_${hemi}_${surf}.surf.gii $transformed_sphere $template ADAP_BARY_AREA $fs_LRdir/sub-${subjid}_ses-${session}_${hemi}_${surf}.32k_fs_LR.surf.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_${hemi}_white.surf.gii  $templatewhite
     done

     # resample .func metrics

    for metric in myelin_map smoothed_myelin_map ; do
	     ${WB_BIN} -metric-resample $nativedir/sub-${subjid}_ses-${session}_${hemi}_${metric}.func.gii $transformed_sphere $template ADAP_BARY_AREA $fs_LRdir/sub-${subjid}_ses-${session}_${hemi}_${metric}.32k_fs_LR.func.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_${hemi}_white.surf.gii  $templatewhite
    done

    # resample .shape metrics
    for metric in sulc curvature thickness corr_thickness ; do
	     ${WB_BIN} -metric-resample $nativedir/sub-${subjid}_ses-${session}_${hemi}_${metric}.shape.gii $transformed_sphere $template ADAP_BARY_AREA $fs_LRdir/sub-${subjid}_ses-${session}_${hemi}_${metric}.32k_fs_LR.shape.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_${hemi}_white.surf.gii  $templatewhite
    done

    ${WB_BIN} -label-resample $nativedir/sub-${subjid}_ses-${session}_${hemi}_drawem.label.gii $transformed_sphere $template ADAP_BARY_AREA $fs_LRdir/sub-${subjid}_ses-${session}_${hemi}_drawem.label.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_${hemi}_white.surf.gii  $templatewhite
done
