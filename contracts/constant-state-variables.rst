.. index:: ! constant

.. _constants:

**************************************
常量和不可变状态变量
**************************************

状态变量可以声明为 ``constant`` （常量）或 ``immutable`` （不可变量）。
在这两种情况下，变量在合约构造后不能被修改。
对于 ``constant`` 变量，值必须在编译时固定，而对于 ``immutable``，它仍然可以在构造时赋值。

也可以在文件级别定义 ``constant`` 变量。

源代码中每次出现这样的变量都会被其基础值替换，编译器不会为其保留存储槽。
它也不能使用 ``transient`` 关键字在临时存储中分配槽。

与常规状态变量相比，常量和不可变变量的 gas 成本要低得多。对于常量，赋值给它的表达式会被复制到所有访问它的地方，并且每次都会重新评估。这允许进行局部优化。不可变变量在构造时评估一次，其值会被复制到代码中所有访问它的地方。对于这些值，保留 32 字节，即使它们可以适应更少的字节。因此，常量值有时可能比不可变值更便宜。

目前并不是所有类型的常量和不可变变量都已实现。唯一支持的类型是
:ref:`strings <strings>` （仅适用于常量）和 :ref:`value types <value-types>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.21;

    uint constant X = 32**22 + 8;

    contract C {
        string constant TEXT = "abc";
        bytes32 constant MY_HASH = keccak256("abc");
        uint immutable decimals = 18;
        uint immutable maxBalance;
        address immutable owner = msg.sender;

        constructor(uint decimals_, address ref) {
            if (decimals_ != 0)
                // 仅在部署时不可变。
                // 在构造时可以被赋值多次。
                decimals = decimals_;

            // 对不可变变量的赋值甚至可以访问（上下文）环境。
            maxBalance = ref.balance;
        }

        function isBalanceTooHigh(address other) public view returns (bool) {
            return other.balance > maxBalance;
        }
    }


常量
========

对于 ``constant`` 变量，值必须在编译时是常量，并且必须在变量声明时赋值。任何访问存储、区块链数据（例如 ``block.timestamp``、``address(this).balance`` 或
``block.number``）或执行数据（``msg.value`` 或 ``gasleft()``）或调用外部合约的表达式都是不允许的。可能对内存分配产生副作用的表达式是允许的，但可能对其他内存对象产生副作用的表达式则不允许。内置函数 ``keccak256``、``sha256``、``ripemd160``、``ecrecover``、``addmod`` 和 ``mulmod`` 是允许的（尽管除了 ``keccak256`` 之外，它们确实调用外部合约）。

允许对内存分配器的副作用的原因是，它应该能够构造复杂对象，例如查找表。此功能尚未完全可用。

不可变量
=========

声明为 ``immutable`` 的变量比声明为 ``constant`` 的变量限制稍少：不可变变量可以在构造时赋值。
在部署之前，值可以随时更改，然后它变得永久。

另一个额外的限制是，不可变变量的赋值只能在创建后不会被执行的表达式中。
这排除了所有修改器定义和构造函数以外的函数。

读取不可变变量没有限制。
读取甚至可以在变量第一次写入之前发生，因为 Solidity 中的变量始终具有明确定义的初始值。
因此，也允许不显式地给不可变变量赋值。

.. warning::
    在构造时访问不可变变量时，请记住 :ref:`初始化顺序
    <state-variable-initialization-order>`。
    即使你提供了显式初始化器，一些表达式可能会在该初始化器之前被评估，特别是当它们位于继承层次结构的不同级别时。

.. note::
    在 Solidity 0.8.21 之前，不可变变量的初始化限制更严格。
    此类变量必须在构造时初始化一次，并且在那之前不能读取。

编译器生成的合约创建代码将在返回之前修改合约的运行时代码，通过用赋值替换所有对不可变变量的引用。这在你比较编译器生成的运行时代码与实际存储在区块链中的代码时非常重要。编译器在 :ref:`compiler JSON standard output <compiler-api>` 的 ``immutableReferences`` 字段中输出这些不可变变量在部署字节码中的位置。