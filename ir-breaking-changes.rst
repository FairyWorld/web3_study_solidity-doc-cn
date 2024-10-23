.. index: ir breaking changes

.. _ir-breaking-changes:

*********************************
基于 Solidity IR 代码生成的变更
*********************************

Solidity 可以通过两种不同的方式生成 EVM 字节码：
要么直接从 Solidity 到 EVM 操作码（“旧代码生成”），要么通过中间表示（“IR”）在 Yul 中（“新代码生成”或“基于 IR 的代码生成”）。

基于 IR 的代码生成器的引入旨在不仅使代码生成更加透明和可审计，而且还能够启用跨函数的更强大的优化过程。

你可以通过命令行使用 ``--via-ir`` 或在 standard-json 中使用选项 ``{"viaIR": true}`` 来启用它，我们鼓励每个人尝试一下！

由于多种原因，旧代码生成器和基于 IR 的代码生成器之间存在微小的语义差异，主要是在我们不期望人们依赖这种行为的领域。
本节重点介绍旧代码生成器和基于 IR 的代码生成器之间的主要差异。

仅语义变更
=====================

本节列出了仅涉及语义的变更，因此可能会隐藏现有代码中的新行为和不同的行为。

.. _state-variable-initialization-order:

- 在继承的情况下，状态变量初始化的顺序发生了变化。

  以前的顺序是：

  - 所有状态变量在开始时都被零初始化。
  - 从最派生到最基础合约评估基构造函数参数。
  - 从最基础到最派生的整个继承层次结构中初始化所有状态变量。
  - 如果存在，则在从最基础到最派生的线性化层次结构中运行所有合约的构造函数。

  新顺序：

  - 所有状态变量在开始时都被零初始化。
  - 从最派生到最基础合约评估基构造函数参数。
  - 对于线性化层次结构中从最基础到最派生的每个合约：

      1. 初始化状态变量。
      2. 运行构造函数（如果存在）。

  这导致在某些合约中，状态变量的初始值依赖于另一个合约中构造函数的结果时出现差异：

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.7.1;

      contract A {
          uint x;
          constructor() {
              x = 42;
          }
          function f() public view returns(uint256) {
              return x;
          }
      }
      contract B is A {
          uint public y = f();
      }

  以前，``y`` 将被设置为 0。这是因为我们首先初始化状态变量：首先，``x`` 被设置为 0，当初始化 ``y`` 时，``f()`` 将返回 0，导致 ``y`` 也为 0。
  根据新规则，``y`` 将被设置为 42。我们首先将 ``x`` 初始化为 0，然后调用 A 的构造函数将 ``x`` 设置为 42。最后，当初始化 ``y`` 时，``f()`` 返回 42，导致 ``y`` 为 42。

- 当存储结构被删除时，包含结构成员的每个存储槽都将完全设置为零。以前，填充空间保持不变。
  因此，如果结构中的填充空间用于存储数据（例如，在合约升级的上下文中），你必须意识到 ``delete`` 现在也会清除添加的成员（而在过去不会被清除）。

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.7.1;

      contract C {
          struct S {
              uint64 y;
              uint64 z;
          }
          S s;
          function f() public {
              // ...
              delete s;
              // s 仅占用 32 字节槽的前 16 字节
              // delete 将写入零到整个槽
          }
      }

  对于隐式删除，我们有相同的行为，例如当结构数组被缩短时。

- 函数修改器在处理函数参数和返回变量时的实现方式略有不同。
  这尤其在修改器中多次评估占位符 ``_;`` 时产生影响。
  在旧代码生成器中，每个函数参数和返回变量在堆栈上都有一个固定的槽。
  如果函数因多次使用 ``_;`` 或在循环中运行多次，则函数参数或返回变量的值的更改在下一次执行函数时是可见的。
  新代码生成器使用实际函数实现修改器并传递函数参数。
  这意味着函数体的多次评估将获得相同的参数值，
  对返回变量的影响是它们在每次执行时都会重置为其默认（零）值。

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.7.0;
      contract C {
          function f(uint a) public pure mod() returns (uint r) {
              r = a++;
          }
          modifier mod() { _; _; }
      }

  如果你在旧代码生成器中执行 ``f(0)``，它将返回 ``1``，而在使用新代码生成器时将返回 ``0``。

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.7.1 <0.9.0;

      contract C {
          bool active = true;
          modifier mod()
          {
              _;
              active = false;
              _;
          }
          function foo() external mod() returns (uint ret)
          {
              if (active)
                  ret = 1; // 同 ``return 1``
          }
      }

  函数 ``C.foo()`` 返回以下值：

  - 旧代码生成器：``1``，因为返回变量在第一次 ``_;`` 评估之前仅初始化为 ``0``，然后被 ``return 1;`` 覆盖。
    它在第二次 ``_;`` 评估时没有再次初始化，且 ``foo()`` 也没有显式赋值（由于 ``active == false``），因此它保持其第一个值。
  - 新代码生成器：``0``，因为所有参数，包括返回参数，在每次 ``_;`` 评估之前都会重新初始化。

  .. index:: ! evaluation order; expression

- 对于旧代码生成器，表达式的评估顺序是未指定的。
  对于新代码生成器，我们尝试按源顺序（从左到右）进行评估，但不保证。
  这可能导致语义差异。

  例如：

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.8.1;
      contract C {
          function preincr_u8(uint8 a) public pure returns (uint8) {
              return ++a + a;
          }
      }

  函数 ``preincr_u8(1)`` 返回以下值：

  - 旧代码生成器：``3``（``1 + 2``），但返回值在一般情况下是未指定的
  - 新代码生成器：``4``（``2 + 2``），但返回值不保证

  .. index:: ! evaluation order; function arguments

  另一方面，函数参数表达式在两个代码生成器中以相同的顺序进行评估，唯一的例外是全局函数 ``addmod`` 和 ``mulmod``。
  例如：

  .. code-block:: solidity

      // SPDX-License-Identifier: GPL-3.0
      pragma solidity >=0.8.1;
      contract C {
          function add(uint8 a, uint8 b) public pure returns (uint8) {
              return a + b;
          }
          function g(uint8 a, uint8 b) public pure returns (uint8) {
              return add(++a + ++b, a + b);
          }
      }
函数 ``g(1, 2)`` 返回以下值：

- 旧代码生成器：``10`` (``add(2 + 3, 2 + 3)``)，但一般情况下返回值未指定
- 新代码生成器：``10``，但返回值不保证

全局函数 ``addmod`` 和 ``mulmod`` 的参数在旧代码生成器中是从右到左评估的，而在新代码生成器中是从左到右评估的。
例如：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.1;
    contract C {
        function f() public pure returns (uint256 aMod, uint256 mMod) {
            uint256 x = 3;
            // 旧代码生成：add/mulmod(5, 4, 3)
            // 新代码生成：add/mulmod(4, 5, 5)
            aMod = addmod(++x, ++x, x);
            mMod = mulmod(++x, ++x, x);
        }
    }

函数 ``f()`` 返回以下值：

- 旧代码生成器：``aMod = 0`` 和 ``mMod = 2``
- 新代码生成器：``aMod = 4`` 和 ``mMod = 0``

- 新代码生成器对自由内存指针施加了 ``type(uint64).max`` 的硬性限制 (``0xffffffffffffffff``)。
  任何会使其值超过此限制的分配都会回退。旧代码生成器没有此限制。

例如：

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >0.8.0;
    contract C {
        function f() public {
            uint[] memory arr;
            // 分配大小：576460752303423481
            // 假设 freeMemPtr 初始指向 0x80
            uint solYulMaxAllocationBeforeMemPtrOverflow = (type(uint64).max - 0x80 - 31) / 32;
            // freeMemPtr 溢出 UINT64_MAX
            arr = new uint[](solYulMaxAllocationBeforeMemPtrOverflow);
        }
    }

函数 ``f()`` 的行为如下：

- 旧代码生成器：在大内存分配后清零数组内容时耗尽 gas
- 新代码生成器：由于自由内存指针溢出而回退（不会耗尽 gas）


内部
=========

内部函数指针
--------------------------

.. index:: function pointers

旧代码生成器使用代码偏移量或标签作为内部函数指针的值。这尤其复杂，因为这些偏移量在构造时和部署后是不同的，并且这些值可以通过存储跨越这个边界。
因此，这两个偏移量在构造时被编码为同一个值（不同的字节）。

在新代码生成器中，函数指针使用按顺序分配的内部 ID。由于通过跳转调用是不可能的，因此通过函数指针的调用必须始终使用一个内部调度函数，该函数使用 ``switch`` 语句选择正确的函数。

ID ``0`` 被保留用于未初始化的函数指针，这会在调用时导致调度函数中的恐慌。

在旧代码生成器中，内部函数指针通过一个特殊函数初始化，该函数总是导致恐慌。
这会在构造时导致存储中内部函数指针的写入。

清理
-------

.. index:: cleanup, dirty bits

旧代码生成器仅在操作之前执行清理，该操作的结果可能会受到脏位值的影响。
新代码生成器在任何可能导致脏位的操作之后执行清理。
希望优化器能够强大到足以消除冗余的清理操作。

例如：

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.1;
    contract C {
        function f(uint8 a) public pure returns (uint r1, uint r2)
        {
            a = ~a;
            assembly {
                r1 := a
            }
            r2 = a;
        }
    }

函数 ``f(1)`` 返回以下值：

- 旧代码生成器： (``fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe``, ``00000000000000000000000000000000000000000000000000000000000000fe``)
- 新代码生成器： (``00000000000000000000000000000000000000000000000000000000000000fe``, ``00000000000000000000000000000000000000000000000000000000000000fe``)

请注意，与新代码生成器不同，旧代码生成器在位取反赋值（``a = ~a``）后不执行清理。
这导致在旧代码生成器和新代码生成器之间返回值 ``r1`` 的赋值不同（在内联汇编块内）。
然而，两个代码生成器在将新值赋值给 ``r2`` 之前都执行了清理。