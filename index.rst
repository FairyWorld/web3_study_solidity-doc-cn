Solidity 中文文档
========
译者说明：这里是 **Solidity官方推荐中文版**，本文档根据当前 `Solidity官方文档 <https://solidity.readthedocs.io/>`_ 最新版本（当前为v0.8.28）进行翻译。


Solidity中文翻译最初由 HiBlock 社区发起，后由 `登链社区 <https://learnblockchain.cn/>`_ 社区持续维护更新。

翻译工作是一个持续的过程（这份文档依旧有部分未完成），我们热情邀请热爱区块链技术的小伙伴一起参与，欢迎加入我们 `翻译小组 <https://github.com/lbc-team>`_ 。

本中文文档大部分情况下，英中直译，但有时为了更好的理解也会使用意译，如需转载请联系Tiny熊（微信：xlbxiong）.


Solidity 是一种面向对象的高级语言，用于实现智能合约。
智能合约是管理以太坊状态中账户行为的程序。

Solidity 是一种 `大括号语言 <https://en.wikipedia.org/wiki/List_of_programming_languages_by_type#Curly_bracket_languages>`_，旨在针对以太坊虚拟机 (EVM)。
它受到 C++、Python 和 JavaScript 的影响。
你可以在 :doc:`语言影响 <language-influences>` 部分找到有关 Solidity 受哪些语言启发的更多详细信息。

Solidity 是静态类型的，支持继承、库和复杂的用户定义类型等特性。

使用 Solidity，你可以创建用于投票、众筹、盲拍和多重签名钱包等用途的合约。

在部署合约时，你应使用最新发布的 Solidity 版本。
除了特殊情况外，只有最新版本会收到 `安全修复 <https://github.com/ethereum/solidity/security/policy#supported-versions>`_。
此外，破坏性更改以及新功能会定期引入。
我们目前使用 0.y.z 版本号 `来表示这种快速变化的步伐 <https://semver.org/#spec-item-4>`_。

.. warning::

  Solidity 最近发布了 0.8.x 版本，引入了许多破坏性更改。
  确保你阅读 :doc:`完整列表 <080-breaking-changes>`。

欢迎提出改进 Solidity 或本文件的想法，
请阅读我们的 :doc:`贡献者指南 <contributing>` 以获取更多详细信息。

.. Hint::

  你可以通过点击左下角的版本下拉菜单并选择首选下载格式
  下载此文档的 PDF、HTML 或 Epub 版本。


入门
---------------

**1. 了解智能合约基础知识**

如果你对智能合约的概念不熟悉，我们建议你从“智能合约简介”部分开始，该部分涵盖以下内容：

* :ref:`一个用 Solidity 编写的简单示例智能合约 <simple-smart-contract>`。
* :ref:`区块链基础 <blockchain-basics>`。
* :ref:`以太坊虚拟机 <the-ethereum-virtual-machine>`。

**2. 了解 Solidity**

一旦你熟悉了基础知识，我们建议你阅读 :doc:`“Solidity 示例” <solidity-by-example>`
和“语言描述”部分，以理解该语言的核心概念。

**3. 安装 Solidity 编译器**

有多种方法可以安装 Solidity 编译器，
只需选择你喜欢的选项并按照 :ref:`安装页面 <installing-solidity>` 上的步骤进行操作。

.. hint::
  你可以直接在浏览器中尝试代码示例，
  使用 `Remix IDE <https://remix.ethereum.org>`_。
  Remix 是一个基于 Web 浏览器的 IDE，允许你编写、部署和管理 Solidity 智能合约，
  无需在本地安装 Solidity。

.. warning::
    由于软件是人编写的，就可能会存在漏洞。
    因此，在编写智能合约时，你应遵循已建立的软件开发最佳实践。
    这包括代码审查、测试、审计和正确性证明。
    智能合约用户有时对代码的信心超过其作者，而区块链和智能合约有其独特的问题需要注意，
    因此在处理生产代码之前，请确保你阅读 :ref:`security_considerations` 部分。

**4. 了解更多**

如果你想了解更多关于在以太坊上构建去中心化应用程序的信息，
`以太坊开发者资源 <https://ethereum.org/en/developers/>`_ 可以为你提供更多关于以太坊的通用文档，
以及广泛的教程、工具和开发框架。

如果你有任何问题，可以尝试搜索答案或在
`以太坊 StackExchange <https://ethereum.stackexchange.com/>`_ 上提问，
或在我们的 `Gitter 频道 <https://gitter.im/ethereum/solidity>`_ 上询问。


内容
========

:ref:`Keyword Index <genindex>`, :ref:`Search Page <search>`

.. toctree::
   :maxdepth: 2
   :caption: 基础

   introduction-to-smart-contracts.rst
   solidity-by-example.rst
   installing-solidity.rst

.. toctree::
   :maxdepth: 2
   :caption: Solidity 语言详解

   layout-of-source-files.rst
   structure-of-a-contract.rst
   types.rst
   units-and-global-variables.rst
   control-structures.rst
   contracts.rst
   assembly.rst
   cheatsheet.rst
   grammar.rst

.. toctree::
   :maxdepth: 2
   :caption: 编译器

   using-the-compiler.rst
   analysing-compilation-output.rst
   ir-breaking-changes.rst

.. toctree::
   :maxdepth: 2
   :caption: 深入 Solidity 内部

   internals/layout_in_storage.rst
   internals/layout_in_memory.rst
   internals/layout_in_calldata.rst
   internals/variable_cleanup.rst
   internals/source_mappings.rst
   internals/optimizer.rst
   metadata.rst
   abi-spec.rst

.. toctree::
   :maxdepth: 2
   :caption: 指导内容

   security-considerations.rst
   bugs.rst
   050-breaking-changes.rst
   060-breaking-changes.rst
   070-breaking-changes.rst
   080-breaking-changes.rst

.. toctree::
   :maxdepth: 2
   :caption: 附加材料

   natspec-format.rst
   smtchecker.rst
   yul.rst
   path-resolution.rst

.. toctree::
   :maxdepth: 2
   :caption: 资源

   style-guide.rst
   common-patterns.rst
   resources.rst
   contributing.rst
   language-influences.rst
   brand-guide.rst