.. include:: glossaries.rst

.. index:: auction;blind, auction;open, blind auction, open auction

*************
盲拍
*************

在本节中，我们将展示如何在以太坊上创建一个完全盲拍合约是多么简单。
我们将从一个公开拍卖开始，所有人都可以看到出价，然后将该合约扩展为一个盲拍，在拍卖期间结束之前无法看到实际出价。

.. _simple_auction:

简单的公开拍卖
===================

以下简单拍卖合约的一般思路是，所有人可以在拍卖期间发送他们的出价。
出价已经包括发送一些资金，例如以太，以便将竞标者绑定到他们的出价上。
如果最高出价被提高，之前的最高出价者将能够取回他们的以太币。
在拍卖结束后，必须手动调用合约，以便受益人能够收到他们的以太 - 合约无法自我激活。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;
    contract SimpleAuction {
        // 拍卖的参数。时间可以是绝对的 unix 时间戳（自 1970-01-01 起的秒数）或以秒为单位的时间段。
        address payable public beneficiary;
        uint public auctionEndTime;

        // 拍卖的当前状态。
        address public highestBidder;
        uint public highestBid;

        // 允许取回的先前出价
        mapping(address => uint) pendingReturns;

        // 在结束时设置为 true，禁止任何更改。
        // 默认初始化为 `false`。
        bool ended;

        // 变更触发的事件。
        event HighestBidIncreased(address bidder, uint amount);
        event AuctionEnded(address winner, uint amount);

        // Errors 用来定义失败

        // 三斜杠注释是所谓的 natspec 注释。
        // 当用户被要求确认交易时将显示它们，或者当显示错误时。

        /// 拍卖已经结束。
        error AuctionAlreadyEnded();
        /// 已经有更高或相等的出价。
        error BidNotHighEnough(uint highestBid);
        /// 拍卖尚未结束。
        error AuctionNotYetEnded();
        /// 函数 auctionEnd 已经被调用。
        error AuctionEndAlreadyCalled();

        /// 创建一个简单的拍卖，拍卖时间为 `biddingTime`秒，代表受益人地址 `beneficiaryAddress`。
        constructor(
            uint biddingTime,
            address payable beneficiaryAddress
        ) {
            beneficiary = beneficiaryAddress;
            auctionEndTime = block.timestamp + biddingTime;
        }

        /// 在拍卖中出价，出价的值与此交易一起发送。
        /// 该值仅在拍卖未获胜时退款。
        function bid() external payable {
            // 不需要参数，所有信息已经是交易的一部分。
            // 关键字 payable 是必需的，以便函数能够接收以太。

            // 如果拍卖时间已过，则撤销调用。
            if (block.timestamp > auctionEndTime)
                revert AuctionAlreadyEnded();

            // 如果出价不高，则将以太币退回（撤销语句将撤销此函数执行中的所有更改，包括它已接收以太币）。
            if (msg.value <= highestBid)
                revert BidNotHighEnough(highestBid);

            if (highestBid != 0) {
                // 通过简单使用 highestBidder.send(highestBid) 退回以太币是一个安全风险，因为它可能会执行一个不受信任的合约。
                // 让接收者自行提取他们的以太币总是更安全。
                pendingReturns[highestBidder] += highestBid;
            }
            highestBidder = msg.sender;
            highestBid = msg.value;
            emit HighestBidIncreased(msg.sender, msg.value);
        }

        /// 取回出价（当该出价已被超越）
        function withdraw() external returns (bool) {
            uint amount = pendingReturns[msg.sender];
            if (amount > 0) {
                // 将其设置为零很重要，因为接收者可以在 `send` 返回之前再次调用此函数作为接收调用的一部分。
                pendingReturns[msg.sender] = 0;

                // msg.sender 不是 `address payable` 类型，必须显式转换为 `payable(msg.sender)` 以便使用成员函数 `send()`。
                if (!payable(msg.sender).send(amount)) {
                    // 这里不需要调用 throw，只需重置未付款
                    pendingReturns[msg.sender] = amount;
                    return false;
                }
            }
            return true;
        }

        /// 结束拍卖并将最高出价发送给受益人。
        function auctionEnd() external {
            // 这是一个好的指导原则，将与其他合约交互的函数（即它们调用函数或发送以太）结构化为三个阶段：
            // 1. 检查条件
            // 2. 执行操作（可能更改条件）
            // 3. 与其他合约交互
            // 如果这些阶段混合在一起，其他合约可能会回调当前合约并修改状态或导致效果（以太支付）被多次执行。
            // 如果内部调用的函数包括与外部合约的交互，它们也必须被视为与外部合约的交互。

            // 1. 条件
            if (block.timestamp < auctionEndTime)
                revert AuctionNotYetEnded();
            if (ended)
                revert AuctionEndAlreadyCalled();

            // 2. 生效
            ended = true;
            emit AuctionEnded(highestBidder, highestBid);

            // 3. 交互
            beneficiary.transfer(highestBid);
        }
    }

盲拍
=============

之前的公开拍卖在以下内容中扩展为盲拍。
盲拍的优点在于，在拍卖期间结束时没有时间压力。
在透明计算平台上创建盲拍听起来像是自相矛盾，但密码学可以实现它。

在 **拍卖期间**，竞标者实际上并不发送他们的出价，而只是发送其哈希版本的出价。
由于目前被认为几乎不可能找到两个（足够长的）值，其哈希值相等，因此竞标者通过此方式承诺出价。
在拍卖结束后，竞标者必须揭示他们的出价：他们以未加密的方式发送他们的值，合约检查哈希值是否与拍卖期间提供的相同。
另一个挑战是如何使拍卖 **具有约束力且保密**：防止竞标者在赢得拍卖后不发送以太币的唯一方法是让他们在出价时一起发送。
由于以太坊中无法对价值转移进行保密，任何人都可以看到该价值。

以下合约通过接受任何高于最高出价的值来解决此问题。
由于这只能在揭示阶段进行检查，因此某些出价可能是 **无效的**，这是故意的（它甚至提供了一个显式标志，以便进行高价值转移的无效出价）：竞标者可以通过提交多个高或低的无效出价来迷惑竞争对手。

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;
    contract BlindAuction {
        struct Bid {
            bytes32 blindedBid;
            uint deposit;
        }

        address payable public beneficiary;
        uint public biddingEnd;
        uint public revealEnd;
        bool public ended;

        mapping(address => Bid[]) public bids;

        address public highestBidder;
        uint public highestBid;

        // 允许提取之前出价
        mapping(address => uint) pendingReturns;

        event AuctionEnded(address winner, uint highestBid);

        // Errors 用来定义失败

        /// 函数被调用得太早。
        /// 请在 `time` 再试一次。
        error TooEarly(uint time);
        /// 函数被调用得太晚。
        /// 不能在 `time` 之后调用。
        error TooLate(uint time);
        /// 函数 auctionEnd 已经被调用。
        error AuctionEndAlreadyCalled();

        // 修改器是一种方便的方式来验证输入函数。
        // `onlyBefore` 应用于下面的 `bid`：新的函数体是修改器的主体，其中 `_` 被旧函数体替换。
        modifier onlyBefore(uint time) {
            if (block.timestamp >= time) revert TooLate(time);
            _;
        }
        modifier onlyAfter(uint time) {
            if (block.timestamp <= time) revert TooEarly(time);
            _;
        }

        constructor(
            uint biddingTime,
            uint revealTime,
            address payable beneficiaryAddress
        ) {
            beneficiary = beneficiaryAddress;
            biddingEnd = block.timestamp + biddingTime;
            revealEnd = biddingEnd + revealTime;
        }

        /// 以 `blindedBid` = keccak256(abi.encodePacked(value, fake, secret)) 的方式提交一个盲出价。
        /// 发送的以太币仅在出价在揭示阶段被正确揭示时才会退还。
        /// 如果与出价一起发送的以太币至少为 "value" 且 "fake" 不为真，则出价有效。
        /// 将 "fake" 设置为真并发送不准确的金额是隐藏真实出价的方式，但仍然满足所需的存款。
        /// 相同地址可以提交多个出价。
        function bid(bytes32 blindedBid)
            external
            payable
            onlyBefore(biddingEnd)
        {
            bids[msg.sender].push(Bid({
                blindedBid: blindedBid,
                deposit: msg.value
            }));
        }

        /// 揭示盲出价。
        /// 将获得所有正确盲出的无效出价的退款，以及除了最高出价之外的所有出价。
        function reveal(
            uint[] calldata values,
            bool[] calldata fakes,
            bytes32[] calldata secrets
        )
            external
            onlyAfter(biddingEnd)
            onlyBefore(revealEnd)
        {
            uint length = bids[msg.sender].length;
            require(values.length == length);
            require(fakes.length == length);
            require(secrets.length == length);

            uint refund;
            for (uint i = 0; i < length; i++) {
                Bid storage bidToCheck = bids[msg.sender][i];
                (uint value, bool fake, bytes32 secret) =
                        (values[i], fakes[i], secrets[i]);
                if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                    // 出价未能正确披露
                    // 不退还存款。
                    continue;
                }
                refund += bidToCheck.deposit;
                if (!fake && bidToCheck.deposit >= value) {
                    if (placeBid(msg.sender, value))
                        refund -= value;
                }
                // 使发送者无法重新取回相同的存款。
                bidToCheck.blindedBid = bytes32(0);
            }
            payable(msg.sender).transfer(refund);
        }

        /// 提取被超出出价的出价。
        function withdraw() external {
            uint amount = pendingReturns[msg.sender];
            if (amount > 0) {
                // 将其设置为零是重要的，
                // 因为，作为接收调用的一部分，
                // 接收者可以在 `transfer` 返回之前重新调用该函数。（可查看上面关于“条件 -> 生效 -> 交互”的标注）
                pendingReturns[msg.sender] = 0;

                payable(msg.sender).transfer(amount);
            }
        }

        /// 结束拍卖并将最高出价发送给受益人。
        function auctionEnd()
            external
            onlyAfter(revealEnd)
        {
            if (ended) revert AuctionEndAlreadyCalled();
            emit AuctionEnded(highestBidder, highestBid);
            ended = true;
            beneficiary.transfer(highestBid);
        }

        // 这是一个“内部”函数，这意味着它只能从合约本身（或从派生合约）调用。
        function placeBid(address bidder, uint value) internal
                returns (bool success)
        {
            if (value <= highestBid) {
                return false;
            }
            if (highestBidder != address(0)) {
                // 退款给之前的最高出价者。
                pendingReturns[highestBidder] += highestBid;
            }
            highestBid = value;
            highestBidder = bidder;
            return true;
        }
    }