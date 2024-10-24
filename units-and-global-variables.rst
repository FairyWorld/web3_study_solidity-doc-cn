.. include:: glossaries.rst

.. index:: ! denomination

**************************************
单位和全局可用变量
**************************************

.. index:: ! wei, ! finney, ! szabo, ! gwei, ! ether, ! denomination;ether

以太单位
===========

字面数字可以带有后缀 ``wei``、``gwei`` 或 ``ether`` 来指定以太的子单位，其中没有后缀的以太数字被假定为 Wei。

.. code-block:: solidity
    :force:

    assert(1 wei == 1);
    assert(1 gwei == 1e9);
    assert(1 ether == 1e18);

子单位后缀的唯一效果是乘以十的幂。

.. note::
    在版本 0.7.0 中，单位 ``finney`` 和 ``szabo`` 已被移除。

.. index:: ! seconds, ! minutes, ! hours, ! days, ! weeks, ! years, ! denomination;time

时间单位
==========

字面数字后可以使用后缀 ``seconds``、``minutes``、``hours``、``days`` 和 ``weeks`` 来指定时间单位，其中秒是基本单位，单位的换算关系如下：

* ``1 == 1 seconds``
* ``1 minutes == 60 seconds``
* ``1 hours == 60 minutes``
* ``1 days == 24 hours``
* ``1 weeks == 7 days``

如果使用这些单位进行日历计算，请小心，因为并非每年都等于 365 天，甚至并非每一天都有 24 小时，因为 `闰秒 <https://en.wikipedia.org/wiki/Leap_second>`_。
由于闰秒无法预测，确切的日历库必须由外部预言机更新。

.. note::
    由于上述原因，后缀 ``years`` 在版本 0.5.0 中已被移除。

这些后缀不能应用于变量。例如，如果你想以天为单位解释函数参数，可以如下进行：

.. code-block:: solidity

    function f(uint start, uint daysAfter) public {
        if (block.timestamp >= start + daysAfter * 1 days) {
            // ...
        }
    }

.. _special-variables-functions:

特殊变量和函数
===============================

有一些特殊变量和函数始终存在于全局命名空间中，主要用于提供有关区块链的信息或是通用的实用函数。

.. index:: abi, block, coinbase, difficulty, prevrandao, encode, number, block;number, timestamp, block;timestamp, block;basefee, block;blobbasefee, msg, data, gas, sender, value, gas price, origin

区块和交易属性
--------------------------------

- ``blockhash(uint blockNumber) returns (bytes32)``：给定区块的哈希，当 ``blocknumber`` 是最近 256 个区块之一时；否则返回零
- ``blobhash(uint index) returns (bytes32)``：与当前交易关联的 ``index``-th blob 的版本哈希。
  版本哈希由一个表示版本的单字节（当前为 ``0x01``）和 KZG 承诺的 SHA256 哈希的最后 31 字节组成（`EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）。
  如果不存在具有给定索引的 blob，则返回零。
- ``block.basefee`` (``uint``)：当前区块的基础费用（`EIP-3198 <https://eips.ethereum.org/EIPS/eip-3198>`_ 和 `EIP-1559 <https://eips.ethereum.org/EIPS/eip-1559>`_）
- ``block.blobbasefee`` (``uint``)：当前区块的 blob 基础费用（`EIP-7516 <https://eips.ethereum.org/EIPS/eip-7516>`_ 和 `EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）
- ``block.chainid`` (``uint``)：当前链 ID
- ``block.coinbase`` (``address payable``)：当前区块矿工的地址
- ``block.difficulty`` (``uint``)：当前区块的难度（``EVM < Paris``）。对于其他 EVM 版本，它作为 ``block.prevrandao`` 的弃用别名
  （`EIP-4399 <https://eips.ethereum.org/EIPS/eip-4399>`_）
- ``block.gaslimit`` (``uint``)：当前区块的 gas 限制
- ``block.number`` (``uint``)：当前区块编号
- ``block.prevrandao`` (``uint``)：由信标链提供的随机数（``EVM >= Paris``）
- ``block.timestamp`` (``uint``)：当前区块的时间戳，以自 Unix 纪元以来的秒数表示
- ``gasleft() returns (uint256)``：剩余 gas
- ``msg.data`` (``bytes calldata``)：完整的 calldata
- ``msg.sender`` (``address``)：消息的发送者（当前调用）
- ``msg.sig`` (``bytes4``)：calldata 的前四个字节（即函数标识符）
- ``msg.value`` (``uint``)：与消息一起发送的 wei 数量
- ``tx.gasprice`` (``uint``)：交易的 gas 价格
- ``tx.origin`` (``address``)：交易的发送者（完整调用链）

.. note::
    ``msg`` 的所有成员的值，包括 ``msg.sender`` 和 ``msg.value`` 可以在每次 **外部** 函数调用中变化。
    这包括对库函数的调用。

.. note::
    当合约在链下评估而不是在包含在区块中的交易上下文中时，你不应假设 ``block.*`` 和 ``tx.*`` 指的是来自任何特定区块或交易的值。
    这些值由执行合约的 EVM 实现提供，可以是任意的。

.. note::
    不要依赖 ``block.timestamp`` 或 ``blockhash`` 作为随机数源，除非你知道自己在做什么。

    时间戳和区块哈希在一定程度上可以被矿工影响。
    矿业社区中的不良行为者可以例如在选择的哈希上运行赌场支付函数，
    如果他们没有收到任何补偿，例如以太，他们只需重试不同的哈希。

    当前区块的时间戳必须严格大于最后一个区块的时间戳，但唯一的保证是它将在规范链中两个连续区块的时间戳之间。

.. note::
    出于可扩展性原因，并非所有区块的区块哈希都是可用的。
    你只能访问最近 256 个区块的哈希，所有其他值将为零。

.. note::
    函数 ``blockhash`` 以前被称为 ``block.blockhash``，在版本 0.4.22 中被弃用，并在版本 0.5.0 中移除。

.. note::
    函数 ``gasleft`` 以前被称为 ``msg.gas``，在版本 0.4.21 中被弃用，并在版本 0.5.0 中移除。

.. note::
    在版本 0.7.0 中，别名 ``now`` （用于 ``block.timestamp``）已被移除。

.. index:: abi, encoding, packed

ABI 编码和解码函数
-----------------------------------

- ``abi.decode(bytes memory encodedData, (...)) returns (...)``：对给定数据进行 ABI 解码，类型在括号中作为第二个参数给出。示例：``(uint a, uint[2] memory b, bytes memory c) = abi.decode(data, (uint, uint[2], bytes))``
- ``abi.encode(...) returns (bytes memory)``：对给定参数进行 ABI 编码
- ``abi.encodePacked(...) returns (bytes memory)``：对给定参数执行 :ref:`packed encoding <abi_packed_mode>`。请注意，打包编码可能会产生歧义！
- ``abi.encodeWithSelector(bytes4 selector, ...) returns (bytes memory)``：对给定参数进行 ABI 编码，从第二个参数开始，并在前面添加给定的四字节选择器
- ``abi.encodeWithSignature(string memory signature, ...) returns (bytes memory)``：等同于 ``abi.encodeWithSelector(bytes4(keccak256(bytes(signature))), ...)``
- ``abi.encodeCall(function functionPointer, (...)) returns (bytes memory)``：对 ``functionPointer`` 的调用进行 ABI 编码，参数在元组中找到。执行完整的类型检查，确保类型与函数签名匹配。结果等于 ``abi.encodeWithSelector(functionPointer.selector, (...))``
.. note::
    这些编码函数可以用于构造数据以进行外部函数调用，而无需实际调用外部函数。此外，``keccak256(abi.encodePacked(a, b))`` 是计算结构化数据哈希的一种方法（尽管要注意，使用不同的函数参数类型可能会构造出“哈希碰撞”）。

有关编码的详细信息，请参阅 :ref:`ABI <ABI>` 和 :ref:`紧打包编码 <abi_packed_mode>` 的文档。

.. index:: bytes members

字节成员
----------------

- ``bytes.concat(...) returns (bytes memory)``: :ref:`将可变数量的 bytes 和 bytes1, ..., bytes32 参数连接成一个字节数组<bytes-concat>`

.. index:: string members

字符串成员
-----------------

- ``string.concat(...) returns (string memory)``: :ref:`将可变数量的字符串参数连接成一个字符串数组<string-concat>`


.. index:: assert, revert, require

错误处理
--------------

有关错误处理的更多详细信息以及何时使用哪个函数，请参阅 :ref:`assert 和 require<assert-and-require>` 的专门部分。

``assert(bool condition)``
    如果条件不满足，则会导致 Panic 错误，从而使状态更改回滚 - 用于内部错误。

``require(bool condition)``
    如果条件不满足，则回滚 - 用于输入或外部组件的错误。

``require(bool condition, string memory message)``
    如果条件不满足，则回滚 - 用于输入或外部组件的错误。还提供错误消息。

``revert()``
    中止执行并回滚状态更改

``revert(string memory reason)``
    中止执行并回滚状态更改，提供解释字符串

.. index:: keccak256, ripemd160, sha256, ecrecover, addmod, mulmod, cryptography,

.. _mathematical-and-cryptographic-functions:

数学和密码学函数
----------------------------------------

``addmod(uint x, uint y, uint k) returns (uint)``
    计算 ``(x + y) % k``，其中加法以任意精度执行，并且不会在 ``2**256`` 处被截取。从版本 0.5.0 开始，确保 ``k != 0``。

``mulmod(uint x, uint y, uint k) returns (uint)``
    计算 ``(x * y) % k``，其中乘法以任意精度执行，并且不会在 ``2**256`` 处被截取。从版本 0.5.0 开始，确保 ``k != 0``。

``keccak256(bytes memory) returns (bytes32)``
    计算输入的 Keccak-256 哈希

.. note::

    以前有一个名为 ``sha3`` 的 ``keccak256`` 别名，该别名在版本 0.5.0 中被移除。

``sha256(bytes memory) returns (bytes32)``
    计算输入的 SHA-256 哈希

``ripemd160(bytes memory) returns (bytes20)``
    计算输入的 RIPEMD-160 哈希

``ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)``
    从椭圆曲线签名中恢复与公钥相关联的地址，或在出错时返回零。
    函数参数对应于签名的 ECDSA 值：

    * ``r`` = 签名的前 32 字节
    * ``s`` = 签名的后 32 字节
    * ``v`` = 签名的最后 1 字节

    ``ecrecover`` 返回一个 ``address``，而不是 ``address payable``。有关转换，请参阅 :ref:`address payable<address>`，以便在需要将资金转移到恢复的地址时使用。

    有关更多详细信息，请阅读 `示例用法 <https://ethereum.stackexchange.com/questions/1777/workflow-on-signing-a-string-with-private-key-followed-by-signature-verificatio>`_。

.. warning::

    如果使用 ``ecrecover``，请注意，合法签名可以在不需要相应私钥的情况下转换为不同的合法签名。在 Homestead 硬分叉中，此问题已针对 _交易_ 签名修复（请参见 `EIP-2 <https://eips.ethereum.org/EIPS/eip-2#specification>`_），但 ecrecover 函数保持不变。

    除非你需要签名是唯一的或使用它们来识别项目，否则这通常不是问题。
    OpenZeppelin 有一个 `ECDSA 辅助库 <https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA>`_，你可以将其用作 ``ecrecover`` 的包装器，以避免此问题。

.. note::

    在 *私有区块链* 上运行 ``sha256``、``ripemd160`` 或 ``ecrecover`` 时，你可能会遇到 Out-of-Gas。这是因为这些函数被实现为“预编译合约”，并且在接收到第一个消息之前实际上并不存在（尽管它们的合约代码是硬编码的）。对不存在的合约的消息成本更高，因此执行可能会遇到 Out-of-Gas 错误。解决此问题的一种方法是在实际合约中使用它们之前，先向每个合约发送 Wei（例如 1）。在主网或测试网中这不是问题。

.. index:: balance, codehash, send, transfer, call, callcode, delegatecall, staticcall

.. _address_related:

地址类型的成员
------------------------

``<address>.balance`` (``uint256``)
    :ref:`address` 的 Wei 余额

``<address>.code`` (``bytes memory``)
    :ref:`address` 的代码（可以为空）

``<address>.codehash`` (``bytes32``)
    :ref:`address` 的代码哈希

``<address payable>.transfer(uint256 amount)``
    将给定数量的 Wei 发送到 :ref:`address`，在失败时回滚，转发 2300 gas 补贴，不可调整

``<address payable>.send(uint256 amount) returns (bool)``
    将给定数量的 Wei 发送到 :ref:`address`，在失败时返回 ``false``，转发 2300 gas 补贴，不可调整

``<address>.call(bytes memory) returns (bool, bytes memory)``
    使用给定有效负载发出低级 ``CALL``，返回成功条件和返回数据，转发所有可用 gas，可调整

``<address>.delegatecall(bytes memory) returns (bool, bytes memory)``
    使用给定有效负载发出低级 ``DELEGATECALL``，返回成功条件和返回数据，转发所有可用 gas，可调整

``<address>.staticcall(bytes memory) returns (bool, bytes memory)``
    使用给定有效负载发出低级 ``STATICCALL``，返回成功条件和返回数据，转发所有可用 gas，可调整

有关更多信息，请参阅 :ref:`address` 部分。

.. warning::
    在执行另一个合约函数时，尽量避免使用 ``.call()``，因为它绕过了类型检查、函数存在性检查和参数打包。

.. warning::
    使用 ``send`` 存在一些危险：如果调用栈深度为 1024，则转账失败（这可以始终由调用者强制），如果接收方耗尽 gas 也会失败。因此，为了安全地转移以太，始终检查 ``send`` 的返回值，使用 ``transfer`` 或更好：
    使用一种模式，让接收方提取以太。

.. warning::
    由于 EVM 将对不存在的合约的调用视为始终成功，
    Solidity 在执行外部调用时使用 ``extcodesize`` 操作码进行额外检查。
    这确保即将被调用的合约实际上存在（它包含代码）
    或引发异常。

    低级调用操作在地址而不是合约实例上操作（即 ``.call()``,
    ``.delegatecall()``, ``.staticcall()``, ``.send()`` 和 ``.transfer()``）**不** 包括此检查，这使它们在 gas 方面更便宜，但也不那么安全。
.. note::
   在版本 0.5.0 之前，Solidity 允许通过合约实例访问地址成员，例如 ``this.balance``。
   现在这是被禁止的，必须显式转换为地址：``address(this).balance``。

.. note::
   如果通过低级 delegatecall 访问状态变量，则两个合约的存储布局
   必须对齐，以便被调用合约能够通过名称正确访问调用合约的存储变量。
   如果存储指针作为函数参数传递，则当然不是这种情况，
   这在高级库中是如此。

.. note::
    在版本 0.5.0 之前，``.call``、``.delegatecall`` 和 ``.staticcall`` 仅返回
    成功条件，而不返回返回数据。

.. note::
    在版本 0.5.0 之前，有一个名为 ``callcode`` 的成员，其语义与 ``delegatecall`` 
    类似但略有不同。

.. index:: this, selfdestruct, super

合约相关
----------------

``this`` （当前合约的类型）
    当前合约，显式可转换为 :ref:`address`

``super``
    继承层次结构中高一级的合约

``selfdestruct(address payable recipient)``
    销毁当前合约，将其资金发送到给定的 :ref:`address` 并结束执行。
    请注意，``selfdestruct`` 继承自 EVM 的一些特殊性：

    - 接收合约的接收函数不会被执行。
    - 合约实际上只在交易结束时被销毁，``revert`` 可能会“撤销”销毁。

此外，当前合约的所有函数都可以直接调用，包括当前函数。

.. warning::
    从 ``EVM >= Cancun`` 开始，``selfdestruct`` **仅** 将账户中的所有以太发送到给定的接收者，而不销毁合约。
    然而，当 ``selfdestruct`` 在创建调用它的合约的同一交易中被调用时，
    ``selfdestruct`` 在 Cancun 硬分叉之前的行为（即 ``EVM <= Shanghai``）得以保留，并将销毁当前合约，
    删除任何数据，包括存储键、代码和账户本身。
    有关更多详细信息，请参见 `EIP-6780 <https://eips.ethereum.org/EIPS/eip-6780>`_。

    新行为是影响以太坊主网和测试网所有合约的网络范围内的变化。
    重要的是要注意，这一变化取决于合约部署所在链的 EVM 版本。
    编译合约时使用的 ``--evm-version`` 设置对此没有影响。

    此外，请注意，``selfdestruct`` 操作码在 Solidity 版本 0.8.18 中已被弃用，
    如 `EIP-6049 <https://eips.ethereum.org/EIPS/eip-6049>`_ 所推荐。
    弃用仍然有效，编译器在使用时仍会发出警告。
    在新部署的合约中强烈不建议使用，即使考虑到新行为。
    对 EVM 的未来更改可能会进一步减少该操作码的功能。

.. note::
    在版本 0.5.0 之前，有一个名为 ``suicide`` 的函数，其语义与 ``selfdestruct`` 相同。

.. index:: type, creationCode, runtimeCode

.. _meta-type:

类型信息
----------------

表达式 ``type(X)`` 可用于检索类型 ``X`` 的信息。
目前对该功能的支持有限（``X`` 可以是合约或整数类型），但未来可能会扩展。

合约类型 ``C`` 可用的属性如下：

``type(C).name``
    合约的名称。

``type(C).creationCode``
    包含合约创建字节码的内存字节数组。
    这可以在内联汇编中用于构建自定义创建例程，特别是通过使用 ``create2`` 操作码。
    此属性 **不能** 在合约本身或任何派生合约中访问。它会导致字节码被包含在调用站点的字节码中，因此不可能有这样的循环引用。

``type(C).runtimeCode``
    包含合约运行时字节码的内存字节数组。
    这是通常由 ``C`` 的构造函数部署的代码。
    如果 ``C`` 有一个使用内联汇编的构造函数，则这可能与实际部署的字节码不同。
    还要注意，库在部署时会修改其运行时字节码，以防止常规调用。
    此属性也适用与 ``.creationCode`` 相同的限制。

除了上述属性外，接口类型 ``I`` 还可用以下属性：

``type(I).interfaceId``
    一个 ``bytes4`` 值，包含给定接口 ``I`` 的 `EIP-165 <https://eips.ethereum.org/EIPS/eip-165>`_
    接口标识符。该标识符定义为接口本身中定义的所有函数选择器的 ``XOR`` - 不包括所有继承的函数。

整数类型 ``T`` 可用的属性如下：

``type(T).min``
    类型 ``T`` 可表示的最小值。

``type(T).max``
    类型 ``T`` 可表示的最大值。

保留关键字
=================

这些关键字在 Solidity 中是保留的。它们可能会在未来成为语法的一部分：

``after``, ``alias``, ``apply``, ``auto``, ``byte``, ``case``, ``copyof``, ``default``,
``define``, ``final``, ``implements``, ``in``, ``inline``, ``let``, ``macro``, ``match``,
``mutable``, ``null``, ``of``, ``partial``, ``promise``, ``reference``, ``relocatable``,
``sealed``, ``sizeof``, ``static``, ``supports``, ``switch``, ``typedef``, ``typeof``,
``var``.