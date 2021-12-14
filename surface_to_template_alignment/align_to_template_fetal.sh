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
    echo " template age: target age for the median template"
    echo " surface template: path to the top level directory of the dHCP surface template"
    echo " pre_rotation : txt file containing rotational transform between MNI and FS_LR space (i.e. file rotational_transforms/week40_toFS_LR_rot.%hemi%.txt  ) "
    echo " outdir : base directory where output will be sent "
    echo " config : base config file "
    echo " script dir: path to scripts"
    echo " MSM bin: msm binary"
    echo " wb bin : workbench binary"
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
templateage=$1;shift
templatespherepath=$1;shift
pre_rotation=$1;shift
outdir=$1; shift
config=$1; shift
SURF2TEMPLATE=$1;shift
MSMBIN=$1; shift
WB_BIN=$1; shift

mkdir -p $outdir $outdir/volume_dofs $outdir/surface_transforms

########## DEFINE PATHS TO VARIABLES ##########

echo native_volume=${topdir}/sub-${subjid}/ses-$session/anat/sub-${subjid}_ses-${session}_T2w.nii.gz
native_volume=${topdir}/sub-${subjid}/ses-$session/anat/sub-${subjid}_ses-${session}_T2w.nii.gz

# native spheres
echo native_sphereL=${topdir}/sub-${subjid}/ses-${session}/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sphere.surf.gii
echo native_sphereR=${topdir}/sub-${subjid}/ses-${session}/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sphere.surf.gii

native_sphereL=${topdir}/sub-${subjid}/ses-${session}/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sphere.surf.gii
native_sphereR=${topdir}/sub-${subjid}/ses-${session}/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sphere.surf.gii


echo native spheres $native_sphere_L $native_sphere_R

# native spheres rotated into FS_LR space
echo native_rot_sphereL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sphere.rot.surf.gii
echo native_rot_sphereR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sphere.rot.surf.gii

native_rot_sphereL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sphere.rot.surf.gii
native_rot_sphereR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sphere.rot.surf.gii

# native data
echo native_dataL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sulc.shape.gii
echo native_dataR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sulc.shape.gii

native_dataL=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-left_sulc.shape.gii
native_dataR=${topdir}/sub-${subjid}/ses-$session/anat/Native/sub-${subjid}_ses-${session}_hemi-right_sulc.shape.gii

# surface template files - assumes directory structure consistent with dHCP surface template
echo templatesphereL=$templatespherepath/week-${age}_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii
echo templatesphereR=$templatespherepath/week-${age}_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii
echo templatedataL=$templatespherepath/week-${age}_hemi-left_space-dhcpSym_dens-32k_sulc.shape.gii 
echo templatedataR=$templatespherepath/week-${age}_hemi-right_space-dhcpSym_dens-32k_sulc.shape.gii 

templatesphereL=$templatespherepath/week-${age}_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii
templatesphereR=$templatespherepath/week-${age}_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii
templatedataL=$templatespherepath/week-${age}_hemi-left_space-dhcpSym_dens-32k_sulc.shape.gii
templatedataR=$templatespherepath/week-${age}_hemi-right_space-dhcpSym_dens-32k_sulc.shape.gii 

# pre-rotations
echo pre_rotationL=$(echo ${pre_rotation} |  sed "s/%hemi%/L/g")
echo pre_rotationR=$(echo ${pre_rotation} |  sed "s/%hemi%/R/g")

pre_rotationL=$(echo ${pre_rotation} |  sed "s/%hemi%/L/g")
pre_rotationR=$(echo ${pre_rotation} |  sed "s/%hemi%/R/g")


########## ROTATE LEFT AND RIGHT HEMISPHERES INTO APPROXIMATE ALIGNMENT WITH SURFACE TEMPLATE SPACE ##########

echo ${WB_BIN} -surface-apply-affine $native_sphereL $pre_rotationL  ${native_rot_sphereL} 
 

${WB_BIN} -surface-apply-affine $native_sphereL $pre_rotationL  ${native_rot_sphereL} 
${WB_BIN} -surface-modify-sphere  ${native_rot_sphereL}  100 ${native_rot_sphereL}  -recenter
${WB_BIN} -surface-apply-affine $native_sphereR $pre_rotationR  ${native_rot_sphereR} 
${WB_BIN} -surface-modify-sphere  ${native_rot_sphereR}  100 ${native_rot_sphereR}  -recenter


########## RUN MSM NON-LINEAR ALIGNMENT TO TEMPLATE FOR LEFT AND RIGHT HEMISPHERES ##########


for hemi in left right; do

    if [ "$hemi" == "left" ]; then
       inmesh=$native_rot_sphereL
       refmesh=$templatesphereL
       refdata=$templatedataL
       indata=$native_dataL
       outname=$outdir/surface_transforms/sub-${subjid}_ses-${session}_hemi-left_from-native_to-dhcpSym${templateage}_dens-32k_mode-

    else
       inmesh=$native_rot_sphereR
       refmesh=$templatesphereR
       indata=$native_dataR
       refdata=$templatedataR
       outname=$outdir/surface_transforms/sub-${subjid}_ses-${session}_hemi-right_from-native_to-dhcpSym${templateage}_dens-32k_mode-
    fi

    if [ ! -f ${outname}sphere.reg.surf.gii ]; then
	     echo  ${MSMBIN} --inmesh=${inmesh} --refmesh=${refmesh} --indata=${indata} --refdata=${refdata} -o ${outname} --conf=${config} --verbose
	      ${MSMBIN} --inmesh=${inmesh} --refmesh=${refmesh} --indata=${indata} --refdata=${refdata} -o ${outname} --conf=${config}
    fi
    
    if [ "$age" != "$templateage" ] ; then 
    	# need to concatenate msm warp to local template with warp from local template to median week template
    	echo ${WB_BIN} -surface-sphere-project-unproject ${outname}sphere.reg.surf.gii ${refmesh} $templatespherepath/week-to-${templateage}-registrations/${hemi}.${age}-to-${templateage}/${hemi}.${age}-to-${templateage}sphere.reg.surf.gii ${outname}sphere.reg${templateage}.surf.gii 

	${WB_BIN} -surface-sphere-project-unproject ${outname}sphere.reg.surf.gii ${refmesh} $templatespherepath/week-to-${templateage}-registrations/${hemi}.${age}-to-${templateage}/${hemi}.${age}-to-${templateage}sphere.reg.surf.gii ${outname}sphere.reg${templateage}.surf.gii

   	 # the output sphere represents the full warp from Native to median week template space - save this
   	 cp ${outname}sphere.reg${templateage}.surf.gii ${topdir}/sub-${subjid}/ses-$session/anat/Native/

    else

    mv ${outname}sphere.reg.surf.gii ${outname}sphere.reg${templateage}.surf.gii

    fi

done

########## RESAMPLE TEMPLATE TOPOLOGY ON NATIVE SURFACES - OUTPUT IN 'dhcpSym_32k' DIRECTORY ##########

echo mkdir -p ${outdir}/sub-${subjid}/ses-$session/dhcpSym_32k  
mkdir -p ${outdir}/sub-${subjid}/ses-$session/dhcpSym_32k  

echo nativedir=${topdir}/sub-${subjid}/ses-$session/anat
echo dhcpSym_dir=${outdir}/sub-${subjid}/ses-$session/dhcpSym_32k 
 
nativedir=${topdir}/sub-${subjid}/ses-$session/anat/Native
dhcpSym_dir=${outdir}/sub-${subjid}/ses-$session/dhcpSym_32k

for hemi in left right ; do

    # first copy the template sphere to the subjects dhcpSym_32k
    # Each subject's template space sphere IS the template! following HCP form.

    if [ "$hemi" == "left" ]; then

	echo template=$templatespherepath/week-${templateage}_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii 
	echo templatemidthickness=$templatespherepath/week-${templateage}_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii 
	     
	template=$templatespherepath/week-${templateage}_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii 
	templatemidthickness=$templatespherepath/week-${templateage}_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii 
    else
	echo template=$templatespherepath/week-${templateage}_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii 
	echo templatemidthickness=$templatespherepath/week-${templateage}_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii 
	  
	template=$templatespherepath/week-${templateage}_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii
	templatemidthickness=$templatespherepath/week-${templateage}_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii 
    fi

	echo cp $template $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii
	cp $template $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii 

    transformed_sphere=$outdir/surface_transforms/sub-${subjid}_ses-${session}_hemi-${hemi}_from-native_to-dhcpSym${templateage}_dens-32k_mode-sphere.reg${templateage}.surf.gii

    # resample surfaces
    for surf in pial wm midthickness inflated vinflated; do
	   echo ${WB_BIN} -surface-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_${surf}.surf.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_${surf}.surf.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii  $templatemidthickness

	${WB_BIN} -surface-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_${surf}.surf.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_${surf}.surf.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii  $templatemidthickness
     done 


    # resample .shape metrics
    for metric in sulc curvature thickness desc-corr_thickness myelinmap desc-smoothed_myelinmap desc-medialwall_mask ; do
	echo ${WB_BIN} -metric-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_${metric}.shape.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_${metric}.shape.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii  $templatemidthickness
	
	${WB_BIN} -metric-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_${metric}.shape.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_${metric}.shape.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii  $templatemidthickness
    done ### LZJW changed output file name ###

	# resample .label files 
echo ${WB_BIN} -label-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_desc-drawem_dseg.label.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_desc-drawem_dseg.label.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii $templatemidthickness

    ${WB_BIN} -label-resample $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_desc-drawem_dseg.label.gii $transformed_sphere $template ADAP_BARY_AREA $dhcpSym_dir/sub-${subjid}_ses-${session}_hemi-${hemi}_space-dhcpSym${templateage}_desc-drawem_dseg.label.gii -area-surfs $nativedir/sub-${subjid}_ses-${session}_hemi-${hemi}_midthickness.surf.gii $templatemidthickness
done 
