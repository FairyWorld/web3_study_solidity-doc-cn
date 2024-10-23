.. index:: ! type;conversion, ! cast

.. _types-conversion-elementary-types:

基本类型之间的转换
====================

隐式转换
--------------------

隐式类型转换是在某些情况下由编译器自动应用的，例如在赋值时、将参数传递给函数时以及应用运算符时。
一般来说，如果语义上合理且没有信息丢失，则值类型之间可以进行隐式转换。

例如，``uint8`` 可以转换为 ``uint16``，而 ``int128`` 可以转换为 ``int256``，但 ``int8`` 不能转换为 ``uint256``，因为 ``uint256`` 不能表示如 ``-1`` 这样的值。

如果运算符应用于不同类型，编译器会尝试将其中一个操作数隐式转换为另一个操作数的类型（赋值时也是如此）。
这意味着操作总是在其中一个操作数的类型下执行。

有关可能的隐式转换的更多详细信息，请查阅关于类型本身的部分。

在下面的示例中，``y`` 和 ``z``，加法的操作数，类型不同，但 ``uint8`` 可以隐式转换为 ``uint16``，而反之则不行。
因此，在执行加法之前，``y`` 会被转换为 ``z`` 的类型，然后在 ``uint16`` 类型下进行加法。
表达式 ``y + z`` 的结果类型为 ``uint16``。
因为它被赋值给一个类型为 ``uint32`` 的变量，所以在加法后又进行了一个隐式转换。

.. code-block:: solidity

    uint8 y;
    uint16 z;
    uint32 x = y + z;


显式转换
--------------------

如果编译器不允许隐式转换，但你确信转换是可行的，有时可以进行显式类型转换。
这可能会导致意外行为，并允许你绕过编译器的一些安全特性，因此请确保测试结果是否符合你的预期！

以下示例将一个负的 ``int`` 转换为 ``uint``：

.. code-block:: solidity

    int  y = -3;
    uint x = uint(y);

在这段代码结束时，``x`` 的值将为 ``0xfffff..fd`` （64 个十六进制字符），这是 256 位二进制补码表示的 -3。

如果一个整数被显式转换为较小的类型，高位会被截断：

.. code-block:: solidity

    uint32 a = 0x12345678;
    uint16 b = uint16(a); // b 为 0x5678

如果一个整数被显式转换为较大的类型，它会在左侧填充（即在高位端）。
转换的结果将与原始整数相等：

.. code-block:: solidity

    uint16 a = 0x1234;
    uint32 b = uint32(a); // b 为 0x00001234
    assert(a == b);

定长字节数组类型在转换时表现不同。它们可以被视为单个字节的序列，转换为较小类型时会截断序列：

.. code-block:: solidity

    bytes2 a = 0x1234;
    bytes1 b = bytes1(a); // b 为 0x12

如果定长字节数组类型被显式转换为较大的类型，它会在右侧填充。
访问固定索引的字节在转换前后将得到相同的值（如果索引仍在范围内）：

.. code-block:: solidity

    bytes2 a = 0x1234;
    bytes4 b = bytes4(a); // b 为 0x12340000
    assert(a[0] == b[0]);
    assert(a[1] == b[1]);

由于整数和定长字节数组在截断或填充时表现不同，因此仅允许在两者大小相同的情况下进行整数与定长字节数组之间的显式转换。如果你想在不同大小的整数和定长字节数组之间进行转换，必须使用中间转换，使所需的截断和填充规则明确：

.. code-block:: solidity

    bytes2 a = 0x1234;
    uint32 b = uint16(a); // b 为 0x00001234
    uint32 c = uint32(bytes4(a)); // c 为 0x12340000
    uint8 d = uint8(uint16(a)); // d 为 0x34
    uint8 e = uint8(bytes1(a)); // e 为 0x12

``bytes`` 数组和 ``bytes`` calldata 切片可以显式转换为固定字节类型（``bytes1``/.../``bytes32``）。
如果数组的长度超过目标固定长度的 bytes 类型，则会在末尾截断。
如果数组的长度小于目标类型，则会在末尾用零填充。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.5;

    contract C {
        bytes s = "abcdefgh";
        function f(bytes calldata c, bytes memory m) public view returns (bytes16, bytes3) {
            require(c.length == 16, "");
            bytes16 b = bytes16(m);  // 如果 m 的长度大于 16，将会发生截断
            b = bytes16(s);  // 在右侧填充，因此结果是 "abcdefgh\0\0\0\0\0\0\0\0"
            bytes3 b1 = bytes3(s); // 截断，b1 等于 "abc"
            b = bytes16(c[:8]);  // 也用零填充
            return (b, b1);
        }
    }

.. index:: ! literal;conversion, literal;rational, literal;hexadecimal number
.. _types-conversion-literals:

字面量与基本类型之间的转换
=================================

整数类型
-------------

十进制和十六进制数字字面量可以隐式转换为任何足够大的整数类型，以便不发生截断：

.. code-block:: solidity

    uint8 a = 12; // 可行
    uint32 b = 1234; // 可行
    uint16 c = 0x123456; // 失败，因为它必须截断为 0x3456

.. note::
    在版本 0.8.0 之前，任何十进制或十六进制数字字面量都可以显式转换为整数类型。从 0.8.0 开始，这种显式转换与隐式转换一样严格，即仅在字面量适合结果范围时才允许。

.. index:: literal;string, literal;hexadecimal

定长字节数组
----------------------

十进制字面常量不能隐式转换为定长字节数组。十六进制字面常量可以是，但仅当十六进制数字大小完全符合定长字节数组长度。
不过零值例外，零的十进制和十六进制字面常量都可以转换为任何定长字节数组类型：
.. code-block:: solidity

    bytes2 a = 54321; // 不可行
    bytes2 b = 0x12; // 不可行
    bytes2 c = 0x123; // 不可行
    bytes2 d = 0x1234; // 可行
    bytes2 e = 0x0012; // 可行
    bytes4 f = 0; // 可行
    bytes4 g = 0x0; // 可行

字符串字面量和十六进制字符串字面量可以隐式转换为定长字节数组，如果它们的字符数小于或等于字节类型的大小：

.. code-block:: solidity

    bytes2 a = hex"1234"; // 可行
    bytes2 b = "xy"; // 可行
    bytes2 c = hex"12"; // 可行
    bytes2 e = "x"; // 可行
    bytes2 f = "xyz"; // 不可行

.. index:: literal;address

地址
---------

如 :ref:`address_literals` 中所述，正确大小的十六进制字面量通过校验和测试后为 ``address`` 类型。
没有其他字面量可以隐式转换为 ``address`` 类型。

显式转换为 ``address`` 仅允许从 ``bytes20`` 和 ``uint160``。

``address a`` 可以通过 ``payable(a)`` 显式转换为 ``address payable``。

.. note::
    在版本 0.8.0 之前，可以从任何整数类型（无论大小、带符号或无符号）显式转换为 ``address`` 或 ``address payable``。
    从 0.8.0 开始，仅允许从 ``uint160`` 进行转换。