**********
速查表
**********

.. index:: operator;precedence

运算符的优先级
===============================

.. include:: types/operator-precedence-table.rst

.. index:: abi;decode, abi;encode, abi;encodePacked, abi;encodeWithSelector, abi;encodeCall, abi;encodeWithSignature

ABI 编码和解码函数
===============================

- ``abi.decode(bytes memory encodedData, (...)) returns (...)``: :ref:`ABI <ABI>`-解码提供的数据。类型在括号中作为第二个参数给出。
  示例: ``(uint a, uint[2] memory b, bytes memory c) = abi.decode(data, (uint, uint[2], bytes))``
- ``abi.encode(...) returns (bytes memory)``: :ref:`ABI <ABI>`-编码给定的参数
- ``abi.encodePacked(...) returns (bytes memory)``: 对给定参数执行 :ref:`packed encoding <abi_packed_mode>`。请注意，这种编码可能会产生歧义！
- ``abi.encodeWithSelector(bytes4 selector, ...) returns (bytes memory)``: :ref:`ABI <ABI>`-编码给定的参数，从第二个参数开始，并在前面添加给定的四字节选择器
- ``abi.encodeCall(function functionPointer, (...)) returns (bytes memory)``: ABI-编码对 ``functionPointer`` 的调用，参数在元组中找到。执行完整的类型检查，确保类型与函数签名匹配。结果等于 ``abi.encodeWithSelector(functionPointer.selector, ...)``
- ``abi.encodeWithSignature(string memory signature, ...) returns (bytes memory)``: 等同于
  ``abi.encodeWithSelector(bytes4(keccak256(bytes(signature))), ...)``

.. index:: bytes;concat, string;concat

``bytes`` 和 ``string`` 的成员
===============================

- ``bytes.concat(...) returns (bytes memory)``: :ref:`将可变数量的参数串联成一个字节数组<bytes-concat>`

- ``string.concat(...) returns (string memory)``: :ref:`将可变数量的参数串联成一个字符串数组<string-concat>`

.. index:: address;balance, address;codehash, address;send, address;code, address;transfer

``address`` 的成员
===============================

- ``<address>.balance`` (``uint256``): :ref:`address` 的余额，以 Wei 为单位
- ``<address>.code`` (``bytes memory``): :ref:`address` 的代码（可以为空）
- ``<address>.codehash`` (``bytes32``): :ref:`address` 的代码哈希
- ``<address>.call(bytes memory) returns (bool, bytes memory)``: 使用给定有效载荷发出低级 ``CALL``，返回成功条件和返回数据
- ``<address>.delegatecall(bytes memory) returns (bool, bytes memory)``: 使用给定有效载荷发出低级 ``DELEGATECALL``，返回成功条件和返回数据
- ``<address>.staticcall(bytes memory) returns (bool, bytes memory)``: 使用给定有效载荷发出低级 ``STATICCALL``，返回成功条件和返回数据
- ``<address payable>.send(uint256 amount) returns (bool)``: 向 :ref:`address` 发送给定数量的 Wei，失败时返回 ``false``
- ``<address payable>.transfer(uint256 amount)``: 向 :ref:`address` 发送给定数量的 Wei，失败时抛出异常

.. index:: blockhash, blobhash, block, block;basefee, block;blobbasefee, block;chainid, block;coinbase, block;difficulty, block;gaslimit, block;number, block;prevrandao, block;timestamp
.. index:: gasleft, msg;data, msg;sender, msg;sig, msg;value, tx;gasprice, tx;origin

区块和交易属性
===============================

- ``blockhash(uint blockNumber) returns (bytes32)``: 给定区块的哈希 - 仅适用于最近的 256 个区块
- ``blobhash(uint index) returns (bytes32)``: 与当前交易关联的 ``index``-th blob 的版本哈希。
  版本哈希由一个表示版本的单字节（当前为 ``0x01``）和 KZG 承诺的 SHA256 哈希的最后 31 字节组成（`EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）。
  如果不存在具有给定索引的 blob，则返回零。
- ``block.basefee`` (``uint``): 当前区块的基础费用（`EIP-3198 <https://eips.ethereum.org/EIPS/eip-3198>`_ 和 `EIP-1559 <https://eips.ethereum.org/EIPS/eip-1559>`_）
- ``block.blobbasefee`` (``uint``): 当前区块的 blob 基础费用（`EIP-7516 <https://eips.ethereum.org/EIPS/eip-7516>`_ 和 `EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）
- ``block.chainid`` (``uint``): 当前链 ID
- ``block.coinbase`` (``address payable``): 当前区块矿工的地址
- ``block.difficulty`` (``uint``): 当前区块的难度（``EVM < Paris``）。对于其他 EVM 版本，它作为 ``block.prevrandao`` 的已弃用别名，将在下一个重大版本中删除
- ``block.gaslimit`` (``uint``): 当前区块的 gas 限制
- ``block.number`` (``uint``): 当前区块编号
- ``block.prevrandao`` (``uint``): 由信标链提供的随机数（``EVM >= Paris``）（见 `EIP-4399 <https://eips.ethereum.org/EIPS/eip-4399>`_）
- ``block.timestamp`` (``uint``): 自 Unix 纪元以来的当前区块时间戳（以秒为单位）
- ``gasleft() returns (uint256)``: 剩余 gas
- ``msg.data`` (``bytes``): 完整的 calldata
- ``msg.sender`` (``address``): 消息的发送者（当前调用）
- ``msg.sig`` (``bytes4``): calldata 的前四个字节（即函数标识符）
- ``msg.value`` (``uint``): 随消息发送的 wei 数量
- ``tx.gasprice`` (``uint``): 交易的 gas 价格
- ``tx.origin`` (``address``): 交易的发送者（完整调用链）

.. index:: assert, require, revert

验证和断言
===============================

- ``assert(bool condition)``: 如果条件为 ``false``，则中止执行并回滚状态更改（用于内部错误）
- ``require(bool condition)``: 如果条件为 ``false``，则中止执行并回滚状态更改（用于格式错误的输入或外部组件中的错误）
- ``require(bool condition, string memory message)``: 如果条件为 ``false``，则中止执行并回滚状态更改（用于格式错误的输入或外部组件中的错误）。同时提供错误消息。
- ``revert()``: 中止执行并回滚状态更改
- ``revert(string memory message)``: 中止执行并回滚状态更改，提供解释字符串

.. index:: cryptography, keccak256, sha256, ripemd160, ecrecover, addmod, mulmod

数学和加密函数
===============================

- ``keccak256(bytes memory) returns (bytes32)``: 计算输入的 Keccak-256 哈希
- ``sha256(bytes memory) returns (bytes32)``: 计算输入的 SHA-256 哈希
- ``ripemd160(bytes memory) returns (bytes20)``: 计算输入的 RIPEMD-160 哈希
- ``ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)``: 从椭圆曲线签名中恢复与公钥关联的地址，出错时返回零
- ``addmod(uint x, uint y, uint k) returns (uint)``: 计算 ``(x + y) % k``，其中加法以任意精度执行，并且在 ``2**256`` 时不会溢出。从版本 0.5.0 开始，断言 ``k != 0``。
- ``mulmod(uint x, uint y, uint k) returns (uint)``: 计算 ``(x * y) % k``，其中乘法以任意精度执行，并且在 ``2**256`` 时不会溢出。从版本 0.5.0 开始，断言 ``k != 0``。

.. index:: this, super, selfdestruct

与合约相关
===============================

- ``this`` (当前合约的类型): 当前合约，显式可转换为 ``address`` 或 ``address payable``
- ``super``: 继承层次结构中一个级别更高的合约
- ``selfdestruct(address payable recipient)``: 将所有资金发送到给定地址，并（仅在 Cancun 之前的 EVM 或在创建合约的交易中调用时）销毁合约。
.. index:: type;name, type;creationCode, type;runtimeCode, type;interfaceId, type;min, type;max

类型信息
================

- ``type(C).name`` (``string``): 合约的名称
- ``type(C).creationCode`` (``bytes memory``): 给定合约的创建字节码，见 :ref:`类型信息<meta-type>`。
- ``type(C).runtimeCode`` (``bytes memory``): 给定合约的运行时字节码，见 :ref:`类型信息<meta-type>`。
- ``type(I).interfaceId`` (``bytes4``): 包含给定接口的 EIP-165 接口标识符的值，见 :ref:`类型信息<meta-type>`。
- ``type(T).min`` (``T``): 整数类型 ``T`` 可表示的最小值，见 :ref:`类型信息<meta-type>`。
- ``type(T).max`` (``T``): 整数类型 ``T`` 可表示的最大值，见 :ref:`类型信息<meta-type>`。


.. index:: visibility, public, private, external, internal

函数可见性说明符
==============================

.. code-block:: solidity
    :force:

    function myFunction() <visibility specifier> returns (bool) {
        return true;
    }

- ``public``: 在外部和内部可见（为存储/状态变量创建 :ref:`getter 函数<getter-functions>`）
- ``private``: 仅在当前合约中可见
- ``external``: 仅在外部可见（仅适用于函数） - 即只能通过消息调用（通过 ``this.func``）
- ``internal``: 仅在内部可见


.. index:: modifiers, pure, view, payable, constant, anonymous, indexed

修改器
=========

- ``pure`` 用于函数: 不允许修改或访问状态。
- ``view`` 用于函数: 不允许修改状态。
- ``payable`` 用于函数: 允许它们在调用时接收以太币。
- ``constant`` 用于状态变量: 不允许赋值（除初始化外），不占用存储槽。
- ``immutable`` 用于状态变量: 允许在构造时赋值，并在部署时保持不变。存储在代码中。
- ``anonymous`` 用于事件: 不将事件签名存储为主题。
- ``indexed`` 用于事件参数: 将参数存储为主题。
- ``virtual`` 用于函数和修改器: 允许在派生合约中更改函数或修改器的行为。
- ``override``: 表示此函数、修改器或公共状态变量更改了基合约中函数或修改器的行为。