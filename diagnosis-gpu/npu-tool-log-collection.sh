#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -V
#$ -o /dev/null
#$ -b yes
#$ -hard 
#{{{ get script_path
if [[ "$0" =~ ^\/.* ]];
then
    script_path=$0
else
    script_path=$(pwd)/$0
fi
script_path=$(readlink -f $script_path)
script_path=${script_path%/*}
#}}}

#===============================================================================
TOP_PATH=$(pwd)
LOG_FILE_NAME=log_$(date +"%Y-%m-%d_%H%M%S")
LOG_FILE_PATH=${TOP_PATH}/${LOG_FILE_NAME}
INSTALL_INFO="/lib/davinci.conf"
Driver_Install_Path=`cat /etc/ascend_install.info | grep ^"Driver_Install_Path_Param" | awk -F "=" '{print $2}'`
mkdir -p ${LOG_FILE_PATH}

# log file
FILE_DRIVER_LOG=${LOG_FILE_PATH}/driver_info.log
FILE_OS_LOG=${LOG_FILE_PATH}/OS_info.log
FILE_PCIE_LOG=${LOG_FILE_PATH}/pcie_info.log
FILE_version_info=${LOG_FILE_PATH}/version_info.log

get_install_path() {
	INSTALL_PATH=`cat /lib/davinci.conf | awk -F '=' '{print $2}'`
}
get_install_path

echo "Driver_Install_Path:"${Driver_Install_Path}
echo "INSTALL_PATH:"${INSTALL_PATH}

do_tee=y
#===============================================================================

function green_echo () {
        local what=$*
        echo -e "\e[1;32m[success] ${what} \e[0m"
}

function yellow_echo () {
        local what=$*
        echo -e "\e[1;33m[warnning] ${what} \e[0m"
}

function red_echo () {
        local what=$*
        echo -e "\e[1;31m[error] ${what} \e[0m"
        exit 1

}

try_tee() {
	if [ ${do_tee} == "y" ];then
		$1 | tee $2
	fi
}

get_driver_info() {
	green_echo "================ Collect Driver info =============="
	date  > ${FILE_DRIVER_LOG}
	cat /etc/ascend_install.info  >> ${FILE_DRIVER_LOG}
	cat /etc/ascend_filelist.info >> ${FILE_DRIVER_LOG}
}

get_version_info() {
	green_echo "================ Collect Driver Version =============="
	echo "--------------- cat drvier build.info ---------------" 		>> ${FILE_version_info}
	cat /usr/local/Ascend/driver/build.info 
	echo "--------------- cat drvier version.info ---------------" 		>> ${FILE_version_info}
	cat ${INSTALL_PATH}/driver/version.info
	if [ -f "${Driver_Install_Path}/firmware/version.info" ]; then
		cat ${INSTALL_PATH}/firmware/version.info
	else
		cat /usr/local/Ascend/firmware/version.info
	fi
	echo "--------------- cat drvier version.info ---------------" 		>> ${FILE_version_info}
	which npu-smi > /dev/null 2>&1
	if [ $? -eq 0 ];then
		npu-smi info
	else
		echo "npu-smi no exist"
	fi
	${INSTALL_PATH}/driver/tools/upgrade-tool --device_index -1 --component -1 --version
	${INSTALL_PATH}/driver/tools/upgrade-tool --device_index -1 --system_version
	echo "--------------- firmware version ---------------" 				>> ${FILE_version_info}
	for bdf in $bdf_list ;do lspci -vvvs $bdf -xxx | grep 4e0;done			>> ${FILE_version_info}
}

function get_pcie_log() {
	green_echo "================ Collect PCIe log =============="
	date > ${FILE_PCIE_LOG}

	echo "--------------- lspci ---------------" 		>> ${FILE_PCIE_LOG}
	lspci | egrep "d100|d500|d801|d802" 				>> ${FILE_PCIE_LOG}

	echo "--------------- bdf_to_devid ---------------" 					>> ${FILE_PCIE_LOG}
	bdf_list=($(lspci | egrep "d100|d500|d801|d802" | awk '{print $1}'))
	cat /sys/bus/pci/devices/0000:${bdf_list[0]}/devdrv_sysfs_bdf_to_devid 	>> ${FILE_PCIE_LOG}
	bdf_list=$(lspci | egrep "d100|d500|d801|d802" | awk '{print $1}') 
	echo "--------------- firmware version ---------------" 				>> ${FILE_PCIE_LOG}
	for bdf in $bdf_list ;do lspci -vvvs $bdf -xxx | grep 4e0;done			>> ${FILE_PCIE_LOG}


	echo "--------------- LnkSta ---------------" >> ${FILE_PCIE_LOG}
	date;lspci | egrep "d100|d500|d801|d802" | awk '{print $1}'|xargs -i lspci -vvvvs {}|grep -E 'LnkSta:'  >> ${FILE_PCIE_LOG}
	
	echo "--------------- NUMA ---------------" >> ${FILE_PCIE_LOG}
	for bdf in $bdf_list ;do echo ====$bdf====;lspci -vvvs $bdf | egrep "Lnk|NUMA";done >> ${FILE_PCIE_LOG}
	for bdf in $bdf_list ;do echo ====$bdf====;lspci -vvvs $bdf | egrep "NUMA";done >> ${FILE_PCIE_LOG}

	echo "--------------- lspci -tv ---------------" >> ${FILE_PCIE_LOG}
	lspci -tv >> ${FILE_PCIE_LOG}
	
	echo "--------------- lspci -xxxvvv -----------" >> ${FILE_PCIE_LOG}
	lspci -xxxvvv >> ${FILE_PCIE_LOG}
}

function get_os_info() {
	green_echo "================ Collect os info =============="
	uname -a
	uname -r
	cat /proc/cmdline
	echo "--------------- os info ---------------"
	hostnamectl	2>/dev/null
	cat /etc/*release*
	cat /etc/*version*
	echo "--------------- meminfo ---------------" >> "${FILE_OS_LOG}"
	cat /proc/meminfo >> "${FILE_OS_LOG}"
	free -h >> "${FILE_OS_LOG}"
	echo "--------------- dmidecode ---------------" >> "${FILE_OS_LOG}"
	dmidecode -t slot >> "${FILE_OS_LOG}"
	echo "--------------- ps -ef ---------------" >> "${FILE_OS_LOG}"
	ps -ef >> "${FILE_OS_LOG}"
	echo "--------------- ls -l /boot ---------------" >> "${FILE_OS_LOG}"
	ls -l /boot >> "${FILE_OS_LOG}"
	echo "--------------- cpuinfo ---------------" >> "${FILE_OS_LOG}"
	cat /proc/cpuinfo >> "${FILE_OS_LOG}"
	echo "--------------- interrupts ---------------" >> "${FILE_OS_LOG}"
	cat /proc/interrupts >> "${FILE_OS_LOG}"
	echo "--------------- last reboot ---------------" >> "${FILE_OS_LOG}"
	last reboot >> "${FILE_OS_LOG}"
}

function get_kernel_msg() {
	local DIR_KERN_LOG=${LOG_FILE_PATH}/host_kern_log
	green_echo "================ Collect kern log =============="
	mkdir -p ${DIR_KERN_LOG}
	dmesg > ${DIR_KERN_LOG}/dmesg.log 		2>/dev/null
	dmesg -T > ${DIR_KERN_LOG}/dmesg_T.log 	2>/dev/null
	cp -r /var/log/messages* ${DIR_KERN_LOG} 	2>/dev/null
	cp -r /var/log/kern*.log ${DIR_KERN_LOG} 	2>/dev/null
	cp -r /var/log/syslog* ${DIR_KERN_LOG}		2>/dev/null
}

function get_qemu_log() {
	green_echo "================ Collect qemu log =============="
	mkdir -p ${LOG_FILE_PATH}/qemu_log
	cp -rf /var/log/libvirt/qemu ${LOG_FILE_PATH}/qemu_log 2>/dev/null
}

function get_device_log() {
	cd ${LOG_FILE_PATH}
	green_echo "================ Collect device log =============="
	msnpureport -f
	cd ${TOP_PATH}
}


function get_npu_log() {
	green_echo "================ Collect npu log =============="
	cd ${LOG_FILE_PATH}
	if [ -f "${Driver_Install_Path}/driver/tools/npu_log_collect.sh" ]; then
		${Driver_Install_Path}/driver/tools/npu_log_collect.sh 2>/dev/null
	else
		${INSTALL_PATH}/driver/tools/npu_log_collect.sh 2>/dev/null || /usr/local/Ascend/driver/tools/npu_log_collect.sh 2>/dev/null
	fi
	for((i = 0;i < 16;i++)) do echo "device_id=${i}"; hccn_tool -i ${i} -link -g ; done > hccn_tool.log
	cd ${TOP_PATH}
}

function get_install_log() {
	green_echo "================ Collect install log =============="
	mkdir -p ${LOG_FILE_PATH}/ascend_seclog
	cp -rf /var/log/ascend_seclog ${LOG_FILE_PATH} 2>/dev/null
}

function get_driver_log() {
	green_echo "================ Collect driver log =============="
	# cp -rf /var/log/npu "${LOG_FILE_PATH}" > /dev/null 2>&1
	cp -rf /var/log/upgradetool "${LOG_FILE_PATH}" > /dev/null 2>&1
	green_echo "================ Collect plog log =============="
	cp -rf ~/ascend "${LOG_FILE_PATH}" > /dev/null 2>&1
}

get_path_env() {
	echo "PATH=${PATH}"
	echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
	env > ${LOG_DIR}/env.log
}

function get_all() {

	date > ${LOG_FILE_PATH}/date.txt
	# try_tee
	try_tee get_path_env ${FILE_ENV_LOG}
	get_install_log
	get_driver_info
	try_tee get_version_info ${FILE_version_info}
	get_pcie_log 2>/dev/null
	# try_tee
	try_tee get_os_info ${FILE_OS_LOG}
	# cp
	get_kernel_msg
	get_qemu_log
	get_driver_log
	get_device_log
	# 这个比较慢
	get_npu_log
}

pack_tar() {
	echo "[INFO]Compressing log files..."
	cd ${TOP_PATH} > /dev/null 2>&1
	tar -czvf "${LOG_FILE_PATH}.tar.gz" ${LOG_FILE_NAME} >/dev/null
	if [ $? -ne 0 ];then
		echo "[ERROR]Compressing failed."
		exit 1
	fi
	echo "[INFO]Compressing success."
	rm -rf ${LOG_FILE_PATH}
}

green_echo "================ Start! =============="
get_all 
green_echo "================ Collect success! =============="
pack_tar
