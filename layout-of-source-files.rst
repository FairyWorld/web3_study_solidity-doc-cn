.. include:: glossaries.rst

********************************
Solidity 源文件的布局
********************************

源文件可以包含任意数量的
:ref:`contract definitions<contract_structure>`, import_ ,
:ref:`pragma<pragma>` 和 :ref:`using for<using-for>`，以及
:ref:`struct<structs>`、:ref:`enum<enums>`、:ref:`function<functions>`、:ref:`error<errors>`
和 :ref:`常量<constants>` 的定义。

.. index:: ! license, spdx

SPDX 许可证标识符
=======================

如果智能合约的源代码开源了，则可以更好地建立信任。由于提供源代码总是涉及到与版权相关的法律问题，Solidity 编译器鼓励使用机器可读的 `SPDX 许可证标识符 <https://spdx.org>`_。
每个源文件应以指示其许可证的注释开头：

``// SPDX-License-Identifier: MIT``

编译器不会验证许可证是否属于 `SPDX 允许的列表 <https://spdx.org/licenses/>`_，
但它会将提供的字符串包含在 :ref:`字节码元数据 <metadata>` 中。

如果你不想指定许可证，或者源代码不是开源的，请使用特殊值 ``UNLICENSED``。
请注意，``UNLICENSED``（不允许使用，不在 SPDX 许可证列表中）与 ``UNLICENSE``（授予所有人所有权利）是不同的。
Solidity 遵循 `npm 的建议 <https://docs.npmjs.com/cli/v7/configuring-npm/package-json#license>`_。

提供此注释当然并不免除你与许可证相关的其他义务，例如在每个源文件中提及特定的许可证头或原始版权持有者。

该注释在文件的任何地方都被编译器识别，但建议将其放在文件的顶部。

有关如何使用 SPDX 许可证标识符的更多信息，请访问 `SPDX 网站 <https://spdx.dev/learn/handling-license-info/#how>`_。

.. index:: ! pragma

.. _pragma:

编译指令
=======

``pragma`` 关键字用于启用某些编译器特性或检查。|pragma| 通常只对本文件有效，因此如果你希望在整个项目中启用它，必须将其添加到所有文件中。
如果你 :ref:`导入<import>` 另一个文件，该文件的编译指令不会自动应用于导入文件。

.. index:: ! pragma;version

.. _version_pragma:

版本编译指令
--------------

源文件可以（并且应该）用版本编译指令进行注释，以拒绝与可能引入不兼容更改的未来编译器版本的编译。
我们尽量将这些更改保持在绝对最小，并以语义变化也需要语法变化的方式引入，但这并不总是可能。
因此，至少对于包含重大更改的版本，通读变更日志始终是个好主意。这些版本的形式总是 ``0.x.0`` 或 ``x.0.0``。

版本编译指令的用法如下：``pragma solidity ^0.5.2;``

包含上述行的源文件在版本低于 0.5.2 的编译器上无法编译，并且在版本从 0.6.0 开始的编译器上也无法工作（第二个条件是通过使用 ``^`` 添加的）。
因为在版本 ``0.6.0`` 之前不会有重大更改，所以你可以确保你的代码按你预期的方式编译。编译器的确切版本并不固定，因此仍然可以进行错误修复版本。

可以为编译器版本指定更复杂的规则，这些规则遵循 `npm <https://docs.npmjs.com/cli/v6/using-npm/semver>`_ 使用的相同语法。

.. note::
  使用版本编译指令 *并不会* 更改编译器的版本。
  它也 *不会* 启用或禁用编译器的特性。
  它只是  指示编译器检查其版本是否与编译指令要求的版本匹配。如果不匹配，编译器会发出错误。

.. index:: ! ABI coder, ! pragma; abicoder, pragma; ABIEncoderV2
.. _abi_coder:

ABI 编码器编译指令
----------------

通过使用 ``pragma abicoder v1`` 或 ``pragma abicoder v2``，可以在 ABI 编码器和解码器的两个实现之间进行选择。

新的 ABI 编码器（v2）能够编码和解码任意嵌套的数组和结构体。
除了支持更多类型外，它还涉及更广泛的验证和安全检查，这可能导致更高的 gas 成本，但也提高了安全性。
从 Solidity 0.6.0 开始，它被认为是非实验性的，并且从 Solidity 0.8.0 开始默认启用。
旧的 ABI 编码器仍然可以通过 ``pragma abicoder v1;`` 进行选择。

新编码器支持的类型集是旧编码器支持的类型的严格超集。使用它的合约可以与不使用它的合约进行交互而没有限制。
反之，只有在非 ``abicoder v2`` 合约不尝试进行需要解码新编码器仅支持的类型的调用时，才可能。
编译器可以检测到这一点，并会发出错误。仅仅为你的合约启用 ``abicoder v2`` 就足以消除错误。

.. note::
  此编译指令适用于在激活它的文件中定义的所有代码，无论该代码最终在哪里。 
  这意味着一个源文件被选择为使用 ABI 编码器 v1 编译的合约仍然可以通过从另一个合约继承来包含使用新编码器的代码。 
  这在新类型仅在内部使用而不在外部函数签名中使用时是允许的。

.. note::
  在 Solidity 0.7.4 之前，可以通过使用 ``pragma experimental ABIEncoderV2`` 来选择 ABI 编码器 v2，但无法显式选择编码器 v1，因为它是默认的。

.. index:: ! pragma; experimental
.. _experimental_pragma:

实验性编译指令
-------------------

第二个编译指令是实验性编译指令。它可以用于启用尚未默认启用的编译器或语言特性。
当前支持以下实验性编译指令：

.. index:: ! pragma; ABIEncoderV2

ABIEncoderV2
~~~~~~~~~~~~

由于 ABI 编码器 v2 不再被视为实验性，
自 Solidity 0.7.4 起可以通过 ``pragma abicoder v2`` 进行选择（请参见上文）。

.. index:: ! pragma; SMTChecker
.. _smt_checker:

SMTChecker
~~~~~~~~~~

当构建 Solidity 编译器时，必须启用此组件，因此并非所有 Solidity 二进制文件都可用。
:ref:`构建说明<smt_solvers_build>` 解释了如何激活此选项。
在大多数版本中，它在 Ubuntu PPA 版本中被激活，但在 Docker 镜像、Windows 二进制文件或静态构建的 Linux 二进制文件中则未被激活。 
如果你在本地安装了 SMT 求解器并通过节点（而不是通过浏览器）运行 solc-js，则可以通过 `smtCallback <https://github.com/ethereum/solc-js#example-usage-with-smtsolver-callback>`_ 激活它。

如果你使用 ``pragma experimental SMTChecker;``，则会获得额外的 :ref:`安全警告<formal_verification>`，这些警告是通过查询 SMT 求解器获得的。
该组件尚不支持 Solidity 语言的所有特性，并且可能会输出许多警告。如果它报告不支持的特性，则分析可能并不完全可靠。

.. index:: source file, ! import, module, source unit

.. _import:
导入其他源文件
============================

语法和语义
--------------------

Solidity 支持导入语句，以帮助模块化代码，这些语句类似于 JavaScript 中可用的导入语句（从 ES6 开始）。
然而，Solidity 不支持 `default export <https://developer.mozilla.org/en-US/docs/web/javascript/reference/statements/export#description>`_ 的概念。

在全局级别，你可以使用以下形式的导入语句：

.. code-block:: solidity

    import "filename";

``filename`` 部分称为 *导入路径*。
该语句将 "filename" 中的所有全局符号（以及在其中导入的符号）导入到当前全局作用域中（与 ES6 不同，但对 Solidity 向后兼容）。
不推荐使用这种形式，因为它不可预测地污染命名空间。
如果你在 "filename" 中添加新的顶级项，它们会自动出现在所有以这种方式从 "filename" 导入的文件中。最好显式导入特定符号。

以下示例创建了一个新的全局符号 ``symbolName``，其成员是来自 ``"filename"`` 的所有全局符号：

.. code-block:: solidity

    import * as symbolName from "filename";

这使得所有全局符号都可以以 ``symbolName.symbol`` 的格式使用。

这种语法的一个变体不是 ES6 的一部分，但可能有用：

.. code-block:: solidity

  import "filename" as symbolName;

这等同于 ``import * as symbolName from "filename";``。

如果存在命名冲突，可以在导入时重命名符号。例如，下面的代码创建了新的全局符号 ``alias`` 和 ``symbol2``，分别引用 ``"filename"`` 中的 ``symbol1`` 和 ``symbol2``。

.. code-block:: solidity

    import {symbol1 as alias, symbol2} from "filename";

.. index:: virtual filesystem, source unit name, import; path, filesystem path, import callback, Remix IDE

导入路径
------------

为了能够在所有平台上支持可重复构建，Solidity 编译器必须抽象出源文件存储的文件系统的细节。
因此，导入路径并不直接指向主机文件系统中的文件。
相反，编译器维护一个内部数据库（简称 *虚拟文件系统* 或 *VFS*），其中每个源单元被分配一个唯一的 *源单元名称*，这是一个不透明且无结构的标识符。
在导入语句中指定的导入路径被转换为源单元名称，并用于在该数据库中查找相应的源单元。

使用 :ref:`标准 JSON <compiler-api>` API，可以直接提供所有源文件的名称和内容作为编译器输入的一部分。
在这种情况下，源单元名称是完全任意的。
然而，如果你希望编译器自动查找并加载源代码到 VFS，你的源单元名称需要以某种方式结构化，以便 :ref:`导入回调 <import-callback>` 能够找到它们。
当使用命令行编译器时，默认的导入回调仅支持从主机文件系统加载源代码，这意味着你的源单元名称必须是路径。
一些环境提供更灵活的自定义回调。
例如，`Remix IDE <https://remix.ethereum.org/>`_ 提供了一个可以让你 `从 HTTP、IPFS 和 Swarm URL 导入文件或直接引用 NPM 注册表中的包 <https://remix-ide.readthedocs.io/en/latest/import.html>`_ 的回调。

有关虚拟文件系统和编译器使用的路径解析逻辑的完整描述，请参见 :ref:`路径解析 <path-resolution>`。

.. index:: ! comment, natspec

注释
========

单行注释（``//``）和多行注释（``/*...*/``）都是可以的。

.. code-block:: solidity

    // 这是一个单行注释。

    /*
    这是一个
    多行注释。
    */

.. note::
  单行注释由任何 Unicode 行终止符（LF、VF、FF、CR、NEL、LS 或 PS）在 UTF-8 编码中终止。
  终止符仍然是注释后的源代码的一部分，因此如果它不是 ASCII 符号（这些是 NEL、LS 和 PS），将导致解析器错误。

此外，还有另一种类型的注释，称为 NatSpec 注释，详细信息见 :ref:`风格指南<style_guide_natspec>`。
它们使用三重斜杠（``///``）或双星号块（``/** ... */``）编写，应该直接放在函数声明或语句的上方。