# 在Centos7中使用一键脚本安装Oracle11g
## 1. 环境准备
1.1 系统版本：Centos7.9（2009）

1.2 Oracle版本：Oracle 11g 11.2.0.4

1.3 网络需求：可以连接互联网

1.4 一键安装：

```bash
curl -o oracle_install.sh https://files-cdn.cnblogs.com/files/blogs/827077/oracle_install.sh?t=1722301473 && chmod +x oracle_install.sh && ./oracle_install.sh
```
PS：此脚本主要为了实现公司内部标准化安装，提升效率，所以很多参数比如SID、密码等都素固定的。（就是我懒得）
## 2. 脚本执行过程
### 2.1 将安装包上传至任意目录
        p13390677_112040_Linux-x86-64_1of7.zip 1.3 GB (1395582860 字节)
        MD5 1616F61789891A56EAFD40DE79F58F28
        SHA-1 983461D6442B0833630475EC4885278588585651
        
        p13390677_112040_Linux-x86-64_2of7.zip 1.1 GB (1151304589 字节)
        MD5 67BA1E68A4F581B305885114768443D3
        SHA-1 2E628D8CAC5D1C6FFF15E728B1F227747BF2DED8
### 2.2 确保软件源可用，并有EPEL源
这是默认的源，可以看到有三个，分别是Base、Extras、Updates。但是由于官方源已经停止维护，repolist为0，即无软件包可用，所以需要更换软件源。

	[root@localhost ~]# yum repolist
	已加载插件：fastestmirror
	Determining fastest mirrors
	Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=stock error was
	14: curl#6 - "Could not resolve host: mirrorlist.centos.org; 未知的错误"
	Loading mirror speeds from cached hostfile
	Loading mirror speeds from cached hostfile
	Loading mirror speeds from cached hostfile
	源标识                                                      源名称                                                         状态
	base/7/x86_64                                               CentOS-7 - Base                                                0
	extras/7/x86_64                                             CentOS-7 - Extras                                              0
	updates/7/x86_64                                            CentOS-7 - Updates                                             0
	repolist: 0
更换阿里云软件源的脚本
```bash
curl -o chageyum.sh https://files-cdn.cnblogs.com/files/blogs/827077/chageyum.sh?t=1722300674 && chmod +x chageyum.sh && ./chageyum.sh
```
更换完成后

	[root@localhost ~]# yum repolist
	已加载插件：fastestmirror
	Loading mirror speeds from cached hostfile
	 * base: mirrors.aliyun.com
	 * extras: mirrors.aliyun.com
	 * updates: mirrors.aliyun.com
	源标识                                       源名称                                                                      状态
	base/7/x86_64                                CentOS-7 - Base - mirrors.aliyun.com                                        10,072
	epel/x86_64                                  Extra Packages for Enterprise Linux 7 - x86_64                              13,791
	extras/7/x86_64                              CentOS-7 - Extras - mirrors.aliyun.com                                         526
	updates/7/x86_64                             CentOS-7 - Updates - mirrors.aliyun.com                                      6,173
	repolist: 30,562
### 2.3 执行安装脚本
```bash
curl -o oracle_install.sh https://files-cdn.cnblogs.com/files/blogs/827077/oracle_install.sh?t=1722301473 && chmod +x oracle_install.sh && ./oracle_install.sh
```
### 2.4 关闭SELINUX
1）脚本提示是否关闭SElinux，这里选择‘y’

2）修改完Selinux配置后，提示重启计算机

	[root@localhost ~]# curl -o oracle_install.sh https://files-cdn.cnblogs.com/files/blogs/827077/oracle_install.sh?t=1722301473 && chmod +x oracle_install.sh && ./oracle_install.sh
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
									 Dload  Upload   Total   Spent    Left  Speed
	100 26899  100 26899    0     0  61891      0 --:--:-- --:--:-- --:--:-- 61979

	SELinux 将被禁用并需要重启。是否继续？ (y/n): y
	SELinux 配置已修改，请重启计算机，并确保 SELinux 状态为 Disabled。

	*******************************************************************
### 2.5 重启后再次执行脚本
再次执行脚本后

1）防火墙会放行1521端口

2）主机名设置为oracledb

```bash
./oracle_install.sh
```

	[root@localhost ~]# ./oracle_install.sh
	usage:  setenforce [ Enforcing | Permissive | 1 | 0 ]
	success
	success
	SELinux 已关闭。
	防火墙已放行1521端口

	*******************************************************************

	主机名已设置为 oracledb。
### 2.6 选择字符集
我这里选择了2：ZHS16GBK。这里只提供了两种，如需其他字符集请手动修改。

	*******************************************************************

	请选择字符集：
	1: AL32UTF8
	2: ZHS16GBK
	请输入选项（1 或 2）: 2
	更改用户 oracle 的密码 。
	passwd：所有的身份验证令牌已经成功更新。
	用户oracle已添加，密码为：oracle

	*******************************************************************

### 2.7 配置安装路径
1）选择‘y’——脚本会获取到系统中空间最大的目录，并将oracle安装到最大目录下的/data/app/oracle目录中。这里获取到的最大分区就是根目录。如果最大分区是x，则会安装放到/x/data/app/oracle中。

2）选择‘n’——可以自定义安装目录。注意自己指定目录时要确保目录有足够的空间。

	*******************************************************************
	是否使用默认安装路径 (//data/app/oracle 在最大分区 / 中)? (y/n): y
	安装目录已创建，并设置了正确的权限。
	用户未选择默认路径

	*******************************************************************
### 2.8 修改hosts文件
脚本会获取本机IP地址，并将IP地址和主机名添加到hosts文件中，并重启网络服务

	*******************************************************************

	192.168.3.70     oracledb
	已更新主机文件。

	*******************************************************************

	网络服务已重启。

	*******************************************************************
### 2.9 安装依赖包
有几个没有的包，不影响安装

	开始安装依赖包...
	已加载插件：fastestmirror
	Loading mirror speeds from cached hostfile
	 * base: mirrors.aliyun.com
	 * extras: mirrors.aliyun.com
	 * updates: mirrors.aliyun.com
	没有可用软件包 compat-libstdc++-33*.devel。
	没有可用软件包 compat-libstdc++-33*.devel。
	软件包 libaio-0.3.109-13.el7.x86_64 已安装并且是最新版本
	没有可用软件包 libaio-devel*.devel。
	·
	·
	·
	·
	·
	更新完毕:
	  binutils.x86_64 0:2.27-44.base.el7_9.1                            glibc.x86_64 0:2.17-326.el7_9.3

	作为依赖被升级:
	  glibc-common.x86_64 0:2.17-326.el7_9.3      nspr.x86_64 0:4.35.0-1.el7_9      nss-softokn-freebl.x86_64 0:3.90.0-6.el7_9
	  nss-util.x86_64 0:3.90.0-1.el7_9

	完毕！
	依赖包安装完成。

	*******************************************************************
### 2.10 解压安装包
1）搜索名称为linux.x64_11gR2_database开头的文件

2）将其解压到临时文件夹/tmp/database/中

3）所有包解压完成后，将/tmp/database/移动到/software/database

	*******************************************************************

	正在解压安装包: /tmp/linux.x64_11gR2_database_2of7.zip  解压完成.
	正在解压安装包: /tmp/linux.x64_11gR2_database_1of7.zip  解压完成.
	正在移动数据库目录内容: /tmp/database/* 到 /software/database
	正在删除原始数据库目录: /tmp/database
	安装包已解压到 /software/database。

	*******************************************************************
### 2.11 配置相关参数
1）修改内核参数			/etc/sysctl.conf

2）修改系统资源限制			/etc/security/limits.conf

3）修改用户限制文件			/etc/pam.d/login

4）修改安装响应文件			/software/database/response/db_install.rsp

5）修改建库响应文件			/software/database/response/dbca.rsp

6）修改oracle用户环境变量	/home/oracle/.bash_profile

	*******************************************************************

	内核参数配置已修改。
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

	*******************************************************************

	系统资源限制已修改。

	*******************************************************************

	用户限制文件已修改。

	*******************************************************************

	安装响应文件内容已修改。

	*******************************************************************

	用户未选择默认路径
	dbinstall.rsp已修改

	*******************************************************************

	dbca.rsp 文件已修改。
	.bash_profile文件已修改。

### 2.12 开始安装
1）出现“[WARNING] [INS-32055] 主产品清单位于 Oracle 基目录中。”警告，不影响安装。

2）出现“grep: //data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录”提示，系脚本正在检测oracle是否安装成功，是正常步骤，不要中断。时间长短因服务器性能而定，一般再5分钟左右。

	开始安装 Oracle 数据库...
	开始安装：
	正在启动 Oracle Universal Installer...

	检查临时空间: 必须大于 120 MB。   实际为 37763 MB    通过
	检查交换空间: 必须大于 150 MB。   实际为 5119 MB    通过
	准备从以下地址启动 Oracle Universal Installer /tmp/OraInstall2024-07-30_09-57-10AM. 请稍候...\n
	Oracle 数据库安装完成。
	开始检查安装日志文件...
	grep: //data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
	[WARNING] [INS-32055] 主产品清单位于 Oracle 基目录中。
	   原因: 主产品清单位于 Oracle 基目录中。
	   操作: Oracle 建议将此主产品清单放置在 Oracle 基目录之外的位置中。
	可以在以下位置找到本次安装会话的日志:
	 //data/app/oracle/oraInventory/logs/installActions2024-07-30_09-57-10AM.log
	grep: //data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
	grep: //data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
	grep: //data/app/oracle/oraInventory/logs/silentInstall*.log: 没有那个文件或目录
	Oracle Database 11g 的 安装 已成功。 志文件 -
	请查看 '//data/app/oracle/oraInventory/logs/silentInstall2024-07-30_09-57-10AM.log' 以获取详细资料。

	以 root 用户的身份执行以下脚本:
			1. //data/app/oracle/oraInventory/orainstRoot.sh
			2. /data/app/oracle/product/11.2.0/db_1/root.sh


	Successfully Setup Software.
### 2.13 执行安装后脚本
安装成功后，会自动执行上面两个脚本

	安装成功。装日志文件 \r正在检查安装日志文件 -
	以 root 用户的身份执行以下脚本：
	1. //data/app/oracle/oraInventory/orainstRoot.sh
	2. //data/app/oracle/product/11.2.0/db_1/root.sh
	执行 //data/app/oracle/oraInventory/orainstRoot.sh
	更改权限//data/app/oracle/oraInventory.
	添加组的读取和写入权限。
	删除全局的读取, 写入和执行权限。

	更改组名//data/app/oracle/oraInventory 到 oinstall.
	脚本的执行已完成。
	执行 //data/app/oracle/product/11.2.0/db_1/root.sh
	Check /data/app/oracle/product/11.2.0/db_1/install/root_oracledb_2024-07-30_09-59-41.log for the output of root script
### 2.14 配置监听
安装后脚本执行完成后，开始自动配置监听

	开始配置监听...
	上一次登录：二 7月 30 09:57:09 CST 2024

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

	*******************************************************************
### 2.15 静默建库
响应文件已经在上面修改好了，这里直接根据需求选择是否建库即可

	是否需要创建实例？(y/n): y
	开始建库...
	上一次登录：二 7月 30 09:59:41 CST 2024
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
	有关详细信息, 请参阅日志文件 "/data/app/oracle/cfgtoollogs/dbca/orcl/orcl.log"。
	静默建库已完成。

	*******************************************************************
### 2.16 为oracle服务和监听配置开机自启

	*******************************************************************

	Created symlink from /etc/systemd/system/multi-user.target.wants/oracle.service to /etc/systemd/system/oracle.service.
	已添加开机自启

	*******************************************************************
### 2.17 输出安装信息
	*******************************************************************

	服务器信息

	*******************************************************************

	主机名：oracledb
	本机IP：192.168.3.70
	oracle用户密码：oracle

	*******************************************************************

	数据库信息

	*******************************************************************

	GDBNAME：orcl
	SID:orcl
	PORT:1521
	sys用户密码：oracle
	system用户密码：oracle
	字符集：ZHS16GBK

	*******************************************************************

	脚本执行完成。
