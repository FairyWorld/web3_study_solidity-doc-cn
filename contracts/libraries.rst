.. index:: ! library, callcode, delegatecall

.. _libraries:

*********
库
*********

库类似于合约，但它们的目的是仅在特定地址上部署一次，并通过 EVM 的 ``DELEGATECALL`` （在 Homestead 之前为 ``CALLCODE``）功能重用其代码。
这意味着如果调用库函数，其代码将在调用合约的上下文中执行，即 ``this`` 指向调用合约，特别是可以访问调用合约的存储。
由于库是一个独立的源代码片段，它只能访问调用合约的状态变量，前提是这些变量被显式提供（否则它将无法命名它们）。
库函数只能直接调用（即不使用 ``DELEGATECALL``），如果它们不修改状态（即如果它们是 ``view`` 或 ``pure`` 函数），因为库被假定为无状态。特别一点是，库库不能被销毁。

.. note::
    在 0.4.20 版本之前，可以通过规避 Solidity 的类型系统来销毁库。从该版本开始，库包含一个 :ref:`机制<call-protection>`，禁止直接调用状态修改函数（即不使用 ``DELEGATECALL``）。

库可以被视为使用它们的合约的隐式基合约。它们不会在继承层次结构中显式可见，但对库函数的调用看起来就像对显式基合约的函数的调用（使用合格访问，如 ``L.f()``）。
当然，对内部函数的调用使用内部调用约定，这意味着所有内部类型可以传递，类型 :ref:`存储在内存中 <data-location>` 将按引用传递而不是复制。
为了在 EVM 中实现这一点，从合约调用的内部库函数的代码以及从其中调用的所有函数将在编译时包含在调用合约中，并将使用常规的 ``JUMP`` 调用而不是 ``DELEGATECALL``。

.. note::
    当涉及到公共函数时，继承类比会失效。
    使用 ``L.f()`` 调用公共库函数会导致外部调用（准确地说是 ``DELEGATECALL``）。
    相反，当 ``A`` 是当前合约的基合约时，``A.f()`` 是内部调用。

.. index:: using for, set

以下示例说明了如何使用库（但使用手动方法，确保查看 :ref:`using for <using-for>` 以获取更高级的实现集合的示例）。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;


    // 我们定义一个新的结构数据类型，将用于在调用合约中保存其数据。
    struct Data {
        mapping(uint => bool) flags;
    }

    library Set {
        // 注意，第一个参数是“存储引用”类型，因此仅其存储地址而不是其内容作为调用的一部分传递。
        // 这是库函数的一个特殊特性。如果函数可以被视为该对象的方法，通常将第一个参数称为 `self`。
        function insert(Data storage self, uint value)
            public
            returns (bool)
        {
            if (self.flags[value])
                return false; // 已经存在
            self.flags[value] = true;
            return true;
        }

        function remove(Data storage self, uint value)
            public
            returns (bool)
        {
            if (!self.flags[value])
                return false; // 不存在
            self.flags[value] = false;
            return true;
        }

        function contains(Data storage self, uint value)
            public
            view
            returns (bool)
        {
            return self.flags[value];
        }
    }


    contract C {
        Data knownValues;

        function register(uint value) public {
            // 可以在没有特定库实例的情况下调用库函数，因为“实例”将是当前合约。
            require(Set.insert(knownValues, value));
        }
        // 在这个合约中，如果需要，我们也可以直接访问 knownValues.flags。
    }

当然，不必遵循这种方式来使用库：它们也可以在不定义结构数据类型的情况下使用。
函数也可以在没有任何存储引用参数的情况下工作，并且可以有多个存储引用参数，并且可以在任何位置。

对 ``Set.contains``、``Set.insert`` 和 ``Set.remove`` 的调用都被编译为对外部合约/库的调用（``DELEGATECALL``）。
如果使用库，请注意会执行实际的外部函数调用。
尽管如此，``msg.sender``、``msg.value`` 和 ``this`` 在此调用中将保留其值（在 Homestead 之前，由于使用 ``CALLCODE``，``msg.sender`` 和 ``msg.value`` 会发生变化）。

以下示例展示了如何使用 :ref:`存储在内存中的类型 <data-location>` 和库中的内部函数，以实现自定义类型而不增加外部函数调用的开销：

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.0;

    struct bigint {
        uint[] limbs;
    }

    library BigInt {
        function fromUint(uint x) internal pure returns (bigint memory r) {
            r.limbs = new uint[](1);
            r.limbs[0] = x;
        }

        function add(bigint memory a, bigint memory b) internal pure returns (bigint memory r) {
            r.limbs = new uint[](max(a.limbs.length, b.limbs.length));
            uint carry = 0;
            for (uint i = 0; i < r.limbs.length; ++i) {
                uint limbA = limb(a, i);
                uint limbB = limb(b, i);
                unchecked {
                    r.limbs[i] = limbA + limbB + carry;

                    if (limbA + limbB < limbA || (limbA + limbB == type(uint).max && carry > 0))
                        carry = 1;
                    else
                        carry = 0;
                }
            }
            if (carry > 0) {
                // 太糟糕了，我们必须添加一个 limb
                uint[] memory newLimbs = new uint[](r.limbs.length + 1);
                uint i;
                for (i = 0; i < r.limbs.length; ++i)
                    newLimbs[i] = r.limbs[i];
                newLimbs[i] = carry;
                r.limbs = newLimbs;
            }
        }

        function limb(bigint memory a, uint index) internal pure returns (uint) {
            return index < a.limbs.length ? a.limbs[index] : 0;
        }

        function max(uint a, uint b) private pure returns (uint) {
            return a > b ? a : b;
        }
    }

    contract C {
        using BigInt for bigint;

        function f() public pure {
            bigint memory x = BigInt.fromUint(7);
            bigint memory y = BigInt.fromUint(type(uint).max);
            bigint memory z = x.add(y);
            assert(z.limb(1) > 0);
        }
    }

可以通过将库类型转换为 ``address`` 类型来获取库的地址，即使用 ``address(LibraryName)``。

由于编译器不知道库将被部署到的地址，编译后的十六进制代码将包含形式为 ``__$30bbc0abd4d6364515865950d3e0d10953$__`` 的占位符 `(格式在 <v0.5.0) <https://docs.soliditylang.org/en/v0.4.26/contracts.html#libraries>`_。
占位符是完全限定库名称的 keccak256 哈希的十六进制编码的 34 个字符前缀，例如，如果库存储在名为 ``bigint.sol`` 的文件中的 ``libraries/`` 目录下，则为 ``libraries/bigint.sol:BigInt``。
这样的字节码是不完整的，不应被部署。占位符需要被实际地址替换。
可以通过在编译库时将它们传递给编译器，或者使用链接器更新已编译的二进制文件来做到这一点。
有关如何使用命令行编译器进行链接的信息，请参见 :ref:`library-linking`。
与合约相比，库在以下方面受到限制：

- 它们不能有状态变量
- 它们不能继承，也不能被继承
- 它们不能接收以太币
- 它们不能被销毁

（这些限制可能在以后被解除。）

.. _library-selectors:
.. index:: ! selector; of a library function

库的函数签名和选择器
==========================

虽然可以对公共或外部库函数进行外部调用，但此类调用的调用约定被认为是 Solidity 内部的，与常规的 :ref:`contract ABI<ABI>` 中规定的不同。
外部库函数支持比外部合约函数更多的参数类型，例如递归结构和存储指针。
因此，用于计算 4 字节选择器的函数签名是根据内部命名方案计算的，而在合约 ABI 中不支持的参数类型使用内部编码。

以下标识符用于签名中的类型：

- 值类型、非存储的 ``string`` 和非存储的 ``bytes`` 使用与合约 ABI 中相同的标识符。
- 非存储数组类型遵循与合约 ABI 中相同的约定，即动态数组为 ``<type>[]``，固定大小数组为 ``<type>[M]``，其中 ``M`` 为元素个数。
- 非存储结构通过其完全限定名引用，即 ``C.S`` 表示 ``contract C { struct S { ... } }``。
- 存储指针映射使用 ``mapping(<keyType> => <valueType>) storage``，其中 ``<keyType>`` 和 ``<valueType>`` 分别是映射的键和值类型的标识符。
- 其他存储指针类型使用其对应非存储类型的类型标识符，但在其后附加一个空格和 ``storage``。

参数编码与常规合约 ABI 相同，存储指针的编码为一个 ``uint256`` 值，指向它们所指向的存储槽。

与合约 ABI 类似，选择器由签名的 Keccak256 哈希的前四个字节组成。
其值可以通过 Solidity 使用 ``.selector`` 成员获得，如下所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.5.14 <0.9.0;

    library L {
        function f(uint256) external {}
    }

    contract C {
        function g() public pure returns (bytes4) {
            return L.f.selector;
        }
    }



.. _call-protection:

库的调用保护
=================

如前言所述，如果库的代码使用 ``CALL`` 而不是 ``DELEGATECALL`` 或 ``CALLCODE`` 执行，它将会回退，除非调用的是 ``view`` 或 ``pure`` 函数。

EVM 并没有提供合约直接检测是否使用 ``CALL`` 调用的方式，但合约可以使用 ``ADDRESS`` 操作码来找出“它”当前运行的位置。
生成的代码将此地址与构造时使用的地址进行比较，以确定调用模式。

更具体地说，库的运行时代码总是以一个推送指令开始，该指令在编译时是一个 20 字节的零。
当部署代码运行时，这个常量在内存中被当前地址替换，并且这个修改后的代码被存储在合约中。
在运行时，这导致部署时的地址成为第一个被推送到栈上的常量，调度代码将当前地址与此常量进行比较，以检查任何非视图和非纯函数。

这意味着存储在链上的库的实际代码与编译器输出的 ``deployedBytecode`` 不同。