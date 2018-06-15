#!/bin/bash

# script to estimate rotations between MNI and FS_LR space
# output: affine transforms that will be used to pre-initialise alignment to template for all native surfaces

# example call:



Usage() {
    echo "estimate_pre_rotations.sh <MNI surf> < MNI data> <target surf> <target  data> <outdir> <config>"
    echo " input args: "
    echo " MNI surf : sphere in MNI space (i.e. old surface template) with wildcard %age% and %hemi% (template age and hemisphere)"
    echo " MNI data : sulc data in MNI space (i.e. for old surface template) with wildcard %age% and %hemi% "
    echo " target surf : target sphere in FS_LR space (i.e. new surface template) with wildcard %age% and %hemi% (template age and hemisphere)"
    echo " target data : target data in FS_LR space (i.e. new surface sulc) with wildcard %age% and %hemi% (template age and hemisphere)"
    echo " outdir : base directory where output will be sent "
    echo " config : base config file "
    echo " ages : list of template ages to be processed "
}

inputsphere=$1;shift
inputdata=$1;shift
templatesphere=$1;shift
templatedata=$1;shift
outdir=$1; shift
config=$1; shift
ages=( "$@" ); shift 

mkdir -p $outdir $outdir/Registrations

for (( i=0; i< ${#ages[@]} ;i++ )); do
    age=${ages[$i]}

    for hemi in L R; do

	inmesh=$(echo $inputsphere | sed "s/%hemi%/$hemi/g" |sed "s/%age%/$age/g" )
	indata=$(echo $inputdata | sed "s/%hemi%/$hemi/g" | sed "s/%age%/$age/g")
	refmesh=$(echo $templatesphere | sed "s/%hemi%/$hemi/g" |sed "s/%age%/$age/g" )
	refdata=$(echo $templatedata | sed "s/%hemi%/$hemi/g" | sed "s/%age%/$age/g")

	if [ ! -f ${outdir}/Registrations/week${age}.oldTOnew.aff.nonlin.L.sphere.reg.surf.gii ]; then
	    echo msm --levels=2 --conf=$config --inmesh=$inmesh --refmesh=$refmesh --indata=$indata --refdata=$refdata --out=${outdir}/Registrations/week${age}.oldTOnew.aff.nonlin.L. --verbose
	    
	    msm --levels=2 --conf=$config --inmesh=$inmesh --refmesh=$refmesh --indata=$indata --refdata=$refdata --out=${outdir}/Registrations/week${age}.oldTOnew.aff.nonlin.L. --verbose
	fi

	echo wb_command -surface-affine-regression $inmesh ${outdir}/Registrations/week${age}.oldTOnew.aff.nonlin.L.sphere.reg.surf.gii ${outdir}/week${age}_toFS_LR_affine.${hemi}.txt

	wb_command -surface-affine-regression $inmesh ${outdir}/Registrations/week${age}.oldTOnew.aff.nonlin.L.sphere.reg.surf.gii ${outdir}/week${age}_toFS_LR_affine.${hemi}.txt

	rotation_file=${outdir}/week${age}_toFS_LR_rot.${hemi}.txt 
	
	python ${SURF2TEMPLATE}/pre_rotation/extract_rotation_from_affine.py --affine ${outdir}/week${age}_toFS_LR_affine.${hemi}.txt  --outname $rotation_file
    done 
    

done
