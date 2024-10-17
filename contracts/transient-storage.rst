.. index:: ! 瞬态存储, ! 瞬态, tstore, tload

.. _transient-storage:

*****************
瞬态存储
*****************

瞬态存储是除了内存、存储、调用数据（以及返回数据和代码）之外的另一种数据位置，它与其各自的操作码 ``TSTORE`` 和 ``TLOAD`` 一起引入，参见 `EIP-1153 <https://eips.ethereum.org/EIPS/eip-1153>`_。
这种新的数据位置表现得像一个键值存储，类似于存储，主要区别在于瞬态存储中的数据不是永久的，而是仅限于当前交易的作用域，之后将重置为零。
由于瞬态存储的内容具有非常有限的生命周期和大小，因此不需要作为状态的一部分永久存储，并且相关的 gas 费用远低于存储的情况。
需要 EVM 版本 ``cancun`` 或更新版本才能使用瞬态存储。

瞬态存储变量不能在声明时初始化，即不能在声明时赋值，因为该值将在创建交易结束时被清除，从而使初始化无效。
瞬态变量将根据其底层类型进行 :ref:`默认值<default-value>` 初始化。
``constant`` 和 ``immutable`` 变量与瞬态存储冲突，因为它们的值要么是内联的，要么直接存储在代码中。

瞬态存储变量与存储具有完全独立的地址空间，因此瞬态状态变量的顺序不会影响存储状态变量的布局，反之亦然。
不过，它们需要不同的名称，因为所有状态变量共享相同的命名空间。
还需要注意的是，瞬态存储中的值以与持久存储中相同的方式打包。
有关更多信息，请参见 :ref:`存储布局 <storage-inplace-encoding>`。

此外，瞬态变量也可以具有可见性，``public`` 变量将像往常一样自动生成一个 getter 函数。

请注意，目前，作为数据位置的 ``transient`` 仅允许用于 :ref:`值类型 <value-types>` 状态变量声明。
引用类型，如数组、映射和结构体，以及局部或参数变量尚不支持。

瞬态存储的一个预期典型用例是更便宜的重入锁，这可以通过操作码轻松实现，如下所示。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.28;

    contract Generosity {
        mapping(address => bool) sentGifts;
        bool transient locked;

        modifier nonReentrant {
            require(!locked, "Reentrancy attempt");
            locked = true;
            _;
            // 解锁保护，使模式可组合。
            // 函数退出后，可以再次调用，即使在同一交易中。
            locked = false;
        }

        function claimGift() nonReentrant public {
            require(address(this).balance >= 1 ether);
            require(!sentGifts[msg.sender]);
            (bool success, ) = msg.sender.call{value: 1 ether}("");
            require(success);

            // 在重入函数中，最后这样做会打开漏洞
            sentGifts[msg.sender] = true;
        }
    }

瞬态存储对拥有它的合约是私有的，方式与持久存储相同。
只有拥有合约的帧可以访问其瞬态存储，当它们访问时，所有帧访问相同的瞬态存储。

瞬态存储是 EVM 状态的一部分，并受到与持久存储相同的可变性强制执行的约束。
因此，任何对它的读取访问都不是 ``pure``，写入访问也不是 ``view``。

如果在 ``STATICCALL`` 的上下文中调用 ``TSTORE`` 操作码，将导致异常，而不是执行修改。
在 ``STATICCALL`` 的上下文中允许使用 ``TLOAD``。

当在 ``DELEGATECALL`` 或 ``CALLCODE`` 的上下文中使用瞬态存储时，瞬态存储的拥有合约是发出 ``DELEGATECALL`` 或 ``CALLCODE`` 指令的合约（调用者），与持久存储相同。
当在 ``CALL`` 或 ``STATICCALL`` 的上下文中使用瞬态存储时，瞬态存储的拥有合约是 ``CALL`` 或 ``STATICCALL`` 指令的目标合约（被调用者）。

.. note::
    在 ``DELEGATECALL`` 的情况下，由于当前不支持对瞬态存储变量的引用，因此无法将其传递给库调用。
    在库中，访问瞬态存储只能通过内联汇编实现。

如果一个帧回滚，则在进入帧和返回之间对瞬态存储的所有写入都将被回滚，包括在内部调用中进行的写入。
外部调用的调用者可以使用 ``try ... catch`` 块来防止回滚从内部调用中冒泡。

*********************************************************************
智能合约的可组合性与瞬态存储的注意事项
*********************************************************************

鉴于 EIP-1153 规范中提到的注意事项，为了保持智能合约的可组合性，建议在更高级的瞬态存储用例中格外小心。

对于智能合约，可组合性是实现自包含行为的一个非常重要的设计原则，使得对单个智能合约的多次调用可以组合成更复杂的应用程序。
到目前为止，EVM 在很大程度上保证了可组合行为，因为在复杂交易中对智能合约的多次调用与在多个交易中对合约的多次调用在本质上是不可区分的。
然而，瞬态存储允许违反这一原则，不正确的使用可能导致复杂的错误，这些错误仅在跨多个调用时显现。

让我们用一个简单的例子来说明这个问题：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.28;

    contract MulService {
        uint transient multiplier;
        function setMultiplier(uint mul) external {
            multiplier = mul;
        }

        function multiply(uint value) external view returns (uint) {
            return value * multiplier;
        }
    }

以及一系列外部调用：

.. code-block:: solidity

    setMultiplier(42);
    multiply(1);
    multiply(2);

如果示例使用内存或存储来存储乘数，它将是完全可组合的。
无论是将序列拆分为单独的交易还是以某种方式将它们组合在一起，都没有关系。
总是会得到相同的结果：在 ``multiplier`` 设置为 ``42`` 后，后续调用将分别返回 ``42`` 和 ``84``。
这使得可以将来自多个交易的调用批量处理在一起以减少 gas 费用。
瞬态存储可能会破坏这样的用例，因为可组合性不再是理所当然的。
在这个例子中，如果调用不是在同一交易中执行的，则 ``multiplier`` 将被重置，后续对函数 ``multiply`` 的调用将始终返回 ``0``。

作为另一个例子，由于瞬态存储被构造为相对便宜的键值存储，智能合约作者可能会被诱使将瞬态存储用作内存映射的替代品，而不跟踪映射中修改的键，从而在调用结束时不清除映射。
然而，这可能会在复杂交易中导致意想不到的行为，其中在同一交易中对合约的先前调用设置的值仍然存在。
使用瞬态存储来处理在调用框架结束时清除的重入锁是安全的。  
然而，请务必抵制节省重入锁重置所需的 100 gas 的诱惑，因为不这样做将限制你的合约在一个交易中只能进行一次调用，从而阻止其在复杂组合交易中的使用，而复杂组合交易一直是链上复杂应用的基石。  

建议在调用智能合约结束时，通常始终完全清除瞬态存储，以避免此类问题，并简化对合约在复杂交易中行为的分析。  
有关更多详细信息，请查看 EIP-1153 的 `安全考虑` 部分 <https://eips.ethereum.org/EIPS/eip-1153#security-considerations>`_。