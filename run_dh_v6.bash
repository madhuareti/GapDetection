#!/bin/bash
home_path="/home/grads/m/mareti"
# matlab_path="$home_path""/.matlab"
gapdetect_path="$home_path""/madhu_workspace/GapDetect/"
if [ -a $matlab_path ]; then
    rm -r "$home_path""/.matlab"
    echo "deleting matlab folder"
else
	echo "matlab folder is not present"
fi
nohup matlab -nosplash -nodisplay -nodesktop -r "addpath(genpath('$gapdetect_path'));distcomp.feature('LocalUseMpiexec',false);run('point_iter_anal_noGT_dh_v6.m');quit;" >> op_dh_v6_1106.txt &
