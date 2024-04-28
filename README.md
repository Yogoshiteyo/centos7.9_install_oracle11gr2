# oracle11gr2_install
## 脚本说明
### 1. 执行脚本的前提条件
1.1 操作系统：centos7.9（中文），其它系统尚未测试。
1.2 系统可以连接互联网。
1.3 系统中有oracle11gr2的安装包（两个zip文件，无需解压。如果没有，会提示下载，并给出下载地址。）
### 2. 基本操作
2.1 脚本会使防火墙放行1521端口

2.2 会关闭SElinux,关闭后需要重启计算机，并重新运行脚本（手动）

2.3 会将主机名已设置为 oracledb （可在脚本中修改）

2.4 更改用户 oracle 的密码为“oracle”（可在脚本中修改）

2.5 会获取系统中最大分区，并询问是否使用默认安装路径 (data/app/oracle 在最大分区  中)?或由用户自定义安装路径。

2.6 安装目录已创建，并设置正确的权限。

2.7 安装依赖包

2.8 查找安装包路径，并解压安装包到/software/database

2.9 修改内核参数

2.10 修改系统资源限制

2.11 修改dbinstall.rsp（安装响应）文件内容，其中重要的参数有：

    ORACLE_HOSTNAME=oracledb
    INVENTORY_LOCATION=$ORACLE_BASE/oraInventory
    SELECTED_LANGUAGES=en,zh_CN
    ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
    ORACLE_BASE=
    oracle.install.db.InstallEdition=EE
    oracle.install.db.config.starterdb.globalDBName=ora11g
    oracle.install.db.config.starterdb.SID=ora11g
    oracle.install.db.config.starterdb.characterSet=AL32UTF8
    DECLINE_SECURITY_UPDATES=true
2.12 修改dbca.rsp（建库响应）文件，sys用户密码可在此处修改，其中重要的参数有：

    GDBNAME = "orcl"
    SID = "orcl"
    CHARACTERSET = "AL32UTF8"
    NATIONALCHARACTERSET = "UTF8"
    SYSPASSWORD = "oracle"
    SYSTEMPASSWORD = "oracle"
2.13 安装数据库软件

2.14 检测是否安装成功，过程中提示grep: /data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录。

2.15 安装成功后自动执行安装后脚本。以 root 用户的身份执行以下脚本:

        1. /data/app/oracle/oraInventory/orainstRoot.sh
        2. /data/app/oracle/product/11.2.0/db_1/root.sh

2.16 安装监听程序

2.17 询问是否建库

2.18 输出安装信息

