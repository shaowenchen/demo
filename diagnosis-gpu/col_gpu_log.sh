#!/bin/bash

# Create temporary directory
temp_dir=$(mktemp -d)

# Set timeout (in seconds)
nvidia_smi_timeout=60
nvidia_bug_report_timeout=300

function check_cmd() {
    for cmd in lspci journalctl dmesg grep timeout nvidia-smi; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: Command $cmd not found. Please ensure it is installed and available in the PATH."
            exit 1
        fi
    done
}

function kern_log() {
    cp /var/log/kern.log $temp_dir
}

function collect_pci_log() {
    lspci -vt > "$temp_dir/lspci_vt.log" &
    lspci | grep -i 'Nvidia' | grep -v 'rev ff' > "$temp_dir/lspci_ff.log" &
}

function collect_xid_log() {
    # Collect xid system log
    echo "Start collecting xid & system log"
    if [ -f "/var/log/messages" ]; then
        logfile="/var/log/messages"
    else
        logfile="/var/log/syslog"
    fi
    (
        echo "--- journalctl Xid logs (last 10 days) ---"
        journalctl --since "$(date -d '10 days ago' '+%Y-%m-%d')" | grep Xid

        echo "--- $logfile Xid logs ---"
        grep 'Xid' $logfile
        logsize=$(du -m $logfile | cut -f1)
        if [ $logsize -le 256 ]; then
            cp $logfile $temp_dir
        fi
        echo "--- dmesg Xid logs ---"
        dmesgsize=$(du -m /var/log/dmesg | cut -f1)
        if [ $dmesgsize -le 256 ]; then
            cp /var/log/dmesg $temp_dir
        fi
        dmesg -T | grep Xid
    ) > "$temp_dir/xid.log" &
}

function collect_gpu_log() {
    # Concurrently collect logs with timeout
    echo "Start collecting nvidia-smi logs..."
    timeout $nvidia_smi_timeout nvidia-smi -q > "$temp_dir/nvidia-smi.log" 2>&1 &
    nvidia_smi_pid=$!
    timeout $nvidia_smi_timeout nvidia-smi topo -m > "$temp_dir/nvidia-smi-topo.log" 2>&1 &
    nvidia_smi_topo_pid=$!

    echo "Start running nvidia-bug-report.sh..."
    timeout $nvidia_bug_report_timeout nvidia-bug-report.sh --output-file "$temp_dir/nvidia-bug-report.log" &
    nvidia_bugreport_pid=$!

    # Check exit status of nvidia-smi commands
    wait $nvidia_smi_pid
    nvidia_smi_exit_code=$?

    wait $nvidia_smi_topo_pid
    nvidia_smi_topo_exit_code=$?

    wait $nvidia_bugreport_pid
    nvidia_bugreport_exit_code=$?

    if [ $nvidia_smi_exit_code -ne 0 ]; then
        echo "nvidia-smi command failed with exit code: $nvidia_smi_exit_code. If the status code is 124, it means the command timed out after 1 minute." >> "$temp_dir/nvidia-smi-error.log"
        echo -e "\n nvidia-smi log collection failed."
    else
        echo -e "\n nvidia-smi log collection completed."
    fi

    if [ $nvidia_smi_topo_exit_code -ne 0 ]; then
        echo "nvidia-smi topo -m command failed with exit code: $nvidia_smi_topo_exit_code. If the status code is 124, it means the command timed out after 1 minute." >> "$temp_dir/nvidia-smi-error.log"
        echo -e "\n nvidia-smi log collection failed."
    else
        echo -e "\n nvidia-smi topo log collection completed."
    fi

    if [ $nvidia_bugreport_exit_code -ne 0 ]; then
        echo "nvidia-bug-report.sh command failed with exit code: $nvidia_bugreport_exit_code. If the status code is 124, it means the command timed out after 5 minute." >> "$temp_dir/nvidia-smi-error.log"
        echo -e "\n nvidia-bug-report.sh log collection failed."
    else
        echo -e "\n nvidia-bug-report.sh log collection completed."
    fi
}

# Create tar.gz file
function package_log() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    # tar_file="nvidia_logs_${timestamp}.tar.gz"
    machine_sn=$(dmidecode -t1 | grep "Serial Number" | sed 's/.*: //')
    tar_file="nvidiaGPU_logs_${machine_sn}_${timestamp}.tar.gz"
    tar -czf "$tar_file" -C "$temp_dir" . --remove-files
    echo -e "\n Logs have been collected and packaged as $tar_file"
}

function main() {
    check_cmd
    collect_pci_log
    collect_xid_log
    collect_gpu_log
    kern_log
    # Wait for all background processes to complete
    wait
    package_log
}

main