.. include:: glossaries.rst

.. index:: ! type;reference, ! reference type, storage, memory, location, array, struct

.. _reference-types:

引用类型
===============

引用类型的值可以通过多个不同的名称进行修改。
与值类型形成对比，值类型在使用时会得到一个独立的副本。因此，引用类型的处理必须比值类型更为小心。
目前，引用类型包括结构体、数组和映射。
如果使用引用类型，必须明确提供存储该类型的数据区域：``memory`` （其生命周期仅限于外部函数调用）、``storage`` （存储状态变量的地点，其生命周期限于合约的生命周期）或 ``calldata`` （包含函数参数的特殊数据位置）。

任何改变数据位置的赋值或类型转换都会自动引发复制操作，而在同一数据位置内的赋值仅在某些情况下会对存储类型进行复制。

.. _data-location:

数据位置
-------------

每个引用类型都有一个额外的注释，即“数据位置”，用于指示其存储位置。
数据位置有三种：``memory``、``storage`` 和 ``calldata``。Calldata 是一个不可修改的、非持久的区域，用于存储函数参数，其行为大致类似于内存。

.. note::
    ``transient`` 目前尚不支持作为引用类型的数据位置。

.. note::
    如果可以，尽量使用 ``calldata`` 作为数据位置，因为这将避免复制并确保数据无法被修改。
    具有 ``calldata`` 数据位置的数组和结构体也可以从函数返回，但无法分配此类类型。

.. note::
    在版本 0.6.9 之前，引用类型参数的数据位置仅限于外部函数中的 ``calldata``、公共函数中的 ``memory``，以及内部和私有函数中的 ``memory`` 或 ``storage``。
    现在 ``memory`` 和 ``calldata`` 在所有函数中均被允许，无论其可见性如何。

.. note::
    在版本 0.5.0 之前，数据位置可以省略，并且会根据变量类型、函数类型等默认到不同的位置，但现在所有复杂类型必须明确给出数据位置。

.. _data-location-assignment:

数据位置与赋值行为
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

数据位置不仅与数据的持久性相关，还与赋值的语义相关：

* 在 ``storage`` 和 ``memory`` 之间（或从 ``calldata``）的赋值总是会创建一个独立的副本。
* 从 ``memory`` 到 ``memory`` 的赋值仅创建引用。这意味着对一个内存变量的更改在所有其他引用相同数据的内存变量中也是可见的。
* 从 ``storage`` 到 **本地** 存储变量的赋值也仅赋值一个引用。
* 所有其他对 ``storage`` 的赋值总是会复制。此类情况的示例包括对状态变量的赋值或对存储结构类型的本地变量成员的赋值，即使本地变量本身只是一个引用。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.0 <0.9.0;

    contract C {
        // x 的数据位置是 storage。
        // 这是唯一可以省略数据位置的地方。
        uint[] x;

        // memoryArray 的数据位置是 memory。
        function f(uint[] memory memoryArray) public {
            x = memoryArray; // 将整个数组复制到 storage，有效
            uint[] storage y = x; // 分配一个指针，y 的数据位置是 storage，有效
            y[7]; // 返回第 8 个元素
            y.pop(); // 通过 y 修改 x
            delete x; // 清空数组，也修改 y，
            // 以下操作无效；它需要在 storage 中创建新的未命名的临时数组，但 storage 是“静态”分配的：
            // y = memoryArray;
            // 同样，“delete y”也是无效的，因为对引用存储对象的本地变量的赋值只能从现有的存储对象进行。 
            // 它会“重置”指针，但没有合理的位置可以指向。
            // 有关更多详细信息，请参见“delete”运算符的文档。
            // delete y;
            g(x); // 调用 g，传递对 x 的引用
            h(x); // 调用 h，并在内存中创建一个独立的临时拷贝
        }

        function g(uint[] storage) internal pure {}
        function h(uint[] memory) public pure {}
    }

.. index:: ! array

.. _arrays:

数组
------

数组可以具有编译时固定大小，也可以具有动态大小。

固定大小为 ``k`` 且元素类型为 ``T`` 的数组类型写作 ``T[k]``，动态大小的数组写作 ``T[]``。

例如，5 个动态数组的 ``uint`` 数组写作``uint[][5]``。该表示法与某些其他语言相反。
在Solidity 中，``X[3]`` 始终是一个包含三个元素的类型为 ``X`` 的数组，即使 ``X`` 本身也是一个数组。这在其他语言（如 C）中并非如此。

索引是从零开始的，访问的方向与声明相反。

例如，如果你有一个变量 ``uint[][5] memory x``，你可以使用 ``x[2][6]`` 访问第三个动态数组中的第七个 ``uint``，要访问第三个动态数组，使用 ``x[2]``。
同样，如果你有一个类型为 ``T`` 的数组 ``T[5] a``，那么 ``a[2]`` 始终具有类型 ``T``。

数组元素可以是任何类型，包括映射或结构体。类型的一般限制适用，即映射只能存储在 ``storage`` 数据位置中，公开可见的函数需要参数为 :ref:`ABI types <ABI>`。

可以将状态变量数组标记为 ``public``，并让 Solidity 创建一个 :ref:`getter <visibility-and-getters>`。
数字索引成为 getter 的必需参数。

访问超出数组长度的元素会导致断言失败。
可以使用方法 ``.push()`` 和 ``.push(value)`` 在动态大小数组的末尾添加新元素，其中 ``.push()`` 会添加一个零初始化的元素并返回对其的引用。

.. note::
    动态大小数组只能在 storage 中调整大小。
    在内存中，此类数组可以具有任意大小，但一旦分配，大小无法更改。

.. index:: ! string, ! bytes

.. _strings:

.. _bytes:

``bytes`` 和 ``string`` 也是数组
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

类型为 ``bytes`` 和 ``string`` 的变量是特殊数组。
``bytes`` 类型类似于 ``bytes1[]``，但在 calldata 和内存中紧密打包。
``string`` 等同于 ``bytes``，但不允许长度或索引访问。

Solidity 没有字符串操作函数，但有第三方字符串库。你还可以通过它们的 keccak256 哈希比较两个字符串，
使用 ``keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2))`` 并使用 ``string.concat(s1, s2)`` 连接两个字符串。

你应该使用 ``bytes`` 而不是 ``bytes1[]``，因为它更便宜，因为在 ``memory`` 中使用 ``bytes1[]`` 会在元素之间添加 31 个填充字节。
请注意，在 ``storage`` 中，由于紧密打包，填充是不存在的，参见 :ref:`bytes and string <bytes-and-string>`。
一般来说，对于任意长度的原始字节数据使用 ``bytes``，对于任意长度的字符串（UTF-8）数据使用 ``string``。
如果可以将长度限制为一定数量的字节，始终使用值类型 ``bytes1`` 到 ``bytes32`` 中的一个，因为它们更便宜。

.. note::
    如果你想访问字符串 ``s`` 的字节表示，使用 ``bytes(s).length`` / ``bytes(s)[7] = 'x';``。
    请记住你正在访问 UTF-8 表示的低级字节，而不是单个字符。

.. index:: ! bytes-concat, ! string-concat

.. _bytes-concat:
.. _string-concat:

函数 ``bytes.concat`` 和 ``string.concat``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

你可以使用 ``string.concat`` 连接任意数量的 ``string`` 值。
该函数返回一个单一的 ``string memory`` 数组，包含参数的内容而不进行填充。
如果你想使用其他类型的参数，而这些类型不能隐式转换为 ``string``，你需要先将它们转换为 ``string``。

类似地，``bytes.concat`` 函数可以连接任意数量的 ``bytes`` 或 ``bytes1 ... bytes32`` 值。
该函数返回一个单一的 ``bytes memory`` 数组，包含参数的内容而不进行填充。
如果你想使用字符串参数或其他类型，而这些类型不能隐式转换为 ``bytes``，你需要先将它们转换为 ``bytes`` 或 ``bytes1``/.../``bytes32``。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.12;

    contract C {
        string s = "Storage";
        function f(bytes calldata bc, string memory sm, bytes16 b) public view {
            string memory concatString = string.concat(s, string(bc), "Literal", sm);
            assert((bytes(s).length + bc.length + 7 + bytes(sm).length) == bytes(concatString).length);

            bytes memory concatBytes = bytes.concat(bytes(s), bc, bc[:2], "Literal", bytes(sm), b);
            assert((bytes(s).length + bc.length + 2 + 7 + bytes(sm).length + b.length) == concatBytes.length);
        }
    }

如果你调用 ``string.concat`` 或 ``bytes.concat`` 而不带参数，它们将返回一个空数组。

.. index:: ! array;allocating, new

分配内存数组
^^^^^^^^^^^^^^^^^^^^^^^^

可以使用 ``new`` 操作符创建动态长度的内存数组。
与存储数组不同，内存数组 **不能** 调整大小（例如，``.push`` 成员函数不可用）。
你必须提前计算所需的大小或创建一个新的内存数组并复制每个元素。

与 Solidity 中的所有变量一样，新分配数组的元素始终初始化为 :ref:`default value<default-value>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        function f(uint len) public pure {
            uint[] memory a = new uint[](7);
            bytes memory b = new bytes(len);
            assert(a.length == 7);
            assert(b.length == len);
            a[6] = 8;
        }
    }

.. index:: ! literal;array, ! inline;arrays

数组字面量
^^^^^^^^^^^^^^

数组字面量是一个用逗号分隔的一个或多个表达式的列表，括在方括号中（``[...]``）。例如 ``[1, a, f(3)]``。
数组字面量的类型如下确定：

它始终是一个静态大小的内存数组，其长度为表达式的数量。

数组的基本类型是列表中第一个表达式的类型，以便所有其他表达式可以隐式转换为它。如果不能转换，则会出现类型错误。

仅仅有一个类型可以转换为所有元素是不够的。列表中的一个元素必须是该类型。

在下面的示例中，``[1, 2, 3]`` 的类型是 ``uint8[3] memory``，因为这些常量的类型都是 ``uint8``。
如果你希望结果为 ``uint[3] memory`` 类型，你需要将第一个元素转换为 ``uint``。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        function f() public pure {
            g([uint(1), 2, 3]);
        }
        function g(uint[3] memory) public pure {
            // ...
        }
    }

数组字面量 ``[1, -1]`` 是无效的，因为第一个表达式的类型是 ``uint8``，而第二个的类型是 ``int8``，它们不能相互隐式转换。
要使其有效，你可以使用 ``[int8(1), -1]``，例如。

由于不同类型的固定大小内存数组不能相互转换（即使基本类型可以），如果你想使用二维数组字面量，你总是必须显式指定一个共同的基本类型：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        function f() public pure returns (uint24[2][4] memory) {
            uint24[2][4] memory x = [[uint24(0x1), 1], [0xffffff, 2], [uint24(0xff), 3], [uint24(0xffff), 4]];
            // 以下代码无效，因为某些内部数组的类型不正确。
            // uint[2][4] memory x = [[0x1, 1], [0xffffff, 2], [0xff, 3], [0xffff, 4]];
            return x;
        }
    }

固定大小的内存数组不能赋值给动态大小的内存数组，即以下代码是不可行的：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    // 这将无法编译。
    contract C {
        function f() public {
            // 下一行会产生类型错误，因为 uint[3] memory
            // 不能转换为 uint[] memory。
            uint[] memory x = [uint(1), 3, 4];
        }
    }

计划在未来删除此限制，但由于数组在 ABI 中的传递方式，这会带来一些复杂性。

如果你想初始化动态大小的数组，你必须逐个赋值：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        function f() public pure {
            uint[] memory x = new uint[](3);
            x[0] = 1;
            x[1] = 3;
            x[2] = 4;
        }
    }

.. index:: ! array;length, length, push, pop, !array;push, !array;pop

.. _array-members:

数组成员
^^^^^^^^^^^^^

**length**:
    数组有一个 ``length`` 成员，包含其元素的数量。
    内存数组的长度是固定的（但动态的，即可以依赖于运行时参数），一旦创建就不能更改。
**push()**:
     动态存储数组和 ``bytes`` （不是 ``string``）有一个成员函数叫做 ``push()``，你可以用它在数组末尾附加一个零初始化的元素。
     它返回对该元素的引用，因此可以像 ``x.push().t = 2`` 或 ``x.push() = b`` 一样使用。
**push(x)**:
     动态存储数组和 ``bytes`` （不是 ``string``）有一个成员函数叫做 ``push(x)``，你可以用它在数组末尾附加一个给定的元素。
     该函数不返回任何内容。
**pop()**:
     动态存储数组和 ``bytes`` （不是 ``string``）有一个成员函数叫做 ``pop()``，你可以用它从数组末尾移除一个元素。
     这也会隐式调用 :ref:`delete<delete>` 来删除被移除的元素。该函数不返回任何内容。

.. note::
    通过调用 ``push()`` 增加存储数组的长度具有恒定的 gas 成本，因为存储总是被零初始化，而通过调用 ``pop()`` 减少长度的成本取决于被移除元素的“大小”。
    如果该元素是一个数组，成本可能非常高，因为它包括显式清除被移除元素，类似于调用 :ref:`delete<delete>`。

.. note::
    要在外部（而不是公共）函数中使用数组的数组，你需要激活 ABI 编码器 v2。

.. note::
    在 Byzantium 之前的 EVM 版本中，无法访问从函数调用返回的动态数组。如果你调用返回动态数组的函数，请确保使用设置为 Byzantium 模式的 EVM。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract ArrayContract {
        uint[2**20] aLotOfIntegers;
        // 请注意，以下内容不是一对动态数组，
        // 而是一个对的动态数组（即固定大小为二的数组）。
        // 在 Solidity 中，T[k] 和 T[] 始终是元素类型为 T 的数组，即使 T 本身是一个数组。
        // 因此，bool[2][] 是一个动态数组，其元素是 bool[2]。
        // 这与其他语言（如 C）不同。
        // 所有状态变量的数据位置为存储。
        bool[2][] pairsOfFlags;

        // newPairs 存储在内存中
        function setAllFlagPairs(bool[2][] memory newPairs) public {
            // 对存储数组的赋值会复制 ``newPairs`` 并替换完整的数组 ``pairsOfFlags``。
            pairsOfFlags = newPairs;
        }

        struct StructType {
            uint[] contents;
            uint moreInfo;
        }
        StructType s;

        function f(uint[] memory c) public {
            // 将对 ``s`` 的引用存储在 ``g`` 中
            StructType storage g = s;
            // 也会改变 ``s.moreInfo``。
            g.moreInfo = 2;
            // 赋值为副本，因为 ``g.contents`` 不是局部变量，而是局部变量的成员。
            g.contents = c;
        }

        function setFlagPair(uint index, bool flagA, bool flagB) public {
            // 访问不存在的索引将抛出异常
            pairsOfFlags[index][0] = flagA;
            pairsOfFlags[index][1] = flagB;
        }

        function changeFlagArraySize(uint newSize) public {
            // 使用 push 和 pop 是唯一改变数组长度的方法
            if (newSize < pairsOfFlags.length) {
                while (pairsOfFlags.length > newSize)
                    pairsOfFlags.pop();
            } else if (newSize > pairsOfFlags.length) {
                while (pairsOfFlags.length < newSize)
                    pairsOfFlags.push();
            }
        }

        function clear() public {
            // 这些会完全清空数组
            delete pairsOfFlags;
            delete aLotOfIntegers;
            // 这里的效果相同
            pairsOfFlags = new bool[2][](0);
        }

        bytes byteData;

        function byteArrays(bytes memory data) public {
            // 字节数组（"bytes"）不同，因为它们存储时没有填充，
            // 但可以被视为与 uint8 [] 相同
            byteData = data;
            for (uint i = 0; i < 7; i++)
                byteData.push();
            byteData[3] = 0x08;
            delete byteData[2];
        }

        function addFlag(bool[2] memory flag) public returns (uint) {
            pairsOfFlags.push(flag);
            return pairsOfFlags.length;
        }

        function createMemoryArray(uint size) public pure returns (bytes memory) {
            // 动态内存数组使用 `new` 创建：
            uint[2][] memory arrayOfPairs = new uint[2][](size);

            // 内联数组始终是静态大小的，如果你只使用字面量，则必须提供至少一种类型。
            arrayOfPairs[0] = [uint(1), 2];

            // 创建一个动态字节数组：
            bytes memory b = new bytes(200);
            for (uint i = 0; i < b.length; i++)
                b[i] = bytes1(uint8(i));
            return b;
        }
    }


.. index:: ! array;dangling storage references

悬空的存储数组元素引用
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

在处理存储数组时，你需要注意避免悬空引用。
悬空引用是指指向不再存在或已移动而未更新引用的内容的引用。
例如，如果你将对数组元素的引用存储在局部变量中，然后从包含数组中 ``.pop()``，则可能会发生悬空引用：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0 <0.9.0;

    contract C {
        uint[][] s;

        function f() public {
            // 存储对 s 的最后一个数组元素的指针。
            uint[] storage ptr = s[s.length - 1];
            // 移除 s 的最后一个数组元素。
            s.pop();
            // 写入不再在数组中的数组元素。
            ptr.push(0x42);
            // 现在向 ``s`` 添加新元素不会添加空数组，
            // 而是会导致长度为 1 的数组，其元素为 ``0x42``。
            s.push();
            assert(s[s.length - 1][0] == 0x42);
        }
    }

在 ``ptr.push(0x42)`` 中的写入将 **不会** 回滚，尽管 ``ptr`` 不再指向 ``s`` 的有效元素。
由于编译器假设未使用的存储始终为零，因此后续的 ``s.push()`` 不会显式地将零写入存储，因此 ``s`` 的最后一个元素在那次 ``push()`` 之后将具有长度 ``1``，并且其第一个元素为 ``0x42``。

请注意，Solidity 不允许在存储中声明对值类型的引用。这些类型的显式悬空引用仅限于嵌套引用类型。
然而，当使用复杂表达式进行元组赋值时，悬空引用也可能会暂时发生：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0 <0.9.0;

    contract C {
        uint[] s;
        uint[] t;
        constructor() {
            // 向存储数组推送一些初始值。
            s.push(0x07);
            t.push(0x03);
        }

        function g() internal returns (uint[] storage) {
            s.pop();
            return t;
        }

        function f() public returns (uint[] memory) {
            // 以下将首先评估 ``s.push()`` 为对索引 1 处的新元素的引用。
            // 之后，对 ``g`` 的调用弹出这个新元素，导致最左边的元组元素变为悬空引用。
            // 赋值仍然发生，并将写入 ``s`` 的数据区域之外。
            (s.push(), g()[0]) = (0x42, 0x17);
            // 随后的对 ``s`` 的推送将揭示前一个句写入的值，
            // 语即在此函数结束时 ``s`` 的最后一个元素将具有值 ``0x42``。
            s.push();
            return s;
        }
    }

在每个语句中仅对存储进行一次赋值，并避免在赋值的左侧使用复杂表达式总是更安全。

在处理对 ``bytes`` 数组元素的引用时，你需要特别小心，因为对字节数组的 ``.push()`` 可能会在存储中切换 :ref:`从短到长布局<bytes-and-string>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0 <0.9.0;

    // 这将发出一个警告
    contract C {
        bytes x = "012345678901234567890123456789";

        function test() external returns(uint) {
            (x.push(), x.push()) = (0x01, 0x02);
            return x.length;
        }
    }

这里，当第一个 ``x.push()`` 被评估时，``x`` 仍然以短布局存储，因此 ``x.push()`` 返回对 ``x`` 的第一个存储槽中元素的引用。
然而，第二个 ``x.push()`` 切换了字节数组到大布局。
现在 ``x.push()`` 所引用的元素在数组的数据区域，而引用仍然指向其原始位置，该位置现在是长度字段的一部分，赋值将有效地混淆 ``x`` 的长度。
为了安全起见，在单个赋值期间仅将字节数组扩大最多一个元素，并且不要在同一语句中同时索引访问数组。

虽然上述描述了当前版本编译器中悬空存储引用的行为，但任何具有悬空引用的代码都应被视为 *未定义行为*。
特别是，这意味着未来的任何编译器版本可能会改变涉及悬空引用的代码的行为。

确保在代码中避免悬空引用！

.. index:: ! array;slice

.. _array-slices:

数组切片
------------

数组切片是对数组连续部分的视图。
它们写作 ``x[start:end]``，其中 ``start`` 和 ``end`` 是结果为 uint256 类型（或隐式可转换为它）的表达式。
切片的第一个元素是 ``x[start]``，最后一个元素是 ``x[end - 1]``。

如果 ``start`` 大于 ``end`` 或 ``end`` 大于数组的长度，将抛出异常。

``start`` 和 ``end`` 都是可选的：``start`` 默认为 ``0``，``end`` 默认为数组的长度。

数组切片没有任何成员。它们隐式可转换为其基础类型的数组并支持索引访问。
索引访问不是在基础数组中的绝对位置，而是相对于切片的起始位置。

数组切片没有类型名称，这意味着没有变量可以将数组切片作为类型，它们仅存在于中间表达式中。

.. note::
    目前，数组切片仅可使用于 calldata 数组。

数组切片对于 ABI 解码通过函数参数传递的二级数据非常有用：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.5 <0.9.0;
    contract Proxy {
        /// @dev 由代理管理的客户端合约的地址，即此合约
        address client;

        constructor(address client_) {
            client = client_;
        }

        /// 转发调用到由客户端实现的 "setOwner(address)"，
        /// 在对地址参数进行基本验证后。
        function forward(bytes calldata payload) external {
            bytes4 sig = bytes4(payload[:4]);
            // 由于截断行为，与 bytes4(payload) 的表现是相同的。
            // bytes4 sig = bytes4(payload);
            if (sig == bytes4(keccak256("setOwner(address)"))) {
                address owner = abi.decode(payload[4:], (address));
                require(owner != address(0), "Address of owner cannot be zero.");
            }
            (bool status,) = client.delegatecall(payload);
            require(status, "Forwarded call failed.");
        }
    }

.. index:: ! struct, ! type;struct

.. _structs:

结构体
-------

Solidity 提供了一种以结构体形式定义新类型的方法，示例如下：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    // 定义一个具有两个字段的新类型。
    // 在合约外部声明结构体允许它被多个合约共享。
    // 在这里，这并不是必需的。
    struct Funder {
        address addr;
        uint amount;
    }

    contract CrowdFunding {
        // 结构体也可以在合约内部定义，这使得它们仅在此处和派生合约中可见。
        struct Campaign {
            address payable beneficiary;
            uint fundingGoal;
            uint numFunders;
            uint amount;
            mapping(uint => Funder) funders;
        }

        uint numCampaigns;
        mapping(uint => Campaign) campaigns;

        function newCampaign(address payable beneficiary, uint goal) public returns (uint campaignID) {
            campaignID = numCampaigns++; // campaignID 作为一个变量返回
            // 不能使用 "campaigns[campaignID] = Campaign(beneficiary, goal, 0, 0)"
            // 因为右侧创建了一个包含映射的内存结构 "Campaign"。
            Campaign storage c = campaigns[campaignID];
            c.beneficiary = beneficiary;
            c.fundingGoal = goal;
        }

        function contribute(uint campaignID) public payable {
            Campaign storage c = campaigns[campaignID];
            // 创建一个新的临时内存结构，使用给定值初始化
            // 并将其复制到存储中。
            // 注意，你也可以使用 Funder(msg.sender, msg.value) 进行初始化。
            c.funders[c.numFunders++] = Funder({addr: msg.sender, amount: msg.value});
            c.amount += msg.value;
        }

        function checkGoalReached(uint campaignID) public returns (bool reached) {
            Campaign storage c = campaigns[campaignID];
            if (c.amount < c.fundingGoal)
                return false;
            uint amount = c.amount;
            c.amount = 0;
            c.beneficiary.transfer(amount);
            return true;
        }
    }

该合约并未提供众筹合约的完整功能，但它包含理解结构体所需的基本概念。
结构体类型可以在映射和数组中使用，并且它们本身可以包含映射和数组。

结构体不能包含其自身类型的成员，尽管结构体本身可以是映射成员的值类型或可以包含其类型的动态大小数组。
此限制是必要的，因为结构体的大小必须是有限的。

注意在所有函数中，结构体类型被分配给数据位置为 ``storage`` 的局部变量。
这并不会复制结构体，而只是存储一个引用，以便对局部变量成员的赋值实际上写入状态。

当然，你也可以直接访问结构体的成员，而无需将其分配给局部变量，如
``campaigns[campaignID].amount = 0``。

.. note::
    在 Solidity 0.7.0 之前，允许包含存储仅类型成员（例如映射）的内存结构，
    并且上述示例中的赋值 ``campaigns[campaignID] = Campaign(beneficiary, goal, 0, 0)``将有效并且会默默跳过这些成员。