.. index:: contract;modular, modular contract

*****************
模块化合约
*****************

模块化构建合约的方法可以帮助减少复杂性并提高可读性，这将有助于在开发和代码审查过程中识别错误和漏洞。
如果在隔离状态下指定和控制每个模块的行为，那么需要考虑的交互仅仅是模块规范之间的交互，而不是合约中其他所有活动部分之间的交互。
在下面的示例中，合约使用 ``Balances`` :ref:`library <libraries>` 的 ``move`` 方法来检查在地址之间发送的余额是否符合预期。
通过这种方式，``Balances`` 库提供了一个隔离的组件，能够正确跟踪账户的余额。
很容易验证 ``Balances`` 库从不产生负余额或溢出，并且所有余额的总和在合约的生命周期内是一个不变的量。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    library Balances {
        function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
            require(balances[from] >= amount);
            require(balances[to] + amount >= balances[to]);
            balances[from] -= amount;
            balances[to] += amount;
        }
    }

    contract Token {
        mapping(address => uint256) balances;
        using Balances for *;
        mapping(address => mapping(address => uint256)) allowed;

        event Transfer(address from, address to, uint amount);
        event Approval(address owner, address spender, uint amount);

        function transfer(address to, uint amount) external returns (bool success) {
            balances.move(msg.sender, to, amount);
            emit Transfer(msg.sender, to, amount);
            return true;

        }

        function transferFrom(address from, address to, uint amount) external returns (bool success) {
            require(allowed[from][msg.sender] >= amount);
            allowed[from][msg.sender] -= amount;
            balances.move(from, to, amount);
            emit Transfer(from, to, amount);
            return true;
        }

        function approve(address spender, uint tokens) external returns (bool success) {
            require(allowed[msg.sender][spender] == 0, "");
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        function balanceOf(address tokenOwner) external view returns (uint balance) {
            return balances[tokenOwner];
        }
    }