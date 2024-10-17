.. include:: glossaries.rst

.. index:: purchase, remote purchase, escrow

********************
安全地远程购买
********************

远程购买商品目前需要多个相互信任的参与方。
最简单的配置涉及卖方和买方。买方希望从卖方那里收到一个物品，而卖方希望获得一些补偿，例如以太币。
这里的问题在于运输：没有办法确定物品是否确实到达了买方手中。

有多种方法可以解决这个问题，但都或多或少存在不足之处。
在以下示例中，双方必须将物品价值的两倍放入合约作为托管。
一旦发生状况，以太币将被锁定在合约中，直到买方确认他们收到了物品。
之后，买方将获得价值（他们存款的一半），而卖方将获得三倍的价值（他们的存款加上价值）。
其背后的想法是双方都有动力来解决这种情况，否则他们的以太币将永远被锁定。

这个合约当然不能解决问题，但概述了如何在合约中使用类似状态机的结构。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;
    contract Purchase {
        uint public value;
        address payable public seller;
        address payable public buyer;

        enum State { Created, Locked, Release, Inactive }
        // 状态变量的默认值为第一个成员，`State.created`
        State public state;

        modifier condition(bool condition_) {
            require(condition_);
            _;
        }

        /// 只有买方可以调用此函数。
        error OnlyBuyer();
        /// 只有卖方可以调用此函数。
        error OnlySeller();
        /// 当前状态下无法调用该函数。
        error InvalidState();
        /// 提供的值必须是偶数。
        error ValueNotEven();

        modifier onlyBuyer() {
            if (msg.sender != buyer)
                revert OnlyBuyer();
            _;
        }

        modifier onlySeller() {
            if (msg.sender != seller)
                revert OnlySeller();
            _;
        }

        modifier inState(State state_) {
            if (state != state_)
                revert InvalidState();
            _;
        }

        event Aborted();
        event PurchaseConfirmed();
        event ItemReceived();
        event SellerRefunded();

        // 确保 `msg.value` 是一个偶数。
        // 如果是奇数，除法将截断。
        // 通过乘法检查它不是奇数。
        constructor() payable {
            seller = payable(msg.sender);
            value = msg.value / 2;
            if ((2 * value) != msg.value)
                revert ValueNotEven();
        }

        /// 中止购买并收回以太币。
        /// 只能由卖方在合约被锁定之前调用。
        function abort()
            external
            onlySeller
            inState(State.Created)
        {
            emit Aborted();
            state = State.Inactive;
            // 我们在这里直接使用转账。
            // 可用于防止重入，因为它是此函数中的最后一个调用，我们已经改变了状态。
            seller.transfer(address(this).balance);
        }

        /// 作为买方确认购买。
        /// 交易必须包括 `2 * value` 以太币。
        /// 以太币将在调用 confirmReceived 之前被锁定。
        function confirmPurchase()
            external
            inState(State.Created)
            condition(msg.value == (2 * value))
            payable
        {
            emit PurchaseConfirmed();
            buyer = payable(msg.sender);
            state = State.Locked;
        }

        /// 确认你（买方）收到了物品。
        /// 这将释放锁定的以太币。
        function confirmReceived()
            external
            onlyBuyer
            inState(State.Locked)
        {
            emit ItemReceived();
            // 首先改变状态是很重要的，
            // 否则，使用 `send` 调用的合约可以再次调用这里。
            state = State.Release;

            buyer.transfer(value);
        }

        /// 此函数退款给卖方，即退还卖方的锁定资金。
        function refundSeller()
            external
            onlySeller
            inState(State.Release)
        {
            emit SellerRefunded();
            // 首先改变状态是很重要的，
            // 否则，使用 `send` 调用的合约可以再次调用这里。
            state = State.Inactive;

            seller.transfer(3 * value);
        }
    }