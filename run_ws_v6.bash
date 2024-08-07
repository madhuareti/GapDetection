#!/bin/bash
home_path="/home/staff/m/mareti"
# matlab_path="$home_path""/.matlab"
gapdetect_path="$home_path""/matlab_ws/GapDetect/"
if [ -a $matlab_path ]; then
    rm -r "$home_path""/.matlab"
    echo "deleting matlab folder"
else
	echo "matlab folder is not present"
fi
nohup matlab -nosplash -nodisplay -nodesktop -r "addpath(genpath('$gapdetect_path'));distcomp.feature('LocalUseMpiexec',false);run('point_iter_anal_noGT_ws_v6.m');quit;" >> op_ws_v6_0224.txt &
