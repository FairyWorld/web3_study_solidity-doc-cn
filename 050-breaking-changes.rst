********************************
Solidity v0.5.0 重大变更
********************************

本节重点介绍了 Solidity 版本 0.5.0 中引入的主要重大变更，以及这些变更背后的原因和如何变更日志受影响的代码。
完整列表请查看 `变更日志 <https://github.com/ethereum/solidity/releases/tag/v0.5.0>`_。

.. note::
   使用 Solidity v0.5.0 编译的合约仍然可以与使用旧版本编译的合约甚至库进行交互，
   而无需重新编译或重新部署它们。 只需更改接口以包含数据位置和可见性及可变性说明符即可。
   请参见下面的 :ref:`与旧合约的互操作性 <interoperability>` 部分。

语义变更
=====================

本节列出了仅涉及语义的变更，因此可能会隐藏现有代码中的新行为和不同的行为。

* 有符号右移现在使用正确的算术右移，即向负无穷舍入，而不是向零舍入。有符号和无符号移位将在君士坦丁堡中有专用的操作码，目前由 Solidity 模拟。

* ``do...while`` 循环中的 ``continue`` 语句现在跳转到条件，这是这种情况下的常见行为。它以前是跳转到循环体。因此，如果条件为假，循环将终止。

* 函数 ``.call()``, ``.delegatecall()`` 和 ``.staticcall()`` 在给定单个 ``bytes`` 参数时不再进行填充。

* 纯函数和视图函数现在在 EVM 版本为拜占庭或更高时使用操作码 ``STATICCALL`` 调用。这禁止在 EVM 级别进行状态更改。

* ABI 编码器现在在外部函数调用和 ``abi.encode`` 中正确填充来自 calldata (``msg.data`` 和外部函数参数) 的字节数组和字符串。对于未填充的编码，请使用 ``abi.encodePacked``。

* 如果传递的 calldata 太短或超出边界，ABI 解码器将在函数开始和 ``abi.decode()`` 中回退。请注意，脏的高位仍然会被简单忽略。

* 从 Tangerine Whistle 开始，所有可用的 gas 都会在外部函数调用中转发。

语义和语法变更
==============================

本节重点介绍影响语法和语义的变更。

* 函数 ``.call()``, ``.delegatecall()``, ``staticcall()``,``keccak256()``, ``sha256()`` 和 ``ripemd160()`` 现在只接受单个 ``bytes`` 参数。
  此外，参数不再填充。此更改旨在更明确和清晰地说明参数是如何连接的。
  将每个 ``.call()`` （及其家族）更改为 ``.call("")``，将每个 ``.call(signature, a, b, c)`` 更改为使用 ``.call(abi.encodeWithSignature(signature, a, b, c))`` （最后一个仅适用于值类型）。
  将每个 ``keccak256(a, b, c)`` 更改为 ``keccak256(abi.encodePacked(a, b, c))``。
  尽管这不是重大变更，但建议开发者将 ``x.call(bytes4(keccak256("f(uint256)")), a, b)`` 更改为 ``x.call(abi.encodeWithSignature("f(uint256)", a, b))``。

* 函数 ``.call()``, ``.delegatecall()`` 和 ``.staticcall()`` 现在返回 ``(bool, bytes memory)`` 以提供对返回数据的访问。
  将 ``bool success = otherContract.call("f")`` 更改为 ``(bool success, bytes memory data) = otherContract.call("f")``。

* Solidity 现在实现了 C99 风格的作用域规则，对于函数局部变量，即变量只能在声明后使用，并且只能在同一作用域或嵌套作用域中使用。
  在 ``for`` 循环的初始化块中声明的变量在循环内部的任何位置都是有效的。

明确性要求
=========================

本节列出了代码现在需要更明确的变更。对于大多数主题，编译器将提供建议。

* 显式函数可见性现在是强制性的。为每个函数和构造函数添加 ``public``，并为每个未指定可见性的回退或接口函数添加 ``external``。

* 所有结构、数组或映射类型变量的显式数据位置现在是强制性的。这也适用于函数参数和返回变量。
  例如，将 ``uint[] x = z`` 更改为 ``uint[] storage x = z``，将 ``function f(uint[][] x)`` 更改为 ``function f(uint[][] memory x)``，
  其中 ``memory`` 是数据位置，可能会相应地替换为 ``storage`` 或 ``calldata``。
  请注意，``external`` 函数要求参数的数据位置为 ``calldata``。

* 合约类型不再包含 ``address`` 成员，以便分离命名空间。因此，现在必须在使用 ``address`` 成员之前显式将合约类型的值转换为地址。
  示例：如果 ``c`` 是一个合约，将 ``c.transfer(...)`` 更改为 ``address(c).transfer(...)``，将 ``c.balance`` 更改为 ``address(c).balance``。

* 现在不允许在不相关的合约类型之间进行显式转换。你只能从合约类型转换为其基类或祖先类型。
  如果你确定一个合约与你想要转换的合约类型兼容，尽管它不继承自它，你可以通过先转换为 ``address`` 来解决此问题。
  示例：如果 ``A`` 和 ``B`` 是合约类型，``B`` 不继承自 ``A``，而 ``b`` 是类型为 ``B`` 的合约，你仍然可以使用 ``A(address(b))`` 将 ``b`` 转换为类型 ``A``。
  请注意，你仍然需要注意匹配可支付的回退函数，如下所述。

* ``address`` 类型被拆分为 ``address`` 和 ``address payable``，其中只有 ``address payable`` 提供 ``transfer`` 函数。一个
  ``address payable`` 可以直接转换为 ``address``，但反向转换是不允许的。
  通过 ``uint160`` 转换 ``address`` 为 ``address payable`` 是可能的。
  如果 ``c`` 是一个合约，``address(c)`` 仅在 ``c`` 具有可支付的回退函数时才会产生 ``address payable``。
  如果你使用 :ref:`提取模式<withdrawal_pattern>`，你很可能不需要更改代码，因为 ``transfer`` 仅在 ``msg.sender`` 上使用，而不是存储的地址，并且 ``msg.sender`` 是一个 ``address payable``。

* 由于 ``bytesX`` 在右侧填充和 ``uintY`` 在左侧填充可能导致意外的转换结果，因此不同大小的 ``bytesX`` 和 ``uintY`` 之间的转换现在不被允许。
  现在必须在转换之前在类型内调整大小。例如，你可以将 ``bytes4`` （4 字节）转换为 ``uint64`` （8 字节），方法是先将 ``bytes4`` 变量转换为 ``bytes8``，然后再转换为 ``uint64``。
  通过 ``uint32`` 转换时会得到相反的填充。在 v0.5.0 之前，任何 ``bytesX`` 和 ``uintY`` 之间的转换都会通过 ``uint8X`` 进行。例如 ``uint8(bytes3(0x291807))`` 将被转换为 ``uint8(uint24(bytes3(0x291807)))`` 结果是 ``0x07``）。

* 在不可支付的函数中使用 ``msg.value`` （或通过修改器引入它）是不允许的，作为安全功能。
  将函数转换为 ``payable`` 或为程序逻辑创建一个新的内部函数，该函数使用 ``msg.value``。

* 出于清晰原因，命令行界面现在要求在使用标准输入作为源时加上 ``-``。

弃用元素
===================

本节列出了使先前功能或语法过时的更改。请注意，许多这些更改在实验模式 ``v0.5.0`` 中已经启用。

命令行和 JSON 接口
--------------------------------

* 命令行选项 ``--formal`` （用于生成进一步形式验证的 Why3 输出）已被弃用并且现在已被移除。一个新的形式验证模块 SMTChecker 通过 ``pragma experimental SMTChecker;`` 启用。

* 命令行选项 ``--julia`` 因中间语言 ``Julia`` 重命名为 ``Yul`` 而被重命名为 ``--yul``。

* ``--clone-bin`` 和 ``--combined-json clone-bin`` 命令行选项已被移除。

* 不允许使用空前缀的重映射。

* JSON AST 字段 ``constant`` 和 ``payable`` 已被移除。该信息现在在 ``stateMutability`` 字段中。

* JSON AST 字段 ``isConstructor`` 的 ``FunctionDefinition`` 节点已被名为 ``kind`` 的字段替代，该字段可以具有值 ``"constructor"``, ``"fallback"`` 或 ``"function"``。

* 在未链接的二进制十六进制文件中，库地址占位符现在是完全限定库名称的 keccak256 哈希的前 36 个十六进制字符，周围用 ``$...$`` 包围。之前，仅使用完全限定的库名称。这减少了碰撞的可能性，特别是在使用长路径时。二进制文件现在还包含从这些占位符到完全限定名称的映射列表。

构造函数
------------

* 现在必须使用 ``constructor`` 关键字定义构造函数。

* 不再允许在没有括号的情况下调用基构造函数。

* 在同一继承层次结构中多次指定基构造函数参数现在是不允许的。

* 现在不允许以错误的参数数量调用带参数的构造函数。如果你只想指定继承关系而不提供参数，请完全不提供括号。

函数
---------

* 函数 ``callcode`` 现在不被允许（支持 ``delegatecall``）。仍然可以通过内联汇编使用它。

* ``suicide`` 现在不被允许（支持 ``selfdestruct``）。

* ``sha3`` 现在不被允许（支持 ``keccak256``）。

* ``throw`` 现在不被允许（支持 ``revert``、``require`` 和 ``assert``）。

转换
-----------

* 从十进制字面量到 ``bytesXX`` 类型的显式和隐式转换现在不被允许。

* 从十六进制字面量到不同大小的 ``bytesXX`` 类型的显式和隐式转换现在不被允许。

字面量和后缀
---------------------

* 由于对闰年的复杂性和混淆，单位名称 ``years`` 现在不被允许。

* 不再允许后面没有数字的尾随点。

* 现在不允许将十六进制数字与单位名称结合（例如 ``0x1e wei``）。

* 十六进制数字的前缀 ``0X`` 不被允许，仅允许 ``0x``。

变量
---------

* 现在不允许声明空结构以提高清晰度。

* 现在不允许使用 ``var`` 关键字以支持显式性。

* 不同组件数量的元组之间的赋值现在不被允许。

* 非编译时常量的常量值不被允许。

* 值数量不匹配的多变量声明现在不被允许。

* 未初始化的存储变量现在不被允许。

* 空元组组件现在不被允许。

* 在变量和结构中检测循环依赖的递归限制为 256。

* 长度为零的固定大小数组现在不被允许。

语法
------

* 现在不允许将 ``constant`` 用作函数状态可变性修改器。

* 布尔表达式不能使用算术运算。

* 一元 ``+`` 运算符现在不被允许。

* 字面量不能再与 ``abi.encodePacked`` 一起使用，而不先转换为显式类型。

* 对于一个或多个返回值的函数，空返回语句现在不被允许。

* “松散汇编”语法现在完全不被允许，即不再允许使用跳转标签、跳转和非功能指令。请改用新的 ``while``、``switch`` 和 ``if`` 构造。

* 没有实现的函数不能再使用修改器。

* 带有命名返回值的函数类型现在不被允许。

* 在 if/while/for 体内的单语句变量声明（不是块）现在不被允许。

* 新关键字：``calldata`` 和 ``constructor``。

* 新保留关键字：``alias``、``apply``、``auto``、``copyof``、``define``、``immutable``、``implements``、``macro``、``mutable``、``override``、``partial``、``promise``、``reference``、``sealed``、``sizeof``、``supports``、``typedef`` 和 ``unchecked``。

.. _interoperability:

与旧合约的互操作性
=====================================

仍然可以通过为它们定义接口与编写的 Solidity 版本低于 v0.5.0 的合约进行接口交互（或反之亦然）。假设你已经部署了以下 0.5.0 之前的版本的合约：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.4.25;
    // 这将在编译器版本 0.4.25 之前报告警告
    // 这在 0.5.0 之后将无法编译
    contract OldContract {
        function someOldFunction(uint8 a) {
            //...
        }
        function anotherOldFunction() constant returns (bool) {
            //...
        }
        // ...
    }

这在 Solidity v0.5.0 中将不再编译。但是，你可以为其定义一个兼容的接口：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;
    interface OldContract {
        function someOldFunction(uint8 a) external;
        function anotherOldFunction() external returns (bool);
    }

请注意，我们没有将 ``anotherOldFunction`` 声明为 ``view``，尽管它在原始合约中被声明为 ``constant``。
这是因为从 Solidity v0.5.0 开始，使用 ``staticcall`` 来调用 ``view` 函数。
在 v0.5.0 之前，``constant`` 关键字并未强制执行，因此使用 ``staticcall`` 调用声明为 ``constant`` 的函数仍可能回退，因为 ``constant`` 函数仍可能尝试修改存储。
因此，在为旧合约定义接口时，你应该仅在绝对确定该函数可以与 ``staticcall`` 一起使用的情况下，使用 ``view`` 替代 ``constant``。

给定上述定义的接口，你现在可以轻松使用已经部署的 0.5.0 版本之前的合约：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    interface OldContract {
        function someOldFunction(uint8 a) external;
        function anotherOldFunction() external returns (bool);
    }

    contract NewContract {
        function doSomething(OldContract a) public returns (bool) {
            a.someOldFunction(0x42);
            return a.anotherOldFunction();
        }
    }

同样，可以通过定义库的函数而不实现，并在链接时提供 0.5.0 之前版本的库地址来使用库（请参见 :ref:`commandline-compiler` 以了解如何使用命令行编译器进行链接）：

.. code-block:: solidity

    // 这将在 0.6.0 之后无法编译
    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.5.0;

    library OldLibrary {
        function someFunction(uint8 a) public returns(bool);
    }

    contract NewContract {
        function f(uint8 a) public returns (bool) {
            return OldLibrary.someFunction(a);
        }
    }


示例
=======

以下示例展示了一个合约及其针对 Solidity v0.5.0 的变更日志版本，包含本节中列出的一些更改。

旧版本：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.4.25;
    // 这将在 0.5.0 之后无法编译

    contract OtherContract {
        uint x;
        function f(uint y) external {
            x = y;
        }
        function() payable external {}
    }

    contract Old {
        OtherContract other;
        uint myNumber;

        // 函数可变性未提供，不是错误。
        function someInteger() internal returns (uint) { return 2; }

        // 函数可见性未提供，不是错误。
        // 函数可变性未提供，不是错误。
        function f(uint x) returns (bytes) {
            // 在这个版本中，变量是可以的。
            var z = someInteger();
            x += z;
            // 抛出在这个版本中是可以的。
            if (x > 100)
                throw;
            bytes memory b = new bytes(x);
            y = -3 >> 1;
            // y == -1（错误，应该是 -2）
            do {
                x += 1;
                if (x > 10) continue;
                // 'Continue' 会导致无限循环。
            } while (x < 11);
            // 调用只返回一个布尔值。
            bool success = address(other).call("f");
            if (!success)
                revert();
            else {
                // 局部变量可以在使用后声明。
                int y;
            }
            return b;
        }

        // 对于 'arr' 不需要显式数据位置
        function g(uint[] arr, bytes8 x, OtherContract otherContract) public {
            otherContract.transfer(1 ether);

            // 由于 uint32（4 字节）小于 bytes8（8 字节）， x 的前 4 字节将丢失。
            // 这可能导致意外行为，因为 bytesX 是右填充的。
            uint32 y = uint32(x);
            myNumber += y + msg.value;
        }
    }

新版本：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.5.0;
    // 这将在 0.6.0 之后无法编译

    contract OtherContract {
        uint x;
        function f(uint y) external {
            x = y;
        }
        function() payable external {}
    }

    contract New {
        OtherContract other;
        uint myNumber;

        // 必须指定函数可变性。
        function someInteger() internal pure returns (uint) { return 2; }

        // 必须指定函数可见性。
        // 必须指定函数可变性。
        function f(uint x) public returns (bytes memory) {
            // 现在必须显式给出类型。
            uint z = someInteger();
            x += z;
            // 抛出现在是不允许的。
            require(x <= 100);
            int y = -3 >> 1;
            require(y == -2);
            do {
                x += 1;
                if (x > 10) continue;
                // 'Continue' 跳转到下面的条件。
            } while (x < 11);

            // 调用返回 (bool, bytes)。
            // 必须指定数据位置。
            (bool success, bytes memory data) = address(other).call("f");
            if (!success)
                revert();
            return data;
        }

        using AddressMakePayable for address;
        // 'arr' 的数据位置必须指定
        function g(uint[] memory /* arr */, bytes8 x, OtherContract otherContract, address unknownContract) public payable {
            // 'otherContract.transfer' 未提供。
            // 由于 'OtherContract' 的代码是已知的并且有回退
            // 函数，address(otherContract) 的类型是 'address payable'。
            address(otherContract).transfer(1 ether);

            // 'unknownContract.transfer' 未提供。
            // 'address(unknownContract).transfer' 未提供
            // 因为 'address(unknownContract)' 不是 'address payable'。
            // 如果函数接受一个接收资金的 'address'，你可以通过 'uint160' 转换为 'address payable'。
            // 注意：这不推荐，应该尽可能使用显式类型 'address payable'。
            // 为了增加清晰度，我们建议使用库来进行转换（在本示例合约后提供）。
            address payable addr = unknownContract.makePayable();
            require(addr.send(1 ether));

            // 由于 uint32（4 字节）小于 bytes8（8 字节），不允许转换。
            // 我们需要先转换为相同的大小：
            bytes4 x4 = bytes4(x); // 填充发生在右侧
            uint32 y = uint32(x4); // 转换是一致的
            // 'msg.value' 不能在 'non-payable' 函数中使用。
            // 我们需要使函数可支付
            myNumber += y + msg.value;
        }
    }

    // 我们可以定义一个库来显式地将 ``address`` 转换为 ``address payable`` 作为解决方法。
    library AddressMakePayable {
        function makePayable(address x) internal pure returns (address payable) {
            return address(uint160(x));
        }
    }