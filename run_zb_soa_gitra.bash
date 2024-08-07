#!/bin/bash
home_path="/home/aisl/"
matlab_path="$home_path"".matlab"
gapdetect_path="$home_path""GapDetect/"
nohup matlab -nosplash -nodisplay -nodesktop -r "addpath(genpath('$gapdetect_path'));distcomp.feature('LocalUseMpiexec',false);run('point_iter_anal_soa_gitra_zb.m');quit;" >> op_soa_gitra_zb_11_06.txt &

