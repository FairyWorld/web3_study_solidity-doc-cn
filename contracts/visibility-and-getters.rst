.. index:: ! visibility, external, public, private, internal

.. |visibility-caveat| replace:: 将某些内容设置为 ``private`` 或 ``internal`` 仅仅是防止其他合约读取或修改这些信息，但它仍然对区块链外的整个世界可见。

.. _visibility-and-getters:

**********************
可见性和 getter 函数
**********************

状态变量可见性
=========================

``public``
    公共状态变量与内部状态变量的不同之处在于，编译器会自动为它们生成 :ref:`getter 函数<getter-functions>`，这允许其他合约读取它们的值。
    在同一合约内使用时，外部访问（例如 ``this.x``）会调用 getter，而内部访问（例如 ``x``）则直接从存储中获取变量值。
    不会生成 Setter函数，因此其他合约无法直接修改它们的值。

``internal``
    内部状态变量只能在定义它们的合约及其派生合约中访问。
    它们无法被外部访问。
    这是状态变量的默认可见性级别。

``private``
    私有状态变量类似于内部变量，但在派生合约中不可见。

.. warning::
    |visibility-caveat|

函数可见性
===================

Solidity 有两种类型的函数调用：外部调用会创建实际的 EVM 消息调用，而内部调用则不会。
此外，内部函数可以对派生合约不可访问。
这产生了四种函数的可见性类型。

``external``
    外部函数是合约接口的一部分，
    这意味着它们可以从其他合约和通过交易调用。
    外部函数 ``f`` 不能被内部调用（即 ``f()`` 不起作用，但 ``this.f()`` 有效）。

``public``
    公共函数是合约接口的一部分可以通过内部调用或消息调用。

``internal``
    内部函数只能在当前合约内
    或从其派生的合约中访问。
    它们无法被外部访问。
    由于它们没有通过合约的 ABI 暴露给外部，因此可以接受内部类型的参数，如映射或存储引用。

``private``
    私有函数类似于内部函数，但在派生合约中不可见。

.. warning::
    |visibility-caveat|

可见性修改器在状态变量的类型后给出，在函数的参数列表和返回参数列表之间。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        function f(uint a) private pure returns (uint b) { return a + 1; }
        function setData(uint a) internal { data = a; }
        uint public data;
    }

在以下示例中，``D`` 可以调用 ``c.getData()`` 来检索在状态存储中的 ``data`` 的值，但无法调用 ``f``。
合约 ``E`` 从 ``C`` 派生，因此可以调用 ``compute``。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        uint private data;

        function f(uint a) private pure returns(uint b) { return a + 1; }
        function setData(uint a) public { data = a; }
        function getData() public view returns(uint) { return data; }
        function compute(uint a, uint b) internal pure returns (uint) { return a + b; }
    }

    // 这将无法编译
    contract D {
        function readData() public {
            C c = new C();
            uint local = c.f(7); // 错误：成员 `f` 不可见
            c.setData(3);
            local = c.getData();
            local = c.compute(3, 5); // 错误：成员 `compute` 不可见
        }
    }

    contract E is C {
        function g() public {
            C c = new C();
            uint val = compute(3, 5); // 访问内部成员（从派生到父合约）
        }
    }

.. index:: ! getter;function, ! function;getter
.. _getter-functions:

Getter 函数
================

编译器会自动为所有 **public** 状态变量创建 getter 函数。
对于下面给出的合约，编译器将生成一个名为 ``data`` 的函数，该函数不接受任何参数并返回一个 ``uint``，即状态变量 ``data`` 的值。
状态变量可以在声明时初始化。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract C {
        uint public data = 42;
    }

    contract Caller {
        C c = new C();
        function f() public view returns (uint) {
            return c.data();
        }
    }

getter 函数具有外部可见性。
如果变量在内部访问（即不带 ``this.``），它会被评估为状态变量。
如果被外部访问（即带有 ``this.``），它会被评估为一个函数。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract C {
        uint public data;
        function x() public returns (uint) {
            data = 3; // 内部访问
            return this.data(); // 外部访问
        }
    }

如果你有一个数组类型的 ``public`` 状态变量，那么你只能通过生成的 getter 函数检索数组的单个元素。
这个机制的存在是为了避免在返回整个数组时产生高昂的 gas 成本。
可以使用参数来指定要返回的单个元素，例如 ``myArray(0)``。如果想在一次调用中返回整个数组，那么需要编写一个函数，例如：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    contract arrayExample {
        // 公共状态变量
        uint[] public myArray;

        // 编译器生成的 getter 函数
        /*
        function myArray(uint i) public view returns (uint) {
            return myArray[i];
        }
        */

        // 返回整个数组的函数
        function getArray() public view returns (uint[] memory) {
            return myArray;
        }
    }

现在可以使用 ``getArray()`` 来检索整个数组，而不是 ``myArray(i)``, 这会每次调用返回一个单独的元素。

下一个示例更复杂：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract Complex {
        struct Data {
            uint a;
            bytes3 b;
            mapping(uint => uint) map;
            uint[3] c;
            uint[] d;
            bytes e;
        }
        mapping(uint => mapping(bool => Data[])) public data;
    }

它生成一个如下形式的函数。
结构中的映射和数组（字节数组除外）被省略，因为没有好的方法选择单个结构成员或为映射提供键：

.. code-block:: solidity

    function data(uint arg1, bool arg2, uint arg3)
        public
        returns (uint a, bytes3 b, bytes memory e)
    {
        a = data[arg1][arg2][arg3].a;
        b = data[arg1][arg2][arg3].b;
        e = data[arg1][arg2][arg3].e;
    }