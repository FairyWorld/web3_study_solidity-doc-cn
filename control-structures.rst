##################################
表达式和控制结构
##################################

.. index:: ! parameter, parameter;input, parameter;output, function parameter, parameter;function, return variable, variable;return, return

.. index:: if, else, while, do/while, for, break, continue, return, switch, goto

控制结构
===================

大多数使用大括号语言的控制结构在 Solidity 中都是可用的：

包括：``if``、``else``、``while``、``do``、``for``、``break``、``continue``、``return``，（它们）具有与 C 或 JavaScript 相同的通常语义。

Solidity 还支持以 ``try``/``catch`` 语句形式的异常处理，但仅适用于 :ref:`外部函数调用 <external-function-calls>` 和合约创建调用。
可以使用 :ref:`revert 语句 <revert-statement>` 创建错误。

条件语句的括号 *不可以* 被省略，但单语句主体周围的花括号可以省略。

请注意，Solidity 中没有从非布尔类型到布尔类型的类型转换，如同 C 和 JavaScript 中那样，因此 ``if (1) { ... }`` 在 Solidity 中是 *无效的*。

.. index:: ! function;call, function;internal, function;external

.. _function-calls:

函数调用
==============

.. _internal-function-calls:

内部函数调用
-----------------------

当前合约的函数可以直接（“内部”）调用，也可以递归调用，如下例所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;

    // 这将发出一个警告
    contract C {
        function g(uint a) public pure returns (uint ret) { return a + f(); }
        function f() internal pure returns (uint ret) { return g(7) + f(); }
    }

这些函数调用被转换为 EVM 内部的简单跳转。这导致当前内存不会被清除，即将内存引用传递给内部调用的函数是非常高效的。
只有同一合约实例的函数可以被内部调用。

仍然应该避免过度递归，因为每个内部函数调用至少使用一个栈槽，而可用的栈槽只有 1024 个。

.. _external-function-calls:

外部函数调用
-----------------------

函数也可以使用 ``this.g(8);`` 和 ``c.g(2);`` 语法调用，其中 ``c`` 是合约实例，``g`` 是属于 ``c`` 的函数。
通过任一方式调用函数 ``g`` 会导致它被称为“外部”调用，使用消息调用而不是直接通过跳转。
请注意，在构造函数中不能使用对 ``this`` 的函数调用，因为实际合约尚未创建。

其他合约的函数必须通过外部调用。对于外部调用，所有函数参数必须复制到内存中。

.. note::
    从一个合约到另一个合约的函数调用不会创建自己的交易，它是作为整体交易的一部分的消息调用。

在调用其他合约的函数时，可以使用特殊选项 ``{value: 10, gas: 10000}`` 指定随调用发送的 Wei 或 gas 数量。
请注意，不建议显式指定 gas 值，因为操作码的 gas 成本可能会在未来发生变化。发送到合约的任何 Wei 都会被添加到该合约的总余额中：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.2 <0.9.0;

    contract InfoFeed {
        function info() public payable returns (uint ret) { return 42; }
    }

    contract Consumer {
        InfoFeed feed;
        function setFeed(InfoFeed addr) public { feed = addr; }
        function callFeed() public { feed.info{value: 10, gas: 800}(); }
    }

你需要在 ``info`` 函数中使用修改器 ``payable``，否则，``value`` 选项将不可用。

.. warning::
  请注意，``feed.info{value: 10, gas: 800}`` 仅在本地设置了随函数调用发送的 ``value`` 和 ``gas`` 数量，最后的括号执行实际调用。
  因此 ``feed.info{value: 10, gas: 800}`` 不会调用函数，``value`` 和 ``gas`` 设置将丢失，只有 ``feed.info{value: 10, gas: 800}()`` 执行函数调用。

由于 EVM 认为对不存在的合约的调用总是成功，Solidity 使用 ``extcodesize`` 操作码检查即将被调用的合约是否实际存在（它包含代码），如果不存在则会引发异常。
如果在调用后将解码返回数据，则会跳过此检查，因此 ABI 解码器将捕获不存在合约的情况。

请注意，在 :ref:`低级调用 <address_related>` 的情况下不会执行此检查，这些调用是基于地址而不是合约实例。

.. note::
    在使用高级调用时要小心 :ref:`预编译合约 <precompiledContracts>`，因为编译器根据上述逻辑将它们视为不存在，尽管它们执行代码并可以返回数据。

如果被调用的合约本身抛出异常或耗尽 gas，函数调用也会导致异常。

.. warning::
    与另一个合约的任何交互都存在潜在危险，特别是合约源代码未知。
    当前合约将控制权交给被调用合约，而被调用合约可能会做任何事情。即使被调用合约继承自已知的父合约，继承合约只需具有正确的接口。
    然而，合约的实现可以完全任意，因此可能会造成危险。此外，要准备好在它调用你系统的其他合约或甚至在第一个调用返回之前回调到调用合约。
    这意味着被调用合约可以通过其函数更改调用合约的状态变量。
    以这样的方式编写你的函数，例如，在对合约中的状态变量进行任何更改后再调用外部函数，以便你的合约不易受到重入攻击。

.. note::
    在 Solidity 0.6.2 之前，指定 value 和 gas 的推荐方式是使用 ``f.value(x).gas(g)()``。
    这在 Solidity 0.6.2 中已弃用，并且在 Solidity 0.7.0 中不再允许使用。

具名参数的函数调用
------------------------------------

当被包含在 ``{ }`` 中时，函数调用参数可以按名称给出，顺序可以任意，如下例所示。
参数列表必须按名称与函数声明中的参数列表一致，但可以是任意顺序。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract C {
        mapping(uint => uint) data;

        function f() public {
            set({value: 2, key: 3});
        }

        function set(uint key, uint value) public {
            data[key] = value;
        }
    }

函数定义中省略名称
-------------------------------------

函数声明中的参数和返回值的名称可以省略。
那些省略名称的项仍然会存在于栈上，但无法通过名称访问。
省略的返回值名称仍然可以通过使用 ``return`` 语句返回值给调用者。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;

    contract C {
        // 省略参数名称
        function func(uint k, uint) public pure returns(uint) {
            return k;
        }
    }


.. index:: ! new, contracts;creating

.. _creating-contracts:

通过 ``new`` 创建合约
==============================

合约可以使用 ``new`` 关键字创建其他合约。在创建合约的合约编译时，必须知道被创建合约的完整代码，因此不可能存在递归创建依赖关系。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    contract D {
        uint public x;
        constructor(uint a) payable {
            x = a;
        }
    }

    contract C {
        D d = new D(4); // 将作为 C 的构造函数的一部分执行

        function createD(uint arg) public {
            D newD = new D(arg);
            newD.x();
        }

        function createAndEndowD(uint arg, uint amount) public payable {
            // 在创建时发送以太币
            D newD = new D{value: amount}(arg);
            newD.x();
        }
    }

如示例所示，在创建 ``D`` 的实例时，可以使用 ``value`` 选项发送以太币，但无法限 gas 的数量。
如果创建失败（由于栈溢出、余额不足或其他问题），将抛出异常。

加“盐”的合约创建 / create2
-----------------------------------

在创建合约时，合约的地址是从创建合约的地址和一个在每次创建合约交易时增加的计数器计算得出的。

如果你指定了 ``salt`` 选项（一个 bytes32 值），那么合约创建将使用不同的机制来生成新合约的地址：

它将根据创建合约的地址、给定的盐值、被创建合约的（创建）字节码和构造函数参数计算地址。

特别地，计数器（“nonce”）不被使用。这为创建合约提供了更多灵活性：你可以在合约创建之前推导出新合约的地址。
此外，你还可以依赖此地址，即使创建合约在此期间创建了其他合约。

这里的主要用例是作为链下交互的裁判的合约，仅在发生争议时需要创建。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    contract D {
        uint public x;
        constructor(uint a) {
            x = a;
        }
    }

    contract C {
        function createDSalted(bytes32 salt, uint arg) public {
            // 这个复杂的表达式只是告诉你地址如何可以预先计算。它只是用于说明。
            // 你实际上只需要 ``new D{salt: salt}(arg)``。
            address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(
                    type(D).creationCode,
                    abi.encode(arg)
                ))
            )))));

            D d = new D{salt: salt}(arg);
            require(address(d) == predictedAddress);
        }
    }

.. warning::
    关于 create2 创建有一些特殊情况。合约在被销毁后可以在相同地址重新创建。
    然而，重新创建的合约可能具有不同的部署字节码，即使创建字节码是相同的（这是一个要求，因为否则地址会改变）。这是因为构造函数可以查询在两次创建之间可能已更改的外部状态，并将其纳入存储之前的部署字节码中。

表达式的求值顺序
==================================

表达式的求值顺序未指定（更正式地说，表达式树中一个节点的子节点的求值顺序未指定，但它们当然在节点本身之前被求值）。该规则只保证语句按顺序执行，并且执行布尔表达式的短路求值。

.. index:: ! assignment

赋值
==========

.. index:: ! assignment;destructuring

解构赋值和返回多个值
-------------------------------------------------------

Solidity 内部允许元组类型，即一个可能具有不同类型的对象列表，其数量在编译时是常量。
这些元组可以用于同时返回多个值。然后可以将这些值分配给新声明的变量或预先存在的变量（或一般的 LValues）。

元组在 Solidity 中不是正式类型，它们只能用于形成表达式的语法分组。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    contract C {
        uint index;

        function f() public pure returns (uint, bool, uint) {
            return (7, true, 2);
        }

        function g() public {
            // 声明类型的变量并从返回的元组中赋值，
            // 并不需要指定所有元素（但数量必须匹配）。
            (uint x, , uint y) = f();
            // 交换值的常见技巧 -- 不适用于非值存储类型。
            (x, y) = (y, x);
            // 组件可以被省略（变量声明也一样）。
            (index, , ) = f(); // 将 index 设置为 7
        }
    }

不可能混合变量声明和非声明赋值，即以下内容无效： ``(x, uint y) = (1, 2);``

.. note::
    在 0.5.0 版本之前，可以将较小大小的元组赋值，填充左侧或右侧（任一为空）。现在不允许这样，因此两侧必须具有相同数量的组件。

.. warning::
    在同时赋值给多个变量时要小心，当涉及引用类型时，因为这可能导致意外的复制行为。

数组和结构的复杂性
------------------------------------

对于非值类型（如数组和结构，包括 ``bytes`` 和 ``string``），赋值的语义更复杂，详见 :ref:`数据位置和赋值行为 <data-location-assignment>`。

在下面的示例中，对 ``g(x)`` 的调用对 ``x`` 没有影响，因为它在内存中创建了存储值的独立副本。
然而，``h(x)`` 成功修改了 ``x``，因为只传递了引用而不是副本。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;

    contract C {
        uint[20] x;

        function f() public {
            g(x);
            h(x);
        }

        function g(uint[20] memory y) internal pure {
            y[2] = 3;
        }

        function h(uint[20] storage y) internal {
            y[3] = 4;
        }
    }

.. index:: ! scoping, declarations, default value

.. _default-value:

作用域和声明
========================

声明的变量将具有初始默认值，其字节表示为全零。
变量的“默认值”是其类型的典型“零状态”。例如，``bool`` 的默认值是 ``false``。``uint`` 或 ``int`` 类型的默认值是 ``0``。
对于静态大小的数组和 ``bytes1`` 到 ``bytes32``，每个单独的元素将被初始化为其类型对应的默认值。
对于动态大小的数组、``bytes`` 和 ``string``，默认值是一个空数组或字符串。
对于 ``enum`` 类型，默认值是其第一个成员。

Solidity 中的作用域遵循 C99（以及许多其他语言）广泛使用的作用域规则：变量从声明后的点开始可见，直到包含该声明的最小 ``{ }`` 块的结束。
作为此规则的例外，在 for 循环的初始化部分声明的变量仅在 for 循环结束之前可见。

参数类变量（函数参数、修改器参数、捕获参数等）在后续代码块中可见——函数和修改器参数的函数体，以及捕获参数的捕获块。

在代码块外声明的变量和其他项，例如函数、合约、自定义类型等，即使在声明之前也可见。这意味着你可以在声明之前使用状态变量并递归调用函数。

因此，以下示例将编译而不会产生警告，因为这两个变量具有相同的名称但作用域不重叠。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;
    contract C {
        function minimalScoping() pure public {
            {
                uint same;
                same = 1;
            }

            {
                uint same;
                same = 3;
            }
        }
    }

作为 C99 作用域规则的一个特殊示例，请注意，在以下代码中，对 ``x`` 的第一次赋值实际上将赋值给外部变量而不是内部变量。
无论如何，你将收到关于外部变量被遮蔽的警告。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;
    // 这将发出警告
    contract C {
        function f() pure public returns (uint) {
            uint x = 1;
            {
                x = 2; // 这将赋值给外部变量
                uint x;
            }
            return x; // x 的值为 2
        }
    }

.. warning::
    在 0.5.0 版本之前，Solidity 遵循与 JavaScript 相同的作用域规则，即在函数内的任何地方声明的变量在整个函数中都是可见的，无论它在哪里声明。
    以下示例显示了一个以前可以编译但从 0.5.0 版本开始导致错误的代码片段。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;
    // 这将无法编译
    contract C {
        function f() pure public returns (uint) {
            x = 2;
            uint x;
            return x;
        }
    }


.. index:: ! safe math, safemath, checked, unchecked
.. _unchecked:

检查或不检查的算术
===============================

溢出或下溢是指在对不受限制的整数执行算术操作时，结果值超出结果类型的范围的情况。

在 Solidity 0.8.0 之前，算术操作在发生下溢或溢出时总是会包裹，导致广泛使用引入额外检查的库。

自 Solidity 0.8.0 起，所有算术操作在发生溢出和下溢时默认会回退，因此不再需要使用这些库。

如果想要之前“截断”的效果，可以使用 ``unchecked`` 块：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.0;
    contract C {
        function f(uint a, uint b) pure public returns (uint) {
            // 减法溢出会返回“截断”的结果
            unchecked { return a - b; }
        }
        function g(uint a, uint b) pure public returns (uint) {
            // 在下溢时将回滚。
            return a - b;
        }
    }

对 ``f(2, 3)`` 的调用将返回 ``2**256-1``，而 ``g(2, 3)`` 将导致断言失败。

``unchecked`` 块可以在块内的任何地方使用，但不能替代一个块。它也不能嵌套。

该设置仅影响语法上位于块内的语句。从 ``unchecked`` 块内调用的函数不会继承该属性。

.. note::
    为了避免歧义，你不能在 ``unchecked`` 块内使用 ``_;``。

以下运算符在发生溢出或下溢时将导致断言失败，并且如果在未检查块内使用则会包裹而不报错：

``++``, ``--``, ``+``, 二元 ``-``, 一元 ``-``, ``*``, ``/``, ``%``, ``**``

``+=``, ``-=``, ``*=``, ``/=``, ``%=``

.. warning::
    无法使用 ``unchecked`` 块禁用对零除法或零取模的检查。

.. note::
   位运算符不执行溢出或下溢检查。
   这在使用位移运算（``<<``, ``>>``, ``<<=``, ``>>=``）代替整数除法和乘以 2 的幂时特别明显。
   例如 ``type(uint256).max << 3`` 不会回退，即使 ``type(uint256).max * 8`` 会。

.. note::
    在 ``int x = type(int).min; -x;`` 中，第二个语句将导致溢出，因为负范围可以容纳比正范围多一个值。

显式类型转换将始终截断，并且不会导致断言失败，整数到枚举类型的转换除外。

.. index:: ! exception, ! throw, ! assert, ! require, ! revert, ! errors

.. _assert-and-require:

错误处理：Assert, Require, Revert
======================================================

Solidity 使用状态回滚异常来处理错误。
这样的异常会撤销当前调用（及其所有子调用）所做的所有状态更改，并向调用者标记错误。

当在子调用中发生异常时，它们会“冒泡”（即，异常会自动重新抛出），除非在 ``try/catch`` 语句中捕获。
规则的例外是 ``send`` 和低级函数 ``call``、``delegatecall`` 和 ``staticcall``：它们在发生异常时将其第一个返回值返回为 ``false``，而不是“冒泡”。

.. warning::
    如果被调用的账户不存在，低级函数 ``call``、``delegatecall`` 和 ``staticcall`` 则将其第一个返回值返回为 ``true``，这是 EVM 设计的一部分。
    如果需要，必须在调用之前检查账户是否存在。

异常可以包含错误数据，以 :ref:`error 实例 <errors>` 的形式传回给调用者。
内置错误 ``Error(string)`` 和 ``Panic(uint256)`` 由特殊函数使用，如下所述。
``Error`` 用于“常规”错误条件，而 ``Panic`` 用于在无错误代码中不应出现的错误。

.. _assert-and-require-statements:

通过 ``assert`` 进行 Panic 和通过 ``require`` 进行错误处理
----------------------------------------------

便利函数 ``assert`` 和 ``require`` 可用于检查条件，并在条件不满足时抛出异常。

``assert`` 函数会创建一个类型为 ``Panic(uint256)`` 的错误。
在某些情况下，编译器也会创建相同的错误，如下所列。

Assert 应仅用于测试内部错误，并检查不变式。正常工作的代码不应创建 Panic，即使在无效的外部输入下也不应如此。
如果发生这种情况，则你的合约中存在一个错误，你应当修复它。
语言分析工具可以评估你的合约，以识别会导致 Panic 的条件和函数调用。

在以下情况下会生成 Panic 异常。
与错误数据一起提供的错误代码指示 Panic 的类型。

#. 0x00: 用于通用编译器插入的 Panic。
#. 0x01: 如果你调用 ``assert`` 并传入一个评估为 false 的参数。
#. 0x11: 如果算术操作导致在 ``unchecked { ... }`` 块外的下溢或上溢。
#. 0x12: 如果你除以零或取模零（例如 ``5 / 0`` 或 ``23 % 0``）。
#. 0x21: 如果你将一个过大或负值转换为枚举类型。
#. 0x22: 如果你访问一个编码不正确的存储字节数组。
#. 0x31: 如果你在空数组上调用 ``.pop()``。
#. 0x32: 如果你在越界或负索引处访问数组、``bytesN`` 或数组切片（即 ``x[i]``，其中 ``i >= x.length`` 或 ``i < 0``）。
#. 0x41: 如果你分配了过多的内存或创建了一个过大的数组。
#. 0x51: 如果你调用一个零初始化的内部函数类型的变量。

``require`` 函数提供三种重载：

1. ``require(bool)``，在没有任何数据的情况下回退（甚至没有错误选择器）。
2. ``require(bool, string)``，在 ``Error(string)`` 的情况下回退。
3. ``require(bool, error)``，在提供的第二个参数中回退自定义的用户提供的错误。

.. note::
    ``require`` 参数是无条件评估的，因此请特别注意确保它们不是具有意外副作用的表达式。
    例如，在 ``require(condition, CustomError(f()));`` 和 ``require(condition, f());`` 中，
    函数 ``f()`` 将被调用，无论提供的条件是 ``true`` 还是 ``false``。

``Error(string)`` 异常（或没有数据的异常）在以下情况下由编译器生成：

#. 调用 ``require(x)``，其中 ``x`` 评估为 ``false``。
#. 如果你使用 ``revert()`` 或 ``revert("description")``。
#. 如果你执行一个外部函数调用，目标合约没有代码。
#. 如果你的合约通过没有 ``payable`` 修改器的公共函数接收以太（包括构造函数和回退函数）。
#. 如果你的合约通过公共 getter 函数接收以太。

在以下情况下，外部调用的错误数据（如果提供）会被转发。这意味着它可以导致 ``Error`` 或 ``Panic``（或其他任何给定的内容）：

#. 如果 ``.transfer()`` 失败。
#. 如果你通过消息调用调用一个函数，但它没有正确完成（即，它耗尽了 gas、没有匹配的函数或自身抛出异常），除非使用低级操作``call``、``send``、``delegatecall``、``callcode`` 或 ``staticcall``。
   低级操作从不抛出异常，而是通过返回 ``false`` 指示失败。
#. 如果你使用 ``new`` 关键字创建一个合约，但合约创建 :ref:`没有正确结束<creating-contracts>`。

你可以选择性地向 ``require`` 提供消息字符串或自定义错误，但 ``assert`` 不行。

.. note::
    如果你不向 ``require`` 提供字符串或自定义错误参数，它将回退并且没有错误数据，甚至不包括错误选择器。

以下示例展示了如何使用 ``require`` 检查输入条件
以及使用 ``assert`` 进行内部错误检查。

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    contract Sharer {
        function sendHalf(address payable addr) public payable returns (uint balance) {
            require(msg.value % 2 == 0, "需要偶数值。");
            uint balanceBeforeTransfer = address(this).balance;
            addr.transfer(msg.value / 2);
            // 由于 transfer 在失败时抛出异常并且不能在这里回调，
            // 因此我们不应仍然拥有一半的以太。
            assert(address(this).balance == balanceBeforeTransfer - msg.value / 2);
            return address(this).balance;
        }
    }

在内部，Solidity 执行回退操作（指令 ``0xfd``）。这导致 EVM 撤销对状态所做的所有更改。
回退的原因是没有安全的方法继续执行，因为预期的效果没有发生。
因为我们希望保持交易的原子性，最安全的操作是撤销所有更改，使整个交易（或至少调用）无效。

在这两种情况下，调用者可以使用 ``try``/``catch`` 对此类失败做出反应，但被调用者的更改将始终被撤销。

.. note::

    Panic 异常在 Solidity 0.8.0 之前使用 ``invalid`` 操作码，这会消耗调用中所有可用的 gas。
    使用 ``require`` 的异常在 Metropolis 版本发布之前会消耗所有 gas。

.. _revert-statement:

``revert``
----------

可以使用 ``revert`` 语句和 ``revert`` 函数来直接触发回退。

``revert`` 语句直接接受一个自定义错误作为参数，无需括号：

    revert CustomError(arg1, arg2);

出于向后兼容的原因，还有 ``revert()`` 函数，它使用括号并接受一个字符串：

    revert();
    revert("描述");

错误数据将被传回给调用者，并可以在那里捕获。
使用 ``revert()`` 会导致没有任何错误数据的回退，而 ``revert("描述")``将创建一个 ``Error(string)`` 错误。

使用自定义错误实例通常比字符串描述便宜得多，因为你可以使用错误的名称来描述它，这仅编码为四个字节。
可以通过 NatSpec 提供更长的描述，而不会产生任何费用。

以下示例展示了如何将错误字符串和自定义错误实例与 ``revert`` 和等效的 ``require`` 一起使用：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.4;

    contract VendingMachine {
        address owner;
        error Unauthorized();
        function buy(uint amount) public payable {
            if (amount > msg.value / 2 ether)
                revert("Not enough Ether provided.");
            // 另一种做法：
            require(
                amount <= msg.value / 2 ether,
                "Not enough Ether provided."
            );
            // 执行购买。
        }
        function withdraw() public {
            if (msg.sender != owner)
                revert Unauthorized();

            payable(msg.sender).transfer(address(this).balance);
        }
    }
两种方式 ``if (!condition) revert(...);`` 和 ``require(condition, ...);`` 是等价的，只要传递给 ``revert`` 和 ``require`` 的参数没有副作用，例如它们只是字符串。

.. note::
    ``require`` 函数的评估方式与其他函数相同。
    这意味着所有参数在函数本身执行之前都会被评估。
    特别是在 ``require(condition, f())`` 中，即使 ``condition`` 为真，函数 ``f`` 也会被执行。

提供的字符串是 :ref:`abi-encoded <ABI>`，就像调用函数 ``Error(string)`` 一样。
在上面的例子中，``revert("Not enough Ether provided.");`` 返回以下十六进制作为错误返回数据：

.. code::

    0x08c379a0                                                         // Error(string) 的函数选择器
    0x0000000000000000000000000000000000000000000000000000000000000020 // 数据偏移
    0x000000000000000000000000000000000000000000000000000000000000001a // 字符串长度
    0x4e6f7420656e6f7567682045746865722070726f76696465642e000000000000 // 字符串数据

调用者可以使用 ``try``/``catch`` 以如下方式检索提供的消息。

.. note::
    以前有一个关键字 ``throw``，其语义与 ``revert()`` 相同，该关键字在版本 0.4.13 中被弃用，并在版本 0.5.0 中移除。

.. _try-catch:

``try``/``catch``
-----------------

可以使用 try/catch 语句捕获外部调用中的失败，如下所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.1;

    interface DataFeed { function getData(address token) external returns (uint value); }

    contract FeedConsumer {
        DataFeed feed;
        uint errorCount;
        function rate(address token) public returns (uint value, bool success) {
            // 如果错误超过 10 次，则永久禁用该机制。
            require(errorCount < 10);
            try feed.getData(token) returns (uint v) {
                return (v, true);
            } catch Error(string memory /*reason*/) {
                // 如果在 getData 中调用了 revert
                // 并提供了原因字符串，则执行此代码。
                errorCount++;
                return (0, false);
            } catch Panic(uint /*errorCode*/) {
                // 如果发生了 panic，即严重错误，如除以零或溢出，则执行此代码。
                // 错误代码可用于确定错误类型。
                errorCount++;
                return (0, false);
            } catch (bytes memory /*lowLevelData*/) {
                // 如果使用了 revert()，则执行此代码。
                errorCount++;
                return (0, false);
            }
        }
    }

``try`` 关键字后必须跟一个表示外部函数调用或合约创建 (``new ContractName()``) 的表达式。
表达式内部的错误不会被捕获（例如，如果它是一个复杂的表达式，还涉及内部函数调用），只有外部调用本身发生的 revert。后面的 ``returns`` 部分（可选）声明与外部调用返回的类型匹配的返回变量。
如果没有错误，这些变量将被赋值，合约的执行将在第一个成功块内继续。如果成功块的末尾被达到，执行将在 ``catch`` 块之后继续。

Solidity 支持不同类型的 catch 块，具体取决于错误类型：

- ``catch Error(string memory reason) { ... }``：如果错误是由 ``revert("reasonString")`` 或``require(false, "reasonString")``（或导致此类异常的内部错误）引起的，则执行此捕获子句。

- ``catch Panic(uint errorCode) { ... }``：如果错误是由 panic 引起的，即由失败的 ``assert``、除以零、无效数组访问、算术溢出等引起的，则将运行此捕获子句。

- ``catch (bytes memory lowLevelData) { ... }``：如果错误签名不匹配任何其他子句，或者在解码错误消息时发生错误，或者如果没有提供错误数据，则执行此子句。在这种情况下，声明的变量提供对低级错误数据的访问。

- ``catch { ... }``：如果你对错误数据不感兴趣，可以仅使用 ``catch { ... }``（即使作为唯一的捕获子句）来替代前面的子句。

计划在未来支持其他类型的错误数据。
字符串 ``Error`` 和 ``Panic`` 目前按原样解析，并不被视为标识符。

为了捕获所有错误情况，你必须至少有子句 ``catch { ...}`` 或子句 ``catch (bytes memory lowLevelData) { ... }``。

在 ``returns`` 和 ``catch`` 子句中声明的变量仅在后续块中有效。

.. note::

    如果在 try/catch 语句中解码返回数据时发生错误，这会导致当前执行合约中的异常，因此不会在捕获子句中捕获。
    如果在解码 ``catch Error(string memory reason)`` 时发生错误并且存在低级捕获子句，则该错误将在那里被捕获。

.. note::

    如果执行到达捕获块，则外部调用的状态更改效果已被回滚。
    如果执行到达成功块，则效果未被回滚。
    如果效果已被回滚，则执行要么继续在捕获块中，要么 try/catch 语句本身的执行回滚（例如，由于上面提到的解码失败或未提供低级捕获子句）。

.. note::
    失败调用的原因可能是多种多样的。不要假设错误消息直接来自被调用的合约：
    错误可能发生在调用链的更深处，被调用的合约只是转发了它。
    此外，这也可能是由于缺少 gas 的情况，而不是故意的错误条件：
    调用者在调用中始终保留至少 1/64 的 gas，因此即使被调用的合约耗尽了 gas，调用者仍然有一些 gas 剩余。