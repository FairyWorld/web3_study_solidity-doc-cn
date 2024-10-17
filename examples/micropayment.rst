********************
微支付通道
********************

在本节中，我们将学习如何构建一个支付通道的示例实现。
它使用加密签名使得在同一方之间重复转移以太币变得安全、即时且没有交易费用。
对于这个示例，我们需要了解如何签名和验证签名，以及如何设置支付通道。

创建和验证签名
=================================

想象一下，Alice 想要向鲍勃发送一些以太币，即 Alice 是发送者，Bob 是接收者。

Alice 只需要向 Bob 发送离线的加密签名消息（例如，通过电子邮件），这类似于开支票。

Alice 和 Bob 使用签名来授权交易，这在以太坊的智能合约中是可能的。
Alice 将构建一个简单的智能合约，让她可以传输以太币，但她不会自己调用函数来发起支付，而是让 Bob 来做，从而支付交易费用。

合约的工作流程如下：

    1. Alice 部署 ``ReceiverPays`` 合约，并附加足够的以太币以覆盖将要进行的支付。
    2. Alice 通过用她的私钥签名一条消息来授权支付。
    3. Alice 将加密签名的消息发送给 Bob。该消息不需要保密（稍后解释），发送机制无关紧要。
    4. Bob 通过向智能合约提交签名消息来索取他的支付，合约验证消息的真实性，然后释放资金。

创建签名
----------------------

Alice 不需要与以太坊网络交互来签署交易，整个过程完全离线。
在本教程中，我们将使用 `web3.js <https://github.com/web3/web3.js>`_ 和 `MetaMask <https://metamask.io>`_ 在浏览器中签名消息，使用 `EIP-712 <https://github.com/ethereum/EIPs/pull/712>`_ 中描述的方法，因为它提供了一些其他的安全好处。

.. code-block:: javascript

    ///  先计算一个 hash，让事情变得简单
    var hash = web3.utils.sha3("message to sign");
    web3.eth.personal.sign(hash, web3.eth.defaultAccount, function () { console.log("Signed"); });

.. note::
  ``web3.eth.personal.sign`` 在签名数据前添加了消息的长度。
  由于我们首先进行哈希处理，消息的长度将始终为 32 字节，因此这个长度前缀始终是相同的。

要签署的内容
------------

对于一个满足支付的合约，签名消息必须包含：

    1. 接收者的地址。
    2. 要转移的金额。
    3. 防止重放攻击的保护。

重放攻击是指重用签名消息以声明第二个操作的授权。
为了避免重放攻击，我们使用与以太坊交易本身相同的技术，即所谓的随机数（nonce），它是由账户发送的交易数量。
智能合约检查随机数是否被多次使用。

另一种重放攻击可能发生在所有者部署 ``ReceiverPays`` 智能合约，进行一些支付，然后销毁合约。
之后，他们决定再次部署 ``RecipientPays`` 智能合约，但新合约不知道之前部署中使用的随机数，因此攻击者可以再次使用旧消息。

Alice 可以通过在消息中包含合约的地址来保护自己免受此攻击，只有包含合约地址的消息才会被接受。
可以在本节末尾完整合约的 ``claimPayment()`` 函数的前两行中找到这个示例。

此外，我们将通过冻结合约来禁用合约的功能，而不是通过调用 ``selfdestruct`` 来销毁合约，后者目前已被弃用，这样在冻结后任何调用都将被回滚。

打包参数
-----------------

现在我们已经确定了要包含在签名消息中的信息，我们准备将消息组合在一起，进行哈希处理并签名。
为了简单起见，我们将数据连接在一起。`ethereumjs-abi <https://github.com/ethereumjs/ethereumjs-abi>`_ 库提供了一个名为 ``soliditySHA3`` 的函数，它模仿了应用于使用 ``abi.encodePacked`` 编码的参数的 Solidity 的 ``keccak256`` 函数的行为。
以下是一个创建 ``ReceiverPays`` 示例的正确签名的 JavaScript 函数：

.. code-block:: javascript

    // recipient 表示向谁付款.
    // amount，以 wei 为单位，指定应该发送多少以太币。
    // nonce 可以是任何唯一数字以防止重放攻击
    // contractAddress 用于防止跨合约重放攻击
    function signPayment(recipient, amount, nonce, contractAddress, callback) {
        var hash = "0x" + abi.soliditySHA3(
            ["address", "uint256", "uint256", "address"],
            [recipient, amount, nonce, contractAddress]
        ).toString("hex");

        web3.eth.personal.sign(hash, web3.eth.defaultAccount, callback);
    }

在 Solidity 中还原消息签名者
-----------------------------------------

一般来说，ECDSA 签名由两个参数 ``r`` 和 ``s`` 组成。
以太坊中的签名包括第三个参数 ``v``，你可以使用它来验证哪个账户的私钥用于签署消息，以及交易的发送者。
Solidity 提供了一个内置函数 :ref:`ecrecover <mathematical-and-cryptographic-functions>`，它接受一条消息以及 ``r``、``s`` 和 ``v`` 参数，并返回用于签署消息的地址。

提取签名参数
-----------------------------------

web3.js 生成的签名是 ``r``、``s`` 和 ``v`` 的连接，因此第一步是将这些参数分开。
可以在客户端进行此操作，但在智能合约内部进行此操作意味着只需发送一个签名参数而不是三个。
将字节数组拆分为其组成部分是一项繁琐的工作，因此我们在 ``splitSignature`` 函数中使用 :doc:`inline assembly <assembly>` 来完成这项工作（本节末尾完整合约中的第三个函数）。

计算消息的哈希值
--------------------------

智能合约需要确切知道哪些参数被签名，因此它必须从参数中重建消息，并使用该消息进行签名验证。
函数 ``prefixed`` 和 ``recoverSigner`` 在 ``claimPayment`` 函数中执行此操作。

完整合约
-----------------

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Owned {
        address payable owner;
        constructor() {
            owner = payable(msg.sender);
        }
    }

    contract Freezable is Owned {
        bool private _frozen = false;

        modifier notFrozen() {
            require(!_frozen, "Inactive Contract.");
            _;
        }

        function freeze() internal {
            if (msg.sender == owner)
                _frozen = true;
        }
    }

    contract ReceiverPays is Freezable {
        mapping(uint256 => bool) usedNonces;

        constructor() payable {}

        function claimPayment(uint256 amount, uint256 nonce, bytes memory signature)
            external
            notFrozen
        {
            require(!usedNonces[nonce]);
            usedNonces[nonce] = true;

            // 这重建了在客户端签名的消息
            bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this)));
            require(recoverSigner(message, signature) == owner);
            payable(msg.sender).transfer(amount);
        }

        /// 冻结合约并回收剩余资金。
        function shutdown()
            external
            notFrozen
        {
            require(msg.sender == owner);
            freeze();
            payable(msg.sender).transfer(address(this).balance);
        }

        /// 签名方法。
        function splitSignature(bytes memory sig)
            internal
            pure
            returns (uint8 v, bytes32 r, bytes32 s)
        {
            require(sig.length == 65);

            assembly {
                // 前 32 个字节，在长度前缀之后。
                r := mload(add(sig, 32))
                // 第二个 32 个字节。
                s := mload(add(sig, 64))
                // 最后一个字节（下一个 32 个字节的第一个字节）。
                v := byte(0, mload(add(sig, 96)))
            }

            return (v, r, s);
        }

        function recoverSigner(bytes32 message, bytes memory sig)
            internal
            pure
            returns (address)
        {
            (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
            return ecrecover(message, v, r, s);
        }

        /// 构建一个带前缀的哈希以模仿 eth_sign 的行为。
        function prefixed(bytes32 hash) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
    }


编写一个简单的支付通道
==========================

Alice 现在构建一个简单但完整的支付通道实现。支付通道使用加密签名安全、即时且无交易费用地进行重复的以太币转账。

什么是支付通道？
------------------

支付通道允许参与者进行重复的以太币转账，而无需使用交易。这意味着可以避免与交易相关的延迟和费用。
我们将探讨一个简单的单向支付通道，涉及两个参与方（Alice 和 Bob）。它包括三个步骤：

    1. Alice 用以太币为智能合约提供资金。这“打开”了支付通道。
    2. Alice 签署指定欠收款人的以太币金额的消息。此步骤对每笔付款重复进行。
    3. Bob “关闭”支付通道，提取他应得的以太币，并将剩余部分发送回发送者。

.. note::
  只有步骤 1 和 3 需要以太坊交易，步骤 2 意味着发送者通过链下方法（例如电子邮件）向接收者传输加密签名的消息。
  这意味着只需要两笔交易即可支持任意数量的转账。

Bob 保证会收到他的资金，因为智能合约托管了以太币并尊重有效的签名消息。
智能合约还强制执行超时，因此即使接收者拒绝关闭通道，Alice 也保证最终能收回她的资金。
支付通道的参与者可以决定保持通道开放的时间长度。
对于短期交易，例如为每分钟的网络访问支付互联网咖啡馆，支付通道可以保持开放有限的时间。
另一方面，对于定期付款，例如按小时支付员工工资，支付通道可以保持开放几个月或几年。

打开支付通道
----------------

要打开支付通道，Alice 需要部署智能合约，附上要托管的以太币，并指定预期的接收者和通道存在的最大持续时间。
这是合约中的``SimplePaymentChannel``函数，在本节末尾。

进行支付
-----------

Alice 通过 Bob 发送签名消息来进行付款。该步骤完全在以太坊网络之外执行。
消息由发送者进行加密签名，然后直接传输给接收者。

每条消息包括以下信息：

    * 智能合约的地址，用于防止跨合约重放攻击。
    * 到目前为止欠接收者的以太币总额。

支付通道仅在一系列转账结束时关闭一次。因此，只能赎回发送的其中一条消息。
这就是为什么每条消息都指定了应付的以太币累计总额，而不是单个微支付的金额。
接收者自然会选择赎回最新的消息，因为那条消息的总额最高。
每条消息的 nonce 不再需要，因为智能合约只会处理一条消息。
智能合约的地址仍然被用于防止针对一个支付通道的消息被用于不同的通道。

这是修改后的 JavaScript 代码，用于对上一节中的消息进行加密签名：

.. code-block:: javascript

    function constructPaymentMessage(contractAddress, amount) {
        return abi.soliditySHA3(
            ["address", "uint256"],
            [contractAddress, amount]
        );
    }

    function signMessage(message, callback) {
        web3.eth.personal.sign(
            "0x" + message.toString("hex"),
            web3.eth.defaultAccount,
            callback
        );
    }

    // contractAddress 用于防止跨合约重放攻击。
    // amount，以 wei 为单位，指定应发送多少以太币。

    function signPayment(contractAddress, amount, callback) {
        var message = constructPaymentMessage(contractAddress, amount);
        signMessage(message, callback);
    }


关闭支付通道
----------------

当 Bob 准备好接收他的资金时，是时候通过调用智能合约上的 ``close`` 函数来关闭支付通道。
关闭通道将支付接收者应得的以太币，并通过冻结合约来停用它，将任何剩余的以太币发送回 Alice。
要关闭通道，Bob 需要提供一条由 Alice 签署的消息。

智能合约必须验证消息是否包含来自发送者的有效签名。进行此验证的过程与接收者使用的过程相同。
Solidity 函数 ``isValidSignature`` 和 ``recoverSigner`` 的工作方式与上一节中的 JavaScript 对应函数相同，后者函数借用自``ReceiverPays``合约。

只有支付通道的接收者可以调用 ``close`` 函数，接收者自然会传递最新的付款消息，因为该消息携带最高的付款总额。
如果允许发送者调用此函数，他们可能会提供一条金额较低的消息，从而欺骗接收者，剥夺他们应得的款项。

该函数验证签名消息是否与给定参数匹配。如果一切正常，接收者将收到他们应得的以太币，发送者将通过 ``transfer`` 发送剩余资金。
可以在完整合约中查看 ``close`` 函数。

通道过期
-----------

Bob 可以随时关闭支付通道，但如果他没有这样做，Alice 需要一种方法来恢复她托管的资金。
在合约部署时设置了一个 *过期* 时间。一旦达到该时间，Alice 可以调用 ``claimTimeout`` 来恢复她的资金。
可以在完整合约中查看``claimTimeout``函数。

在调用此函数后，Bob 将无法再接收任何以太币，因此在到期之前，Bob 关闭通道是很重要的。

完整合约
-----------------

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Frozeable {
        bool private _frozen = false;

        modifier notFrozen() {
            require(!_frozen, "Inactive Contract.");
            _;
        }

        function freeze() internal {
            _frozen = true;
        }
    }

    contract SimplePaymentChannel is Frozeable {
        address payable public sender;    // 发送支付的账户。
        address payable public recipient; // 接收支付的账户。
        uint256 public expiration;        // 超时，如果接收者从未关闭。

        constructor (address payable recipientAddress, uint256 duration)
            payable
        {
            sender = payable(msg.sender);
            recipient = recipientAddress;
            expiration = block.timestamp + duration;
        }

        /// 接收者可以随时通过提供发送者的签名金额来关闭通道。
        /// 接收者将收到该金额，其余部分将返回给发送者
        function close(uint256 amount, bytes memory signature)
            external
            notFrozen
        {
            require(msg.sender == recipient);
            require(isValidSignature(amount, signature));

            recipient.transfer(amount);
            freeze();
            sender.transfer(address(this).balance);
        }

        /// 发送者可以随时延长到期时间
        function extend(uint256 newExpiration)
            external
            notFrozen
        {
            require(msg.sender == sender);
            require(newExpiration > expiration);

            expiration = newExpiration;
        }

        /// 如果超时到达而接收者未关闭通道，则以太币将返回给发送者。
        function claimTimeout()
            external
            notFrozen
        {
            require(block.timestamp >= expiration);
            freeze();
            sender.transfer(address(this).balance);
        }

        function isValidSignature(uint256 amount, bytes memory signature)
            internal
            view
            returns (bool)
        {
            bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));
            // 检查签名是否来自支付发送者
            return recoverSigner(message, signature) == sender;
        }

        /// 以下所有函数均来自于 '创建和验证签名' 章节。
        function splitSignature(bytes memory sig)
            internal
            pure
            returns (uint8 v, bytes32 r, bytes32 s)
        {
            require(sig.length == 65);

            assembly {
                // 前 32 个字节，长度前缀后
                r := mload(add(sig, 32))
                // 第二个 32 个字节
                s := mload(add(sig, 64))
                // 最后一个字节（下一个 32 个字节的第一个字节）
                v := byte(0, mload(add(sig, 96)))
            }
            return (v, r, s);
        }

        function recoverSigner(bytes32 message, bytes memory sig)
            internal
            pure
            returns (address)
        {
            (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
            return ecrecover(message, v, r, s);
        }

        /// 构建一个带前缀的哈希，以模仿 eth_sign 的行为。
        function prefixed(bytes32 hash) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
    }


.. note::
  函数 ``splitSignature`` 没有做足够的安全检查。
  例如 openzeppelin 的 `版本 <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol>`_。

验证支付
------------------

与上一节不同，支付通道中的消息不会立即兑现。接收者跟踪最新消息，并在关闭支付通道时兑现。
这意味着接收者必须对每条消息进行自己的验证。否则，接收者无法保证最终能够获得支付。

接收者应使用以下过程验证每条消息：

    1. 验证消息中的合约地址是否与支付通道匹配。
    2. 验证新总金额是否为预期金额。
    3. 验证新总金额是否不超过托管的以太币金额。
    4. 验证签名是否有效，并且来自支付通道发送者。

我们将使用 `ethereumjs-util <https://github.com/ethereumjs/ethereumjs-util>`_ 库来编写此验证。
最后一步可以通过多种方式完成，我们使用 JavaScript。
以下代码借用了上面签名 **JavaScript 代码** 中的 ``constructPaymentMessage`` 函数：

.. code-block:: javascript

    // 这模仿了 eth_sign JSON-RPC 方法的前缀行为。
    function prefixed(hash) {
        return ethereumjs.ABI.soliditySHA3(
            ["string", "bytes32"],
            ["\x19Ethereum Signed Message:\n32", hash]
        );
    }

    function recoverSigner(message, signature) {
        var split = ethereumjs.Util.fromRpcSig(signature);
        var publicKey = ethereumjs.Util.ecrecover(message, split.v, split.r, split.s);
        var signer = ethereumjs.Util.pubToAddress(publicKey).toString("hex");
        return signer;
    }

    function isValidSignature(contractAddress, amount, signature, expectedSigner) {
        var message = prefixed(constructPaymentMessage(contractAddress, amount));
        var signer = recoverSigner(message, signature);
        return signer.toLowerCase() ==
            ethereumjs.Util.stripHexPrefix(expectedSigner).toLowerCase();
    }