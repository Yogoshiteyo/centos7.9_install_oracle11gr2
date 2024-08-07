#!/bin/bash

# 获取最大分区
max_partition=$(df --output=target,size | awk 'NR>1 {print $2,$1}' | sort -nr | head -n 1 | cut -d' ' -f2)

# 默认安装路径
DEFAULT_INSTALL_DIR="$max_partition/data/app/oracle"

# 确认安装路径
confirm_installation_path() {
    local MAX_PARTITION_DIR="$max_partition"
    local INSTALL_PATH_FILE="/tmp/install_path.txt"

    if [[ -f "$INSTALL_PATH_FILE" ]]; then
        # 如果文件存在，读取安装路径
        INSTALL_DIR=$(<"$INSTALL_PATH_FILE")
        echo "检测到上次保存的安装路径：$INSTALL_DIR"
        return 0
    else
        read -p "是否使用默认安装路径 ($DEFAULT_INSTALL_DIR 在最大分区 $max_partition 中)? (y/n): " use_default
        if [[ $use_default =~ ^[Yy]$ ]]; then
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            echo "$INSTALL_DIR" > "$INSTALL_PATH_FILE"
            return 0
        else
            # 用户指定安装路径
            read -p "请输入自定义安装路径: " USER_SPECIFIED_DIR
            INSTALL_DIR="$USER_SPECIFIED_DIR"
            echo "$INSTALL_DIR" > "$INSTALL_PATH_FILE"
            return 1
        fi
    fi
}


create_user_and_groups() {
    # 建立组
    groupadd -g 200 oinstall
    groupadd -g 201 dba

    # 建立用户
    useradd -u 440 -g oinstall -G dba oracle 
    echo "oracle" | passwd --stdin oracle
    echo "用户oracle已添加，密码为：oracle"
    add_comment
}

# 函数：添加注释
add_comment() {
    echo -e "\n*******************************************************************\n"
}

# 函数：确认操作
confirm_operation() {
    read -p "$1 (y/n): " choice
    if [[ ! $choice =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 1
    fi
}

# 函数：创建安装目录并设置权限
# 参数：
#   $1: 是否选择了默认路径（true/false）
create_installation_directory_and_set_permissions() {
    local install_dir="$max_partition/data/app/oracle"

    # 创建目录

    if [ "$1" = true ]; then
        mkdir -p "$install_dir" || { echo "错误：无法创建目录 $install_dir" >&2; exit 1; }
        # 设置权限
        chmod 755 "$install_dir" || { echo "错误：无法设置目录权限 $install_dir" >&2; exit 1; }
        chown oracle.oinstall -R "$install_dir" || { echo "错误：无法设置目录所有者 $install_dir" >&2; exit 1; }
        echo "安装目录已创建，并设置了正确的权限。"        
        echo "用户选择了默认路径"
    else
        mkdir -p "$INSTALL_DIR" || { echo "错误：无法创建目录 $INSTALL_DIR" >&2; exit 1; }
        # 设置权限
        chmod 755 "$INSTALL_DIR" || { echo "错误：无法设置目录权限 $INSTALL_DIR" >&2; exit 1; }
        chown oracle.oinstall -R "$INSTALL_DIR" || { echo "错误：无法设置目录所有者 $INSTALL_DIR" >&2; exit 1; }
        echo "安装目录已创建，并设置了正确的权限。"        
        echo "用户未选择默认路径"
    fi
    add_comment
}

# 函数：安装依赖包
install_dependencies() {
    dependencies=(
        "unzip"
        "vim"
        "net-tools"
        "binutils"
        "compat-libcap1"
        "compat-libstdc++-33"
        "compat-libstdc++-33*i686"
        "compat-libstdc++-33*.devel"
        "compat-libstdc++-33"
        "compat-libstdc++-33*.devel"
        "gcc"
        "gcc-c++"
        "glibc"
        "glibc*.i686"
        "glibc-devel"
        "glibc-devel*.i686"
        "ksh"
        "libaio"
        "libaio*.i686"
        "libaio-devel"
        "libaio-devel*.devel"
        "libgcc"
        "libgcc*.i686"
        "libstdc++"
        "libstdc++*.i686"
        "libstdc++-devel"
        "libstdc++-devel*.devel"
        "libXi"
        "libXi*.i686"
        "libXtst"
        "libXtst*.i686"
        "make"
        "sysstat"
        "unixODBC"
        "unixODBC*.i686"
        "unixODBC-devel"
        "unixODBC-devel*.i686"
    )

    echo "开始安装依赖包..."
    yum install -y "${dependencies[@]}"
    echo "依赖包安装完成。"
    add_comment
}

# 函数：设置SELinux
setup_selinux() {
    selinux=$(getenforce)
    if [ "$selinux" != "Disabled" ]; then
        confirm_operation "SELinux 将被禁用并需要重启。是否继续？"
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        echo "SELinux 配置已修改，请重启计算机，并确保 SELinux 状态为 Disabled。"
        add_comment
        exit 0
    fi
    setenforce 
    firewall-cmd --zone=public --add-port=1521/tcp --permanent
    firewall-cmd --reload
    echo "SELinux 已关闭。"
    echo "防火墙已放行1521端口"
    add_comment
}

# 函数：设置主机名
setup_hostname() {
    new_hostname="oracledb"
    hostnamectl set-hostname "$new_hostname"
    echo "主机名已设置为 $new_hostname。"
    add_comment
}

# 函数：修改 /etc/hosts 文件
update_hosts_file() {
    localip=$(hostname -I)
    if grep -q "oracledb" /etc/hosts; then
        echo "主机文件已更新。"
    else
        echo "$localip    oracledb" | tee -a /etc/hosts
        echo "已更新主机文件。"
    fi
    add_comment
}

# 函数：重启网络服务
restart_network_service() {
    systemctl restart network
    echo "网络服务已重启。"
    add_comment
}

# 函数：解压安装包
extract_installation_packages() {
    local install_packages
    local package_dir
    local spinner="/|\\-"
    local delay=0.1

    # 查找安装包
    install_packages=($(find / -name "linux.x64_11gR2_database_*" -o -name "p13390677_112040_Linux-x86-64*"))
    if [ ${#install_packages[@]} -eq 0 ]; then
        echo "错误：安装包不存在，请下载安装包。
         
        p13390677_112040_Linux-x86-64_1of7.zip 1.3 GB (1395582860 字节)
        MD5 1616F61789891A56EAFD40DE79F58F28
        SHA-1 983461D6442B0833630475EC4885278588585651
        
        p13390677_112040_Linux-x86-64_2of7.zip 1.1 GB (1151304589 字节)
        MD5 67BA1E68A4F581B305885114768443D3
        SHA-1 2E628D8CAC5D1C6FFF15E728B1F227747BF2DED8"
        
        #https://updates.oracle.com/Orion/Services/download/p13390677_112040_Linux-x86-64_1of7.zip?aru=16716375&patch_file=p13390677_112040_Linux-x86-64_1of7.zip
        #https://updates.oracle.com/Orion/Services/download/p13390677_112040_Linux-x86-64_2of7.zip?aru=16716375&patch_file=p13390677_112040_Linux-x86-64_2of7.zip
        >&2
        exit 1
    fi

    package_dir=$(dirname "${install_packages[0]}")
    cd "$package_dir" || { echo "错误：无法进入目录 $package_dir" >&2; exit 1; }

    # 创建目录/software/database，如果不存在的话
    mkdir -p /software/database || { echo "错误：无法创建目录 /software/database" >&2; exit 1; }

    # 解压安装包到临时目录
    for package in "${install_packages[@]}"; do
        echo -n "正在解压安装包: $package "
        unzip -q "$package" -d /tmp && echo " 解压完成." || { echo " 解压失败." >&2; exit 1; }
    done

    # 查找并移动解压后的数据库目录到指定目录
    database_dirs=($(find /tmp -type d -name "database"))
    if [ ${#database_dirs[@]} -eq 0 ]; then
        echo "错误：找不到解压后的数据库目录。" >&2
        exit 1
    fi

    for db_dir in "${database_dirs[@]}"; do
        # 移动数据库目录下的内容到指定目录
        echo "正在移动数据库目录内容: $db_dir/* 到 /software/database"
        mv "$db_dir"/* /software/database || { echo "错误：移动数据库目录内容失败。" >&2; exit 1; }
        # 删除原始的数据库目录
        echo "正在删除原始数据库目录: $db_dir"
        rm -rf "$db_dir" || { echo "错误：删除数据库目录失败。" >&2; exit 1; }
    done

    echo "安装包已解压到 /software/database。"
    add_comment
}


# 函数：设置系统参数
setup_system_parameters() {
    # 修改内核参数配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    if grep -q "net.ipv4.ip_local_port_range.*9000.*65500" /etc/sysctl.conf &&
        grep -q "fs.file-max.*6815744" /etc/sysctl.conf &&
        grep -q "kernel.shmall.*10523004" /etc/sysctl.conf &&
        grep -q "kernel.shmmax.*6465333657" /etc/sysctl.conf &&
        grep -q "kernel.shmmni.*4096" /etc/sysctl.conf &&
        grep -q "kernel.sem.*250.*32000.*100128" /etc/sysctl.conf &&
        grep -q "net.core.rmem_default.*262144" /etc/sysctl.conf &&
        grep -q "net.core.wmem_default.*262144" /etc/sysctl.conf &&
        grep -q "net.core.rmem_max.*4194304" /etc/sysctl.conf &&
        grep -q "net.core.wmem_max.*1048576" /etc/sysctl.conf &&
        grep -q "fs.aio-max-nr.*1048576" /etc/sysctl.conf; then
        echo "内核参数配置已存在，无需修改。"
    else
        cat <<EOF >>/etc/sysctl.conf
net.ipv4.ip_local_port_range = 9000 65500
fs.file-max = 6815744
kernel.shmall = 10523004
kernel.shmmax = 6465333657
kernel.shmmni = 4096
kernel.sem = 250 32000 100128
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
EOF
        echo "内核参数配置已修改。"
    fi
    sysctl -p
    add_comment

    # 修改系统资源限制
    cp /etc/security/limits.conf /etc/security/limits.conf.bak

    if grep -q "oracle.*nproc.*2047" /etc/security/limits.conf &&
        grep -q "oracle.*nproc.*16384" /etc/security/limits.conf &&
        grep -q "oracle.*nofile.*1024" /etc/security/limits.conf &&
        grep -q "oracle.*nofile.*65536" /etc/security/limits.conf; then
        echo "系统资源限制已存在，无需修改。"
    else
        cat <<EOF >>/etc/security/limits.conf
oracle  soft  nproc  2047
oracle  hard  nproc  16384
oracle  soft  nofile  1024
oracle  hard  nofile  65536
EOF
        echo "系统资源限制已修改。"
    fi
    add_comment

    # 修改用户验证选项
    cp /etc/pam.d/login /etc/pam.d/login.bak

    if grep -q "pam_limits.so" /etc/pam.d/login; then
        echo "用户限制文件已存在，无需修改。"
    else
        line_number=$(grep -n "pam_namespace.so" /etc/pam.d/login | cut -d':' -f1)
        if [ -n "$line_number" ]; then
            sed -i "${line_number}a session    required     pam_limits.so" /etc/pam.d/login
            echo "用户限制文件已修改。"
        else
            echo "session    required     pam_limits.so" >>/etc/pam.d/login
            echo "未找到匹配的行，新参数已添加到 /etc/pam.d/login 文件末尾。"
        fi
    fi
    add_comment

}


# 函数：修改安装响应文件的内容
modify_response_file_content1() {
    local rsp_file="/software/database/response/db_install.rsp"
    local keyword1="oracle.install.responseFileVersion"
    local replace_content1="oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0"
    local keyword2="oracle.install.option"
    local replace_content2="oracle.install.option=INSTALL_DB_SWONLY"
    local keyword3="ORACLE_HOSTNAME"
    local replace_content3="ORACLE_HOSTNAME=oracledb"
    local keyword4="UNIX_GROUP_NAME"
    local replace_content4="UNIX_GROUP_NAME=oinstall"
    local keyword5="INVENTORY_LOCATION"
    local replace_content5="INVENTORY_LOCATION=/data/app/oracle/oraInventory"
    local keyword6="SELECTED_LANGUAGES"
    local replace_content6="SELECTED_LANGUAGES=en,zh_CN"
    local keyword7="ORACLE_HOME"
    local replace_content7="ORACLE_HOME=/data/app/oracle/product/11.2.0/db_1"
    local keyword8="ORACLE_BASE"
    local replace_content8="ORACLE_BASE=/data/app/oracle"
    local keyword9="oracle.install.db.InstallEdition"
    local replace_content9="oracle.install.db.InstallEdition=EE"
    local keyword10="oracle.install.db.EEOptionsSelection"
    local replace_content10="oracle.install.db.EEOptionsSelection=false"
    local keyword11="oracle.install.db.optionalComponents"
    local replace_content11="oracle.install.db.optionalComponents=oracle.rdbms.partitioning:11.2.0.4.0,oracle.oraolap:11.2.0.4.0,oracle.rdbms.dm:11.2.0.4.0,oracle.rdbms.dv:11.2.0.4.0,oracle.rdbms.lbac:11.2.0.4.0,oracle.rdbms.rat:11.2.0.4.0"
    local keyword12="oracle.install.db.DBA_GROUP"
    local replace_content12="oracle.install.db.DBA_GROUP=dba"
    local keyword13="oracle.install.db.OPER_GROUP"
    local replace_content13="oracle.install.db.OPER_GROUP=oinstall"
    local keyword14="oracle.install.db.config.starterdb.type"
    local replace_content14="oracle.install.db.config.starterdb.type=GENERAL_PURPOSE"
    local keyword15="oracle.install.db.config.starterdb.globalDBName"
    local replace_content15="oracle.install.db.config.starterdb.globalDBName=ora11g"
    local keyword16="oracle.install.db.config.starterdb.SID"
    local replace_content16="oracle.install.db.config.starterdb.SID=ora11g"
    local keyword17="oracle.install.db.config.starterdb.characterSet"
    local replace_content17="oracle.install.db.config.starterdb.characterSet=$character_set"
    local keyword18="oracle.install.db.config.starterdb.memoryOption"
    local replace_content18="oracle.install.db.config.starterdb.memoryOption=true"
    local keyword19="oracle.install.db.config.starterdb.memoryLimit"
    local replace_content19="oracle.install.db.config.starterdb.memoryLimit=1500"
    local keyword20="oracle.install.db.config.starterdb.installExampleSchemas"
    local replace_content20="oracle.install.db.config.starterdb.installExampleSchemas=false"
    local keyword21="oracle.install.db.config.starterdb.enableSecuritySettings"
    local replace_content21="oracle.install.db.config.starterdb.enableSecuritySettings=true"
    local keyword22="oracle.install.db.config.starterdb.password.ALL"
    local replace_content22="oracle.install.db.config.starterdb.password.ALL=oracle"
    local keyword23="oracle.install.db.config.starterdb.control"
    local replace_content23="oracle.install.db.config.starterdb.control=DB_CONTROL"
    local keyword24="oracle.install.db.config.starterdb.automatedBackup.enable"
    local replace_content24="oracle.install.db.config.starterdb.automatedBackup.enable=false"
    local keyword25="oracle.install.db.config.starterdb.storageType"
    local replace_content25="oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE"
    local keyword26="DECLINE_SECURITY_UPDATES"
    local replace_content26="DECLINE_SECURITY_UPDATES=true"

    if [ ! -f "$rsp_file" ]; then
        echo "错误：安装响应文件 $rsp_file 不存在。" >&2
        exit 1
    fi

    # 替换安装响应文件中的内容
    sed -i "s|^$keyword1=.*$|$replace_content1|g" "$rsp_file"
    sed -i "s|^$keyword2=.*$|$replace_content2|g" "$rsp_file"
    sed -i "s|^$keyword3=.*$|$replace_content3|g" "$rsp_file"
    sed -i "s|^$keyword4=.*$|$replace_content4|g" "$rsp_file"
    sed -i "s|^$keyword5=.*$|$replace_content5|g" "$rsp_file"
    sed -i "s|^$keyword6=.*$|$replace_content6|g" "$rsp_file"
    sed -i "s|^$keyword7=.*$|$replace_content7|g" "$rsp_file"
    sed -i "s|^$keyword8=.*$|$replace_content8|g" "$rsp_file"
    sed -i "s|^$keyword9=.*$|$replace_content9|g" "$rsp_file"
    sed -i "s|^$keyword10=.*$|$replace_content10|g" "$rsp_file"
    sed -i "s|^$keyword11=.*$|$replace_content11|g" "$rsp_file"
    sed -i "s|^$keyword12=.*$|$replace_content12|g" "$rsp_file"
    sed -i "s|^$keyword13=.*$|$replace_content13|g" "$rsp_file"
    sed -i "s|^$keyword14=.*$|$replace_content14|g" "$rsp_file"
    sed -i "s|^$keyword15=.*$|$replace_content15|g" "$rsp_file"
    sed -i "s|^$keyword16=.*$|$replace_content16|g" "$rsp_file"
    sed -i "s|^$keyword17=.*$|$replace_content17|g" "$rsp_file"
    sed -i "s|^$keyword18=.*$|$replace_content18|g" "$rsp_file"
    sed -i "s|^$keyword19=.*$|$replace_content19|g" "$rsp_file"
    sed -i "s|^$keyword20=.*$|$replace_content20|g" "$rsp_file"
    sed -i "s|^$keyword21=.*$|$replace_content21|g" "$rsp_file"
    sed -i "s|^$keyword22=.*$|$replace_content22|g" "$rsp_file"
    sed -i "s|^$keyword23=.*$|$replace_content23|g" "$rsp_file"
    sed -i "s|^$keyword24=.*$|$replace_content24|g" "$rsp_file"
    sed -i "s|^$keyword25=.*$|$replace_content25|g" "$rsp_file"
    sed -i "s|^$keyword26=.*$|$replace_content26|g" "$rsp_file"

    echo "安装响应文件内容已修改。"
    add_comment
}

# 函数：修改安装响应文件的内容
# 参数：
#   $1: 是否选择了默认路径（true/false）

modify_response_file_content2() {
    local rsp_file="/software/database/response/db_install.rsp"
    local default_install_dir="$max_partition/data/app/oracle"

    if [ ! -f "$rsp_file" ]; then
        echo "错误：安装响应文件 $rsp_file 不存在。" >&2
        exit 1
    fi

    local use_default="$1"  # 获取参数

    # 替换安装响应文件中的内容
    if [ "$use_default" = true ]; then
        sed -i "s|^INVENTORY_LOCATION=.*$|INVENTORY_LOCATION=$default_install_dir/oraInventory|g" "$rsp_file"
        sed -i "s|^ORACLE_HOME=.*$|ORACLE_HOME=$default_install_dir/product/11.2.0/db_1|g" "$rsp_file"
        sed -i "s|^ORACLE_BASE=.*$|ORACLE_BASE=$default_install_dir|g" "$rsp_file"
        echo "用户选择了默认路径"
    else
        sed -i "s|^INVENTORY_LOCATION=.*$|INVENTORY_LOCATION=$INSTALL_DIR/oraInventory|g" "$rsp_file"
        sed -i "s|^ORACLE_HOME=.*$|ORACLE_HOME=$INSTALL_DIR/product/11.2.0/db_1|g" "$rsp_file"
        sed -i "s|^ORACLE_BASE=.*$|ORACLE_BASE=$INSTALL_DIR|g" "$rsp_file"
        echo "用户未选择默认路径"
    fi
    echo "dbinstall.rsp已修改"
    add_comment
}


check_installation_logs() {
    local log_dir="$INSTALL_DIR/oraInventory/logs"
    local success_flag=0
    local error_flag=0
    local spinner="|/-\-"
    local delay=5

    echo "开始检查安装日志文件..."

    # 循环检查安装日志文件
    while true; do
        for log_file in "$log_dir"/silentInstall*.log; do
            if grep -qE "成功|successful" "$log_file" >/dev/null 2>&1; then
                echo "安装成功。"
                execute_root_scripts
                success_flag=1
                break 2
            elif grep -qE "错误|error" "$log_file"; then
                sleep 10
                error_flag=1
                break
            fi
        done

        if [ $success_flag -eq 0 ] && [ $error_flag -eq 0 ]; then
            for (( i=0; i<${#spinner}; i++ )); do
                echo -ne "正在检查安装日志文件 ${spinner:$i:1}\r"
                sleep $delay
            done
        else
            break
        fi
    done

    if [ $success_flag -eq 0 ]; then
        if [ $error_flag -eq 1 ]; then
            echo "安装失败，请检查安装日志文件以获取详细信息。"
        else
            echo "未在任何安装日志文件中找到 '成功' 或 'successfully'，安装可能未成功。"
        fi
    fi
}

execute_root_scripts() {
    local oraInventory_root_script="$INSTALL_DIR/oraInventory/orainstRoot.sh"
    local oracle_root_script="$INSTALL_DIR/product/11.2.0/db_1/root.sh"

    echo "以 root 用户的身份执行以下脚本："
    echo "1. $oraInventory_root_script"
    echo "2. $oracle_root_script"

    # 检查脚本文件是否存在，如果不存在则退出
    if [ ! -f "$oraInventory_root_script" ] || [ ! -f "$oracle_root_script" ]; then
        echo "错误：脚本文件不存在，请确保路径正确。"
        exit 1
    fi

    # 以 root 用户的身份执行脚本
    echo "执行 $oraInventory_root_script"
    sudo "$oraInventory_root_script"

    echo "执行 $oracle_root_script"
    sudo "$oracle_root_script"
}

#修改oracle用户的环境变量
modify_oracle_user_profile() {
    local use_default="$1"
    local bash_profile="/home/oracle/.bash_profile"
    
    # 注释掉.bash_profile文件中最后两行
    sed -i '/^export ORACLE_SID=/ s/^/#/' "$bash_profile"
    sed -i '/^export NLS_LANG=/ s/^/#/' "$bash_profile"
    
    # 决定$ORACLE_BASE的值
    local ORACLE_BASE
    if [ "$use_default" = true ]; then
        ORACLE_BASE="$max_partition/data/app/oracle"
    else
        ORACLE_BASE="$INSTALL_DIR"
    fi
    
    # 写入环境变量内容
    echo "export ORACLE_BASE=$ORACLE_BASE" >> "$bash_profile"
    echo "export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1" >> "$bash_profile"
    echo 'export PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin' >> "$bash_profile"
    echo 'export ORACLE_SID=orcl' >> "$bash_profile"
    echo 'export ORACLE_PID=ora11g' >> "$bash_profile"
    echo 'export NLS_LANG=AMERICAN_AMERICA.'"$character_set" >> "$bash_profile"
    echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib' >> "$bash_profile"

    echo ".bash_profile文件已修改。"
}


# 函数：安装 Oracle 数据库
install_oracle_database() {
    echo "开始安装 Oracle 数据库..."
    # 切换到 oracle 用户并执行安装
    su - oracle <<EOF
    cd /software/database/
    echo "开始安装："
    ./runInstaller -silent -responseFile /software/database/response/db_install.rsp -ignorePrereq
    echo "\n"
EOF
    echo "Oracle 数据库安装完成。"
}

# 函数：安装监听
install_netca() {
    echo "开始配置监听..."
    # 切换到 oracle 用户并执行安装
    su - oracle <<EOF
    \$ORACLE_HOME/bin/netca /silent /responseFile /software/database/response/netca.rsp
    echo "\n"
EOF
    echo "监听创建完成。"
    add_comment

}

# 函数：静默建库
install_dbca() {
    echo "开始建库..."
    # 切换到 oracle 用户并执行安装
    su - oracle <<EOF
    \$ORACLE_HOME/bin/dbca -silent -responseFile /software/database/response/dbca.rsp
EOF
    echo "静默建库已完成。"
    add_comment

}


modify_dbca_response_file() {
    local dbca_file="/software/database/response/dbca.rsp"
    local keyword1='GDBNAME = "orcl11g.us.oracle.com"'
    local replace_content1='GDBNAME = "orcl"'
    local keyword2='SID = "orcl11g"'
    local replace_content2='SID = "orcl"'
    local keyword3='#CHARACTERSET = "US7ASCII"'
    local replace_content3="CHARACTERSET = \"$character_set\""
    local keyword4='#NATIONALCHARACTERSET= "UTF8"'
    local replace_content4='NATIONALCHARACTERSET = "UTF8"'
    local keyword5='#SYSPASSWORD = "password"'
    local replace_content5='SYSPASSWORD = "oracle"'
    local keyword6='#SYSTEMPASSWORD = "password"'
    local replace_content6='SYSTEMPASSWORD = "oracle"'

    if [ ! -f "$dbca_file" ]; then
        echo "错误：安装响应文件 $dbca_file 不存在。" >&2
        exit 1
    fi

    sed -i "s|^$keyword1|$replace_content1|g" "$dbca_file"
    sed -i "s|^$keyword2|$replace_content2|g" "$dbca_file"
    sed -i "s|^$keyword3|$replace_content3|g" "$dbca_file"
    sed -i "s|^$keyword4|$replace_content4|g" "$dbca_file"
    sed -i "s|^$keyword5|$replace_content5|g" "$dbca_file"
    sed -i "s|^$keyword6|$replace_content6|g" "$dbca_file"

    echo "dbca.rsp 文件已修改。"
}

echo_server_info() {
    echo "服务器信息"
    add_comment
    echo "主机名：oracledb"
    echo "本机IP：$localip"
    echo "oracle用户密码：oracle"
    add_comment
}

echo_db_info() {
    echo "数据库信息"
    add_comment
    echo "GDBNAME：orcl"
    echo "SID:orcl"
    echo "PORT:1521"
    echo "sys用户密码：oracle"
    echo "system用户密码：oracle"
    echo "字符集：$character_set"
    add_comment
}

# 实现Oracle开机自启设置
setup_oracle_autostart() {
    # 检查当前用户是否为root
    if [ "$(id -u)" != "0" ]; then
        echo "Error: This script must be run as root or with sudo." >&2
        exit 1
    fi

    # 获取oracle用户的环境变量中的路径
    ORACLE_HOME=$(su - oracle -c 'echo $ORACLE_HOME')
    ORACLE_BASE=$(su - oracle -c 'echo $ORACLE_BASE')

    # 判断ORACLE_HOME是否为空
    if [ -z "$ORACLE_HOME" ]; then
        echo "Error: ORACLE_HOME is not set for the oracle user." >&2
        exit 1
    fi

    # 修改Oracle脚本dbstart和dbshut中的ORACLE_HOME_LISTNER为ORACLE_HOME
    dbstart_script="$ORACLE_HOME/bin/dbstart"
    dbshut_script="$ORACLE_HOME/bin/dbshut"
    sed -i "s|ORACLE_HOME_LISTNER=\$1|ORACLE_HOME_LISTNER=\$ORACLE_HOME|" "$dbstart_script"
    sed -i "s|ORACLE_HOME_LISTNER=\$1|ORACLE_HOME_LISTNER=\$ORACLE_HOME|" "$dbshut_script"

    # 修改/etc/oratab文件，将orcl实例的启动标志修改为Y
    rm -rf /etc/oratab
    touch /etc/oratab
    echo "orcl:$ORACLE_HOME:Y" >> "/etc/oratab"
    su - oracle -c 'lsnrctl start'
}

create_startup_sql(){
    cat  << EOF > /home/oracle/startup.sql
    conn / as sysdba
    startup
EOF

}

create_oracle_service(){
    cat << EOF > /etc/systemd/system/oracle.service
    [Unit]
    Description=Oracle Startup Service
    After=network.target

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -lc 'su - oracle -c "lsnrctl start && sleep 10 && sqlplus /nolog @/home/oracle/startup.sql"'

    [Install]
    WantedBy=multi-user.target
EOF
}

auto_startup_oracle(){
    create_startup_sql
    create_oracle_service
    systemctl enable oracle
    echo "已添加开机自启"
    add_comment
}

get_character_set_configuration() {
    echo "请选择字符集："
    echo "1: AL32UTF8"
    echo "2: ZHS16GBK"
    read -p "请输入选项（1 或 2）: " choice
    case $choice in
        1) character_set="AL32UTF8";;
        2) character_set="ZHS16GBK";;
        *) echo "无效的选项，请重新选择。"; get_character_set_configuration;;
    esac
}

ask_create_instance() {
    read -p "是否需要创建实例？(y/n): " create_instance
    if [[ $create_instance =~ ^[Yy]$ ]]; then
        install_dbca
    else
        echo "不创建实例。"
    fi
    add_comment
}




# 主函数
main() {
    setup_selinux
    # 设置selinux
    setup_hostname
    # 设置主机名
    get_character_set_configuration
    # 获取最大分区
    create_user_and_groups
    # 创建用户和组
    confirm_installation_path
    # 确认安装路径
    create_installation_directory_and_set_permissions
    # 创建安装文件夹并设置权限
    update_hosts_file
    # 修改hosts文件
    restart_network_service
    # 重启网络服务
    install_dependencies
    # 安装依赖包
    extract_installation_packages
    # 解压安装包
    setup_system_parameters
    # 设置系统参数
    modify_response_file_content1
    # 修改安装响应文件
    modify_response_file_content2
    # 修改安装响应文件
    modify_dbca_response_file
    # 修改建库响应文件
    modify_oracle_user_profile
    # 修改oracle用户环境变量
    install_oracle_database
    # 开始安装oracle数据库软件
    check_installation_logs
    # 检查log文件，判断是否安装完成
    install_netca
    # 配置监听
    ask_create_instance
    # 询问是否创建实例
    auto_startup_oracle
    # 创建自动启动
    echo_server_info
    # 输出服务器信息
    echo_db_info
    # 输出数据库信息
    echo "脚本执行完成。"
}

# 执行主函数
main
