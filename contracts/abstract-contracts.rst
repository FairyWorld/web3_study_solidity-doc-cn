.. index:: ! contract;abstract, ! abstract contract

.. _abstract-contract:

******************
抽象合约
******************

当合约的至少一个函数未实现或未为其所有基合约构造函数提供参数时，合约必须标记为抽象。即使不是这种情况，合约仍然可以标记为抽象，例如当您不打算直接创建该合约时。抽象合约类似于 :ref:`interfaces`，但接口在声明内容上更为有限。

抽象合约使用 ``abstract`` 关键字声明，如下例所示。请注意，该合约需要定义为抽象，因为函数 ``utterance()`` 已声明，但未提供实现（未给出实现体 ``{ }``）。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    abstract contract Feline {
        function utterance() public virtual returns (bytes32);
    }

这样的抽象合约不能直接实例化。如果一个抽象合约本身实现了所有定义的函数，这一点也是如此。抽象合约作为基类的用法在以下示例中展示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    abstract contract Feline {
        function utterance() public pure virtual returns (bytes32);
    }

    contract Cat is Feline {
        function utterance() public pure override returns (bytes32) { return "miaow"; }
    }

如果一个合约继承自抽象合约并且未通过重写实现所有未实现的函数，则该合约也需要标记为抽象合约。

请注意，未实现的函数与 :ref:`Function Type <function_types>` 是不同的，尽管它们的语法看起来非常相似。

未实现函数的示例（函数声明）：

.. code-block:: solidity

    function foo(address) external returns (address);

函数类型的变量声明示例：

.. code-block:: solidity

    function(address) external returns (address) foo;

抽象合约将合约的定义与其实现解耦，提供更好的可扩展性和自我文档化，并促进像 `Template method <https://en.wikipedia.org/wiki/Template_method_pattern>`_ 这样的模式，消除代码重复。抽象合约的用途与在接口中定义方法的用途相同。这是抽象合约设计者表示“我的任何子类必须实现此方法”的一种方式。

.. note::

  抽象合约不能用未实现的函数覆盖已实现的虚函数。