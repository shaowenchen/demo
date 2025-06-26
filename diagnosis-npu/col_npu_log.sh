#!/bin/bash

# Create temporary directory
temp_dir=$(mktemp -d)

# Set timeout (in seconds)
npu_smi_timeout=60

function check_cmd() {
    for cmd in npu-smi hccn_tool msnpureport; do
        if ! command -v $cmd &>/dev/null; then
            echo "Error: Command $cmd not found. Please ensure it is installed and available in the PATH."
            exit 1
        fi
    done
}

function get_npu_count() {
    # Get NPU count using npu-smi info -l command
    npu_count=$(npu-smi info -l 2>/dev/null | grep -o 'Total Count\s*:\s*[0-9]\+' | awk '{print $NF}' | sed 's/ //g')

    if [ -z "$npu_count" ] || [ "$npu_count" -eq 0 ]; then
        echo "Error: No NPU cards found" >&2
        return 1
    fi

    echo "$npu_count"
}

function collect_npu_info() {
    echo "Collecting NPU-SMI information..."
    npu-smi info >"$temp_dir/npu-smi-info.log" 2>&1
}

function collect_health_status() {
    echo "Collecting NPU health status..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/npu-health.log"
        npu-smi info -t health -i $i -c 0 >>"$temp_dir/npu-health.log" 2>&1
    done
}

function collect_network_health() {
    echo "Collecting network health status..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/network-health.log"
        hccn_tool -i $i -net_health -g >>"$temp_dir/network-health.log" 2>&1
    done
}

function collect_optical_info() {
    echo "Collecting optical module information..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/optical-info.log"
        hccn_tool -i $i -optical -g >>"$temp_dir/optical-info.log" 2>&1
    done
}

function collect_link_status() {
    echo "Collecting link status..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/link-status.log"
        hccn_tool -i $i -link -g >>"$temp_dir/link-status.log" 2>&1
    done
}

function collect_link_history() {
    echo "Collecting link history..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/link-history.log"
        hccn_tool -i $i -link_stat -g >>"$temp_dir/link-history.log" 2>&1
    done
}

function collect_cdr_snr() {
    echo "Collecting CDR receive side SNR quality..."
    npu_count=$(get_npu_count) || return 1
    for i in $(seq 0 $((npu_count - 1))); do
        echo "==> NPU $i" >>"$temp_dir/cdr-snr.log"
        hccn_tool -i $i -scdr -t 5 >>"$temp_dir/cdr-snr.log" 2>&1
    done
}

function collect_npu_snr() {
    if ! command -v ascend-dmi &>/dev/null; then
        echo "Error: ascend-dmi command not found. Please ensure it is installed and available in the PATH."
        return 1
    fi
    echo "Collecting NPU receive side SNR quality..."
    npu_count=$(get_npu_count) || return 1
    # Create comma-separated list of NPU indices
    npu_list=$(seq -s, 0 $((npu_count - 1)))
    ascend-dmi --sq -t roce -d $npu_list >"$temp_dir/npu-snr.log" 2>&1
}

function collect_msnpureport() {
    echo "Collecting msnpureport..."
    msnpureport_dir="$temp_dir/msnpureport"
    mkdir -p "$msnpureport_dir"
    cd "$msnpureport_dir"
    msnpureport -f
    cd ..
    # Wait a moment to ensure all files are written
    sleep 2
}

# Create tar.gz file
function package_log() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    hostname=$(hostname)
    tar_dir_name="npu_logs_${hostname}_${timestamp}"
    home_dir=$(echo ~)
    cp -r "$temp_dir" "$home_dir/$tar_dir_name"
    tar_file="${tar_dir_name}.tar.gz"
    tar -czf "$home_dir/$tar_file" -C "$home_dir" "$tar_dir_name" --remove-files
    echo -e "\n Logs have been collected and packaged as $home_dir/$tar_file"
}

function main() {
    check_cmd
    collect_npu_info
    collect_health_status
    collect_network_health
    collect_optical_info
    collect_link_status
    collect_link_history
    collect_cdr_snr
    collect_npu_snr
    collect_msnpureport
    package_log
}

main
