.. _inline-assembly:

###############
内联汇编
###############

.. index:: ! assembly, ! asm, ! evmasm

译者注：登链社区有一篇译文 `Solidity 中编写内联汇编(assembly)的那些事 <https://learnblockchain.cn/article/675>`_  推荐阅读。

你可以将 Solidity 语句与接近以太坊虚拟机语言的内联汇编交错使用。这为你提供了更细粒度的控制，特别是在通过编写库或优化 gas 使用来增强语言时非常有用。

Solidity 中用于内联汇编的语言称为 :ref:`Yul <yul>`，并在其自己的部分中进行了文档说明。本节将仅涵盖内联汇编代码如何与周围的 Solidity 代码接口。

.. 提示::
    内联汇编是一种以低级别访问以太坊虚拟机的方法。这绕过了 Solidity 的几个重要安全特性和检查。
    你应该仅在需要时使用它，并且只有在你对使用它有信心的情况下。

内联汇编块由 ``assembly { ... }`` 标记，其中大括号内的代码是 :ref:`Yul <yul>` 语言的代码。

内联汇编代码可以访问本地 Solidity 变量，如下所述。

不同的内联汇编块不共享命名空间，即无法调用在不同内联汇编块中定义的 Yul 函数或访问 Yul 变量。

示例
-------

以下示例提供了库代码，以访问另一个合约的代码并将其加载到 ``bytes`` 变量中。这在“原生 Solidity”中也可以通过使用 ``<address>.code`` 来实现。
但这里的重点是可重用的汇编库可以在不更改编译器的情况下增强 Solidity 语言。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    library GetCode {
        function at(address addr) public view returns (bytes memory code) {
            assembly {
                // 获取代码的大小，这需要使用汇编
                let size := extcodesize(addr)
                // 分配输出字节数组——这也可以在没有汇编的情况下完成
                // by using code = new bytes(size)
                code := mload(0x40)
                // 新的“内存结束”，包括填充
                mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                // 在内存中存储长度
                mstore(code, size)
                // 真正获取代码的大小，这需要使用汇编
                extcodecopy(addr, add(code, 0x20), 0, size)
            }
        }
    }

内联汇编在优化器未能生成高效代码的情况下也很有用，例如：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;


    library VectorSum {
        // 这个函数效率较低，因为优化器目前未能删除数组访问中的边界检查。
        function sumSolidity(uint[] memory data) public pure returns (uint sum) {
            for (uint i = 0; i < data.length; ++i)
                sum += data[i];
        }

        // 我们知道我们只在边界内访问数组，因此可以避免检查。
        // 0x20 需要加到数组上，因为第一个槽包含数组长度。
        function sumAsm(uint[] memory data) public pure returns (uint sum) {
            for (uint i = 0; i < data.length; ++i) {
                assembly {
                    sum := add(sum, mload(add(add(data, 0x20), mul(i, 0x20))))
                }
            }
        }

        // 与上述相同，但在内联汇编中完成整个代码。
        function sumPureAsm(uint[] memory data) public pure returns (uint sum) {
            assembly {
                // 加载长度（前 32 字节）
                let len := mload(data)

                // 跳过长度字段。
                //
                // 保留临时变量，以便可以就地递增。
                //
                // 注意：递增 data 会导致在此汇编块后 data 变量变得不可用
                let dataElementLocation := add(data, 0x20)

                // 迭代直到不满足边界。
                for
                    { let end := add(dataElementLocation, mul(len, 0x20)) }
                    lt(dataElementLocation, end)
                    { dataElementLocation := add(dataElementLocation, 0x20) }
                {
                    sum := add(sum, mload(dataElementLocation))
                }
            }
        }
    }

.. index:: selector; of a function

访问外部变量、函数和库
-----------------------------------------------------

你可以通过使用其名称访问 Solidity 变量和其他标识符。

值类型的本地变量可以直接在内联汇编中使用。它们可以被读取和赋值。

引用内存的本地变量评估为内存中变量的地址，而不是值本身。
这些变量也可以被赋值，但请注意，赋值只会更改指针而不会更改数据，并且你有责任遵守 Solidity 的内存管理。
请参见 :ref:`Conventions in Solidity <conventions-in-solidity>`。

同样，引用静态大小的 calldata 数组或 calldata 结构的本地变量评估为 calldata 中变量的地址，而不是值本身。
该变量也可以被赋值一个新的偏移量，但请注意，不会执行验证以确保该变量不会指向超出 ``calldatasize()`` 的位置。

对于外部函数指针，可以使用 ``x.address`` 和 ``x.selector`` 访问地址和函数选择器。
选择器由四个右对齐的字节组成。这两个值都可以被赋值。例如：

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.10 <0.9.0;

    contract C {
        // 将新的选择器和地址分配给返回变量 @fun
        function combineToFunctionPointer(address newAddress, uint newSelector) public pure returns (function() external fun) {
            assembly {
                fun.selector := newSelector
                fun.address  := newAddress
            }
        }
    }

对于动态 calldata 数组，你可以使用 ``x.offset`` 和 ``x.length`` 访问它们的 calldata 偏移量（以字节为单位）和长度（元素数量）。
这两个表达式也可以被赋值，但与静态情况一样，不会执行验证以确保结果数据区域在 ``calldatasize()`` 的范围内。

对于本地存储变量或状态变量（包括临时存储），单个 Yul 标识符是不够的，因为它们不一定占用单个完整的存储槽。
因此，它们的“地址”由槽和该槽内的字节偏移组成。要检索变量 ``x`` 指向的槽，你可以使用 ``x.slot``，要检索字节偏移量，你可以使用 ``x.offset``。
使用 ``x`` 本身将导致错误。

你还可以将本地存储变量指针的 ``.slot`` 部分赋值。对于这些（结构、数组或映射），``.offset`` 部分始终为零。
然而，无法将状态变量的 ``.slot`` 或 ``.offset`` 部分赋值。

本地 Solidity 变量可用于赋值，例如：

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.28 <0.9.0;

    // 这将发出一个警告
    contract C {
        bool transient a;
        uint b;
        function f(uint x) public returns (uint r) {
            assembly {
                // 我们忽略存储槽偏移量，我们知道在这个特殊情况下它是零
                r := mul(x, sload(b.slot))
                tstore(a.slot, true)
            }
        }
    }

.. 提示::
    如果你访问的变量类型少于 256 位（例如 ``uint64``、``address`` 或 ``bytes16``），
    你不能对不属于该类型编码的位做出任何假设。特别是，不要假设它们为零。
    为了安全起见，在你在重要的上下文中使用数据之前，始终正确清除数据：
    ``uint32 x = f(); assembly { x := and(x, 0xffffffff) /* 现在使用 x */ }``
    要清理有符号类型，你可以使用 ``signextend`` 操作码：
    ``assembly { signextend(<num_bytes_of_x_minus_one>, x) }``


自 Solidity 0.6.0 起，内联汇编变量的名称不能遮蔽内联汇编块作用域内可见的任何声明（包括变量、合约和函数声明）。

自 Solidity 0.7.0 起，在内联汇编块中声明的变量和函数不能包含 ``.``，但使用 ``.`` 来访问内联汇编块外的 Solidity 变量是有效的。

避免的事项
---------------

内联汇编可能看起来相当高级，但实际上它是非常低级别的语言。
函数调用、循环、条件语句和开关通过简单的重写规则转换，之后，
汇编器为你做的唯一事情就是重新排列函数式风格的操作码，计算变量访问的栈高度，并在其块结束时移除汇编局部变量的栈槽。

.. _conventions-in-solidity:

Solidity 中的约定
-----------------------

.. _assembly-typed-variables:

类型变量的值
=========================

与 EVM 汇编相比，Solidity 有比 256 位更窄的类型，例如 ``uint24``。
为了效率，大多数算术操作忽略类型可以短于 256 位的事实，并在必要时清除高位，即在写入内存或执行比较之前不久。
这意味着如果你从内联汇编中访问这样的变量，你可能需要手动先清除高位。

.. _assembly-memory-management:

内存管理
=================

Solidity 以以下方式管理内存。在内存中的位置 ``0x40`` 有一个“自由内存指针”。
如果你想分配内存，请使用从该指针指向的位置开始的内存并变更日志它。
没有保证内存之前没有被使用，因此你不能假设其内容为零字节。
没有内置机制来释放或释放已分配的内存。
以下是你可以用来分配内存的汇编代码片段，遵循上述过程：

.. code-block:: yul

    function allocate(length) -> pos {
      pos := mload(0x40)
      mstore(0x40, add(pos, length))
    }

内存的前 64 字节可以用作“临时空间”进行短期分配。
自由内存指针之后的 32 字节（即，从 ``0x60`` 开始）应永久保持为零，并用作空动态内存数组的初始值。
这意味着可分配的内存从 ``0x80`` 开始，这是自由内存指针的初始值。

Solidity 中内存数组的元素始终占用 32 字节的倍数（即使对于 ``bytes1[]`` 也是如此，但对于 ``bytes`` 和 ``string`` 则不是）。
多维内存数组是指向内存数组的指针。动态数组的长度存储在数组的第一个槽中，后面是数组元素。

.. 提示::
    静态大小的内存数组没有长度字段，但可能会在以后添加以允许在静态和动态大小数组之间更好地转换；因此，不要依赖于此。

内存安全
=============

在不使用内联汇编的情况下，编译器可以依赖内存始终保持在良好定义的状态。
这对于 :ref:`通过 Yul IR 的新代码生成管道 <ir-breaking-changes>` 特别相关：
这个代码生成路径可以将局部变量从栈移动到内存，以避免栈过深错误，并执行额外的内存优化，如果它可以依赖于某些关于内存使用的假设。

虽然我们建议始终尊重 Solidity 的内存模型，但内联汇编允许你以不兼容的方式使用内存。
因此，在存在任何包含内存操作的内联汇编块或在内存中分配给 Solidity 变量的情况下，默认情况下，移动栈变量到内存和额外的内存优化是全局禁用的。

然而，你可以特别注释一个汇编块，以指示它实际上遵循 Solidity 的内存模型，如下所示：

.. code-block:: solidity

    assembly ("memory-safe") {
        ...
    }

特别是，内存安全的汇编块只能访问以下内存范围：

- 你自己使用上述 ``allocate`` 函数描述的机制分配的内存。
- Solidity 分配的内存，例如你引用的内存数组的范围内的内存。
- 上述提到的内存偏移量 0 到 64 之间的临时空间。
- 位于内联汇编块开始时自由内存指针值 *之后* 的临时内存，即在自由内存指针处“分配”的内存，而不变更日志自由内存指针。

此外，如果汇编块在内存中分配给 Solidity 变量，你需要确保对Solidity 变量的访问仅访问这些内存范围。

由于这主要涉及优化器，因此即使汇编块回滚或终止，这些限制仍然需要遵循。
作为示例，以下汇编代码片段不是内存安全的，因为 ``returndatasize()`` 的值可能超过 64 字节的临时空间：

.. code-block:: solidity

    assembly {
      returndatacopy(0, 0, returndatasize())
      revert(0, returndatasize())
    }

另一方面，以下代码 *是* 内存安全的，因为超出自由内存指针指向的位置的内存可以安全地用作临时临时空间：

.. code-block:: solidity

    assembly ("memory-safe") {
      let p := mload(0x40)
      returndatacopy(p, 0, returndatasize())
      revert(p, returndatasize())
    }

请注意，如果没有后续分配，你不需要变更日志自由内存指针，
但你只能使用从自由内存指针给出的当前偏移量开始的内存。

如果内存操作使用零长度，使用任何偏移量也是可以的（不仅限于临时空间）：

.. code-block:: solidity

    assembly ("memory-safe") {
      revert(0, 0)
    }

请注意，不仅内联汇编中的内存操作可能不安全，内存中对引用类型的 Solidity 变量的赋值也可能不安全。
例如，以下代码不是内存安全的：

.. code-block:: solidity

    bytes memory x;
    assembly {
      x := 0x40
    }
    x[0x20] = 0x42;

内联汇编不涉及任何访问内存的操作，也不向内存中的任何 Solidity 变量赋值，自动被视为内存安全的，无需注释。

.. 提示::
    确保汇编确实满足内存模型是你的责任。如果你将一个汇编块注释为内存安全，但违反了内存假设，这 **将** 导致不正确和未定义的行为，且无法通过测试轻易发现。

如果你正在开发一个旨在与多个版本的 Solidity 兼容的库，可以使用特殊注释将汇编块标注为内存安全：

.. code-block:: solidity

    /// @solidity memory-safe-assembly
    assembly {
        ...
    }

请注意，我们将在未来的重大版本中禁止通过注释进行标注；因此，如果你不关心与旧编译器版本的向后兼容性，建议使用方言字符串。

内存的高级安全使用
---------------------------

超出上述内存安全的严格定义，有些情况下你可能希望使用超过 64 字节的临时空间，从内存偏移 ``0`` 开始。
如果你小心，可以在不包括偏移 ``0x80`` 的情况下使用内存，并仍然安全地将汇编块声明为 ``memory-safe``。
这在以下任一条件下是允许的：

- 在汇编块结束时，偏移 ``0x40`` 处的自由内存指针恢复到一个合理的值（即，它要么恢复到其原始值，要么由于手动内存分配而增加），并且偏移 ``0x60`` 处的内存字恢复为零值。

- 汇编块终止，即执行永远无法返回到高级 Solidity 代码。例如，如果你的汇编块无条件地以调用 ``revert`` 操作码结束，则是这种情况。

此外，你需要注意，Solidity 中动态数组的默认值指向内存偏移 ``0x60``，因此在临时更改内存偏移 ``0x60`` 处的值期间，你无法再依赖读取动态数组时获得准确的长度值，直到你恢复 ``0x60`` 处的零值。
更确切地说，只有在覆盖零指针时，我们才保证安全，如果汇编片段的其余部分不与高级 Solidity 对象的内存交互（包括读取先前存储在变量中的偏移）。