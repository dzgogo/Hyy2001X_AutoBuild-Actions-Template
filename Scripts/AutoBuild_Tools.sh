#!/bin/bash
# AutoBuild Module by Hyy2001 <https://github.com/Hyy2001X/AutoBuild-Actions>
# AutoBuild_Tools for Openwrt
# Dependences: bash wget curl block-mount e2fsprogs smartmontools

Version=V1.7.9

ECHO() {
	case $1 in
		r) Color="${Red}";;
		g) Color="${Green}";;
		b) Color="${Blue}";;
		y) Color="${Yellow}";;
		x) Color="${Grey}";;
	esac
	[[ $# -gt 1 ]] && shift
	echo -e "${White}${Color}${*}${White}"
}

AutoBuild_Tools_UI() {
while :
do
	clear
	echo -e "$(cat /etc/banner)"
	echo -e "
${Grey}AutoBuild 固件工具箱 ${Version}${White} [$$] [${Tools_File}]

1. USB 空间扩展			6. 环境修复
2. Samba 设置			7. 系统信息监控
3. 端口占用列表			8. 在线设备列表
4. 硬盘信息
5. 网络检查

${Grey}u. 固件更新
${Yellow}x. 更新脚本
${White}q. 退出
"
	read -p "请从上方选项中选择一个操作:" Choose
	case $Choose in
	q)
		rm -rf ${Tools_Cache}/*
		exit 0
	;;
	u)
		[ -s ${AutoUpdate_File} ] && {
			AutoUpdate_UI
		} || {
			ECHO r "\n未检测到 '/bin/AutoUpdate.sh',请确保当前固件支持一键更新!"
			sleep 2
		}
	;;
	x)
		wget -q ${Github_Raw}/Scripts/AutoBuild_Tools.sh -O ${Tools_Cache}/AutoBuild_Tools.sh
		if [[ $? == 0 && -s ${Tools_Cache}/AutoBuild_Tools.sh ]];then
			ECHO y "\n[AutoBuild_Tools] 脚本更新成功!"
			rm -f ${Tools_File}
			mv -f ${Tools_Cache}/AutoBuild_Tools.sh ${Tools_File}
			chmod +x ${Tools_File}
			sleep 2
			exec ${Tools_File}
		else
			ECHO r "\n[AutoBuild_Tools] 脚本更新失败!"
			sleep 2
		fi
	;;
	1)
		[[ ! $(CHECK_PKG block) == true ]] && {
			ECHO r "\n缺少相应依赖包,请先安装 [block-mount] !"
			sleep 2
		} || AutoExpand_UI
	;;
	2)
		[[ ! $(CHECK_PKG block) == true ]] && {
			ECHO r "\n缺少相应依赖包,请先安装 [block-mount] !"
			sleep 2
			return
		}
		[[ ! $(CHECK_PKG smbpasswd) == true ]] && {
			ECHO r "\n缺少相应依赖包,请先安装 [samba] !"
			sleep 2
			return
		}
		Samba_UI
	;;
	3)
		ECHO y "\nLoading Service Configuration ..."
		Netstat1=${Tools_Cache}/Netstat1
		Netstat2=${Tools_Cache}/Netstat2
		ps_Info=${Tools_Cache}/ps_Info
		rm -f ${Netstat2} && touch -a ${Netstat2}
		netstat -ntupa | egrep ":::[0-9].+|0.0.0.0:[0-9]+|127.0.0.1:[0-9]+" | awk '{print $1" "$4" "$6" "$7}' | sed -r 's/0.0.0.0:/\1/;s/:::/\1/;s/127.0.0.1:/\1/;s/LISTEN/\1/' | sort | uniq > ${Netstat1}
		ps -w > ${ps_Info}
		local i=1;while :;do
			Proto=$(sed -n ${i}p ${Netstat1} | awk '{print $1}')
			[[ -z ${Proto} ]] && break
			Port=$(sed -n ${i}p ${Netstat1} | awk '{print $2}')
			_Service=$(sed -n ${i}p ${Netstat1} | awk '{print $3}')
			[[ ${_Service} == '-' ]] && {
				Service="Unknown"
			} || {
				Service=$(echo ${_Service} | cut -d '/' -f2)
				PID=$(echo ${_Service} | cut -d '/' -f1)
				Task=$(grep -v "grep" ${ps_Info} | grep "${PID}" | awk '{print $5}')
			}
			i=$(($i + 1))
			echo -e "${Proto} ${Port} ${Service} ${PID} ${Task}" | egrep "tcp|udp" >> ${Netstat2}
		done
		clear
		ECHO x "端口占用列表\n"
		printf "${Yellow}%-10s %-16s %-22s %-12s %-40s\n${White}" 协议 占用端口 服务名称 PID 进程信息
		local X;while read X;do
			printf "%-8s %-12s %-18s %-12s %-40s\n" ${X}
		done < ${Netstat2}
		ENTER
	;;
	4)
		[[ ! $(CHECK_PKG smartctl) == true ]] && {
			ECHO r "\n缺少相应依赖包,请先安装 [smartmontools] !"
			sleep 2
		} || SmartInfo_UI
	;;
	5)
		if [[ $(CHECK_PKG curl) == true ]];then
			ping 223.5.5.5 -c 1 -W 2 > /dev/null 2>&1
			[[ $? == 0 ]] && {
				ECHO y "\n基础网络连接正常!"
			} || {
				ECHO r "\n基础网络连接错误!"
			}
			ping www.baidu.com -c 1 -W 2 > /dev/null 2>&1
			[[ $? == 0 ]] && {
				ECHO y "Baidu 连接正常!"
			} || {
				ECHO r "Baidu 连接错误!"
			}
			Google_Check=$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)
			case ${Google_Check} in
			301)
				ECHO y "Google 连接正常!"
			;;
			*)
				ECHO r "Google 连接错误!"
			;;
			esac
		else
			ECHO r "\n缺少相应依赖包,请先安装 [curl] !"
		fi
		sleep 2
	;;
	6)
		cp -a /rom/etc/AutoBuild/Default_Variable /etc/AutoBuild
		cp -a /rom/etc/profile /etc
		cp -a /rom/etc/banner /etc
		cp -a /rom/etc/openwrt_release /etc
		cp -a /rom/bin/AutoUpdate.sh ${AutoUpdate_File}
		cp -a /rom/bin/AutoBuild_Tools.sh ${Tools_File}
		cp -a /rom/etc/config/autoupdate /etc/config
		ECHO y "\n固件环境修复完成!"
		sleep 2
	;;
	7)
		Sysinfo show
	;;
	8)
		clear
		Online_List="${Tools_Cache}/Online_List"
		i=1
		ECHO x "在线设备列表\n"
		ECHO y "序号   MAC 地址			IP 地址			设备名称"
		grep "br-lan" /proc/net/arp | grep "0x2" | grep -v "0x0" | grep "$(echo $(GET_IP 4) | egrep -o "[0-9]+\.[0-9]+\.[0-9]+")" | awk '{print $4"\t"$1}' | while read X;do
			echo " ${i}     ${X}		$(grep $(echo ${X} | awk '{print $2}') /tmp/dhcp.leases | awk '{print $4}')"
			i=$(($i + 1))
		done
		ENTER
	;;
	esac
done
}

AutoExpand_UI() {
	USB_Info
	[[ -s ${Block_Info} ]] && {
		clear
		ECHO x "USB 扩展内部空间\n"
		printf "${Yellow}   %-14s %-40s %-12s %-15s %-18s %-10s\n${White}" 设备 UUID 格式 挂载点 可用空间 状态
		local X i=1;while read X;do
			[[ $(echo ${X} | awk '{print $4}') =~ (/boot|/rom|/opt) || $(echo ${X} | awk '{print $5}') == '-' ]] && {
				Status="不推荐"
			} || {
				[[ $(echo ${X} | awk '{print $4}') == '/' ]] && Status="已挂载" || Status="可用"
			}
			printf "${i}. %-12s %-40s %-10s %-12s %-14s %-10s\n" ${X} ${Status}
			i=$(($i + 1))
		done < ${Disk_Processed_List}
		echo -e "\nq. 返回"
		echo "r. 重新载入列表"
	} || {
		ECHO r "未检测到任何外接设备,请检查接口或插入 USB 设备!"
		sleep 2
		return 1
	}
	Logic_Disk_Count=$(sed -n '$=' ${Logic_Disk_List})
	echo
	read -p "请输入要操作的设备编号[1-${Logic_Disk_Count}]:" Choose
	case ${Choose} in
	q)
		return
	;;
	r)
		AutoExpand_UI
	;;
	*)
		[[ ${Choose} =~ [0-9] && ${Choose} -le ${Logic_Disk_Count} && ${Choose} -gt 0 ]] > /dev/null 2>&1 && {
			if [[ $(CHECK_PKG mkfs.ext4) == true ]];then
				Choose_Disk=$(sed -n ${Choose}p ${Disk_Processed_List} | awk '{print $1}')
				Choose_Mount=$(grep "${Choose_Disk}" ${Disk_Processed_List} | awk '{print $4}')
				AutoExpand_Core ${Choose_Disk} ${Choose_Mount}
			else
				ECHO r "\n系统缺少相应依赖包,请先安装 [e2fsprogs] !" && sleep 2
				return
			fi
		} || {
			ECHO r "\n输入错误,请输入正确的选项!"
			AutoExpand_UI
		}
	;;
	esac
}

USB_Info() {
	Logic_Disk_List="${Tools_Cache}/Logic_Disk_List"
	Phy_Disk_List="${Tools_Cache}/Phy_Disk_List"
	Block_Info="${Tools_Cache}/Block_Info"
	dev_Info="${Tools_Cache}/dev_Info"
	Disk_Processed_List="${Tools_Cache}/Disk_Processed_List"
	echo -ne "\n${Yellow}Loading USB Configuration ...${White}"
	rm -f ${Block_Info} ${Logic_Disk_List} ${Disk_Processed_List} ${Phy_Disk_List}
	touch ${Disk_Processed_List}
	block mount
	block info | grep -v "mtdblock" | egrep "sd[a-z][0-9]|mmcblk[0-9]+[a-z][0-9]+" > ${Block_Info}
	ls -1 /dev | egrep "sd[a-z]|mmcblk|nvme" > ${dev_Info}
	[[ -s ${Block_Info} ]] && {
		cat ${Block_Info} | awk -F '[:]' '{print $1}' > ${Logic_Disk_List}
		for Disk_Name in $(cat ${Logic_Disk_List})
		do
			UUID=$(grep "${Disk_Name}" ${Block_Info} | egrep -o 'UUID=".+"' | awk -F '["]' '/UUID/{print $2}')
			Logic_Mount=$(grep "${Disk_Name}" ${Block_Info} | egrep -o 'MOUNT="/[0-9a-zA-Z].+"|MOUNT="/"' | awk -F '["]' '/MOUNT/{print $2}')
			[[ -z ${Logic_Mount} ]] && Logic_Mount="$(df ${Disk_Name} | grep "${Disk_Name}" | awk '{print $6}' | awk 'NR==1')"
			Logic_Format="$(grep "${Disk_Name}" ${Block_Info} | egrep -o 'TYPE="[0-9a-zA-Z].+' | awk -F '["]' '/TYPE/{print $2}')"
			Logic_Available="$(df -h ${Disk_Name} | grep "${Disk_Name}" | awk '{print $4}' | awk 'NR==1')"
			[[ -z ${UUID} ]] && UUID='-'
			[[ -z ${Logic_Format} ]] && Logic_Format='-'
			[[ -z ${Logic_Mount} ]] && Logic_Mount='-'
			[[ -z ${Logic_Available} ]] && Logic_Available='-'
			echo "${Disk_Name}	${UUID}	${Logic_Format}	${Logic_Mount}	${Logic_Available}" >> ${Disk_Processed_List}
		done
		egrep -v "sd[a-z][0-9]|mmcblk[0-9][a-z][0-9]|nvme[0-9][a-z].+" ${Logic_Disk_List} | sort | uniq > ${Phy_Disk_List}
	}
	echo -ne "\r                             \r"
	return
}

AutoExpand_Core() {
	ECHO r "\n警告: 操作开始后请不要中断任务或进行其他操作,否则可能导致设备无法开机"
	ECHO r "      固件更新将改变分区表,从而导致扩容失效,当前硬盘上的数据可能会丢失"
	echo -ne "\n${Yellow}本操作将把设备 '$1' 格式化为 ext4 格式,${White}"
	read -p "是否确认执行格式化操作?[Y/n]:" Choose
	[[ ${Choose} == [Yesyes] ]] && {
		ECHO y "\n开始运行一键挂载脚本 ..."
		sleep 2
	} || return 0
	echo "禁用自动挂载 ..."
	uci set fstab.@global[0].auto_mount='0'
	uci commit fstab
	[[ ! $2 == '-' ]] && {
		echo "卸载设备 '$1' 位于 '$2' ..."
		umount -l $2 > /dev/null 2>&1
		[[ $? != 0 ]] && {
			ECHO r "设备 '$2' 卸载失败!"
			exit 1
		}
	}
	echo "正在格式化设备 '$1' 为 ext4 格式,请耐心等待 ..."
	mkfs.ext4 -F $1 > /dev/null 2>&1
	[[ $? == 0 ]] && {
		echo "设备 '$1' 已成功格式化为 ext4 格式!"
		USB_Info
	} || {
		ECHO r "设备 '$1' 格式化失败!"
		exit 1
	}
	UUID=$(grep "$1" ${Disk_Processed_List} | awk '{print $2}')
	echo "UUID: ${UUID}"
	echo "挂载设备 '$1' 到 ' /tmp/extroot' ..."
	mkdir -p /tmp/introot || {
		ECHO r "临时文件夹 '/tmp/introot' 创建失败!"
		exit 1
	}
	mkdir -p /tmp/extroot || {
		ECHO r "临时文件夹 '/tmp/extroot' 创建失败!"
		exit 1
	}
	mount --bind / /tmp/introot || {
		ECHO r "绑定 '/' 到 '/tmp/introot' 失败!"
		exit 1

	}
	mount $1 /tmp/extroot || {
		ECHO r "挂载 '$1' 到 '/tmp/extroot' 失败!"
		exit 1

	}
	echo "正在复制系统文件到 '$1' ..."
	tar -C /tmp/introot -cf - . | tar -C /tmp/extroot -xf -
	echo "卸载设备 '/tmp/introot' '/tmp/extroot' ..."
	umount /tmp/introot
	umount /tmp/extroot
	sync
	for ((i=0;i<=10;i++));do
		uci delete fstab.@mount[0] > /dev/null 2>&1
	done
	echo "写入新分区表到 '/etc/config/fstab' ..."
	cat >> /etc/config/fstab <<EOF
config mount
        option enabled '1'
        option uuid '${UUID}'
        option target '/'

EOF
	uci commit fstab
	ECHO y "\n运行结束,外接设备 '$1' 已挂载为系统根目录 '/'\n"
	read -p "操作需要重启生效,是否立即重启?[Y/n]:" Choose
	[[ ${Choose} == [Yesyes] ]] && {
		ECHO g "\n正在重启设备,请耐心等待 ..."
		sync
		reboot
	} || exit
}

Samba_UI() {
	USB_Info
	Samba_tmp="${Tools_Cache}/AutoSamba"
	[[ ! -d ${Tools_Cache} ]] && mkdir -p "${Tools_Cache}"
	while :
	do
		autoshare_Mode="$(uci get samba.@samba[0].autoshare)"
		clear
		ECHO x "Samba 工具箱\n"
		echo "1. 自动生成 Samba 挂载点"
		echo "2. 删除已有挂载点"
		echo "3. $([[ ${autoshare_Mode} == 1 ]] && ECHO r 关闭 || ECHO y 开启) Samba 自动共享"
		echo "4. 设置 Samba 访问密码 $([ -s /etc/samba/smbpasswd ] && ECHO y "[已设置]" || ECHO r "[未设置]")"
		[ -s /etc/samba/smbpasswd ] && echo "5. 删除 Samba 密码"
		echo -e "\nq. 返回\n"
		read -p "请从上方选项中选择一个操作:" Choose
		case ${Choose} in
		1)
			Samba_UCI_List="${Tools_Cache}/UCI_List"
			Logic_Disk_Count=$(sed -n '$=' ${Disk_Processed_List})
			echo
			for ((i=1;i<=${Logic_Disk_Count};i++));
			do
				Disk_Name=$(sed -n ${i}p ${Disk_Processed_List} | awk '{print $1}')
				Disk_Mounted_Point=$(sed -n ${i}p ${Disk_Processed_List} | awk '{print $4}')
				Samba_Name=${Disk_Mounted_Point#*/mnt/}
				Samba_Name=$(echo ${Samba_Name} | cut -d "/" -f2-5)
				uci show 2>&1 | grep "sambashare" > ${Samba_UCI_List}
				if [[ ! $(cat ${Samba_UCI_List}) =~ ${Disk_Mounted_Point} ]] > /dev/null 2>&1 ;then
					ECHO g "设置挂载点 '${Samba_Name}' ..."
					cat >> /etc/config/samba <<EOF

config sambashare
	option auto '1'
	option name '${Samba_Name}'
	option device '${Disk_Name}'
	option path '${Disk_Mounted_Point}'
	option read_only 'no'
	option guest_ok 'yes'
	option create_mask '0777'
	option dir_mask '0777'
EOF
				else
					ECHO y "'${Disk_Mounted_Point}' 挂载点已存在!"
				fi
			done
			uci commit samba
			/etc/init.d/samba restart
			sleep 2
		;;
		2)
			while :
			do
				Samba_config="$(grep "sambashare" /etc/config/samba | wc -l)"
				[[ ${Samba_config} -eq 0 ]] && break
				uci delete samba.@sambashare[0]
				uci commit samba > /dev/null 2>&1
			done
			ECHO y "\n已删除所有 Samba 挂载点!"
		;;
		3)
			[[ ${autoshare_Mode} == 0 ]] && {
				uci set samba.@samba[0].autoshare='1'
				autosamba_mode="开启"
			} || {
				uci set samba.@samba[0].autoshare='0'
				autosamba_mode="关闭"
			}
			ECHO y "\n已${autosamba_mode} Samba 自动共享!"
			uci commit samba
		;;
		4)
			sed -i '/invalid users/d' /etc/samba/smb.conf.template >/dev/null 2>&1
			ECHO y "\n注意: 将为 root 用户设置密码,同时自动允许 root 用户进行访问,
      请连续输入两次相同的密码,输入的内容不会显示,完成后回车即可!\n"
			smbpasswd -a root
			[[ $? == 0 ]] && {
				ECHO y "\n已为 root 用户设置 Samba 访问密码!"
				/etc/init.d/samba restart
			} || {
				ECHO r "\nSamba 访问密码设置失败!"
			}
		;;
		5)
			if [ -s /etc/samba/smbpasswd ];then
				smbpasswd -x root
				ECHO y "\n已删除 Samba 访问密码!"
				/etc/init.d/samba restart
			fi
		;;
		q)
			break
		;;
		esac
		sleep 2
	done
}

AutoUpdate_UI() {
while :
do
	AutoUpdate_Version=$(awk 'NR==6' ${AutoUpdate_File} | awk -F '[="]+' '/Version/{print $2}')
	clear
	echo -e "$(cat /etc/banner)"
	ECHO x "AutoBuild 固件更新/AutoUpdate ${AutoUpdate_Version}\n
${Yellow}1. 更新固件 [保留配置]${White}
2. 更新固件 (强制刷入固件) [保留配置]
3. 不保留配置更新固件 [全新安装]
4. 列出固件信息
5. 清除固件下载缓存
6. 更改 Github API 地址
7. 打印运行日志 (反馈问题)
8. 检查 AutoUpdate 运行环境
9. 备份系统配置
$([ $(${AutoUpdate_File} --var TARGET_BOARD) == x86 ] && echo "10. 指定下载 <UEFI | Legacy> 引导的固件\n")
${Yellow}x. 更新 [AutoUpdate] 脚本
${White}q. 返回\n"
	read -p "请从上方选择一个操作:" Choose
	case ${Choose} in
	q)
		break
	;;
	x)
		wget -q ${Github_Raw}/Scripts/AutoUpdate.sh -O ${Tools_Cache}/AutoUpdate.sh
		if [[ $? == 0 && -s ${Tools_Cache}/AutoUpdate.sh ]];then
			ECHO y "\n[AutoUpdate] 脚本更新成功!"
			rm -f ${AutoUpdate_File}
			mv -f ${Tools_Cache}/AutoUpdate.sh /bin
			chmod +x ${Tools_File}
		else
			ECHO r "\n[AutoUpdate] 脚本更新失败!"
		fi
	;;
	1)
		bash ${AutoUpdate_File}
	;;
	2)
		bash ${AutoUpdate_File} -F
	;;
	3)
		bash ${AutoUpdate_File} -n
	;;
	4)
		bash ${AutoUpdate_File} --list
	;;
	5)
		ECHO y "\n下载缓存清理完成!"
		bash ${AutoUpdate_File} --clean
	;;
	6)
		echo ""
		read -p "请输入新的 Github 地址:" Github_URL
		[[ -n ${Github_URL} ]] && bash ${AutoUpdate_File} -C ${Github_URL} || {
			ECHO r "\nGithub 地址不能为空!"
		}
	;;
	7)
		bash ${AutoUpdate_File} -L
	;;
	8)
		bash ${AutoUpdate_File} --check
	;;
	9)
		echo ""
		read -p "请输入配置保存路径(回车即为当前路径):" BAK_PATH
		bash ${AutoUpdate_File} --backup ${BAK_PATH}
	;;
	10)
		echo ""
		read -p "请输入你想要的启动方式[UEFI/Legacy]:" _BOOT
		[[ -n ${_BOOT} ]] && bash ${AutoUpdate_File} -B ${_BOOT} || {
			ECHO r "\n启动方式不能为空!"
		}
	;;
	esac
	ENTER
done
}

SmartInfo_UI() {
	USB_Info
	[[ -s ${Phy_Disk_List} ]] && {
		clear
		ECHO x "硬盘信息列表"
		cat ${Phy_Disk_List} | while read Phy_Disk;do
			SmartInfo_Core ${Phy_Disk}
		done
		ENTER
	} || {
		ECHO r "未检测到任何外接设备,请检查 USB 接口可用性或插入更多 USB 设备!"
		sleep 2
		return 1
	}
}

SmartInfo_Core() {
	Smart_Info1="${Tools_Cache}/Smart_Info1"
	Smart_Info2="${Tools_Cache}/Smart_Info2"
	smartctl -H -A -i $1 > ${Smart_Info1}
	smartctl -H -A -i -d scsi $1 > ${Smart_Info2}
	if [[ ! $(smartctl -H $1) =~ Unknown ]];then
		[[ $(smartctl -H $1) =~ PASSED ]] && Phy_Health=PASSED || Phy_Health=Failure
	else
		Phy_Health=$(GET_INFO "SMART Health Status:" ${Smart_Info2})
	fi
	Phy_Name=$(GET_INFO "Device Model:" ${Smart_Info1})
	Phy_ID=$(GET_INFO "Serial number:" ${Smart_Info2})
	Phy_Capacity=$(GET_INFO "User Capacity:" ${Smart_Info2})
	Phy_Part_Number=$(grep -c "${Phy_Disk}" ${Disk_Processed_List})
	Phy_Factor=$(GET_INFO "Form Factor:" ${Smart_Info2})
	[[ -z ${Phy_Factor} ]] && Phy_Factor="未知"
	Phy_Sata_Version=$(GET_INFO "SATA Version is:" ${Smart_Info1})
	[[ -z ${Phy_Sata_Version} ]] && Phy_Sata_Version="未知"
	TRIM_Command=$(GET_INFO "TRIM Command:" ${Smart_Info1})
	[[ -z ${TRIM_Command} ]] && TRIM_Command="不可用"
	Power_On=$(grep "Power_On" ${Smart_Info1} | awk '{print $NF}')
	Power_Cycle_Count=$(grep "Power_Cycle_Count" ${Smart_Info1} | awk '{print $NF}')
	[[ -z ${Power_On} ]] && {
		Power_Status="未知"
	} || {
		Power_Status="${Power_On} 小时 / ${Power_Cycle_Count} 次"
	}
	if [[ $(GET_INFO "Rotation Rate:" ${Smart_Info2}) =~ "Solid State" ]];then
		Phy_Type="固态硬盘"
		Phy_RPM="不可用"
	else
		Phy_Type="其他"
		if [[ $(GET_INFO "Rotation Rate:" ${Smart_Info2}) =~ rpm ]];then
			Phy_RPM=$(GET_INFO "Rotation Rate:" ${Smart_Info2})
			Phy_Type="机械硬盘"
		else
			Phy_RPM="未知"
		fi
	fi
	[[ -z ${Phy_Name} ]] && {
		Phy_Name=$(GET_INFO Vendor: ${Smart_Info2})$(GET_INFO Product: ${Smart_Info2})
	}
	Phy_LB=$(GET_INFO "Logical block size:" ${Smart_Info2})
	Phy_PB=$(GET_INFO "Physical block size:" ${Smart_Info2})
	if [[ -n ${Phy_PB} ]];then
		Phy_BS="${Phy_LB} / ${Phy_PB}"
	else
		Phy_BS="${Phy_LB}"
	fi
	cat <<EOF

	硬盘型号: ${Phy_Name}
	硬盘尺寸: ${Phy_Factor}
	硬盘 ID : ${Phy_ID}
	硬盘容量: ${Phy_Capacity}
	健康状况: ${Phy_Health}
	分区数量: ${Phy_Part_Number}
	SATA 版本: ${Phy_Sata_Version}
	TRIM 指令: ${TRIM_Command}
	硬盘类型: ${Phy_Type}
	硬盘转速: ${Phy_RPM}
	扇区大小: ${Phy_BS}
	通电情况: ${Power_Status}

========================================================

EOF
}

Sysinfo() {
	while :;do
		CPU_Model=$(awk -F ':[ ]' '/model name/{printf ($2);exit}' /proc/cpuinfo)
		CPU_Threads=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
		CPU_Usage=$(top -n 1 | grep "CPU:" | awk '{print $2}')
		if [[ -z ${CPU_Model} ]];then
			CPU_Model=$(awk -F ':[ ]' '/system type/{printf ($2);exit}' /proc/cpuinfo)
			Low_Mode=1
		else
			CPU_Cores=$(awk -F '[ :]' '/cpu cores/ {print $4;exit}' /proc/cpuinfo)
			CPU_Freq=$(echo "$(grep 'MHz' /proc/cpuinfo | awk '{Freq_Sum += $4};END {print Freq_Sum}') / ${CPU_Threads}" | bc)
			CPU_Temp=$(echo "$(sensors 2> /dev/null | grep Core | awk '{Sum += $3};END {print Sum}') / ${CPU_Cores}" | bc 2>/dev/null | awk '{a=$1;b=32+$1*1.8} {printf("%d°C | %.1f°F\n",a,b)}')
		fi
		OS_Info=$(awk -F '[= "]' '/OPENWRT_RELEASE/{print $3,$4,$5}' /etc/os-release)
		FW_Info=$(awk -F "[=']" '/DISTRIB_REVISION/{print $3,$4,$5}' /etc/openwrt_release)
		Mem_Total=$(free | grep Mem | awk '{a=$2/1024} {printf("%dMB\n",a)}')
		Mem_Free=$(free | grep Mem | awk '{a=$7*100/$2;b=$7/1024;c=$2/1024} {printf("%dMB | %.1f%%\n",b,a)}')
		Kernel_Version=$(uname -r)
		Sys_Startup=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=($1%60)} {printf("%d 天 %d 小时 %d 分钟 %d 秒\n",a,b,c,d)}' /proc/uptime)
		IPv4=$(GET_IP 4)
		IPv6=$(GET_IP 6)
		Support_Format=$(grep -v "nodev" /proc/filesystems | awk '{print $1}' | sort | uniq)
		Online_Users=$(grep "br-lan" /proc/net/arp | grep "0x2" | grep -v "0x0" | grep "$(echo ${IPv4} | egrep -o "[0-9]+\.[0-9]+\.[0-9]+")" | wc -l)
		[[ ! $1 == show ]] && return

		clear
		ECHO x "系统信息监控\n"	
		echo -e "${Grey}操作系统${Yellow}		${OS_Info}"
		echo -e "${Grey}内核版本${Yellow}		${Kernel_Version}"
		echo -e "${Grey}固件版本${Yellow}		${FW_Info}"
		echo -e "${Grey}登陆用户名${Yellow}		${USER}"
		echo -e "${Grey}物理内存${Yellow}		${Mem_Total}"
		echo -e "${Grey}可用内存${Yellow}		${Mem_Free}"
		echo -e "${Grey}CPU 型号${Yellow}		${CPU_Model}"
		[[ ${Low_Mode} == 1 ]] && {
			echo -e "${Grey}CPU 核心信息${Yellow}		${CPU_Threads} 线程"
		} || {
			echo -e "${Grey}CPU 核心信息${Yellow}		${CPU_Cores} 核心 ${CPU_Threads} 线程"
			echo -e "${Grey}CPU 平均频率${Yellow}		${CPU_Freq}MHz"
			echo -e "${Grey}CPU 平均温度${Yellow}		${CPU_Temp}"
		}
		echo -e "${Grey}CPU 使用率${Yellow}		${CPU_Usage}"
		echo -e "${Grey}IPv4 地址${Yellow}		$(echo ${IPv4})"
		[[ -n ${IPv6} ]] && echo -e "${Grey}IPv6 地址${Yellow}		[${IPv6}]"
		echo -e "${Grey}运行时间${Yellow}		${Sys_Startup}"
		echo -e "${Grey}文件系统${Yellow}		$(echo ${Support_Format})"
		echo -e "${Grey}在线用户${Yellow}		${Online_Users}"
		ECHO g "\n同时按下[Ctrl+C]键以退出系统监控 ..."
		sleep 1
	done
}

GET_IP() {
	case $1 in
	4)
		ip -4 a | egrep "br-lan" | grep "inet" | awk '{print $2}'
	;;
	6)
		ip -6 a | grep inet6 | grep "global dynamic" | awk '{print $2}' | awk 'NR==1'
	;;
	*)
		return 1
	;;
	esac
}

GET_INFO() {
	grep "$1" $2 | sed "s/^[$1]*//g" 2> /dev/null | sed 's/^[ \t]*//g' 2> /dev/null
}

CHECK_PKG() {
	which $1 > /dev/null 2>&1
	[[ $? == 0 ]] && echo "true" || echo "false"
}

ENTER() {
	echo -e "${Green}"
	read -p "按下[回车]键以继续操作 ..." Key
	echo -e "${White}"
}

KILL_OTHER() {
	local i;for i in $(ps | grep -v grep | grep $1 | grep -v $$ | awk '{print $1}');do
		kill -9 ${i} 2> /dev/null
	done
}

# KILL_OTHER AutoBuild_Tools.sh

White="\e[0m"
Yellow="\e[33m"
Red="\e[31m"
Blue="\e[34m"
Grey="\e[36m"
Green="\e[32m"

Tools_Cache=/tmp/AutoBuild_Tools
Tools_File=$(cd $(dirname $0) && pwd)/AutoBuild_Tools.sh
AutoUpdate_File=/bin/AutoUpdate.sh
[[ ! -d ${Tools_Cache} ]] && mkdir -p ${Tools_Cache}
Github_Raw="https://ghproxy.com/https://raw.githubusercontent.com/Hyy2001X/AutoBuild-Actions/master"
AutoBuild_Tools_UI