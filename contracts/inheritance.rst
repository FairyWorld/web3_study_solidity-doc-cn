.. include:: glossaries.rst

.. index:: ! inheritance, ! base class, ! contract;base, ! deriving

***********
继承
***********

Solidity 支持多重继承，包括多态。

多态意味着函数调用（内部和外部）始终在继承层次结构中最派生的合约中执行同名（和参数类型相同）的函数。这必须在层次结构中的每个函数上显式启用，使用 ``virtual`` 和 ``override`` 关键字。有关更多详细信息，请参见 :ref:`函数重写 <function-overriding>`。

可以通过显式指定合约来在继承层次结构中更高层次上内部调用函数，使用 ``ContractName.functionName()`` 或使用 ``super.functionName()`` 如果你想调用在扁平化继承层次结构中高一层的函数（见下文）。

当一个合约从其他合约继承时，区块链上只创建一个合约，所有基类合约的代码都被编译到创建的合约中。这意味着对基类合约函数的所有内部调用也仅使用内部函数调用（``super.f(..)`` 将使用 JUMP 而不是消息调用）。

状态变量遮蔽被视为错误。派生合约只能声明状态变量 ``x``，如果在其任何基类中没有可见的同名状态变量。

一般的继承系统与 `Python's <https://docs.python.org/3/tutorial/classes.html#inheritance>`_ 非常相似，特别是在多重继承方面，但也有一些 :ref:`差异 <multi-inheritance>`。

以下示例提供了详细信息。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Owned {
        address payable owner;
        constructor() { owner = payable(msg.sender); }
    }

    // 使用 `is` 从另一个合约派生。派生合约可以访问所有非私有成员，包括内部函数和状态变量。然而，这些不能通过 `this` 从外部访问。
    contract Emittable is Owned {
        event Emitted();

        // 关键字 `virtual` 意味着该函数可以在派生类中改变其行为（“重写”）。
        function emitEvent() virtual public {
            if (msg.sender == owner)
                emit Emitted();
        }
    }

    // 这些抽象合约仅用于使接口为编译器所知。注意没有主体的函数。如果合约没有实现所有函数，它只能用作接口。
    abstract contract Config {
        function lookup(uint id) public virtual returns (address adr);
    }

    abstract contract NameReg {
        function register(bytes32 name) public virtual;
        function unregister() public virtual;
    }

    // 多重继承是可能的。注意 `Owned` 也是 `Emittable` 的基类，但只有一个 `Owned` 的实例（就像 C++ 中的虚拟继承一样）。
    contract Named is Owned, Emittable {
        constructor(bytes32 name) {
            Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
            NameReg(config.lookup(1)).register(name);
        }

        // 函数可以被另一个具有相同名称和相同数量/类型输入的函数重写。如果重写函数具有不同类型的输出参数，则会导致错误。
        // 本地和基于消息的函数调用都会考虑这些重写。
        // 如果你希望函数重写，你需要使用 `override` 关键字。如果你希望这个函数再次被重写，你需要再次指定 `virtual` 关键字。
        function emitEvent() public virtual override {
            if (msg.sender == owner) {
                Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
                NameReg(config.lookup(1)).unregister();
                // 仍然可以调用特定的重写函数。
                Emittable.emitEvent();
            }
        }
    }


    // 如果构造函数需要一个参数，则需要在派生合约的构造函数的头部或修改器调用样式中提供。
    contract PriceFeed is Owned, Emittable, Named("GoldFeed") {
        uint info;

        function updateInfo(uint newInfo) public {
            if (msg.sender == owner) info = newInfo;
        }

        // 在这里，我们只指定 `override` 而不指定 `virtual`。
        // 这意味着从 `PriceFeed` 派生的合约不能再改变 `emitEvent` 的行为。
        function emitEvent() public override(Emittable, Named) { Named.emitEvent(); }
        function get() public view returns(uint r) { return info; }
    }

注意上面，我们调用 ``Emittable.emitEvent()`` 来“转发”发出事件请求。这样做是有问题的，如下例所示：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Owned {
        address payable owner;
        constructor() { owner = payable(msg.sender); }
    }

    contract Emittable is Owned {
        event Emitted();

        function emitEvent() virtual public {
            if (msg.sender == owner) {
                emit Emitted();
            }
        }
    }

    contract Base1 is Emittable {
        event Base1Emitted();
        function emitEvent() public virtual override {
            /* 在这里，我们发出一个事件以模拟一些 Base1 逻辑 */
            emit Base1Emitted();
            Emittable.emitEvent();
        }
    }

    contract Base2 is Emittable {
        event Base2Emitted();
        function emitEvent() public virtual override {
            /* 在这里，我们发出一个事件以模拟一些 Base2 逻辑 */
            emit Base2Emitted();
            Emittable.emitEvent();
        }
    }

    contract Final is Base1, Base2 {
        event FinalEmitted();
        function emitEvent() public override(Base1, Base2) {
            /* 在这里，我们发出一个事件以模拟一些 Final 逻辑 */
            emit FinalEmitted();
            Base2.emitEvent();
        }
    }

对 ``Final.emitEvent()`` 的调用将调用 ``Base2.emitEvent``，因为我们在最终重写中显式指定了它，但这个函数将绕过 ``Base1.emitEvent``，导致以下事件序列：
``FinalEmitted -> Base2Emitted -> Emitted``，而不是预期的序列：
``FinalEmitted -> Base2Emitted -> Base1Emitted -> Emitted``。
解决此问题的方法是使用 ``super``：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Owned {
        address payable owner;
        constructor() { owner = payable(msg.sender); }
    }

    contract Emittable is Owned {
        event Emitted();

        function emitEvent() virtual public {
            if (msg.sender == owner) {
                emit Emitted();
            }
        }
    }

    contract Base1 is Emittable {
        event Base1Emitted();
        function emitEvent() public virtual override {
            /* 在这里，我们发出一个事件以模拟一些 Base1 逻辑 */
            emit Base1Emitted();
            super.emitEvent();
        }
    }

    contract Base2 is Emittable {
        event Base2Emitted();
        function emitEvent() public virtual override {
            /* 在这里，我们发出一个事件以模拟一些 Base2 逻辑 */
            emit Base2Emitted();
            super.emitEvent();
        }
    }

    contract Final is Base1, Base2 {
        event FinalEmitted();
        function emitEvent() public override(Base1, Base2) {
            /* 在这里，我们发出一个事件以模拟一些 Final 逻辑 */
            emit FinalEmitted();
            super.emitEvent();
        }
    }

如果 ``Final`` 调用 ``super`` 的一个函数，它并不只是简单地在其基合约之一上调用此函数。
相反，它在最终继承图中的下一个基合约上调用此函数，因此它将调用 ``Base1.emitEvent()``（请注意最终继承顺序是 -- 从最派生的合约开始：Final, Base2, Base1, Emittable, Owned）。
在使用 super 时调用的实际函数在使用它的类的上下文中并不为人所知，尽管其类型是已知的。
这与普通的虚拟方法查找类似。

.. index:: ! overriding;function

.. _function-overriding:

函数重写
===================

基函数可以通过继承合约进行重写，以改变其行为，如果它们被标记为 ``virtual``。
重写的函数必须在函数头中使用 ``override`` 关键字。
重写的函数只能将被重写函数的可见性从 ``external`` 更改为 ``public``。
可变性可以按照以下顺序更改为更严格的：
``nonpayable`` 可以被 ``view`` 和 ``pure`` 重写。 ``view`` 可以被 ``pure`` 重写。
``payable`` 是一个例外，不能更改为任何其他可变性。

以下示例演示了可变性和可见性的更改：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Base
    {
        function foo() virtual external view {}
    }

    contract Middle is Base {}

    contract Inherited is Middle
    {
        function foo() override public pure {}
    }

对于多重继承，必须在 ``override`` 关键字后显式指定定义相同函数的最派生基合约。
换句话说，你必须指定所有定义相同函数的基合约并且尚未被另一个基合约重写（在继承图的某些路径上）。
此外，如果一个合约从多个（无关的）基合约继承相同的函数，则必须显式重写它：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract Base1
    {
        function foo() virtual public {}
    }

    contract Base2
    {
        function foo() virtual public {}
    }

    contract Inherited is Base1, Base2
    {
        // 从多个定义 foo() 的基合约派生，因此我们必须显式重写它
        function foo() public override(Base1, Base2) {}
    }

如果函数在一个公共基合约中定义，或者在一个公共基合约中有一个唯一的函数已经重写了所有其他函数，则不需要显式重写说明符。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract A { function f() public pure{} }
    contract B is A {}
    contract C is A {}
    // 不需要显式重写
    contract D is B, C {}

更正式地说，如果存在一个基合约是所有签名的重写路径的一部分，并且
（1）该基合约实现了该函数，并且从当前合约到基合约的路径中没有提到具有该签名的函数，或者（
2）该基合约没有实现该函数，并且在从当前合约到该基合约的所有路径中最多只有一个提到该函数，则不需要重写从多个基合约继承的函数。

在这个意义上，签名的重写路径是一个路径，通过继承图，从考虑的合约开始并结束于提到具有该签名的函数的合约而不重写。

如果你没有将重写的函数标记为 ``virtual``，则派生合约将不再能够改变该函数的行为。

.. note::

  具有 ``private`` 可见性的函数不能是 ``virtual``。

.. note::

  没有实现的函数必须在接口外标记为 ``virtual``。在接口中，所有函数都被自动视为 ``virtual``。

.. note::

  从 Solidity 0.8.8 开始，重写接口函数时不需要 ``override`` 关键字，除非函数在多个基合约中定义。


公共状态变量可以重写外部函数，如果函数的参数和返回类型与变量的 getter 函数匹配：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract A
    {
        function f() external view virtual returns(uint) { return 5; }
    }

    contract B is A
    {
        uint public override f;
    }

.. note::

  虽然公共状态变量可以重写外部函数，但它们本身不能被重写。

.. index:: ! overriding;modifier

.. _modifier-overriding:

修改器重写
===================

函数修改器可以相互重写。这与 :ref:`函数重写 <function-overriding>` 的工作方式相同（除了修改器没有重载）。
重写的修改器必须在重写的修改器中使用 ``virtual`` 关键字，并且在重写的修改器中必须使用 ``override`` 关键字：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract Base
    {
        modifier foo() virtual {_;}
    }

    contract Inherited is Base
    {
        modifier foo() override {_;}
    }


在多重继承的情况下，所有直接基合约必须显式指定：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    contract Base1
    {
        modifier foo() virtual {_;}
    }

    contract Base2
    {
        modifier foo() virtual {_;}
    }

    contract Inherited is Base1, Base2
    {
        modifier foo() override(Base1, Base2) {_;}
    }



.. index:: ! constructor

.. _constructor:

构造函数
============

构造函数是一个可选的函数，用 ``constructor`` 关键字声明在合约创建时执行，可以在其中运行合约初始化代码。

在执行构造函数代码之前，如果在行内初始化状态变量，则它们会将被初始化为指定的值，或者不初始化，则为 :ref:`默认值<default-value>`。

在构造函数运行后，合约的最终代码被部署到区块链。代码的部署会产生额外的 gas 费用，费用与代码的长度成线性关系。
此代码包括所有属于公共接口的函数以及所有可以通过函数调用从那里到达的函数。
它不包括构造函数代码或仅从构造函数调用的内部函数。

如果没有构造函数，合约将假定默认构造函数，这等同于 ``constructor() {}``。例如：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    abstract contract A {
        uint public a;

        constructor(uint a_) {
            a = a_;
        }
    }

    contract B is A(1) {
        constructor() {}
    }

你可以在构造函数中使用内部参数（例如存储指针）。在这种情况下，合约必须标记为 :ref:`abstract <abstract-contract>`，因为这些参数不能从外部分配有效值，而只能通过派生合约的构造函数进行分配。

.. warning::
    在版本 0.4.22 之前，构造函数被定义为与合约同名的函数。
    这种语法已被弃用，并且在版本 0.5.0 中不再允许。

.. warning::
    在版本 0.7.0 之前，你必须将构造函数的可见性指定为
    ``internal`` 或 ``public``。


.. index:: ! base;constructor, inheritance list, contract;abstract, abstract contract

基类构造函数的参数
===============================

所有基类的构造函数将按照下面解释的线性化规则被调用。如果基类构造函数有参数，派生合约需要指定所有参数。这可以通过两种方式完成：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Base {
        uint x;
        constructor(uint x_) { x = x_; }
    }

    // 要么直接在继承列表中指定...
    contract Derived1 is Base(7) {
        constructor() {}
    }

    // 或通过派生构造函数的“修改器”...
    contract Derived2 is Base {
        constructor(uint y) Base(y * y) {}
    }

    // 或声明为抽象...
    abstract contract Derived3 is Base {
    }

    // 然后让下一个具体的派生合约进行初始化。
    contract DerivedFromDerived is Derived3 {
        constructor() Base(10 + 10) {}
    }

一种方式是在继承列表中直接指定（``is Base(7)``）。
另一种方式是在派生构造函数中以修改器的方式调用（``Base(y * y)``）。
如果构造函数参数是常量并定义了合约的行为或描述它，第一种方式更方便。
如果基类的构造函数参数依赖于派生合约的参数，则必须使用第二种方式。
参数必须在继承列表中给出，或者在派生构造函数中以修改器样式给出。
在两个地方指定参数是错误的。

如果派生合约没有为其所有基类构造函数指定参数，则必须声明为抽象。
在这种情况下，当另一个合约从它派生时，那个合约的继承列表或构造函数必须为所有未指定参数的基类提供必要的参数（否则，那个合约也必须声明为抽象）。
例如，在上面的代码片段中，参见 ``Derived3`` 和 ``DerivedFromDerived``。

.. index:: ! inheritance;multiple, ! linearization, ! C3 linearization

.. _multi-inheritance:

多重继承和线性化
======================================

允许多重继承的语言必须处理几个问题。其中一个是 `钻石问题 <https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem>`_。
Solidity 类似于 Python，因为它使用 "`C3 线性化 <https://en.wikipedia.org/wiki/C3_linearization>`_" 来强制基类的有向无环图（DAG）中的特定顺序。
这导致了单调性的理想属性，但不允许某些继承图。特别是，基类在 ``is`` 指令中给出的顺序是重要的：必须按“最基础”到“最派生”的顺序列出直接基合约。
请注意，这个顺序与 Python 中使用的顺序相反。

另一种简化的解释是，当调用在不同合约中多次定义的函数时，给定的基类是从右到左（在 Python 中是从左到右）以深度优先的方式进行搜索，直到找到第一个匹配。如果一个基合约已经被搜索，则会被跳过。

在以下代码中，Solidity 将给出错误“无法线性化继承图”。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract X {}
    contract A is X {}
    // 这将无法编译
    contract C is A, X {}

原因是 ``C`` 请求 ``X`` 来覆盖 ``A``（通过以这种顺序指定 ``A, X``），但 ``A`` 自身请求覆盖 ``X``，这是一种无法解决的矛盾。

由于必须显式覆盖从多个基类继承的没有唯一覆盖的函数，因此 C3 线性化在实践中并不是太重要。

继承层次结构中多个构造函数的一个领域，继承线性化尤其重要，可能不太清楚。构造函数将始终按照线性化顺序执行，而不管它们的参数在继承合约的构造函数中提供的顺序。例如：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    contract Base1 {
        constructor() {}
    }

    contract Base2 {
        constructor() {}
    }

    // 构造函数按以下顺序执行：
    //  1 - Base1
    //  2 - Base2
    //  3 - Derived1
    contract Derived1 is Base1, Base2 {
        constructor() Base1() Base2() {}
    }

    // 构造函数按以下顺序执行：
    //  1 - Base2
    //  2 - Base1
    //  3 - Derived2
    contract Derived2 is Base2, Base1 {
        constructor() Base2() Base1() {}
    }

    // 构造函数仍然按以下顺序执行：
    //  1 - Base2
    //  2 - Base1
    //  3 - Derived3
    contract Derived3 is Base2, Base1 {
        constructor() Base1() Base2() {}
    }


继承同名的不同类型成员
======================================================

由于继承，合约可能包含多个共享相同名称的定义的唯一情况是：

- 函数的重载。
- 虚函数的重写。
- 通过状态变量获取器重写外部虚函数。
- 虚修改器的重写。
- 事件的重载。