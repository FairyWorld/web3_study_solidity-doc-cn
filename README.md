# Solidity 中文文档 


本份 Solidity 中文文档是区块链社区通力合作下的杰作。翻译最初 HiBlock 社区发起，后经过 [登链社区](https://learnblockchain.cn) 社区成员根据最新版本补充翻译。

文档托管在 [https://learnblockchain.cn/docs/solidity/](https://learnblockchain.cn/docs/solidity/)



## 参与翻译

参见当前目录下文档：[translation_process.md](translation_process.md)

## 本地环境设置

1. 安装Python https://www.python.org/downloads/  
    版本要求 <= 3.11.10
    
2. 安装Sphinx（用于生成文档的工具） https://www.sphinx-doc.org/en/master/usage/installation.html

3. 配置环境变量
    ```
    # Github 仓库
    export RTD_GITHUB_REPO="solidity-doc-cn"

    # Github 仓库用户名
    export RTD_GITHUB_USER="lbc-team"
    ```

4. 运行 `./docs.sh` 来安装依赖并构建项目：

```sh
./docs.sh
```

这将把生成的HTML文件输出到 _build/ 目录下。

## 服务环境

```py
python3 -m http.server -d _build/html --cgi 8080
```

访问开发服务器 http://localhost:8080。




## 致谢  
### 管理员  

[Tiny熊](https://github.com/xilibi2003), [左洪斌](https://github.com/hongbinzuo),[杨镇](https://github.com/riversyang),[王兴宇](https://github.com/wxy),[姜信宝](https://github.com/bobjiang), [dwong](https://github.com/0xdwong) 

### 贡献者列表

以下排名不分先后。

[Toya](https://github.com/toyab), [侯伯薇](https://github.com/houbowei), [李捷](https://github.com/oldcodeoberyn), [虞是乎](https://github.com/ysqi), [周锷](https://github.com/ghostrd), [毛明旺](https://github.com/dennisWind), [孔庆丰](https://github.com/buffalo2004), [卓跃萍](https://github.com/JocelynZhuo), [左洪斌](https://github.com/hongbinzuo),[杨镇](https://github.com/riversyang),[王兴宇](https://github.com/wxy),[姜信宝](https://github.com/bobjiang), [盖盖](https://github.com/gitferry), [Kerwin](https://github.com/KerwinChung2018), [蔡晓静](https://github.com/caixiaoqing627) , [Justin](https://github.com/justinquan) , [dwong](https://github.com/0xdwong)  

翻译工作是一个持续的过程（这份文档目前也还有部分未完成），我们热情邀请热爱区块链技术的小伙伴一起参与，欢迎加入我们 Group： https://github.com/lbc-team 

申请成为译者，可以勾搭 Tiny熊（微信：xlbxiong）。





