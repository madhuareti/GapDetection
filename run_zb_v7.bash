#!/bin/bash
nohup matlab -nosplash -nodisplay -nodesktop -r "addpath(genpath('/home/aisl/GapDetect'));distcomp.feature('LocalUseMpiexec',false);run('point_iter_anal_noGT_zb_v7.m');quit;" > op_zb_v7_1107.txt &
