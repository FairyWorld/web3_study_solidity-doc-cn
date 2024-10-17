.. index:: ! contract;interface, ! interface contract

.. _interfaces:

**********
接口
**********

接口类似于抽象合约，但它们不能实现任何函数。
还有进一步的限制：

- 它们不能从其他合约继承，但可以从其他接口继承。
- 所有声明的函数在接口中必须是外部的，即使它们在合约中是公共的。
- 它们不能声明构造函数。
- 它们不能声明状态变量。
- 它们不能声明修改器。

这些限制中的一些可能在未来会被解除。

接口基本上仅限于合约 ABI 可以表示的内容，ABI 与接口之间的转换应该可以在没有任何信息丢失的情况下进行。

接口由它们自己的关键字表示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.2 <0.9.0;

    interface Token {
        enum TokenType { Fungible, NonFungible }
        struct Coin { string obverse; string reverse; }
        function transfer(address recipient, uint amount) external;
    }

合约可以像继承其他合约一样继承接口。

在接口中声明的所有函数隐式为 ``virtual``，任何重写它们的函数不需要 ``override`` 关键字。
这并不自动意味着重写的函数可以再次被重写 —— 只有当重写的函数被标记为 ``virtual`` 时才可以再次重写。

接口可以从其他接口继承。这与正常继承的规则相同。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.2 <0.9.0;

    interface ParentA {
        function test() external returns (uint256);
    }

    interface ParentB {
        function test() external returns (uint256);
    }

    interface SubInterface is ParentA, ParentB {
        // 必须重新定义 test 以确保父级含义是兼容的。
        function test() external override(ParentA, ParentB) returns (uint256);
    }

在接口和其他类似合约的结构中定义的类型可以从其他合约访问： ``Token.TokenType`` 或 ``Token.Coin``。

.. warning::

    接口自 :doc:`Solidity 版本 0.5.0 <050-breaking-changes>` 起支持 ``enum`` 类型，确保 pragma 版本指定此版本作为最低版本。