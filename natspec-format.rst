.. _natspec:

##############
NatSpec 规范
##############

Solidity 合约可以使用一种特殊形式的注释来提供丰富的函数、返回变量等文档。
这种特殊形式被称为以太坊自然语言规范规范（NatSpec）。

.. note::

  NatSpec 的灵感来源于 `Doxygen <https://en.wikipedia.org/wiki/Doxygen>`_。
  虽然它使用 Doxygen 风格的注释和标签，但并不打算与 Doxygen 保持严格兼容。请仔细检查下面列出的支持标签。

本 documentation 分为面向开发者的消息和面向最终用户的消息。这些消息可能会在最终用户（人类）与合约交互时显示（即签署交易时）。

建议 Solidity 合约对所有公共接口（ABI 中的所有内容）进行完整的 NatSpec 注释。

NatSpec 包括智能合约作者将使用的注释规范，并且 Solidity 编译器可以理解这些注释。下面详细说明了 Solidity 编译器的输出，它将这些注释提取为机器可读的格式。

NatSpec 还可以包括第三方工具使用的注释。这些通常通过 ``@custom:<name>`` 标签实现，一个好的用例是分析和验证工具。

.. _header-doc-example:

文档示例
=====================

文档插入在每个 ``contract``、``interface``、``library``、``function`` 和 ``event`` 之上，使用 Doxygen 注释规范。
对于 NatSpec，``public`` 状态变量等同于 ``function``。

-  对于 Solidity，你可以选择 ``///`` 用于单行或多行注释，或使用 ``/**`` 并以 ``*/`` 结束。

-  对于 Vyper，使用 ``"""`` 并缩进到内部内容，带有裸注释。请参见 `Vyper documentation <https://docs.vyperlang.org/en/latest/natspec.html>`__。

以下示例展示了一个合约和一个函数，使用了所有可用标签。

.. note::

  Solidity 编译器仅在标签为外部或公共时解释标签。
  你可以为内部和私有函数使用类似的注释，但这些将不会被解析。

  未来可能会有所改变。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.2 < 0.9.0;

    /// @title A simulator for trees
    /// @author Larry A. Gardner
    /// @notice You can use this contract for only the most basic simulation
    /// @dev All function calls are currently implemented without side effects
    /// @custom:experimental This is an experimental contract.
    contract Tree {
        /// @notice Calculate tree age in years, rounded up, for live trees
        /// @dev The Alexandr N. Tetearing algorithm could increase precision
        /// @param rings The number of rings from dendrochronological sample
        /// @return Age in years, rounded up for partial years
        /// @return Name of the tree
        function age(uint256 rings) external virtual pure returns (uint256, string memory) {
            return (rings + 1, "tree");
        }

        /// @notice Returns the amount of leaves the tree has.
        /// @dev Returns only a fixed number.
        function leaves() external virtual pure returns(uint256) {
            return 2;
        }
    }

    contract Plant {
        function leaves() external virtual pure returns(uint256) {
            return 3;
        }
    }

    contract KumquatTree is Tree, Plant {
        function age(uint256 rings) external override pure returns (uint256, string memory) {
            return (rings + 2, "Kumquat");
        }

        /// Return the amount of leaves that this specific kind of tree has
        /// @inheritdoc Tree
        function leaves() external override(Tree, Plant) pure returns(uint256) {
            return 3;
        }
    }

.. _header-tags:

标签
====

所有标签都是可选的。下表解释了每个 NatSpec 标签的目的及其使用场景。
作为特例，如果未使用标签，则 Solidity 编译器将以与 ``@notice`` 标签相同的方式解释 ``///`` 或 ``/**`` 注释。

=============== ====================================================================================== =============================
Tag                                                                                                    Context
=============== ====================================================================================== =============================
``@title``      A title that should describe the contract/interface                                    contract, library, interface, struct, enum
``@author``     The name of the author                                                                 contract, library, interface, struct, enum
``@notice``     Explain to an end user what this does                                                  contract, library, interface, function, public state variable, event, struct, enum, error
``@dev``        Explain to a developer any extra details                                               contract, library, interface, function, state variable, event, struct, enum, error
``@param``      Documents a parameter just like in Doxygen (must be followed by parameter name)        function, event, error
``@return``     Documents the return variables of a contract's function                                function, public state variable
``@inheritdoc`` Copies all missing tags from the base function (must be followed by the contract name) function, public state variable
``@custom:...`` Custom tag, semantics is application-defined                                           everywhere
=============== ====================================================================================== =============================

如果你的函数返回多个值，例如 ``(int quotient, int remainder)``则使用多个 ``@return`` 语句，格式与 ``@param`` 语句相同。

自定义标签以 ``@custom:`` 开头，后面必须跟一个或多个小写字母或连字符。
但不能以连字符开头。它们可以在任何地方使用，并且是开发者文档的一部分。

.. _header-dynamic:

动态表达式
-------------------

Solidity 编译器将根据本指南将 NatSpec 文档从你的 Solidity 源代码传递到 JSON 输出。
此 JSON 输出的消费者，例如最终用户客户端软件，可能会直接将其呈现给最终用户，或者可能会应用一些预处理。

例如，一些客户端软件将渲染：

.. code:: Solidity

   /// @notice This function will multiply `a` by 7

给最终用户呈现为：

.. code:: text

    This function will multiply 10 by 7

如果调用一个函数并且输入 ``a`` 被赋值为 10。

.. _header-inheritance:

继承注意事项
-----------------

没有 NatSpec 的函数将自动继承其基函数的文档。例外情况包括：

* 当参数名称不同。
* 当有多个基函数时。
* 当有显式的 ``@inheritdoc`` 标签指定应使用哪个合约进行继承。

.. _header-output:

文档输出
====================

当被编译器解析时，来自上述示例的文档将生成两个不同的 JSON 文件。一个是供最终用户在执行函数时作为通知使用，另一个供开发者使用。
如果上述合约保存为 ``ex1.sol``，则可以使用以下命令生成文档：

.. code-block:: shell

   solc --userdoc --devdoc ex1.sol

输出如下。

.. note::
    从 Solidity 版本 0.6.11 开始，NatSpec 输出还包含 ``version`` 和 ``kind`` 字段。
    当前 ``version`` 设置为 ``1``，而 ``kind`` 必须是 ``user`` 或 ``dev`` 之一。
    将来可能会引入新版本，弃用旧版本。

.. _header-user-doc:

用户文档
------------------

上述文档将为 ``Tree`` 合约生成以下用户文档 JSON 文件作为输出：

.. code-block:: json

    {
      "version" : 1,
      "kind" : "user",
      "methods" :
      {
        "age(uint256)" :
        {
          "notice" : "Calculate tree age in years, rounded up, for live trees"
        }
        "leaves()" :
        {
            "notice" : "Returns the amount of leaves the tree has."
        }
      },
      "notice" : "You can use this contract for only the most basic simulation"
    }

请注意，查找方法的关键是函数的规范签名，如 :ref:`合约 ABI <abi_function_selector>` 中定义的，而不仅仅是函数的名称。

.. _header-developer-doc:

开发者文档
-----------------------

除了用户文档文件外，还应生成开发者文档 JSON 文件，格式如下：

.. code-block:: json

    {
      "version" : 1,
      "kind" : "dev",
      "author" : "Larry A. Gardner",
      "details" : "All function calls are currently implemented without side effects",
      "custom:experimental" : "This is an experimental contract.",
      "methods" :
      {
        "age(uint256)" :
        {
          "details" : "The Alexandr N. Tetearing algorithm could increase precision",
          "params" :
          {
            "rings" : "The number of rings from dendrochronological sample"
          },
          "returns" : {
            "_0" : "Age in years, rounded up for partial years",
            "_1" : "Name of the tree"
          }
        },
        "leaves()" :
        {
            "details" : "Returns only a fixed number."
        }
      },
      "title" : "A simulator for trees"
    }