.. include:: glossaries.rst
.. index:: ! function;modifier

.. _modifiers:

******************
函数修改器
******************

|modifier| 可以以声明的方式改变函数的行为。例如，你可以使用 |modifier| 在执行函数之前自动检查条件。

|modifier| 是合约的可继承属性，可以被派生合约重写 ，但只有在标记为 ``virtual`` 的情况下。有关详细信息，请参见 :ref:`修改器重写 <modifier-overriding>`。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.1 <0.9.0;

    contract owned {
        constructor() { owner = payable(msg.sender); }
        address payable owner;

        // 该合约仅定义了一个修改器，但未使用它：它将在派生合约中使用。
        // 函数体插入在修改器定义中的特殊符号 `_;` 出现的位置。
        // 这意味着如果所有者调用此函数，则函数将被执行，否则将抛出异常。
        modifier onlyOwner {
            require(
                msg.sender == owner,
                "Only owner can call this function."
            );
            _;
        }
    }

    contract priced {
        // 修改器可以接收参数：
        modifier costs(uint price) {
            if (msg.value >= price) {
                _;
            }
        }
    }

    contract Register is priced, owned {
        mapping(address => bool) registeredAddresses;
        uint price;

        constructor(uint initialPrice) { price = initialPrice; }

        // 这里也必须提供 `payable` 关键字，否则该函数将自动拒绝所有发送给它的以太币。
        function register() public payable costs(price) {
            registeredAddresses[msg.sender] = true;
        }

        // 该合约从 `owned` 合约继承了 `onlyOwner` 修改器。
        // 因此，调用 `changePrice` 仅在存储的所有者进行调用时才会生效。
        function changePrice(uint price_) public onlyOwner {
            price = price_;
        }
    }

    contract Mutex {
        bool locked;
        modifier noReentrancy() {
            require(
                !locked,
                "Reentrant call."
            );
            locked = true;
            _;
            locked = false;
        }

        /// 此函数受互斥锁保护，这意味着来自 `msg.sender.call` 的重入调用不能再次调用 `f`。
        /// `return 7` 语句将 7 赋值给返回值，执行修改器中的语句 `locked = false`。仍会执行。
        function f() public noReentrancy returns (uint) {
            (bool success,) = msg.sender.call("");
            require(success);
            return 7;
        }
    }

如果你想访问合约 ``C`` 中定义的 |modifier| ``m``，可以使用 ``C.m`` 来引用它，而无需虚拟查找。
只能使用当前合约或其基合约中定义的 |modifier| 。 |modifier| 也可以在库中定义，但是他们被限定在库函数使用。

通过在空格分隔的列表中指定多个修改器，可以将它们应用于一个函数，并按呈现的顺序进行评估。

修改器不能隐式访问或更改它们所修饰的函数的参数和返回值。
这些值只能在调用时显式传递给它们。

在函数修改器中，必须指定希望应用修饰符的函数何时运行。占位符语句（由单个下划线字符 ``_`` 表示）用于表示应插入被修饰函数的主体的位置。
请注意，占位符运算符与在变量名称中使用下划线作为前导或尾随字符不同，这是一种风格选择。

|modifier| 或函数主体的显式返回仅离开当前|modifier| 或函数主体。
返回变量被赋值，控制流在前面的 |modifier| 中的 ``_`` 之后继续。

.. warning::
    在早期版本的 Solidity 中，具有 |modifier| 的函数中的``return`` 语句的行为不同。

从 |modifier| 显式返回 ``return;`` 不会影响函数返回值。
但是，|modifier| 可以选择完全不执行函数主体，在这种情况下，返回变量被设置为 :ref:`默认值<default-value>`，就像函数有一个空主体一样。

``_`` 符号可以在 |modifier| 中多次出现。每次出现都被函数主体替换，函数返回最后一次出现的返回值。

|modifier| 参数允许任意表达式，在这种情况下，函数中可见的所有符号在 |modifier| 中都是可见的。
在 |modifier| 中引入的符号在函数中不可见（因为它们可能通过重载而改变）。