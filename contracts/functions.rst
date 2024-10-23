.. index:: ! functions, ! function;free

.. _functions:

*********
函数
*********

函数可以在合约内外定义。

合约外的函数，也称为“自由函数”，始终具有隐式的 ``internal`` :ref:`可见性<visibility-and-getters>`。
它们的代码包含在所有调用它们的合约中，类似于内部库函数。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.1 <0.9.0;

    function sum(uint[] memory arr) pure returns (uint s) {
        for (uint i = 0; i < arr.length; i++)
            s += arr[i];
    }

    contract ArrayExample {
        bool found;
        function f(uint[] memory arr) public {
            // 这在内部调用自由函数。
            // 编译器会将其代码添加到合约中。
            uint s = sum(arr);
            require(s >= 10);
            found = true;
        }
    }

.. note::
    在合约外定义的函数仍然在合约的上下文中执行。
    它们仍然可以调用其他合约，向它们发送以太，并销毁调用它们的合约，以及其他事情。
    与在合约内定义的函数的主要区别是自由函数无法直接访问变量 ``this``、存储变量和不在其作用域范围内的函数。

.. _function-parameters-return-variables:

函数参数和返回变量
========================

函数接受类型化参数作为输入，并且与许多其他语言不同，它们也可以返回任意数量的值作为输出。

函数参数
-------------------

函数参数的声明方式与变量相同，未使用参数的名称可以省略。

例如，如果你希望合约接受一种带有两个整数的外部调用，你可以使用如下内容：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract Simple {
        uint sum;
        function taker(uint a, uint b) public {
            sum = a + b;
        }
    }

函数参数可以像其它局部变量一样使用，并且它们也可以被赋值。

.. index:: return array, return string, array, string, array of strings, dynamic array, variably sized array, return struct, struct

返回变量
----------------

函数返回变量语法声明与 ``returns`` 关键字后的语法声明相同。

例如，假设你想返回两个结果：两个作为函数参数传递的整数的和与积，那么你可以使用如下内容：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract Simple {
        function arithmetic(uint a, uint b)
            public
            pure
            returns (uint sum, uint product)
        {
            sum = a + b;
            product = a * b;
        }
    }

返回变量的名称可以省略。
返回变量可以像其他局部变量一样使用，并且它们以其 :ref:`默认值 <default-value>` 初始化，并在被（重新）赋值之前保持该值。

可以显式地赋值给返回变量，然后像上面那样离开函数，或者可以通过 ``return`` 语句直接提供返回值（可以是单个或 :ref:`多个值<multi-return>`）：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract Simple {
        function arithmetic(uint a, uint b)
            public
            pure
            returns (uint sum, uint product)
        {
            return (a + b, a * b);
        }
    }

如果使用早期的 ``return`` 离开一个具有返回变量的函数，必须与返回语句一起提供返回值。

.. note::
    不能从非内部函数返回某些类型。
    这包括以下列出的类型以及任何递归包含它们的复合类型：

    - mappings （映射）,
    - 内部函数类型，
    - 位置设置为 ``storage`` 的引用类型，
    - 多维数组（仅适用于 :ref:`ABI 编码器 v1 <abi_coder>`），
    - 结构体（仅适用于 :ref:`ABI 编码器 v1 <abi_coder>`）。

    由于库函数的不同 :ref:`内部 ABI <library-selectors>`，此限制不适用于库函数。

.. _multi-return:

返回多个值
-------------------------

当一个函数有多个返回类型时，可以使用语句 ``return (v0, v1, ..., vn)`` 返回多个值。
组件的数量必须与返回变量的数量相同，并且它们的类型必须匹配，可能在 :ref:`隐式转换 <types-conversion-elementary-types>` 之后。

.. _state-mutability:

状态可变性
================

.. index:: ! view function, function;view

.. _view-functions:

视图函数
--------------

函数可以声明为 ``view``，在这种情况下它们承诺不修改状态。

.. note::
  如果编译器的 EVM 目标是 Byzantium 或更新版本（默认），则在调用 ``view`` 函数时使用操作码 ``STATICCALL``，这强制状态在 EVM 执行过程中保持不变。
  对于库 ``view`` 函数使用 ``DELEGATECALL``，因为没有组合的 ``DELEGATECALL`` 和 ``STATICCALL``。
  这意味着库 ``view`` 函数没有运行时检查来防止状态修改。这不应对安全性产生负面影响，因为库代码通常在编译时已知，静态检查器执行编译时检查。

以下语句被视为修改状态：

#. 写入状态变量（存储和临时存储）。
#. :ref:`发出事件 <events>`。
#. :ref:`创建其他合约 <creating-contracts>`。
#. 使用 ``selfdestruct``。
#. 通过调用发送以太。
#. 调用任何未标记为 ``view`` 或 ``pure`` 的函数。
#. 使用低级调用。
#. 使用包含某些操作码的内联汇编。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    contract C {
        function f(uint a, uint b) public view returns (uint) {
            return a * (b + 42) + block.timestamp;
        }
    }

.. note::
  ``constant`` 在函数上曾经是 ``view`` 的别名，但在 0.5.0 版本中被删除。

.. note::
  Getter 方法自动标记为 ``view``。

.. note::
  在 0.5.0 版本之前，编译器未对 ``view`` 函数使用 ``STATICCALL`` 操作码。
  这使得通过使用无效的显式类型转换在 ``view`` 函数中进行状态修改成为可能。
  通过对 ``view`` 函数使用 ``STATICCALL``，在 EVM 层面上防止了对状态的修改。

.. index:: ! pure function, function;pure

.. _pure-functions:

纯函数
--------------

函数可以声明为 ``pure``，在这种情况下，函数承诺不读取或修改状态。
特别是，给定仅其输入和 ``msg.data``，但不需要了解当前区块链状态，应该能够在编译时评估 ``pure`` 函数。
这意味着读取 ``immutable`` 变量可能是非纯操作。

.. note::
  如果编译器的 EVM 编译目标设置为 Byzantium 或更新版本（默认），则使用操作码 ``STATICCALL``，这并不保证状态不被读取，但至少保证状态不被修改。
除了上述解释的状态修改语句列表，以下被视为读取状态：

#. 从状态变量（存储和临时存储）读取。
#. 访问 ``address(this).balance`` 或 ``<address>.balance``。
#. 访问 ``block``、``tx``、``msg`` 的任何成员（``msg.sig`` 和 ``msg.data`` 除外）。
#. 调用任何未标记为 ``pure`` 的函数。
#. 使用包含某些操作码的内联汇编。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    contract C {
        function f(uint a, uint b) public pure returns (uint) {
            return a * (b + 42);
        }
    }

纯函数能够使用 ``revert()`` 和 ``require()`` 函数在发生 :ref:`错误 <assert-and-require>` 时恢复潜在的状态更改。

恢复状态变化不被视为“状态修改”，因为只有在代码中先前进行的、未带有 ``view`` 或 ``pure`` 限制的状态更改被恢复，而且该代码可以选择捕捉 ``revert`` 并不传递它。

这种行为也符合 ``STATICCALL`` 操作码。

.. warning::
  在 EVM 层面上，无法阻止函数读取状态，只能阻止它们写入状态（即只能在 EVM 层面上强制执行 ``view``，而无法强制执行 ``pure``）。

.. note::
  在 0.5.0 版本之前，编译器未对 ``pure`` 函数使用 ``STATICCALL`` 操作码。
  这使得通过使用无效的显式类型转换在 ``pure`` 函数中启用了状态修改。
  通过对 ``pure`` 函数使用 ``STATICCALL``，在 EVM 层面上防止了对状态的修改。

.. note::
  在 0.4.17 版本之前，编译器未强制 ``pure`` 不读取状态。
  这是一种编译时类型检查，可以通过进行无效的显式转换来规避合约类型之间的转换，因为编译器可以验证合约的类型不执行状态更改操作，但无法检查在运行时将被调用的合约实际上是否属于该类型。

.. _special-functions:

特殊函数
=================

.. index:: ! 接收以太币函数, function;receive, ! receive

.. _receive-ether-function:

接收以太币函数
----------------------

一个合约最多可以有一个 ``receive`` 函数，声明为 ``receive() external payable { ... }`` （不带 ``function`` 关键字）。
该函数不能有参数，不能返回任何内容，必须具有``external`` 可见性和 ``payable`` 状态可变性。
它可以是虚拟的，可以重写，并且可以有 |modifier|。

接收函数在调用合约时执行，且没有提供任何 calldata。这是执行普通以太转账时调用的函数（例如通过 ``.send()`` 或 ``.transfer()``）。
如果不存在这样的函数，但存在可支付的 :ref:`回退函数 <fallback-function>`，则在普通以太转账时将调用回退函数。
如果既没有接收以太函数也没有可支付的回退函数，合约将无法通过调用不可支付函数来接收以太，将抛出异常。

在最坏的情况下，``receive`` 函数只有 2300 gas 可用（例如当使用 ``send`` 或 ``transfer`` 时），几乎没有空间执行其他操作，除了基本的日志记录。
以下操作将消耗超过 2300 gas 补贴：

- 写入存储
- 创建合约
- 调用消耗大量 gas 的外部函数
- 发送以太币

.. warning::
    当以太币直接发送到合约（没有函数调用，即发送者使用 ``send`` 或 ``transfer``），但接收合约未定义接收以太币函数或可支付回退函数时，将抛出异常，退回以太币（在 Solidity v0.4.0 之前是不同的）。
    如果你希望你的合约接收以太币，你必须实现接收以太币函数（使用可支付回退函数接收以太并不推荐，因为回退会被调用，并且不会因发送者的接口混淆而失败）。

.. warning::
    没有接收以太币函数的合约可以作为 **coinbase 交易** （即 **矿工区块奖励**）的接收者或作为 ``selfdestruct`` 的目标接收以太币。

    合约无法对这种以太转账做出反应，因此也无法拒绝它们。这是 EVM 的设计选择，Solidity 无法规避。

    这也意味着 ``address(this).balance`` 可能高于合约中实现的一些手动会计的总和（即在接收以太币函数中更新计数器）。

下面是一个使用 ``receive`` 函数的 Sink 合约示例。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    // 该合约保留所有发送给它的以太币，无法取回。
    contract Sink {
        event Received(address, uint);
        receive() external payable {
            emit Received(msg.sender, msg.value);
        }
    }

.. index:: ! 回退函数, function;fallback

.. _fallback-function:

回退函数
-----------------

一个合约最多可以有一个 ``fallback`` 函数，声明为 ``fallback () external [payable]`` 或 ``fallback (bytes calldata input) external [payable] returns (bytes memory output)`` （两者均不带 ``function`` 关键字）。

该函数必须具有 ``external`` 可见性。回退函数可以是虚拟的，可以重写，并且可以有修改器。

如果没有其他函数与给定的函数签名匹配，或者根本没有提供数据且没有 :ref:`接收以太函数 <receive-ether-function>`，、则在调用合约时执行回退函数。
回退函数始终接收数据，但为了接收以太币，它必须标记为 ``payable``。

如果使用带参数的版本，``input`` 将包含发送到合约的完整数据（等于 ``msg.data``），并可以在 ``output`` 中返回数据。
返回的数据将不会被 ABI 编码。相反，它将未经修改（甚至不填充）返回。

在最坏的情况下，如果可支付的回退函数也用作接收函数，则它只能依赖于 2300 gas 可用（请参阅 :ref:`接收以太函数 <receive-ether-function>` 以简要描述其影响）。

像任何函数一样，只要传递给它的 gas 足够，回退函数可以执行复杂的操作。

.. warning::
    如果没有 :ref:`接收以太币函数 <receive-ether-function>`，则对于普通以太币转账，也会执行 ``payable`` 回退函数。
    建议如果你定义可支付回退函数，也始终定义接收以太币函数，以区分以太币转账和接口混淆。

.. note::
    如果想解码输入数据，可以检查前四个字节以获取函数选择器，然后可以使用 ``abi.decode`` 结合数组切片语法来解码 ABI 编码的数据：
    ``(c, d) = abi.decode(input[4:], (uint256, uint256));``
    请注意，这应仅作为最后的手段使用，应该使用适当的函数。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.2 <0.9.0;

    contract Test {
        uint x;
        // 此函数会被调用以处理发送到此合约的所有消息（没有其他函数）。
        // 向此合约发送以太币将导致异常，因为回退函数没有 `payable`修改器。
        fallback() external { x = 1; }
    }

    contract TestPayable {
        uint x;
        uint y;
        // 此函数会被调用以处理发送到此合约的所有消息，除了普通的以太币转账（除了接收函数外没有其他函数）。
        // 任何带有非空 calldata 的调用都会执行回退函数（即使在调用时发送了以太币）。
        fallback() external payable { x = 1; y = msg.value; }

        // 此函数会被调用以处理普通的以太币转账，即
        // 对于每个带有空 calldata 的调用。
        receive() external payable { x = 2; y = msg.value; }
    }

    contract Caller {
        function callTest(Test test) public returns (bool) {
            (bool success,) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
            require(success);
            //  结果是 test.x 变成 == 1。

            // address(test) 不允许直接调用 ``send``，因为 ``test`` 没有 payable 回退函数。
            // 必须将其转换为 ``address payable`` 类型才能允许调用 ``send``。
            address payable testPayable = payable(address(test));

            // 如果有人向该合约发送以太币，转账将失败，即这里返回 false。
            return testPayable.send(2 ether);
        }

        function callTestPayable(TestPayable test) public returns (bool) {
            (bool success,) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
            require(success);
            // 结果是 test.x 变为 == 1，test.y 变为 0。
            (success,) = address(test).call{value: 1}(abi.encodeWithSignature("nonExistingFunction()"));
            require(success);
            // 结果是 test.x 变为 == 1，test.y 变为 1。

            // 如果有人向该合约发送以太币，TestPayable 中的接收函数将被调用。
            // 由于该函数写入存储，它消耗的 gas 比简单的 ``send`` 或 ``transfer`` 更多。
            // 因此，我们必须使用低级调用。
            (success,) = address(test).call{value: 2 ether}("");
            require(success);
            // 结果是 test.x 变为 == 2，test.y 变为 2 ether。

            return true;
        }
    }

.. index:: ! overload

.. _overload-function:

函数重载
====================

一个合约可以有多个同名但参数类型不同的函数。
这个过程称为“重载”，也适用于继承的函数。
以下示例展示了合约 ``A`` 范围内函数 ``f`` 的重载。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract A {
        function f(uint value) public pure returns (uint out) {
            out = value;
        }

        function f(uint value, bool really) public pure returns (uint out) {
            if (really)
                out = value;
        }
    }

重载函数也存在于外部接口中。如果两个
外部可见的函数在 Solidity 类型上不同但在外部类型上相同，则会出错。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    // 这将无法编译
    contract A {
        function f(B value) public pure returns (B out) {
            out = value;
        }

        function f(address value) public pure returns (address out) {
            out = value;
        }
    }

    contract B {
    }


上述两个 ``f`` 函数重载最终都接受地址类型用于 ABI，尽管
它们在 Solidity 内部被视为不同。

重载解析和参数匹配
-----------------------------------------

通过将当前范围内的函数声明与函数调用中提供的参数进行匹配来选择重载函数。
如果所有参数都可以隐式转换为预期类型，则函数被选为重载候选。
如果没有恰好一个候选，解析将失败。

.. note::
    返回参数不计入重载解析。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract A {
        function f(uint8 val) public pure returns (uint8 out) {
            out = val;
        }

        function f(uint256 val) public pure returns (uint256 out) {
            out = val;
        }
    }

调用 ``f(50)`` 将产生类型错误，因为 ``50`` 可以隐式转换为 ``uint8``
和 ``uint256`` 类型。另一方面，``f(256)`` 将解析为 ``f(uint256)`` 重载，因为 ``256`` 不能隐式
转换为 ``uint8``。