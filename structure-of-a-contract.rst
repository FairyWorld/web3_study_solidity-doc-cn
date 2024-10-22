.. include:: glossaries.rst
.. index:: contract, state variable, function, event, struct, enum, function;modifier

.. _contract_structure:

***********************
合约的结构
***********************

Solidity 中的合约类似于面向对象语言中的类。
每个合约可以包含 :ref:`structure-state-variables`、:ref:`structure-functions`、:ref:`structure-function-modifiers`、:ref:`structure-events`、:ref:`structure-errors`、:ref:`structure-struct-types` 和 :ref:`structure-enum-types` 的声明。
此外，合约可以从其他合约继承。

还有一些特殊类型的合约，称为 :ref:`libraries<libraries>` 和 :ref:`interfaces<interfaces>`。

关于 :ref:`contracts<contracts>` 的部分包含比本节更多的细节，本节旨在提供快速概述。

.. _structure-state-variables:

状态变量
===============

状态变量是其值永久存储在合约存储中，或者临时存储在每个交易结束时会被清除的瞬态存储中的变量。
有关更多详细信息，请参见 :ref:`data locations <locations>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract SimpleStorage {
        uint storedData; // 状态变量
        // ...
    }

有关有效状态变量类型的信息，请参见 :ref:`types` 部分，以及 :ref:`visibility-and-getters` 以获取可选的可见性选择。

.. _structure-functions:

函数
=========

函数是可执行的代码单元。函数通常在合约内部定义，但也可以在合约外部定义。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.1 <0.9.0;

    contract SimpleAuction {
        function bid() public payable { // 函数
            // ...
        }
    }

    // 在合约外部定义的辅助函数
    function helper(uint x) pure returns (uint) {
        return x * 2;
    }

:ref:`function-calls` 可以在内部或外部发生，并且对其他合约具有不同级别的 :ref:`visibility<visibility-and-getters>`。
:ref:`Functions<functions>` 接受 :ref:`parameters and return variables<function-parameters-return-variables>` 以在它们之间传递参数和数值。

.. _structure-function-modifiers:

函数修改器
==================

函数 |modifier| 可以以声明的方式修改函数的语义（请参见合约部分的 :ref:`modifiers`）。

重载，即使用不同参数的相同修改器名称，是不可能的。

与函数一样，修改器可以被 :ref:`overridden <modifier-overriding>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;

    contract Purchase {
        address public seller;

        modifier onlySeller() { // 修改器
            require(
                msg.sender == seller,
                "只有卖家可以调用此函数。"
            );
            _;
        }

        function abort() public view onlySeller { // 修改器使用
            // ...
        }
    }

.. _structure-events:

事件
======

事件是能方便地调用以太坊虚拟机日志功能的接口。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.22;

    event HighestBidIncreased(address bidder, uint amount); // 事件

    contract SimpleAuction {
        function bid() public payable {
            // ...
            emit HighestBidIncreased(msg.sender, msg.value); // 触发事件
        }
    }

有关事件如何声明和如何在 dapp 中使用的信息，请参见合约部分的 :ref:`events`。

.. _structure-errors:

错误
======

错误允许你为失败情况定义描述性名称和数据。
错误可以在 :ref:`revert statements <revert-statement>` 中使用。
与字符串描述相比，错误的成本更低，并且允许你编码额外的数据。还可以使用 NatSpec 来描述错误给用户。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    /// 转账资金不足。请求的 `requested`，
    /// 但只有 `available` 可用。
    error NotEnoughFunds(uint requested, uint available);

    contract Token {
        mapping(address => uint) balances;
        function transfer(address to, uint amount) public {
            uint balance = balances[msg.sender];
            if (balance < amount)
                revert NotEnoughFunds(amount, balance);
            balances[msg.sender] -= amount;
            balances[to] += amount;
            // ...
        }
    }

有关更多信息，请参见合约部分的 :ref:`errors`。

.. _structure-struct-types:

结构体类型
=============

结构是自定义定义的类型，可以将多个变量分组（请参见类型部分的 :ref:`structs`）。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract Ballot {
        struct Voter { // 结构
            uint weight;
            bool voted;
            address delegate;
            uint vote;
        }
    }

.. _structure-enum-types:

枚举类型
==========

枚举可用于创建具有有限“常量值”集合的自定义类型（请参见类型部分的 :ref:`enums`）。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract Purchase {
        enum State { Created, Locked, Inactive } // 枚举
    }