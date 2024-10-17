.. index:: ! using for, library, ! operator;user-defined, function;free

.. _using-for:

*********
Using For
*********

指令 ``using A for B`` 可用于将函数（``A``）作为运算符附加到用户定义的值类型或作为任何类型（``B``）的成员函数。
成员函数接收调用它们的对象作为第一个参数（类似于 Python 中的 ``self`` 变量）。运算符函数接收操作数作为参数。

它在文件级别或合约内部、合约级别都是有效的。

第一部分 ``A`` 可以是以下之一：

- 函数列表，选项上可以指定运算符名称（例如 ``using {f, g as +, h, L.t} for uint``）。如果未指定运算符，则该函数可以是库函数或自由函数，并作为成员函数附加到类型上。否则，它必须是自由函数，并成为该类型上运算符的定义。
- 库的名称（例如 ``using L for uint``） —— 库的所有非私有函数作为成员函数附加到该类型上。

在文件级别，第二部分 ``B`` 必须是显式类型（没有数据位置说明符）。
在合约内部，你也可以使用 ``*`` 代替类型（例如 ``using L for *;``），这将使库 ``L`` 的所有函数附加到 *所有* 类型上。

如果指定一个库，*所有* 非私有函数都会被附加，即使第一个参数的类型与对象的类型不匹配。类型在调用函数时进行检查，并执行函数重载解析。

如果使用函数列表（例如 ``using {f, g, h, L.t} for uint``），则类型（``uint``）必须可以隐式转换为这些函数的第一个参数。
即使这些函数没有被调用，也会执行此检查。请注意，私有库函数只能在 ``using for`` 在库内部时指定。

如果定义一个运算符（例如 ``using {f as +} for T``），则类型（``T``）必须是 :ref:`用户定义值类型 <user-defined-value-types>`，并且定义必须是 ``pure`` 函数。
运算符定义必须是全局的。
可以通过以下方式定义以下运算符：

+------------+----------+---------------------------------------------+
| Category   | Operator | Possible signatures                         |
+============+==========+=============================================+
| Bitwise    | ``&``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``|``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``^``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``~``    | ``function (T) pure returns (T)``           |
+------------+----------+---------------------------------------------+
| Arithmetic | ``+``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``-``    | ``function (T, T) pure returns (T)``        |
|            +          +---------------------------------------------+
|            |          | ``function (T) pure returns (T)``           |
|            +----------+---------------------------------------------+
|            | ``*``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``/``    | ``function (T, T) pure returns (T)``        |
|            +----------+---------------------------------------------+
|            | ``%``    | ``function (T, T) pure returns (T)``        |
+------------+----------+---------------------------------------------+
| Comparison | ``==``   | ``function (T, T) pure returns (bool)``     |
|            +----------+---------------------------------------------+
|            | ``!=``   | ``function (T, T) pure returns (bool)``     |
|            +----------+---------------------------------------------+
|            | ``<``    | ``function (T, T) pure returns (bool)``     |
|            +----------+---------------------------------------------+
|            | ``<=``   | ``function (T, T) pure returns (bool)``     |
|            +----------+---------------------------------------------+
|            | ``>``    | ``function (T, T) pure returns (bool)``     |
|            +----------+---------------------------------------------+
|            | ``>=``   | ``function (T, T) pure returns (bool)``     |
+------------+----------+---------------------------------------------+

请注意，单目和双目 ``-`` 需要单独的定义。编译器将根据运算符的调用方式选择正确的定义。

``using A for B;`` 指令仅在当前作用域内有效（无论是合约还是当前模块/源单元），包括其所有函数内，并且在使用它的合约或模块外没有效果。

当指令在文件级别使用并应用于在同一文件中以文件级别定义的用户定义类型时，可以在末尾添加单词 ``global``。
这将使得函数和运算符在类型可用的所有地方（包括其他文件）附加到该类型，而不仅仅是在使用语句的作用域内。

让我们以这种方式重写 :ref:`libraries` 部分中的集合示例，使用文件级函数而不是库函数。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.13;

    struct Data { mapping(uint => bool) flags; }
    // 现在我们将函数附加到类型上。
    // 附加的函数可以在模块的其余部分使用。
    // 如果你导入模块，你必须在那里重复使用指令，例如
    //   import "flags.sol" as Flags;
    //   using {Flags.insert, Flags.remove, Flags.contains}
    //     for Flags.Data;
    using {insert, remove, contains} for Data;

    function insert(Data storage self, uint value)
        returns (bool)
    {
        if (self.flags[value])
            return false; // 已经存在
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, uint value)
        returns (bool)
    {
        if (!self.flags[value])
            return false; // 不存在
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, uint value)
        view
        returns (bool)
    {
        return self.flags[value];
    }


    contract C {
        Data knownValues;

        function register(uint value) public {
            // 在这里，所有类型为 Data 的变量都有相应的成员函数。
            // 以下函数调用与 `Set.insert(knownValues, value)` 相同
            require(knownValues.insert(value));
        }
    }

以这种方式扩展内置类型也是可能的。在这个例子中，我们将使用一个库。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.13;

    library Search {
        function indexOf(uint[] storage self, uint value)
            public
            view
            returns (uint)
        {
            for (uint i = 0; i < self.length; i++)
                if (self[i] == value) return i;
            return type(uint).max;
        }
    }
    using Search for uint[];

    contract C {
        uint[] data;

        function append(uint value) public {
            data.push(value);
        }

        function replace(uint from, uint to) public {
            // 执行库函数调用
            uint index = data.indexOf(from);
            if (index == type(uint).max)
                data.push(to);
            else
                data[index] = to;
        }
    }

注意所有外部库调用都是实际的 EVM 函数调用。
这意味着如果你传递内存或值类型，将会执行复制，即使在 ``self`` 变量的情况下。
唯一不执行复制的情况是使用存储引用变量或调用内部库函数时。

另一个示例展示了如何为用户定义类型定义自定义运算符：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.19;

    type UFixed16x2 is uint16;

    using {
        add as +,
        div as /
    } for UFixed16x2 global;

    uint32 constant SCALE = 100;

    function add(UFixed16x2 a, UFixed16x2 b) pure returns (UFixed16x2) {
        return UFixed16x2.wrap(UFixed16x2.unwrap(a) + UFixed16x2.unwrap(b));
    }

    function div(UFixed16x2 a, UFixed16x2 b) pure returns (UFixed16x2) {
        uint32 a32 = UFixed16x2.unwrap(a);
        uint32 b32 = UFixed16x2.unwrap(b);
        uint32 result32 = a32 * SCALE / b32;
        require(result32 <= type(uint16).max, "Divide overflow");
        return UFixed16x2.wrap(uint16(a32 * SCALE / b32));
    }

    contract Math {
        function avg(UFixed16x2 a, UFixed16x2 b) public pure returns (UFixed16x2) {
            return (a + b) / UFixed16x2.wrap(200);
        }
    }