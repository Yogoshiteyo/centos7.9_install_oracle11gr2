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

2.11 修改dbinstall.rsp（安装响应）文件内容，可在modify_response_file_content1函数按需修改。中其中重要的参数有：

    ORACLE_HOSTNAME=oracledb
    SELECTED_LANGUAGES=en,zh_CN
    oracle.install.db.InstallEdition=EE
    oracle.install.db.config.starterdb.globalDBName=ora11g
    oracle.install.db.config.starterdb.SID=ora11g
    oracle.install.db.config.starterdb.characterSet=AL32UTF8
    DECLINE_SECURITY_UPDATES=true
2.12 修改dbca.rsp（建库响应）文件，可在modify_dbca_response_file函数中按需修改。其中重要的参数有：

    GDBNAME = "orcl"
    SID = "orcl"
    CHARACTERSET = "AL32UTF8"
    NATIONALCHARACTERSET = "UTF8"
    SYSPASSWORD = "oracle"
    SYSTEMPASSWORD = "oracle"
2.13 安装数据库软件

    开始安装 Oracle 数据库...
    开始安装：
    正在启动 Oracle Universal Installer...
    
    检查临时空间: 必须大于 120 MB。   实际为 275772 MB    通过
    检查交换空间: 必须大于 150 MB。   实际为 16383 MB    通过
    准备从以下地址启动 Oracle Universal Installer /tmp/OraInstall2024-04-28_01-56-37PM. 请稍候...\n
    Oracle 数据库安装完成。
    开始检查安装日志文件...
    grep: /data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
    [WARNING] [INS-32055] 主产品清单位于 Oracle 基目录中。
       原因: 主产品清单位于 Oracle 基目录中。
       操作: Oracle 建议将此主产品清单放置在 Oracle 基目录之外的位置中。
    可以在以下位置找到本次安装会话的日志:
     /data/app/oracle/oraInventory/logs/installActions2024-04-28_01-56-37PM.log


2.14 检测是否安装成功，过程中提示grep: /data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录。

    grep: /data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
    grep: /data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
    Oracle Database 11g 的 安装 已成功。 志文件 -
    请查看 '/data/app/oracle/oraInventory/logs/silentInstall2024-04-28_01-56-37PM.log' 以获取详细资料。

    以 root 用户的身份执行以下脚本:
        1. /data/app/oracle/oraInventory/orainstRoot.sh
        2. /data/app/oracle/product/11.2.0/db_1/root.sh

    
    Successfully Setup Software.
    安装成功。


2.15 安装成功后自动执行安装后脚本。以 root 用户的身份执行以下脚本:

    执行 /data/app/oracle/oraInventory/orainstRoot.sh
    更改权限/data/app/oracle/oraInventory.
    添加组的读取和写入权限。
    删除全局的读取, 写入和执行权限。 
    
    更改组名/data/app/oracle/oraInventory 到 oinstall.
    脚本的执行已完成。
    执行 /data/app/oracle/product/11.2.0/db_1/root.sh
    Check /data/app/oracle/product/11.2.0/db_1/install/root_oracledb_2024-04-28_14-30-44.log for the output of root script


2.16 安装监听程序

    开始配置监听...
    上一次登录：日 4月 28 14:27:21 CST 2024
    
    正在对命令行参数进行语法分析:
    参数"silent" = true
    参数"responsefile" = /software/database/response/netca.rsp
    完成对命令行参数进行语法分析。
    Oracle Net Services 配置:
    完成概要文件配置。
    Oracle Net 监听程序启动:
        正在运行监听程序控制:
          /data/app/oracle/product/11.2.0/db_1/bin/lsnrctl start LISTENER
        监听程序控制完成。
        监听程序已成功启动。
    监听程序配置完成。
    成功完成 Oracle Net Services 配置。退出代码是0
    \n
    监听创建完成。

2.17 询问是否建库

    是否需要创建实例？(y/n): y
    开始建库...
    上一次登录：日 4月 28 13:59:35 CST 2024
    复制数据库文件
    1% 已完成
    3% 已完成
    11% 已完成
    18% 已完成
    26% 已完成
    37% 已完成
    正在创建并启动 Oracle 实例
    40% 已完成
    45% 已完成
    50% 已完成
    55% 已完成
    56% 已完成
    60% 已完成
    62% 已完成
    正在进行数据库创建
    66% 已完成
    70% 已完成
    73% 已完成
    85% 已完成
    96% 已完成
    100% 已完成
    有关详细信息, 请参阅日志文件 "/data/app/oracle/cfgtoollogs/dbca/orcl11g/orcl11g.log"。
    静默建库已完成。


2.18 输出安装信息

    
    数据库信息
    
    *******************************************************************
    
    GDBNAME：orcl
    SID:orcl
    PORT:1521
    sys用户密码：oracle
    system用户密码：oracle
    字符集：AL32UTF8
    
    *******************************************************************
    
    脚本执行完成。
    
    *******************************************************************
    
    服务器信息
    
    *******************************************************************
    
    主机名：oracledb
    本机IP：192.168.3.68
    oracle用户密码：oracle
    
