.. include :: glossaries.rst

.. _security_considerations:

#######################
安全考量
#######################

虽然构建按预期工作的软件通常相对简单，但想要确保没有人以**未**预期的方式使用它则要困难得多。

在 Solidity 中，这一点尤为重要，因为你可以使用智能合约来处理代币或，可能，更有价值的东西。
此外，智能合约的每次执行都是公开的，并且，源代码通常也是可用的。

当然，你始终需要考虑风险有多大：你可以将智能合约与一个对公众开放的网络服务进行比较（因此，也对恶意行为者开放），并且可能甚至是开源的。
如果你仅在该网络服务上存储你的购物清单，你可能不需要太过小心，但如果你使用该网络服务管理你的银行账户，你就应该更加谨慎。

本节将列出一些陷阱和一般安全建议，但当然永远无法做到全面。
此外，请记住，即使你的智能合约代码没漏洞，编译器或平台本身也可能存在漏洞。
有关编译器的一些公开已知安全相关漏洞的列表可以在 :ref:`已知漏洞列表<known_bugs>` 中找到，该列表也是机器可读的。
请注意，有一个 `漏洞赏金计划 <https://ethereum.org/en/bug-bounty/>`_ 涵盖了 Solidity 编译器的代码生成器。

与往常一样，关于开源文档，请帮助我们扩展本节（特别是，一些示例会更好）！

注意：除了下面的列表，还可以在 `Guy Lando 的知识列表 <https://github.com/guylando/KnowledgeLists/blob/master/EthereumSmartContracts.md>`_ 和 `Consensys GitHub 仓库 <https://consensys.github.io/smart-contract-best-practices/>`_ 中找到更多安全建议和最佳实践。

********
陷阱
********

私有信息和随机性
==================================

你在智能合约中使用的所有内容都是公开可见的，即使是标记为 ``private`` 的局部变量和状态变量。

在智能合约中使用随机数是相当棘手的，如果你不希望区块构建者能够作弊。

重入
==========

合约（A）与另一个合约（B）之间的任何交互以及任何以太的转移都会将控制权交给该合约（B）。这使得 B 可以在此交互完成之前回调 A。
举个例子，以下代码包含一个错误（这只是一个片段，而不是完整的合约）：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    // 此合约包含一个错误 - 请勿使用
    contract Fund {
        /// @dev 合约的以太份额映射。
        mapping(address => uint) shares;
        /// 提取你的份额。
        function withdraw() public {
            if (payable(msg.sender).send(shares[msg.sender]))
                shares[msg.sender] = 0;
        }
    }

这里的问题并不太严重，因为 ``send`` 的 gas 限制，但它仍然暴露了一个弱点：以太转移始终可以包含代码执行，因此接收者可能是一个回调到 ``withdraw`` 的合约。
这将使其获得多次退款，并基本上检索合约中的所有以太。特别是，以下合约将允许攻击者多次退款，因为它使用 ``call``，默认情况下会转发所有剩余的 gas：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.2 <0.9.0;

    // 此合约包含一个错误 - 请勿使用
    contract Fund {
        /// @dev 合约的以太份额映射。
        mapping(address => uint) shares;
        /// 提取你的份额。
        function withdraw() public {
            (bool success,) = msg.sender.call{value: shares[msg.sender]}("");
            if (success)
                shares[msg.sender] = 0;
        }
    }

为了避免重入，你可以使用检查-生效-交互模式，如下所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract Fund {
        /// @dev 合约的以太份额映射。
        mapping(address => uint) shares;
        /// 提取你的份额。
        function withdraw() public {
            uint share = shares[msg.sender];
            shares[msg.sender] = 0;
            payable(msg.sender).transfer(share);
        }
    }

检查-生效-交互模式确保合约中的所有代码路径在修改合约状态之前完成对提供参数的所有必要检查（检查）；只有在此之后才对状态进行任何更改（效果）；它可以在所有计划的状态更改已写入存储后（交互）调用其他合约中的函数。这是一种常见的防止*重入攻击*的万无一失的方法，其中外部调用的恶意合约可以重复消费一个配额，重复提取一个余额等，通过使用逻辑在原始合约完成其交易之前回调。

请注意，重入不仅是以太转移的结果，也是对另一个合约的任何函数调用的结果。
此外，你还必须考虑多合约情况。被调用的合约可能会修改你依赖的另一个合约的状态。

Gas 限制和循环
===================

没有固定迭代次数的循环，例如，依赖存储值的循环，必须谨慎使用：由于区块 gas 限制，交易只能消耗一定数量的 gas。
无论是显式还是仅由于正常操作，循环中的迭代次数可能会超过区块 gas 限制，这可能导致整个合约在某个时刻停止。
这可能不适用于仅用于从区块链读取数据的 ``view`` 函数。
尽管如此，这些函数可能会被其他合约作为链上操作的一部分调用并导致停止。
请在合约文档中明确说明此类情况。

发送和接收以太
===========================

- 目前，合约和“外部账户”都无法阻止某人向其发送以太。
  合约可以对常规转账做出反应并拒绝，但有一些方法可以在不创建消息调用的情况下转移以太。
  一种方法是简单地“挖矿到”合约地址，第二种方法是使用 ``selfdestruct(x)``。

- 如果合约接收到以太（没有调用任何函数），则会执行 :ref:`接收以太 <receive-ether-function>` 或 :ref:`回退 <fallback-function>` 函数。
  如果它没有 ``receive`` 或 ``fallback`` 函数，则以太将被拒绝（通过抛出异常）。
  在执行这些函数之一期间，合约只能依赖于它在该时刻获得的“gas 补贴”（2300 gas）。
  该补贴不足以修改存储（不过，不要对此掉以轻心，补贴可能会随着未来的硬分叉而变化）。
  为了确保你的合约可以以这种方式接收以太，请检查接收和回退函数的 gas 要求（例如在 Remix 的“详细信息”部分）。
- 有一种方法可以通过 ``addr.call{value: x}("")`` 将更多的 gas 转发到接收合约。
  这本质上与 ``addr.transfer(x)`` 相同，只是它转发所有剩余的 gas，并且允许接收方执行更昂贵的操作（并且它返回一个失败代码，而不是自动传播错误）。
这可能包括回调发送合约或其他你可能没有想到的状态变化。
因此，它为诚实用户提供了极大的灵活性，但也为恶意行为者提供了机会。

- 尽可能使用最精确的单位来表示 Wei 数量，因为你会失去由于缺乏精度而四舍五入的任何值。

- 如果你想使用 ``address.transfer`` 发送 Ether，有一些细节需要注意：

  1. 如果接收方是一个合约，它会导致其接收或回退函数被执行，这可能会反过来调用发送合约。
  2. 发送 Ether 可能会失败，因为调用深度超过 1024。由于调用者完全控制调用深度，他们可以强制转账失败；
     考虑到这一可能性，或者使用 ``send`` 并确保始终检查其返回值。
     更好的做法是使用一种模式，让接收方可以提取 Ether。
  3. 发送 Ether 也可能失败，因为接收合约的执行需要超过分配的 gas 量（通过使用 :ref:`require <assert-and-require>`、:ref:`assert <assert-and-require>`、:ref:`revert <assert-and-require>` 显式地，或者因为操作过于昂贵） - 它“耗尽了 gas”（OOG）。
     如果你使用 ``transfer`` 或 ``send`` 并进行返回值检查，这可能会为接收方提供阻止发送合约进展的手段。.
     再次强调，最佳实践是使用 :ref:`"“取回”模式而不是“发送”模式<withdrawal_pattern>`。

调用栈深度
================

外部函数调用可能随时失败，因为它们超过了最大调用栈大小限制 1024。在这种情况下，Solidity 会抛出异常。
恶意行为者可能能够在与你的合约交互之前强制调用栈达到高值。
请注意，自 `Tangerine Whistle <https://eips.ethereum.org/EIPS/eip-608>`_ 硬分叉以来，`63/64 rule <https://eips.ethereum.org/EIPS/eip-150>`_ 使得调用栈深度攻击变得不切实际。
还要注意，调用栈和表达式栈是无关的，尽管两者的大小限制都是 1024 个栈槽。

请注意，``.send()`` 在调用栈耗尽时**不会**抛出异常，而是返回 ``false``。
低级函数 ``.call()``, ``.delegatecall()`` 和 ``.staticcall()`` 的行为也是一样的。

授权代理
==================

如果你的合约可以充当代理，即如果它可以使用用户提供的数据调用任意合约，那么用户基本上可以假设代理合约的身份。
即使你有其他保护措施，最好还是构建你的合约系统，使得代理没有任何权限（甚至没有为自己）。
如果需要，你可以使用第二个代理来实现这一点：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.0;
    contract ProxyWithMoreFunctionality {
        PermissionlessProxy proxy;

        function callOther(address addr, bytes memory payload) public
                returns (bool, bytes memory) {
            return proxy.callOther(addr, payload);
        }
        // 其他函数和其他功能
    }

    // 这是完整的合约，它没有其他功能，并且不需要特权即可工作。
    contract PermissionlessProxy {
        function callOther(address addr, bytes memory payload) public
                returns (bool, bytes memory) {
            return addr.call(payload);
        }
    }

tx.origin
=========

永远不要使用 ``tx.origin`` 进行授权。假设你有一个钱包合约，如下所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    // 这个合约包含一个漏洞 - 不要使用
    contract TxUserWallet {
        address owner;

        constructor() {
            owner = msg.sender;
        }

        function transferTo(address payable dest, uint amount) public {
            // 漏洞就在这里，你必须使用 msg.sender 而不是 tx.origin
            require(tx.origin == owner);
            dest.transfer(amount);
        }
    }

现在有人欺骗你将 Ether 发送到这个攻击钱包的地址：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    interface TxUserWallet {
        function transferTo(address payable dest, uint amount) external;
    }

    contract TxAttackWallet {
        address payable owner;

        constructor() {
            owner = payable(msg.sender);
        }

        receive() external payable {
            TxUserWallet(msg.sender).transferTo(owner, msg.sender.balance);
        }
    }

如果你的钱包检查 ``msg.sender`` 进行授权，它将获得攻击钱包的地址，而不是所有者的地址。
但通过检查 ``tx.origin``，它获得了启动交易的原始地址，仍然是所有者的地址。
攻击钱包瞬间耗尽了你的所有资金。

.. _underflow-overflow:

二进制补码 / 下溢 / 上溢
=========================================

与许多编程语言一样，Solidity 的整数类型实际上并不是整数。它们在值较小时类似于整数，但无法表示任意大的数字。

以下代码会导致上溢，因为加法的结果太大，无法存储在 ``uint8`` 类型中：

.. code-block:: solidity

  uint8 x = 255;
  uint8 y = 1;
  return x + y;

Solidity 有两种处理这些上溢的模式：检查模式和未检查模式或“包装”模式。

默认的检查模式将检测上溢并导致断言失败。你可以使用 ``unchecked { ... }`` 禁用此检查，从而使上溢被静默忽略。
上述代码如果被包装在 ``unchecked { ... }`` 中将返回 ``0``。

即使在检查模式下，也不要假设你受到上溢漏洞的保护。
在此模式下，上溢将始终回退。如果无法避免上溢，这可能导致智能合约被卡在某种状态。

一般来说，了解二进制补码表示的限制，尤其是对于有符号数字还有一些特殊的边界情况。

尽量使用 ``require`` 限制输入的大小在合理范围内，并使用 :ref:`SMT checker<smt_checker>` 查找潜在的上溢。

.. _clearing-mappings:

清除映射
=================

Solidity 类型 ``mapping`` （见 :ref:`mapping-types`）是一种仅用于存储的键值数据结构，它不跟踪被分配了非零值的键。
因此，在没有关于已写入键的额外信息的情况下，清除映射是不可能的。
如果 ``mapping`` 被用作动态存储数组的基本类型，删除或弹出数组将对 ``mapping`` 元素没有影响。
比如，如果 ``mapping`` 被用作 ``struct`` 的成员字段类型，而该 ``struct`` 是动态存储数组的基本类型，情况也是如此。
在包含 ``mapping`` 的结构体或数组的赋值中，``mapping`` 也会被忽略。
.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract Map {
        mapping(uint => uint)[] array;

        function allocate(uint newMaps) public {
            for (uint i = 0; i < newMaps; i++)
                array.push();
        }

        function writeMap(uint map, uint key, uint value) public {
            array[map][key] = value;
        }

        function readMap(uint map, uint key) public view returns (uint) {
            return array[map][key];
        }

        function eraseMaps() public {
            delete array;
        }
    }

考虑上述示例和以下调用序列： ``allocate(10)``, ``writeMap(4, 128, 256)``。
此时，调用 ``readMap(4, 128)`` 返回 256。
如果我们调用 ``eraseMaps``，状态变量 ``array`` 的长度被置为零，
但由于其 ``mapping`` 元素无法被置零，因此它们的信息仍然保留在合约的存储中。
在删除 ``array`` 后，调用 ``allocate(5)`` 使我们能够再次访问 ``array[4]``，
并且调用 ``readMap(4, 128)`` 返回 256，即使没有再次调用 ``writeMap``。

如果你的 ``mapping`` 信息必须被删除，请考虑使用类似于 `iterable mapping <https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol>`_ 的库，
允许你遍历键并在适当的 ``mapping`` 中删除它们的值。

次要细节
=============

- 不占用完整 32 字节的类型可能包含“脏的高位”。
  如果你访问 ``msg.data``，这尤其重要 - 它带来了可变性风险：
  你可以构造调用函数 ``f(uint8 x)`` 的交易，其原始字节参数为 ``0xff000001`` 和 ``0x00000001``。
  两者都被传递给合约，并且就 ``x`` 而言，它们看起来都是数字 ``1``，
  但 ``msg.data`` 将是不同的，因此如果你对 ``msg.data`` 使用 ``keccak256``，你将获得不同的结果。

***************
建议
***************

认真对待警告
=======================

如果编译器对你发出警告，你应该进行更改。
即使你认为这个特定的警告没有安全隐患，也可能在其下埋藏着其他问题。
我们发出的任何编译器警告都可以通过对代码进行轻微更改来消除。

始终使用最新版本的编译器，以便获得所有最近引入的警告通知。

编译器发出的 ``info`` 类型消息并不危险，仅仅代表编译器认为对用户可能有用的额外建议和可选信息。

限制以太币的数量
============================

限制可以存储在智能合约中的以太币（或其他代币）数量。
如果你的源代码、编译器或平台存在漏洞，这些资金可能会丢失。
如果你想限制损失，请限制以太币的数量。

保持小而模块化
=========================

保持你的合约短小精炼且易于理解。
将不相关的功能单独放在其他合约或库中。
关于源代码质量的一般建议当然适用：
限制局部变量的数量、函数的长度等。
记录你的函数，以便其他人可以看到你的意图以及它是否与代码的实际行为不同。

使用检查-生效-交互模式
===========================================

大多数函数将首先执行一些检查，这些检查应该首先完成（谁调用了该函数，参数是否在范围内，是否发送了足够的以太币，该人是否拥有代币等）。

作为第二步，如果所有检查通过，则应对当前合约的状态变量进行效果处理。
与其他合约的交互应是任何函数中的最后一步。

早期合约延迟了一些效果，并等待外部函数调用在无错误状态下返回。
这通常是一个严重的错误，因为上述的重入问题。

请注意，已知合约的调用也可能导致对
未知合约的调用，因此最好始终应用此模式。

包含故障安全模式
========================

虽然使你的系统完全去中心化将消除任何中介，但对于新代码，包含某种故障安全机制可能是个好主意：

你可以在智能合约中添加一个函数，执行一些自检，例如“是否有以太币泄漏？”、“代币的总和是否等于合约的余额？”或类似的事情。
请记住，你不能为此使用过多的 gas，因此可能需要通过链外计算提供帮助。

如果自检失败，合约将自动切换到某种“故障安全”模式，
例如，禁用大多数功能，将控制权交给一个固定且可信的第三方或仅将合约转换为一个简单的“把我的以太币还给我”合约。

请求同行评审
===================

检查一段代码的人越多，发现的问题就越多。
请求他人审查你的代码也有助于交叉检查，以找出你的代码是否易于理解 -这是良好智能合约的重要标准。