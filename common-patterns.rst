.. include:: glossaries.rst

###############
通用模式
###############

.. index:: withdrawal

.. _withdrawal_pattern:

*************************
从合约中提现
*************************

在效果发生后发送资金的推荐方法是使用提现模式。尽管由于效果，发送以太币的最直观方法是直接调用 ``transfer``，但这并不推荐，因为它引入了潜在的安全风险。
可以在 :ref:`security_considerations` 页面上阅读更多相关内容。

以下是提现模式在实践中的一个示例，合约的目标是将某种补偿（例如以太币）发送到合约中，以便成为“最富有”的人，灵感来自于 `King of the Ether <https://www.kingoftheether.com/>`_。

在以下合约中，如果你不再是最富有的，你将收到现在最富有的人的资金。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    contract WithdrawalContract {
        address public richest;
        uint public mostSent;

        mapping(address => uint) pendingWithdrawals;

        /// 发送的以太币数量不高于
        /// 当前最高金额。
        error NotEnoughEther();

        constructor() payable {
            richest = msg.sender;
            mostSent = msg.value;
        }

        function becomeRichest() public payable {
            if (msg.value <= mostSent) revert NotEnoughEther();
            pendingWithdrawals[richest] += msg.value;
            richest = msg.sender;
            mostSent = msg.value;
        }

        function withdraw() public {
            uint amount = pendingWithdrawals[msg.sender];
            // 记得在发送之前将待退款金额置零
            // 以防止重入攻击
            pendingWithdrawals[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

这与更直观的发送模式相对：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    contract SendContract {
        address payable public richest;
        uint public mostSent;

        /// 发送的以太币数量不高于
        /// 当前最高金额。
        error NotEnoughEther();

        constructor() payable {
            richest = payable(msg.sender);
            mostSent = msg.value;
        }

        function becomeRichest() public payable {
            if (msg.value <= mostSent) revert NotEnoughEther();
            // 这一行可能会导致问题（下面会解释）。
            richest.transfer(msg.value);
            richest = payable(msg.sender);
            mostSent = msg.value;
        }
    }

请注意，在这个例子中，攻击者可以通过使 ``richest`` 成为一个具有失败的接收或回退函数的合约地址（例如，通过使用 ``revert()`` 或仅消耗超过转移给他们的 2300 gas 补贴）来使合约陷入不可用状态。
这样，每当调用 ``transfer`` 将资金发送到“有毒”合约时，它将失败，因此 ``becomeRichest`` 也将失败，合约将永远被卡住。

相反，如果你使用第一个示例中的“提现”模式，攻击者只能导致他或她自己的提现失败，而不会影响合约的其他功能。

.. index:: access;restricting

******************
限制访问
******************

限制访问是合约的一个常见模式。请注意，你永远无法限制任何人或计算机读取你的交易内容或合约状态。你可以通过使用加密使其变得稍微困难一些，但如果你的合约需要读取数据，其他人也会如此。

你可以通过 **其他合约** 限制对合约状态的读取访问。这实际上是默认设置，除非你将状态变量声明为 ``public``。

此外，你可以限制谁可以修改合约的状态或调用合约的函数，这就是本节的内容。

.. index:: function;modifier

使用 **函数修改器** 使这些限制具有高度可读性。

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    contract AccessRestriction {
        // 这些将在构造阶段分配，
        // 其中 `msg.sender` 是创建此合约的账户。
        address public owner = msg.sender;
        uint public creationTime = block.timestamp;

        // 现在列出此合约可以生成的错误
        // 以及特殊注释中的文本说明。

        /// 发送者未被授权进行此操作。
        error Unauthorized();

        /// 函数过早调用
        error TooEarly();

        /// 函数调用时发送的以太币不足。
        error NotEnoughEther();

        // 修改器可用于更改函数的主体。
        // 如果使用此修改器，
        // 它将在函数从某个地址调用时通过检查。
        modifier onlyBy(address account)
        {
            if (msg.sender != account)
                revert Unauthorized();
            // 不要忘记 "_;"！
            // 它将在使用修改器时替换为实际的函数主体。
            _;
        }

        /// 将 `newOwner` 设置为此
        /// 合约的新所有者。
        function changeOwner(address newOwner)
            public
            onlyBy(owner)
        {
            owner = newOwner;
        }

        modifier onlyAfter(uint time) {
            if (block.timestamp < time)
                revert TooEarly();
            _;
        }

        /// 删除所有权信息。
        /// 只能在合约创建后 6 周调用。
        function disown()
            public
            onlyBy(owner)
            onlyAfter(creationTime + 6 weeks)
        {
            delete owner;
        }

        // 此修改器要求与函数调用相关联的特定费用 。
        // 如果调用者发送的金额过多，他或她将被退款，但仅在函数主体之后。
        // 在 Solidity 版本 0.4.0 之前，这很危险，
        // 因为可以跳过 `_;` 后面的部分。
        modifier costs(uint amount) {
            if (msg.value < amount)
                revert NotEnoughEther();

            _;
            if (msg.value > amount)
                payable(msg.sender).transfer(msg.value - amount);
        }

        function forceOwnerChange(address newOwner)
            public
            payable
            costs(200 ether)
        {
            owner = newOwner;
            // 只是一些示例条件
            if (uint160(owner) & 0 == 1)
                // 这在 Solidity 0.4.0 版本之前没有退款。
                return;
            // 退款多支付的费用
        }
    }

在下一个示例中，将讨论限制对函数调用的访问的更专业方法。

.. index:: state machine

*************
状态机
*************
合约通常充当状态机，这意味着它们具有某些 **阶段**，在这些阶段中它们的行为不同，或者可以调用不同的函数。函数调用通常结束一个阶段，并将合约转换到下一个阶段（特别是当合约模拟 **交互** 时）。某些阶段在 **时间** 的某个点上也会自动到达。

一个例子是盲拍合约，它从“接受盲标”阶段开始，然后过渡到“揭示标”阶段，最后以“确定拍卖结果”结束。

.. index:: function;modifier

在这种情况下，可以使用函数修改器来建模状态并防止合约的错误使用。

示例
=======

在以下示例中，修改器 ``atStage`` 确保该函数只能在特定阶段调用。

自动定时转换由修改器 ``timedTransitions`` 处理，应该在所有函数中使用。

.. note::
    **修改器的顺序很重要**。
    如果 atStage 与 timedTransitions 结合使用，请确保在后者之后提及它，以便新阶段被考虑在内。

最后，修改器 ``transitionNext`` 可以在函数完成时自动进入下一个阶段。

.. note::
    **修改器可以被跳过**。
    这仅适用于 0.4.0 版本之前的 Solidity：
    由于修改器是通过简单替换代码而不是通过函数调用来应用的，
    如果函数本身使用返回，transitionNext 修改器中的代码可以被跳过。
    如果你想这样做，请确保从这些函数手动调用 nextStage。
    从 0.4.0 版本开始，即使函数显式返回，修改器代码也会运行。

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    contract StateMachine {
        enum Stages {
            AcceptingBlindedBids,
            RevealBids,
            AnotherStage,
            AreWeDoneYet,
            Finished
        }
        /// 函数在此时无法调用。
        error FunctionInvalidAtThisStage();

        // 这是当前阶段。
        Stages public stage = Stages.AcceptingBlindedBids;

        uint public creationTime = block.timestamp;

        modifier atStage(Stages stage_) {
            if (stage != stage_)
                revert FunctionInvalidAtThisStage();
            _;
        }

        function nextStage() internal {
            stage = Stages(uint(stage) + 1);
        }

        // 执行定时转换。确保首先提及
        // 此修改器，否则保护措施
        // 将不会考虑新阶段。
        modifier timedTransitions() {
            if (stage == Stages.AcceptingBlindedBids &&
                        block.timestamp >= creationTime + 10 days)
                nextStage();
            if (stage == Stages.RevealBids &&
                    block.timestamp >= creationTime + 12 days)
                nextStage();
            // 其他阶段通过交易转换
            _;
        }

        // 修改器的顺序在这里很重要！
        function bid()
            public
            payable
            timedTransitions
            atStage(Stages.AcceptingBlindedBids)
        {
            // 我们在这里不会实现
        }

        function reveal()
            public
            timedTransitions
            atStage(Stages.RevealBids)
        {
        }

        // 此修改器在函数完成后
        // 进入下一个阶段。
        modifier transitionNext()
        {
            _;
            nextStage();
        }

        function g()
            public
            timedTransitions
            atStage(Stages.AnotherStage)
            transitionNext
        {
        }

        function h()
            public
            timedTransitions
            atStage(Stages.AreWeDoneYet)
            transitionNext
        {
        }

        function i()
            public
            timedTransitions
            atStage(Stages.Finished)
        {
        }
    }