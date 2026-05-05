#!/bin/bash
# JRNGC Complete Experiment Matrix Runner
# Run on cloud: bash run_all_jrngc.sh

set -e
PYTHON=/root/miniconda3/envs/jrngc_bw/bin/python
GPU=0
LOG_DIR="./batch_logs"
mkdir -p "$LOG_DIR"

run_exp() {
    local desc="$1"
    local yaml="$2"
    local dtype="$3"
    shift 3
    local extra_args="$@"
    local logfile="$LOG_DIR/$(echo "$desc" | tr ' /' '_' ).log"
    echo "==== $(date) START $desc ====" | tee -a "$logfile"
    $PYTHON -u demo.py --yaml_dir "$yaml" --data_type "$dtype" --gpu $GPU $extra_args >> "$logfile" 2>&1
    echo "==== $(date) DONE  $desc ====" | tee -a "$logfile"
}

echo "=========================================="
echo "Phase 1: VAR experiments"
echo "=========================================="

# VAR d=10 (already done but re-run for clean results)
run_exp "VAR_d10" "./F_var.yaml" "var"

# VAR d=50
run_exp "VAR_d50" "./F_var_d50.yaml" "var" --var_t 500 --var_t_eval 100

# VAR d=100
run_exp "VAR_d100" "./F_var_d100.yaml" "var" --var_t 500 --var_t_eval 100

echo "=========================================="
echo "Phase 2: Lorenz-96 experiments"
echo "=========================================="

# Lorenz-96 F=10 (already done but re-run for clean results)
run_exp "Lorenz_F10" "./Florenztest1.yaml" "lorenz" --lorenz_t 500 --lorenz_t_eval 100

# Lorenz-96 F=40
run_exp "Lorenz_F40" "./F_lorenz_f40.yaml" "lorenz" --lorenz_t 500 --lorenz_t_eval 100

echo "=========================================="
echo "Phase 3: DREAM3 experiments (d=10,50,100 x 5 subjects)"
echo "=========================================="

for d in 10 50 100; do
    if [ "$d" = "10" ]; then
        yaml="./F_dream3.yaml"
    elif [ "$d" = "50" ]; then
        yaml="./F_dream3_d50.yaml"
    else
        yaml="./F_dream3_d100.yaml"
    fi
    for subj in 0 1 2 3 4; do
        run_exp "DREAM3_d${d}_subj${subj}" "$yaml" "dream3" --dream3_subject $subj
    done
done

echo "=========================================="
echo "Phase 4: fMRI experiments"
echo "=========================================="

# fMRI d=15
run_exp "fMRI_d15" "./F_fmri.yaml" "fmri" --f_subject 0 --f_t 200 --f_t_eval 0

# fMRI d=50
run_exp "fMRI_d50" "./F_fmri_d50.yaml" "fmri" --f_subject 0 --f_t 200 --f_t_eval 0

echo "=========================================="
echo "ALL EXPERIMENTS COMPLETE"
echo "=========================================="
