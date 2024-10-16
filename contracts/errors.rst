.. index:: ! error, revert, require, ! selector; of an error
.. _errors:

*************
自定义错误
*************

Solidity 中的错误提供了一种方便且节省 gas 的方式来向用户解释操作失败的原因。它们可以在合约内部和外部（包括接口和库）定义。

它们必须与 :ref:`revert 语句 <revert-statement>` 或 :ref:`require 函数 <assert-and-require-statements>` 一起使用。
在 ``revert`` 语句或 ``require`` 调用中，如果条件被评估为 false，则当前调用中的所有更改都会被回滚，错误数据会传回调用者。

下面的示例展示了在函数 ``transferWithRevertError`` 中使用 ``revert`` 语句的自定义错误，以及在函数 ``transferWithRequireError`` 中使用 ``require`` 的新方法。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.27;

    /// 转账余额不足。需要 `required` 但只有
    /// `available` 可用。
    /// @param available 可用余额。
    /// @param required 请求转账的金额。
    error InsufficientBalance(uint256 available, uint256 required);

    contract TestToken {
        mapping(address => uint) balance;
        function transferWithRevertError(address to, uint256 amount) public {
            if (amount > balance[msg.sender])
                revert InsufficientBalance({
                    available: balance[msg.sender],
                    required: amount
                });
            balance[msg.sender] -= amount;
            balance[to] += amount;
        }
        function transferWithRequireError(address to, uint256 amount) public {
            require(amount <= balance[msg.sender], InsufficientBalance(balance[msg.sender], amount));
            balance[msg.sender] -= amount;
            balance[to] += amount;
        }
        // ...
    }

另一个重要的细节是，当使用 ``require`` 和自定义错误时，错误基础的回滚原因的内存分配仅在回滚的情况下发生，这与常量和字符串字面量的优化一起，使其在 gas 效率上与 ``if (!condition) revert CustomError(args)`` 模式相当。

错误不能被重载或重写，但可以被继承。
同一个错误可以在多个地方定义，只要作用域不同。
错误的实例只能通过 ``revert`` 语句创建，或作为 ``require`` 函数的第二个参数。

错误创建的数据会在回滚操作中传递给调用者，以便返回给链外组件或在 :ref:`try/catch 语句 <try-catch>` 中捕获。
请注意，只有来自外部调用的错误才能被捕获，内部调用或同一函数内发生的回滚无法被捕获。

如果你不提供任何参数，错误只需要四个字节的数据，你可以使用 :ref:`NatSpec <natspec>` 来进一步解释错误背后的原因，这些原因不会存储在链上。
这使得这是一个非常便宜且方便的错误报告功能。

更具体地说，一个错误实例的ABI编码方式与调用相同名称和类型的函数的方式相同，然后作为 ``revert`` 操作码中的返回数据使用。
这意味着数据由一个 4 字节的选择器和 :ref:`ABI 编码<abi>` 数据组成。
选择器由错误类型签名的 keccak256 哈希的前四个字节组成。

.. note::
    合约可以不同的错误名称或甚至不同位置定义的错误进行回滚，这些错误对调用者来说是不可区分的。对于外部，即 ABI，只有错误的名称是相关的，而不是定义它的合约或文件。

如果你可以定义 ``error Error(string)``，语句 ``require(condition, "description");`` 等价于 ``if (!condition) revert Error("description")``。
但是，请注意，``Error`` 是内置类型，不能在用户提供的代码中定义。

同样，失败的 ``assert`` 或类似条件将以内置类型 ``Panic(uint256)`` 的错误进行回滚。

.. note::
    错误数据应仅用于指示失败，而不是作为控制流的手段。原因是内部调用的回滚数据默认通过外部调用链传播。这意味着内部调用可以“伪造”看似来自调用它的合约的回滚数据。

Errors 成员
=================

- ``error.selector``: 一个 ``bytes4`` 值，包含错误选择器。