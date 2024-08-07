#!/bin/bash
home_path="/home/aisl"
matlab_path="$home_path"".matlab"
gapdetect_path="$home_path""/GapDetect/"
if [ -a $matlab_path ]; then
   rm -r $matlab_path
    echo "deleting matlab folder"
else
        echo "matlab folder is not present"
fi
nohup matlab -nosplash -nodisplay -nodesktop -r "addpath(genpath('$gapdetect_path'));distcomp.feature('LocalUseMpiexec',false);run('point_iter_anal_soa_zb_v1_2.m');quit;" >> op_soa_zb_1007_2.txt &

