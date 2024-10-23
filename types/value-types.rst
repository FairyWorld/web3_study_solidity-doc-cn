.. include:: glossaries.rst

.. index:: ! value type, ! type;value
.. _value-types:

值类型
===========

以下被称为值类型，因为它们的变量总是按值传递，即在用作函数参数或赋值时总是被复制。

与 :ref:`引用类型 <reference-types>` 不同，值类型声明不指定数据位置，因为它们足够小，可以存储在栈上。
唯一的例外是 :ref:`状态变量 <structure-state-variables>`。
这些变量默认位于存储中，但也可以标记为 :ref:`瞬态 <transient-storage>`、:ref:`常量或不可变 <constants>`。

.. index:: ! bool, ! true, ! false

布尔类型
--------

``bool``：可能的值是常量 ``true`` 和 ``false``。

运算符：

*  ``!`` （逻辑非）
*  ``&&`` （逻辑与，“和”）
*  ``||`` （逻辑或，“或”）
*  ``==`` （相等）
*  ``!=`` （不相等）

运算符 ``||`` 和 ``&&`` 遵循常见的短路规则。
这意味着在表达式 ``f(x) || g(y)`` 中，如果 ``f(x)`` 计算为 ``true``，则 ``g(y)`` 将不会被计算，即使它可能有副作用。

.. index:: ! uint, ! int, ! integer
.. _integers:

整型
--------

``int`` / ``uint``：各种大小的有符号和无符号整数。
关键字 ``uint8`` 到 ``uint256`` 以 ``8`` 为步长（无符号从 8 位到 256 位）和 ``int8`` 到 ``int256``。 
``uint`` 和 ``int`` 分别是 ``uint256`` 和 ``int256`` 的别名。

运算符：

* 比较：``<=``、``<``、``==``、``!=``、``>=``、``>``（计算为 ``bool``）
* 位运算符：``&``、``|``、``^``（按位异或）、``~``（按位取反）
* 移位运算符：``<<``（左移）、``>>``（右移）
* 算术运算符：``+``、``-``、一元 ``-``（仅适用于有符号整数）、``*``、``/``、``%``（取模）、``**``（指数）

对于整数类型 ``X``，可以使用 ``type(X).min`` 和 ``type(X).max`` 来访问该类型可表示的最小值和最大值。

.. warning::

  Solidity 中的整数限制在某个范围内。例如，对于 ``uint32``，范围是 ``0`` 到 ``2**32 - 1``。
  对这些类型的算术运算有两种模式："wrapping"（截断）模式或称 "unchecked"（不检查）模式和"checked" （检查）模式。
  默认情况下，算术运算始终是 "checked" 的，这意味着如果操作的结果超出该类型的值范围，则调用通过 :ref:`失败的断言<assert-and-require>` 被回退。
  可以使用 ``unchecked { ... }`` 切换到 "unchecked"模式。更多细节可以在 :ref:`unchecked <unchecked>` 部分找到。

比较
^^^^^^^^^^^

比较的值是通过比较整数值获得的。

位运算
^^^^^^^^^^^^^^

位运算是在数字的二进制补码表示上执行的。
这意味着，例如 ``~int256(0) == int256(-1)``。

移位
^^^^^^

移位操作的结果具有左操作数的类型，结果被截断以匹配该类型。
右操作数必须是无符号类型，尝试用有符号类型进行移位将产生编译错误。

移位可以通过乘以二的幂以以下方式“模拟”。请注意，左操作数的截断总是在最后执行，但是不会明确提及。

- ``x << y`` 相当于数学表达式 ``x * 2**y``。
- ``x >> y`` 相当于数学表达式 ``x / 2**y``，四舍五入到负无穷。

.. warning::
    在 ``0.5.0`` 版本之前，负数 ``x`` 的右移 ``x >> y`` 相当于数学表达式 ``x / 2**y`` 会四舍五入到零，
    即右移使用向上舍入（向零）而不是向下舍入（向负无穷）。

.. note::
    移位操作从不执行溢出检查，而算术操作会执行。相反，其结果始终被截断。

加法、减法和乘法
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

加法、减法和乘法具有通常的语义，关于溢出和下溢有两种不同的模式：

默认情况下，所有算术运算都检查下溢或溢出，但可以使用 :ref:`unchecked 块<unchecked>` 禁用，此时会返回截断的结果。
更多细节可以在该部分找到。

表达式 ``-x`` 相当于 ``(T(0) - x)``，其中 ``T`` 是 ``x`` 的类型。它只能应用于有符号类型。
如果 ``x`` 为负，则 ``-x`` 的值可以为正。还有另一个警告也源于二进制补码表示：

如果有 ``int x = type(int).min;``，那 ``-x`` 将不在正数取值的范围内。
这意味着 ``unchecked { assert(-x == x); }`` 是有效的，而在检查模式下使用表达式 ``-x`` 将导致断言失败。

除法
^^^^^^^^

由于操作的结果类型始终是其中一个操作数的类型，因此整数上的除法始终会产生一个整数。
在 Solidity 中，除法向零舍入。这意味着 ``int256(-5) / int256(2) == int256(-2)``。

请注意，相比之下， :ref:`字面量<rational_literals>` 上的除法会产生任意精度的分数值。

.. note::
  除以 0 会导致 :ref:`Panic 错误<assert-and-require>`。此检查 **不能** 通过 ``unchecked { ... }`` 禁用。

.. note::
  表达式 ``type(int).min / (-1)`` 是唯一导致除法溢出的情况。
  在算术检查模式下，这将导致断言失败，而在截断模式下，值将是 ``type(int).min``。

模运算
^^^^^^

模运算 ``a % n`` 产生操作数 ``a`` 除以操作数 ``n`` 后的余数 ``r``，其中 ``q = int(a / n)`` 和 ``r = a - (n * q)``。
这意味着模运算结果与其左操作数（或零）具有相同的符号，并且对于负数 ``a``，``a % n == -(-a % n)`` 成立：

* ``int256(5) % int256(2) == int256(1)``
* ``int256(5) % int256(-2) == int256(1)``
* ``int256(-5) % int256(2) == int256(-1)``
* ``int256(-5) % int256(-2) == int256(-1)``

.. note::
  对 0 取模会导致 :ref:`Panic 错误<assert-and-require>`。此检查 **不能** 通过 ``unchecked { ... }`` 禁用。

指数
^^^^^^^^^^^^^^

指数运算仅适用于无符号类型的指数。指数运算的结果类型始终等于基数的类型。
请确保它足够大以容纳结果，并准备好潜在的断言失败或包装行为。

.. note::
  在“checked”模式下，指数运算仅对小基数使用相对便宜的 ``exp`` 操作码。
  对于 ``x**3`` 的情况，表达式 ``x*x*x`` 可能更便宜。
  在任何情况下，都建议进行 gas 成本测试并使用优化器。

.. note::
  请注意，``0**0`` 被 EVM 定义为 ``1``。

.. index:: ! ufixed, ! fixed, ! fixed point number

定长浮点型
-------------------

.. warning::
    Solidity 中尚未完全支持定长浮点型。它们可以被声明，但不能被赋值。

``fixed`` / ``ufixed``：各种大小的有符号和无符号定长浮点型。
关键字 ``ufixedMxN`` 和 ``fixedMxN``，其中 ``M`` 表示类型占用的位数，``N`` 表示可用的小数位数。
``M`` 必须是 8 的倍数，范围从 8 到 256 位。
``N`` 必须在 0 到 80 之间（包括 0 和 80）。
``ufixed`` 和 ``fixed`` 分别是 ``ufixed128x18`` 和 ``fixed128x18`` 的别名。
运算符：

* 比较运算符： ``<=``, ``<``, ``==``, ``!=``, ``>=``, ``>``（返回值是布尔型）
* 算术运算符： ``+``, ``-``, 一元运算 ``-``, ``*``, ``/``, ``%``（取模）

.. note::
    浮点型（在许多语言中为 ``float`` 和 ``double``, 更准确地说是 IEEE 754 数字）与定长浮点型之间的主要区别在于，
    前者用于整数和小数部分（小数点后的部分）所使用的位数是灵活的，而后者则是严格定义的。
    一般来说，在浮点型中，几乎整个空间都用于表示数字，而只有少量位数定义小数点的位置。

.. index:: address, balance, send, call, delegatecall, staticcall, transfer

.. _address:

地址类型
-------

地址类型有两种基本相同的变体：

- ``address``：保存一个 20 字节的值（以太坊地址的大小）。
- ``address payable``：与 ``address`` 相同，但具有额外的成员 ``transfer`` 和 ``send``。

这种区分的想法是 ``address payable`` 是一个可以发送以太币的地址，
而不应该向普通的 ``address`` 发送以太币，例如因为它可能是一个不支持接受以太币的智能合约。

类型转换：

允许从 ``address payable`` 到 ``address`` 的隐式转换，
而从 ``address`` 到 ``address payable`` 的转换必须通过 ``payable(<address>)`` 显式进行。

对于 ``uint160``、整数字面量、``bytes20`` 和合约类型，允许显式转换为 ``address``。

只有类型为 ``address`` 和合约类型的表达式可以通过显式转换 ``payable(...)`` 转换为 ``address payable`` 类型。
对于合约类型，只有在合约可以接收以太币时才允许此转换，即合约要么具有 :ref:`receive <receive-ether-function>`，要么具有可支付的回退函数。
请注意 ``payable(0)`` 是有效的，并且是此规则的例外。

.. note::
    如果你需要 ``address`` 类型的变量并计划向其发送以太币，那么将其类型声明为 ``address payable`` 可以明确表达出你的需求。
    此外，尽量尽早进行这种区分或转换。

    ``address`` 和 ``address payable`` 之间的区分是在 0.5.0 版本中引入的。
    从该版本开始，合约不再隐式转换为 ``address`` 类型，但仍可以显式转换为 ``address`` 或 ``address payable``，如果它们具有 receive 或 payable 回退函数。

运算符：

* ``<=``, ``<``, ``==``, ``!=``, ``>=`` 和 ``>``

.. warning::
    如果使用更大字节大小的类型转换为 ``address``，例如 ``bytes32``，则 ``address`` 会被截断。
    为了减少转换歧义，从 0.4.24 版本开始，编译器将强制在转换中显式进行截断。
    例如 32 字节值 ``0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC``。

    可以使用 ``address(uint160(bytes20(b)))``，结果为 ``0x111122223333444455556666777788889999aAaa``，
    或者使用 ``address(uint160(uint256(b)))``，结果为 ``0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc``。

.. note::
    符合 `EIP-55 <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md>`_ 的混合大小写十六进制数字会自动被视为 ``address`` 类型的字面量。请参见 :ref:`Address Literals<address_literals>`。

.. _members-of-addresses:

地址类型的成员变量
^^^^^^^^^^^^^^^^^^^^

有关地址所有成员的快速参考，请参见 :ref:`address_related`。

* ``balance`` 和 ``transfer``

可以使用 ``balance`` 属性查询地址的余额，并使用 ``transfer`` 函数向可支付地址发送以太币（以 wei 为单位）：

.. code-block:: solidity
    :force:

    address payable x = payable(0x123);
    address myAddress = address(this);
    if (x.balance < 10 && myAddress.balance >= 10) x.transfer(10);

如果当前合约的余额不足，或者以太币转账被接收账户拒绝，则 ``transfer`` 函数会失败。``transfer`` 函数在失败时会回退。

.. note::
    如果 ``x`` 是合约地址，则其代码（更具体地说：其 :ref:`receive-ether-function`，如果存在，或者其 :ref:`fallback-function`，如果存在）将与 ``transfer`` 调用一起执行（这是 EVM 的一个特性，无法阻止）。
    如果该执行耗尽了 gas 或因任何原因失败，则以太币转账将被回退，前的合约也会在终止的同时抛出异常。

* ``send``

``send`` 是 ``transfer`` 对应的低级函数。如果执行失败，当前合约不会以异常停止，但 ``send`` 将返回 ``false``。

.. warning::
    使用 ``send`` 存在一些危险：如果调用栈深度达到 1024，则转账失败（这总是可以被调用者强制），如果接收者耗尽 gas 也会失败。
    因此，为了安全地转账以太币，请始终检查 ``send`` 的返回值，使用 ``transfer`` 或更好地方式：让接收者提取以太币的模式。

* ``call``、``delegatecall`` 和 ``staticcall``

为了与不符合 |ABI| 的合约交互，或者要更直接地控制编码，提供了 ``call``、``delegatecall`` 和 ``staticcall`` 函数。
它们都接受一个 ``bytes memory`` 参数并返回执行成功状态（``bool``）和数据（``bytes memory``）。
可以使用 ``abi.encode``、``abi.encodePacked``、``abi.encodeWithSelector`` 和 ``abi.encodeWithSignature`` 来编码结构化数据。

示例：

.. code-block:: solidity

    bytes memory payload = abi.encodeWithSignature("register(string)", "MyName");
    (bool success, bytes memory returnData) = address(nameReg).call(payload);
    require(success);

.. warning::
    所有这些函数都是低级函数，使用时应谨慎。
    特别是，任何未知合约都可能是恶意的，如果你调用它，将控制权交给该合约，这可能会反过来调用你的合约，因此请准备好在调用返回时更改你的状态变量。
    与其他合约交互的常规方式是调用合约对象上的函数（``x.f()``）。

.. note::
    以前版本的 Solidity 允许这些函数接收任意参数，并且还会以不同的方式处理类型为 ``bytes4`` 的第一个参数。
    在 0.5.0 版本中移除了这些边缘情况。

可以使用 ``gas`` |modifier| 调整提供的 gas 数量：

.. code-block:: solidity

    address(nameReg).call{gas: 1000000}(abi.encodeWithSignature("register(string)", "MyName"));

同样，提供的以太币值也可以控制：

.. code-block:: solidity

    address(nameReg).call{value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));

最后，这些 |modifier| 可以组合使用。它们的顺序无关紧要：

.. code-block:: solidity

    address(nameReg).call{gas: 1000000, value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));

以类似的方式，可以使用 ``delegatecall`` 函数：区别在于仅使用给定地址的代码，所有其他方面（存储、余额等）都来自当前合约。
``delegatecall`` 的目的是使用存储在另一个合约中的库代码。
用户必须确保两个合约中的存储布局适合使用 delegatecall。

.. note::
    在家园（homestead）之前，只有一种有限的变体叫做 ``callcode``，它无法访问原始的 ``msg.sender`` 和 ``msg.value`` 值。此功能在 0.5.0 版本中被移除。

自拜占庭（byzantium）版本 起，``staticcall`` 也可以使用。这基本上与 ``call`` 相同，但如果被调用的函数以任何方式修改状态，则会回退。

这三种函数 ``call``、``delegatecall`` 和 ``staticcall`` 都是非常底层的函数，应该仅当作 *最后的手段* 来使用，因为它们破坏了 Solidity 的类型安全。

``gas`` 选项在所有三种方法中都可用，而 ``value`` 选项仅在 ``call`` 中可用。

.. note::
    最好避免在智能合约代码中依赖硬编码的 gas 值，无论是读取状态还是写入状态，因为这可能会有许多陷阱。此外，未来 gas 的使用可能会发生变化。

* ``code`` 和 ``codehash``

你可以查询任何智能合约的已部署代码。使用 ``.code`` 获取 EVM 字节码作为 ``bytes memory``，这可能是空的。
使用 ``.codehash`` 获取该代码的 Keccak-256 哈希（作为 ``bytes32``）。
请注意，``addr.codehash`` 比使用 ``keccak256(addr.code)`` 更便宜。

.. warning::
    如果与 ``addr`` 关联的账户为空或不存在（即没有代码、零余额和零 nonce，如 `EIP-161 <https://eips.ethereum.org/EIPS/eip-161>`_ 所定义），则 ``addr.codehash`` 的输出可能为 ``0``。
    如果账户没有代码但有非零余额或 nonce，则 ``addr.codehash`` 将输出空数据的 Keccak-256 哈希（即 ``keccak256("")``，其值等于 ``c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470``），如 `EIP-1052 <https://eips.ethereum.org/EIPS/eip-1052>`_ 所定义。

.. note::
    所有合约都可以转换为 ``address`` 类型，因此可以使用 ``address(this).balance`` 查询当前合约的余额。

.. index:: ! contract type, ! type; contract

.. _contract_types:

合约类型
--------------

每个 :ref:`contract<contracts>` 定义其自己的类型。
你可以隐式地将合约转换为它们继承的合约。
合约可以显式地转换为 ``address`` 类型和从 ``address`` 类型转换。

只有当合约类型具有接收或可支付的回退函数时，才能显式转换为 ``address payable`` 类型。转换仍然使用 ``address(x)`` 进行。如果合约类型没有接收或可支付的回退函数，则可以使用 ``payable(address(x))`` 进行转换。
你可以在 :ref:`address type<address>` 部分找到更多信息。

.. note::
    在 0.5.0 版本之前，合约直接派生自地址类型，并且 ``address`` 和 ``address payable`` 之间没有区别。

如果你声明一个合约类型的局部变量（``MyContract c``），则可以在该合约上调用函数。请确保从相同的合约类型的某个地方进行赋值。

你还可以实例化合约（这意味着它们是新创建的）。你可以在 :ref:`'Contracts via new'<creating-contracts>` 部分找到更多详细信息。

合约的数据表示与 ``address`` 类型相同，并且该类型也用于 :ref:`ABI<ABI>`。

合约不支持任何运算符。

合约类型的成员是合约的外部函数，包括任何标记为 ``public`` 的状态变量。

对于合约 ``C``，你可以使用 ``type(C)`` 访问有关合约的 :ref:`type information<meta-type>`。

.. index:: byte array, bytes32

定长字节数组
----------------------

值类型 ``bytes1``、``bytes2``、``bytes3``、...、``bytes32`` 持有从一个到最多 32 的字节序列。

运算符：

* 比较：``<=``、``<``、``==``、``!=``、``>=``、``>``（评估为 ``bool``）
* 位运算符：``&``、``|``、``^``（按位异或）、``~``（按位取反）
* 移位运算符：``<<``（左移）、``>>``（右移）
* 索引访问：如果 ``x`` 是类型 ``bytesI``，则 ``x[k]`` 对于 ``0 <= k < I`` 返回第 ``k`` 个字节（只读）。

移位运算符的右操作数必须是无符号整数类型（但返回左操作数的类型），表示要移位的位数。
进行有符号整数位移运算将产生编译错误。

成员：

* ``.length`` 返回字节数组的长度（只读）。

.. note::
    类型 ``bytes1[]`` 是字节数组，但由于填充规则，每个元素浪费 31 字节的空间（存储中除外）。最好使用 ``bytes`` 类型。

.. note::
    在 0.8.0 版本之前，``byte`` 曾是 ``bytes1`` 的别名。

.. index:: address, ! literal;address

.. _address_literals:

地址字面量
----------------

通过地址校验和测试的十六进制字面量，例如 ``0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF`` 是 ``address`` 类型。
长度在 39 到 41 位之间且未通过校验和测试的十六进制字面量会产生错误。你可以在前面添加（对于整数类型）或在后面添加零（对于 bytesNN 类型）以消除错误。

.. note::
    混合大小写的地址校验和格式在 `EIP-55 <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md>`_ 中定义。

.. index:: integer, rational number, ! literal;rational

.. _rational_literals:

有理数和整数字面量
-----------------------------

整数字面量由范围为 0-9 的数字序列组成。它们被解释为十进制。例如，``69`` 表示六十九。
Solidity 中不存在八进制字面量，前导零是无效的。

十进制分数字面量由 ``.`` 和小数点后至少一个数字组成。
示例包括 ``.1`` 和 ``1.3``（但不是 ``1.``）。

支持以 ``2e10`` 形式的科学计数法，其中尾数可以是分数，但指数必须是整数。
字面量 ``MeE`` 等于 ``M * 10**E``。
示例包括 ``2e10``、``-2e10``、``2e-10``、``2.5e1``。

可以使用下划线分隔数字字面量的数字以提高可读性。
例如，十进制 ``123_000``、十六进制 ``0x2eff_abde``、科学十进制表示法 ``1_2e345_678`` 都是有效的。
下划线仅允许在两个数字之间，并且只允许一个连续的下划线。
包含下划线的数字字面量没有额外的语义含义，下划线会被忽略。

数字字面量表达式在转换为非字面量类型之前保持任意精度（即通过与数字字面量表达式以外的任何内容（如布尔字面量）一起使用或通过显式转换）。
这意味着在数字字面量表达式中，计算不会溢出，除法不会截断。

例如，``(2**800 + 1) - 2**800`` 的结果是常量 ``1``（类型为 ``uint8``），尽管中间结果甚至无法适应机器字大小。此外，``.5 * 8`` 的结果是整数 ``4``（尽管在中间使用了非整数）。

.. warning::
    虽然大多数运算符在应用于字面量时会产生字面量表达式，但有某些运算符不遵循此模式：

    - 三元运算符（``... ? ... : ...``），
    - 数组下标（``<array>[<index>]``）。
你可能会期望像 ``255 + (true ? 1 : 0)`` 或 ``255 + [1, 2, 3][0]`` 这样的表达式与直接使用字面量 256 等价，但实际上它们是在类型 ``uint8`` 内计算的，并且可能会溢出。

任何可以应用于整数的运算符也可以应用于数字字面量表达式，只要操作数是整数。
如果其中任何一个是分数，则不允许位运算，如果指数是分数，则不允许指数运算（因为这可能导致非有理数）。

使用字面量数字作为左侧（或基数）操作数和整数类型作为右侧（指数）操作数的移位和指数运算始终在 ``uint256``（对于非负字面量）或 ``int256``（对于负字面量）类型中执行，而不管右侧（指数）操作数的类型。

.. warning::
    在 Solidity 0.4.0 版本之前，整数字面量上的除法会截断，但现在会转换为有理数，即 ``5 / 2`` 不等于 ``2``，而是 ``2.5``。

.. note::
    Solidity 为每个有理数都有一个数字字面量类型。
    整数字面量和有理数字面量属于数字字面量类型。
    此外，所有数字字面量表达式（即仅包含数字字面量和运算符的表达式）都属于数字字面量类型。
    因此，数字字面量表达式 ``1 + 2`` 和 ``2 + 1`` 都属于有理数三的同一数字字面量类型。

.. note::
    数字字面量表达式在与非字面量表达式一起使用时会转换为非字面量类型。
    不考虑类型，下面赋值给 ``b`` 的表达式的值计算为整数。
    因为 ``a`` 的类型是 ``uint128``，所以表达式 ``2.5 + a`` 必须具有适当的类型。
    由于 ``2.5`` 和 ``uint128`` 没有共同类型，Solidity 编译器不接受此代码。

.. code-block:: solidity

    uint128 a = 1;
    uint128 b = 2.5 + a + 0.5;

.. index:: ! literal;string, string
.. _string_literals:

字符串字面量和类型
-------------------------

字符串字面量用双引号或单引号（``"foo"`` 或 ``'bar'``）书写，并且可以拆分为多个连续部分（``"foo" "bar"`` 等价于 ``"foobar"``），这在处理长字符串时很有帮助。
它们并不意味着像 C 中那样的尾随零；``"foo"`` 代表三个字节，而不是四个。
与整数字面量一样，它们的类型可以变化，但如果适合，它们可以隐式转换为 ``bytes1``，...，``bytes32``，``bytes`` 和 ``string``。

例如，使用 ``bytes32 samevar = "stringliteral"`` 时，字符串字面量在赋值给 ``bytes32`` 类型时以其原始字节形式解释。

字符串字面量只能包含可打印的 ASCII 字符，这意味着字符在 0x20 到 0x7E 之间（包括这两个值）。

此外，字符串字面量还支持以下转义字符：

- ``\<newline>``（转义实际换行符）
- ``\\``（反斜杠）
- ``\'``（单引号）
- ``\"``（双引号）
- ``\n``（换行符）
- ``\r``（回车符）
- ``\t``（制表符）
- ``\xNN``（十六进制转义，见下文）
- ``\uNNNN``（Unicode 转义，见下文）

``\xNN`` 采用十六进制值并插入适当的字节，而 ``\uNNNN`` 采用 Unicode 代码点并插入 UTF-8 序列。

.. note::

    在版本 0.8.0 之前，还有三个额外的转义序列：``\b``、``\f`` 和 ``\v``。
    它们在其他语言中常见，但在实践中很少需要。
    如果确实需要，可以通过十六进制转义插入它们，即 ``\x08``、``\x0c`` 和 ``\x0b``，就像任何其他 ASCII 字符一样。

以下示例中的字符串长度为十个字节。
它以换行字节开头，后跟一个双引号、一个单引号、一个反斜杠字符，然后（没有分隔符）是字符序列 ``abcdef``。

.. code-block:: solidity
    :force:

    "\n\"\'\\abc\
    def"

任何不是换行符的 Unicode 行终止符（即 LF、VF、FF、CR、NEL、LS、PS）都被视为终止字符串字面量。只有在前面没有 ``\`` 的情况下，换行符才会终止字符串字面量。

.. index:: ! literal;unicode

Unicode 字面量
----------------

虽然常规字符串字面量只能包含 ASCII，但 Unicode 字面量 - 以关键字 ``unicode`` 为前缀 - 可以包含任何有效的 UTF-8 序列。
它们也支持与常规字符串字面量相同的转义序列。

.. code-block:: solidity

    string memory a = unicode"Hello 😃";

.. index:: ! literal;hexadecimal, bytes

十六进制字面量
--------------------

十六进制字面量以关键字 ``hex`` 为前缀，并用双引号或单引号括起来（``hex"001122FF"``, ``hex'0011_22_FF'``）。
它们的内容必须是十六进制数字，可以选择性地在字节边界之间使用单个下划线作为分隔符。字面量的值将是十六进制序列的二进制表示。

用空格分隔的多个十六进制字面量会连接成一个字面量：
``hex"00112233" hex"44556677"`` 等价于 ``hex"0011223344556677"``

在某些方面，十六进制字面量的行为类似于 :ref:`string literals <string_literals>`，但不能隐式转换为 ``string`` 类型。

.. index:: enum

.. _enums:

枚举
-----

枚举是创建用户定义类型的一种方式。它们可以显式地转换为和从所有整数类型转换，但不允许隐式转换。
显式从整数转换时会在运行时检查值是否在枚举范围内，否则会导致 :ref:`Panic error<assert-and-require>`。
枚举至少需要一个成员，声明时的默认值是第一个成员。枚举不能有超过 256 个成员。

数据表示与 C 中的枚举相同：选项由从 ``0`` 开始的后续无符号整数值表示。

使用 ``type(NameOfEnum).min`` 和 ``type(NameOfEnum).max`` 可以获取给定枚举的最小值和最大值。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.8;

    contract test {
        enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }
        ActionChoices choice;
        ActionChoices constant defaultChoice = ActionChoices.GoStraight;

        function setGoStraight() public {
            choice = ActionChoices.GoStraight;
        }

        // 由于枚举类型不是 ABI 的一部分，对于所有外部 Solidity 事务
        // "getChoice" 的签名将自动更改为 "getChoice() returns (uint8)"。
        function getChoice() public view returns (ActionChoices) {
            return choice;
        }

        function getDefaultChoice() public pure returns (uint) {
            return uint(defaultChoice);
        }

        function getLargestValue() public pure returns (ActionChoices) {
            return type(ActionChoices).max;
        }

        function getSmallestValue() public pure returns (ActionChoices) {
            return type(ActionChoices).min;
        }
    }

.. note::
    枚举也可以在文件级别声明，位于合约或库定义之外。 

.. index:: ! user defined value type, custom type

.. _user-defined-value-types:

用户定义值类型
------------------------

用户定义值类型允许在基本值类型上创建零成本抽象。这类似于别名，但具有更严格的类型要求。

用户定义值类型使用 ``type C is V`` 定义，其中 ``C`` 是新引入类型的名称，``V`` 必须是内置值类型（“基础类型”）。
函数 ``C.wrap`` 用于将基础类型转换为自定义类型。类似地，函数 ``C.unwrap`` 用于将自定义类型转换为基础类型。

类型 ``C`` 没有任何运算符或附加成员函数。特别是，甚至运算符 ``==`` 也未定义。显式和隐式转换到其他类型和从其他类型转换是不允许的。

此类值的数据表示继承自基础类型，基础类型也用于 ABI。

以下示例说明了一个自定义类型 ``UFixed256x18``，表示具有 18 位小数的十进制定点类型，以及一个用于对该类型进行算术运算的最小库。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.8;

    // 使用用户定义值类型表示一个 18 位小数、256 位宽的定点类型。
    type UFixed256x18 is uint256;

    /// 一个用于对 UFixed256x18 进行定点运算的最小库。
    library FixedMath {
        uint constant multiplier = 10**18;

        /// 添加两个 UFixed256x18 数字。溢出时回滚，依赖于 uint256 的算术检查。
        function add(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
            return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
        }
        /// 将 UFixed256x18 和 uint256 相乘。溢出时回滚，依赖于 uint256 的算术检查。
        function mul(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
            return UFixed256x18.wrap(UFixed256x18.unwrap(a) * b);
        }
        /// 取 UFixed256x18 数字的下限。
        /// @return 不超过 `a` 的最大整数。
        function floor(UFixed256x18 a) internal pure returns (uint256) {
            return UFixed256x18.unwrap(a) / multiplier;
        }
        /// 将 uint256 转换为相同值的 UFixed256x18。
        /// 如果整数过大则回滚。
        function toUFixed256x18(uint256 a) internal pure returns (UFixed256x18) {
            return UFixed256x18.wrap(a * multiplier);
        }
    }

注意 ``UFixed256x18.wrap`` 和 ``FixedMath.toUFixed256x18`` 具有相同的签名，但执行两种非常不同的操作：
``UFixed256x18.wrap`` 函数返回一个 ``UFixed256x18``，其数据表示与输入相同，而 ``toUFixed256x18`` 返回一个 ``UFixed256x18``，其数值相同。

.. index:: ! function type, ! type; function

.. _function_types:

函数类型
--------------

函数类型是函数的类型。函数类型的变量可以从函数中赋值，函数类型的函数参数可以用于将函数传递给函数调用并从中返回函数。
函数类型有两种类型 - *内部* 和 *外部* 函数：

内部函数只能在当前合约内部调用（更具体地说，在当前代码单元内部，这也包括内部库函数和继承函数），因为它们不能在当前合约的上下文之外执行。
调用内部函数是通过跳转到其入口标签来实现的，就像在内部调用当前合约的函数一样。

外部函数由地址和函数签名组成，可以通过外部函数调用传递和返回。

函数类型的表示如下：

.. code-block:: solidity
    :force:

    function (<parameter types>) {internal|external} [pure|view|payable] [returns (<return types>)]

与参数类型不同，返回类型不能为空 - 如果函数类型不应返回任何内容，则必须省略整个 ``returns (<return types>)`` 部分。

默认情况下，函数类型是内部的，因此可以省略 ``internal`` 关键字。
请注意，这仅适用于函数类型。对于在合约中定义的函数，必须显式指定可见性，它们没有默认值。

类型转换：

函数类型 ``A`` 仅在以下情况下可以隐式转换为函数类型 ``B``：
它们的参数类型相同，它们的返回类型相同，它们的内部/外部属性相同，并且 ``A`` 的状态可变性比 ``B`` 更严格。
特别是：

- ``pure`` 函数可以转换为 ``view`` 和 ``non-payable`` 函数
- ``view`` 函数可以转换为 ``non-payable`` 函数
- ``payable`` 函数可以转换为 ``non-payable`` 函数

其他函数类型之间的转换则不可以。

关于 ``payable`` 和 ``non-payable`` 的规则可能有点令人困惑，但本质上，如果一个函数是 ``payable``，这意味着它也接受零以太的支付，因此它也是 ``non-payable``。
另一方面，``non-payable`` 函数将拒绝发送给它的以太，因此 ``non-payable`` 函数不能转换为 ``payable`` 函数。
为了澄清，拒绝以太比不拒绝以太更严格。这意味着你可以用非支付函数覆盖支付函数，但不能反过来。

此外，当你定义 ``non-payable`` 函数指针时，编译器并不强制要求指向的函数实际上会拒绝以太。
相反，它强制要求函数指针永远不能用于发送以太。这使得可以将 ``payable`` 函数指针分配给 ``non-payable`` 函数指针，确保这两种类型的行为相同，即都不能用于发送以太。

如果函数类型变量未初始化，调用它会导致 :ref:`Panic error<assert-and-require>`。如果在对其使用 ``delete`` 后调用函数，也会发生同样的情况。

如果在 Solidity 的上下文之外使用外部函数类型，它们将被视为 ``function`` 类型，该类型将地址与函数标识符一起编码为单个 ``bytes24`` 类型。

请注意，当前合约的公共函数可以同时用作内部和外部函数。要将 ``f`` 用作内部函数，只需使用 ``f``，如果要使用其外部形式，请使用 ``this.f``。

内部类型的函数可以分配给内部函数类型的变量，而不管它在哪里定义。这包括合约和库的私有、内部和公共函数以及自由函数。
另一方面，外部函数类型仅与公共和外部合约函数兼容。

.. note::
    带有 ``calldata`` 参数的外部函数与带有 ``calldata`` 参数的外部函数类型不兼容。
    它们与相应的带有 ``memory`` 参数的类型兼容。
    例如，没有函数可以由类型为 ``function (string calldata) external`` 的值指向，而 ``function (string memory) external`` 可以指向 ``function f(string memory) external {}`` 和 ``function g(string calldata) external {}``。
    这是因为对于这两种位置，参数以相同的方式传递给函数。调用者不能直接将其 calldata 传递给外部函数，并始终将参数 ABI 编码到内存中。
    将参数标记为 ``calldata`` 仅影响外部函数的实现，而在调用者的函数指针中没有意义。
.. warning::
    在启用优化器的旧版管道中，内部函数指针的比较可能会产生意想不到的结果，
    因为它可能会将相同的函数合并为一个，这将导致这些函数指针比较为相等而不是不相等。
    不建议进行此类比较，并且会导致编译器发出警告，直到下一个重大版本发布（0.9.0），
    警告将升级为错误，从而禁止此类比较。

库被排除在外，因为它们需要 ``delegatecall`` 并使用 :ref:`不同的 ABI 约定用于它们的选择器 <library-selectors>`。
在接口中声明的函数没有定义，因此指向它们也没有意义。

成员：

外部（或公共）函数具有以下成员：

* ``.address`` 返回函数的合约地址。
* ``.selector`` 返回 :ref:`ABI 函数选择器 <abi_function_selector>`

.. note::
  public（或 external）函数曾经有额外的成员 ``.gas(uint)`` 和 ``.value(uint)``。
  这些在 Solidity 0.6.2 中被弃用，并在 Solidity 0.7.0 中被移除。
  请改用 ``{gas: ...}`` 和 ``{value: ...}`` 来分别指定发送到函数的 gas 量或 wei 量。
  有关更多信息，请参见 :ref:`外部函数调用 <external-function-calls>`。

显示如何使用成员的示例：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.4 <0.9.0;

    contract Example {
        function f() public payable returns (bytes4) {
            assert(this.f.address == address(this));
            return this.f.selector;
        }

        function g() public {
            this.f{gas: 10, value: 800}();
        }
    }

显示如何使用内部函数类型的示例：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    library ArrayUtils {
        // 内部函数可以在内部库函数中使用，
        // 因为它们将是同一代码上下文的一部分
        function map(uint[] memory self, function (uint) pure returns (uint) f)
            internal
            pure
            returns (uint[] memory r)
        {
            r = new uint[](self.length);
            for (uint i = 0; i < self.length; i++) {
                r[i] = f(self[i]);
            }
        }

        function reduce(
            uint[] memory self,
            function (uint, uint) pure returns (uint) f
        )
            internal
            pure
            returns (uint r)
        {
            r = self[0];
            for (uint i = 1; i < self.length; i++) {
                r = f(r, self[i]);
            }
        }

        function range(uint length) internal pure returns (uint[] memory r) {
            r = new uint[](length);
            for (uint i = 0; i < r.length; i++) {
                r[i] = i;
            }
        }
    }


    contract Pyramid {
        using ArrayUtils for *;

        function pyramid(uint l) public pure returns (uint) {
            return ArrayUtils.range(l).map(square).reduce(sum);
        }

        function square(uint x) internal pure returns (uint) {
            return x * x;
        }

        function sum(uint x, uint y) internal pure returns (uint) {
            return x + y;
        }
    }

另一个使用外部函数类型的示例：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;


    contract Oracle {
        struct Request {
            bytes data;
            function(uint) external callback;
        }

        Request[] private requests;
        event NewRequest(uint);

        function query(bytes memory data, function(uint) external callback) public {
            requests.push(Request(data, callback));
            emit NewRequest(requests.length - 1);
        }

        function reply(uint requestID, uint response) public {
            // 这里进行检查，确保回复来自可信来源
            requests[requestID].callback(response);
        }
    }


    contract OracleUser {
        Oracle constant private ORACLE_CONST = Oracle(address(0x00000000219ab540356cBB839Cbe05303d7705Fa)); // 已知合约
        uint private exchangeRate;

        function buySomething() public {
            ORACLE_CONST.query("USD", this.oracleResponse);
        }

        function oracleResponse(uint response) public {
            require(
                msg.sender == address(ORACLE_CONST),
                "Only oracle can call this."
            );
            exchangeRate = response;
        }
    }

.. note::
    计划支持 Lambda 或内联函数，但尚未支持。