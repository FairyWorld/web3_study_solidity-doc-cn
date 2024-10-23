.. index:: ! contract;creation, constructor

******************
创建合约
******************

合约可以通过以太坊交易“从外部”创建，也可以通过 Solidity 合约内部创建。

IDE，如 `Remix <https://remix.ethereum.org/>`_，通过 UI 元素使创建过程更加顺畅。

在以太坊上以编程方式创建合约的一种方法是通过 JavaScript API `web3.js <https://github.com/web3/web3.js>`_。
它有一个名为 `web3.eth.Contract <https://web3js.readthedocs.io/en/1.0/web3-eth-contract.html#new-contract>`_
的函数来促进合约的创建。

当合约被创建时，它的 :ref:`constructor <constructor>` （用 ``constructor`` 关键字声明的函数）会被执行一次。

构造函数是可选的。只允许存在一个构造函数，这意味着不支持重载。

构造函数执行后，合约的最终代码会存储在区块链上。此代码包括所有公共和外部函数以及所有可以通过函数调用从那里访问的函数。部署的代码不包括构造函数代码或仅从构造函数调用的内部函数。

.. index:: constructor;arguments

在内部，构造函数参数在合约代码本身之后以 :ref:`ABI 编码 <ABI>` 传递，但如果你使用 ``web3.js``，则不必关心这一点。

如果一个合约想要创建另一个合约，则必须知道被创建合约的源代码（和二进制）。这意味着循环创建依赖是不可能的。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;


    contract OwnedToken {
        // `TokenCreator` 是下面定义的合约类型。
        // 只要不用于创建新合约，引用它是可以的。
        TokenCreator creator;
        address owner;
        bytes32 name;

        // 这是构造函数，它注册了
        // 创建者和传入的名称。
        constructor(bytes32 name_) {
            // 状态变量通过其名称访问
            // 而不是通过例如 `this.owner`。
            // 函数可以直接访问或通过 `this.f` 访问，
            // 但后者提供了对函数的外部视图。特别是在构造函数中，
            // 你不应该从外部访问函数，
            // 因为该函数尚不存在。
            // 有关详细信息，请参见下一节。
            owner = msg.sender;

            // `address` 显式转换为 `TokenCreator`
            // 并假设调用合约的类型是 `TokenCreator`，
            // 但没有真正的方法来验证这一点。
            // 这不会创建新合约。
            creator = TokenCreator(msg.sender);
            name = name_;
        }

        function changeName(bytes32 newName) public {
            // 只有创建者可以更改名称。
            // 我们根据其地址比较合约，
            // 合约可以通过显式转换为地址来检索。
            if (msg.sender == address(creator))
                name = newName;
        }

        function transfer(address newOwner) public {
            // 只有当前所有者可以转让代币。
            if (msg.sender != owner) return;

            // 我们询问创建者合约是否应该继续转让
            // 通过使用下面定义的 `TokenCreator` 合约的一个函数。如果
            // 调用失败（例如由于耗尽 gas），
            // 此处的执行也会失败。
            if (creator.isTokenTransferOK(owner, newOwner))
                owner = newOwner;
        }
    }


    contract TokenCreator {
        function createToken(bytes32 name)
            public
            returns (OwnedToken tokenAddress)
        {
            // 创建一个新的 `Token` 合约并返回其地址。
            // 从 JavaScript 端，此函数的返回类型
            // 是 `address`，因为这是
            // ABI 中可用的最接近的类型。
            return new OwnedToken(name);
        }

        function changeName(OwnedToken tokenAddress, bytes32 name) public {
            // 同样，`tokenAddress` 的外部类型
            // 也是 `address`。
            tokenAddress.changeName(name);
        }

        // 执行检查以确定是否应该继续将代币转让给
        // `OwnedToken` 合约
        function isTokenTransferOK(address currentOwner, address newOwner)
            public
            pure
            returns (bool ok)
        {
            // 检查任意条件以查看转让是否应该继续
            return keccak256(abi.encodePacked(currentOwner, newOwner))[0] == 0x7f;
        }
    }