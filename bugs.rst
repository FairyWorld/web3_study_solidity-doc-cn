.. index:: Bugs

.. _known_bugs:

##################
已知漏洞列表
##################

下面是一些已知与安全相关的漏洞的 JSON 格式列表，这些漏洞存在于 Solidity 编译器中。
该文件本身托管在 `GitHub 仓库 <https://github.com/ethereum/solidity/blob/develop/docs/bugs.json>`_ 中。
该列表追溯到 0.3.0 版本，已知仅存在于该版本之前的漏洞未列出。

还有另一个文件叫 `bugs_by_version.json <https://github.com/ethereum/solidity/blob/develop/docs/bugs_by_version.json>`_，可以用来检查哪些漏洞影响特定版本的编译器。

合约源代码验证工具以及其他与合约交互的工具应根据以下标准查阅此列表：

- 如果合约是使用夜间编译器版本而不是发布版本编译的，则稍显可疑。此列表不跟踪未发布或夜间版本。
- 如果合约是使用在合约创建时不是最新版本的编译器编译的，则也稍显可疑。对于从其他合约创建的合约，你必须追溯创建链到交易，并使用该交易的日期作为创建日期。
- 如果合约是使用包含已知漏洞的编译器编译的，并且合约是在已经发布了包含修复的新编译器版本的时间创建的，则高度可疑。

下面的已知漏洞 JSON 文件是一个对象数组，每个对象代表一个漏洞，包含以下键：

uid
    以 ``SOL-<year>-<number>`` 形式给定的漏洞唯一标识符。可能存在多个具有相同 uid 的条目。这意味着多个版本范围受到相同漏洞的影响。
name
    给定漏洞的唯一名称
summary
    漏洞的简短描述
description
    漏洞的详细描述
link
    具有更多详细信息的网站 URL， 可选
introduced
    包含该漏洞的首次发布的编译器版本， 可选
fixed
    不再包含该漏洞的首次发布的编译器版本
publish
    漏洞公开被知晓的日期， 可选
severity
    漏洞的严重性：very low， low， medium， high。考虑到在合约测试中的可发现性、发生的可能性和利用造成的潜在损害。
conditions
    触发漏洞必须满足的条件。可以使用以下键：
    ``optimizer``，布尔值，表示必须开启优化器才能启用该漏洞。
    ``evmVersion``，一个字符串，指示哪些 EVM 版本编译器设置会触发该漏洞。该字符串可以包含比较运算符。例如，``">=constantinople"`` 表示当 EVM 版本设置为 ``constantinople`` 或更高时，该漏洞存在。
    如果没有给出条件，则假设该漏洞存在。
check
    此字段包含不同的检查，报告智能合约是否包含该漏洞。第一种类型的检查是 JavaScript 正则表达式，需与源代码进行匹配（“source-regex”），如果漏洞存在。如果没有匹配，则该漏洞很可能不存在。如果有匹配，则该漏洞可能存在。为了提高准确性，检查应在去除注释后的源代码上应用。
    第二种类型的检查是要在 Solidity 程序的紧凑 AST 上检查的模式（“ast-compact-json-path”）。指定的搜索查询是一个 `JsonPath <https://github.com/json-path/JsonPath>`_ 表达式。如果 Solidity AST 的至少一条路径与查询匹配，则该漏洞可能存在。

.. literalinclude:: bugs.json
   :language: js