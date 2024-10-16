.. index:: ! event, ! event; anonymous, ! event; indexed, ! event; topic

.. _events:

******
事件
******

Solidity 事件（Events）在 EVM 的日志功能之上提供了一个抽象层。
应用程序可以通过以太坊客户端的 RPC 接口订阅和监听这些事件。

事件可以在文件级别定义或作为合约（包括接口和库）的可继承成员定义。
当你调用它们时，它们会导致参数被存储在交易的日志中——区块链中的一种特殊数据结构。这些日志与发出它们的合约地址相关联，包含在区块链中，并在一个区块可访问的时间内保留（目前是永久的，但未来可能会改变）。日志及其事件数据无法从合约内部访问（甚至无法从创建它们的合约访问）。

可以请求日志的 Merkle 证明，因此如果外部实体向合约提供这样的证明，它可以检查日志是否确实存在于区块链中。你必须提供区块头，因为合约只能看到最后 256 个区块哈希。

你可以将属性 ``indexed`` 添加到最多三个参数，这会将它们添加到一个称为 :ref:`"topics" <abi_events>` 的特殊数据结构中，而不是日志的数据部分。
一个主题只能容纳一个单词（32 字节），因此如果你对一个索引参数使用 :ref:`引用类型 <reference-types>`，则该值的 Keccak-256 哈希将作为主题存储。

所有没有 ``indexed`` 属性的参数都被 :ref:`ABI 编码 <ABI>` 到日志的数据部分。

主题允许你搜索事件，例如在过滤一系列区块以查找特定事件时。你还可以通过发出事件的合约地址过滤事件。

例如，下面的代码使用 web3.js ``subscribe("logs")``
`方法 <https://web3js.readthedocs.io/en/1.0/web3-eth-subscribe.html#subscribe-logs>`_ 来过滤与某个地址值匹配的主题的日志：

.. code-block:: javascript

    var options = {
        fromBlock: 0,
        address: web3.eth.defaultAccount,
        topics: ["0x0000000000000000000000000000000000000000000000000000000000000000", null, null]
    };
    web3.eth.subscribe('logs', options, function (error, result) {
        if (!error)
            console.log(result);
    })
        .on("data", function (log) {
            console.log(log);
        })
        .on("changed", function (log) {
    });


事件的签名哈希是主题之一，除非你使用 ``anonymous`` 修饰符声明事件。这意味着无法按名称过滤特定的匿名事件，只能按合约地址过滤。匿名事件的优点是它们的部署和调用成本更低。它还允许你声明四个索引参数而不是三个。

.. note::
    由于交易日志只存储事件数据而不存储类型，你必须知道事件的类型，包括哪个参数是索引的，以及事件是否是匿名的，以便正确解释数据。
    特别是，可以使用匿名事件“伪造”另一个事件的签名。

.. index:: ! selector; of an event

Events 成员
=================

- ``event.selector``: 对于非匿名事件，这是一个 ``bytes32`` 值
  包含事件签名的 ``keccak256`` 哈希，作为默认主题使用。


示例
=======

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.21 <0.9.0;

    contract ClientReceipt {
        event Deposit(
            address indexed from,
            bytes32 indexed id,
            uint value
        );

        function deposit(bytes32 id) public payable {
            // 事件通过 `emit` 发出，后跟事件的名称和（如果有的话）括号中的参数
            // 任何这样的调用（即使是深度嵌套）都可以通过
            // JavaScript API 通过过滤 `Deposit` 来检测。
            emit Deposit(msg.sender, id, msg.value);
        }
    }

在 JavaScript API 中的用法如下：

.. code-block:: javascript

    var abi = /* abi 由编译器产生 */;
    var ClientReceipt = web3.eth.contract(abi);
    var clientReceipt = ClientReceipt.at("0x1234...ab67" /* 地址 */);

    var depositEvent = clientReceipt.Deposit();

    // 监听变化
    depositEvent.watch(function(error, result){
        // result 包含非索引参数和
        // 传递给 `Deposit` 调用的主题。
        if (!error)
            console.log(result);
    });


    // 或者传递一个回调以立即开始监视
    var depositEvent = clientReceipt.Deposit(function(error, result) {
        if (!error)
            console.log(result);
    });

上述输出如下（已修剪）：

.. code-block:: json

    {
       "returnValues": {
           "from": "0x1111…FFFFCCCC",
           "id": "0x50…sd5adb20",
           "value": "0x420042"
       },
       "raw": {
           "data": "0x7f…91385",
           "topics": ["0xfd4…b4ead7", "0x7f…1a91385"]
       }
    }

理解事件的其他资源
=============================================

- `JavaScript 文档 <https://github.com/web3/web3.js/blob/1.x/docs/web3-eth-contract.rst#events>`_
- `事件的示例用法 <https://github.com/ethchange/smart-exchange/blob/master/lib/contracts/SmartExchange.sol>`_
- `如何在 js 中访问它们 <https://github.com/ethchange/smart-exchange/blob/master/lib/exchange_transactions.js>`_