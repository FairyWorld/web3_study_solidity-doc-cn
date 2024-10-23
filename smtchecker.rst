.. _formal_verification:

##################################
SMTChecker 和形式化验证
##################################

通过形式验证，可以进行自动化的数学证明，证明你的源代码满足某个特定的形式规范。
该规范仍然是形式的（就像源代码一样），但通常要简单得多。

请注意，形式验证本身只能帮助你理解你所做的（规范）与你如何做到这一点（实际实现）之间的区别。你仍然需要检查规范是否是你想要的，并且没有遗漏任何意外效果。

Solidity 实现了一种基于 `SMT (Satisfiability Modulo Theories) <https://en.wikipedia.org/wiki/Satisfiability_modulo_theories>`_ 和 `Horn <https://en.wikipedia.org/wiki/Horn-satisfiability>`_ 求解的形式验证方法。
SMTChecker 模块会自动尝试证明代码满足由 ``require`` 和 ``assert`` 语句给出的规范。也就是说，它将 ``require`` 语句视为假设，并尝试证明 ``assert`` 语句中的条件始终为真。如果发现断言失败，可能会向用户提供一个反例，显示如何违反该断言。如果 SMTChecker 对某个属性没有发出警告，则意味着该属性是安全的。

SMTChecker 在编译时检查的其他验证目标包括：

- 算术下溢和上溢。
- 除以零。
- 平凡条件和不可达代码。
- 弹出空数组。
- 越界索引访问。
- 转账资金不足。

如果启用了所有引擎，以上所有目标默认情况下都会自动检查，除了 Solidity >=0.8.7 的下溢和上溢。

SMTChecker 报告的潜在警告包括：

- ``<failing property> happens here.``。这意味着 SMTChecker 证明了某个属性失败。可能会给出一个反例，但在复杂情况下也可能不显示反例。在某些情况下，这个结果也可能是误报，因为 SMT 编码为 Solidity 代码添加了抽象，这些代码很难或不可能表达。
- ``<failing property> might happen here``。这意味着求解器在给定的超时内无法证明任一情况。由于结果未知，SMTChecker 报告潜在的失败以确保健全性。这可以通过增加查询超时来解决，但问题也可能太难以至于引擎无法解决。

要启用 SMTChecker，你必须选择 :ref:`which engine should run<smtchecker_engines>`，默认情况下没有引擎。选择引擎会在所有文件上启用 SMTChecker。

.. note::

    在 Solidity 0.8.4 之前，启用 SMTChecker 的默认方式是通过 ``pragma experimental SMTChecker;``，只有包含该 pragma 的合约会被分析。该 pragma 已被弃用，尽管它仍然为向后兼容启用 SMTChecker，但将在 Solidity 0.9.0 中删除。还要注意，现在即使在单个文件中使用该 pragma 也会为所有文件启用 SMTChecker。

.. note::

    对于验证目标缺乏警告表示无可争议的正确性数学证明，假设 SMTChecker 和底层求解器没有错误。请记住，这些问题是 *非常困难* 的，有时在一般情况下 *不可能* 自动解决。因此，对于大型合约，某些属性可能无法解决或可能导致误报。每个被证明的属性都应被视为重要成就。对于高级用户，请参见 :ref:`SMTChecker Tuning <smtchecker_options>` 以了解一些可能有助于证明更复杂属性的选项。

********
教程
********

溢出
========

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Overflow {
        uint immutable x;
        uint immutable y;

        function add(uint x_, uint y_) internal pure returns (uint) {
            return x_ + y_;
        }

        constructor(uint x_, uint y_) {
            (x, y) = (x_, y_);
        }

        function stateAdd() public view returns (uint) {
            return add(x, y);
        }
    }

上述合约展示了一个溢出检查的示例。
SMTChecker 默认情况下不检查 Solidity >=0.8.7 的下溢和上溢，因此我们需要使用命令行选项 ``--model-checker-targets "underflow,overflow"`` 或 JSON 选项 ``settings.modelChecker.targets = ["underflow", "overflow"]``。
请参见 :ref:`this section for targets configuration<smtchecker_targets>`。
在这里，它报告如下：

.. code-block:: text

    Warning: CHC: Overflow (resulting value larger than 2**256 - 1) happens here.
    Counterexample:
    x = 1, y = 115792089237316195423570985008687907853269984665640564039457584007913129639935
     = 0

    Transaction trace:
    Overflow.constructor(1, 115792089237316195423570985008687907853269984665640564039457584007913129639935)
    State: x = 1, y = 115792089237316195423570985008687907853269984665640564039457584007913129639935
    Overflow.stateAdd()
        Overflow.add(1, 115792089237316195423570985008687907853269984665640564039457584007913129639935) -- internal call
     --> o.sol:9:20:
      |
    9 |             return x_ + y_;
      |                    ^^^^^^^

如果我们添加 ``require`` 语句来过滤掉溢出情况，SMTChecker 证明没有溢出是可达的（通过不报告警告）：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Overflow {
        uint immutable x;
        uint immutable y;

        function add(uint x_, uint y_) internal pure returns (uint) {
            return x_ + y_;
        }

        constructor(uint x_, uint y_) {
            (x, y) = (x_, y_);
        }

        function stateAdd() public view returns (uint) {
            require(x < type(uint128).max);
            require(y < type(uint128).max);
            return add(x, y);
        }
    }


断言
======

断言表示你代码中的不变式：必须对 **所有交易，包括所有输入和存储值** 成立的属性，否则就存在错误。

下面的代码定义了一个函数 ``f``，保证没有溢出。
函数 ``inv`` 定义了 ``f`` 是单调递增的规范：对于每一对可能的 ``(a, b)``, 如果 ``b > a`` 则 ``f(b) > f(a)``。
由于 ``f`` 确实是单调递增的，SMTChecker 证明我们的属性是正确的。鼓励你玩弄属性和函数定义，以查看结果！

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Monotonic {
        function f(uint x) internal pure returns (uint) {
            require(x < type(uint128).max);
            return x * 42;
        }

        function inv(uint a, uint b) public pure {
            require(b > a);
            assert(f(b) > f(a));
        }
    }

我们还可以在循环中添加断言，以验证更复杂的属性。
以下代码搜索一个不受限制的数字数组的最大元素，并断言找到的元素必须大于或等于数组中的每个元素。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Max {
        function max(uint[] memory a) public pure returns (uint) {
            uint m = 0;
            for (uint i = 0; i < a.length; ++i)
                if (a[i] > m)
                    m = a[i];

            for (uint i = 0; i < a.length; ++i)
                assert(m >= a[i]);

            return m;
        }
    }

注意，在这个例子中，SMTChecker 将自动尝试证明三个属性：

1. ``++i`` 在第一个循环中不会溢出。
2. ``++i`` 在第二个循环中不会溢出。
3. 该断言始终为真。

.. note::

    这些属性涉及循环，这使得它比之前的例子 **难得多**，所以要小心循环！

所有属性都被正确证明是安全的。可以随意更改属性和/或对数组添加限制，以查看不同的结果。
例如，将代码更改为

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Max {
        function max(uint[] memory a) public pure returns (uint) {
            require(a.length >= 5);
            uint m = 0;
            for (uint i = 0; i < a.length; ++i)
                if (a[i] > m)
                    m = a[i];

            for (uint i = 0; i < a.length; ++i)
                assert(m > a[i]);

            return m;
        }
    }

会给我们：

.. code-block:: text

    Warning: CHC: Assertion violation happens here.
    Counterexample:

    a = [0, 0, 0, 0, 0]
     = 0

    Transaction trace:
    Test.constructor()
    Test.max([0, 0, 0, 0, 0])
      --> max.sol:14:4:
       |
    14 |            assert(m > a[i]);


状态属性
================

到目前为止，示例仅演示了在纯代码上使用 SMTChecker，证明关于特定操作或算法的属性。
智能合约中常见的属性类型是涉及合约状态的属性。可能需要多次交易才能使此类属性的断言失败。

作为一个例子，考虑一个二维网格，其中两个轴的坐标范围为 (-2^128, 2^128 - 1)。
让我们将一个机器人放置在位置 (0, 0)。机器人只能对角移动，每次一步，并且不能移动出网格。
机器人的状态机可以通过下面的智能合约表示。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Robot {
        int x = 0;
        int y = 0;

        modifier wall {
            require(x > type(int128).min && x < type(int128).max);
            require(y > type(int128).min && y < type(int128).max);
            _;
        }

        function moveLeftUp() wall public {
            --x;
            ++y;
        }

        function moveLeftDown() wall public {
            --x;
            --y;
        }

        function moveRightUp() wall public {
            ++x;
            ++y;
        }

        function moveRightDown() wall public {
            ++x;
            --y;
        }

        function inv() public view {
            assert((x + y) % 2 == 0);
        }
    }

函数 ``inv`` 表示状态机的一个不变式，即 ``x + y`` 必须是偶数。
SMTChecker 设法证明无论我们给机器人多少命令，即使是无限多，该不变式*永远*不会失败。感兴趣的读者也可以手动证明这一事实。提示：这个不变式是归纳的。

我们还可以欺骗 SMTChecker，让它给我们一条到某个我们认为可能到达的位置的路径。我们可以添加属性 (2, 4) *不可*到达，通过添加以下函数。

.. code-block:: solidity

    function reach_2_4() public view {
        assert(!(x == 2 && y == 4));
    }

这个属性是错误的，而在证明该属性为假时，SMTChecker 精确地告诉我们 **如何** 到达 (2, 4)：

.. code-block:: text

    Warning: CHC: Assertion violation happens here.
    Counterexample:
    x = 2, y = 4

    Transaction trace:
    Robot.constructor()
    State: x = 0, y = 0
    Robot.moveLeftUp()
    State: x = (- 1), y = 1
    Robot.moveRightUp()
    State: x = 0, y = 2
    Robot.moveRightUp()
    State: x = 1, y = 3
    Robot.moveRightUp()
    State: x = 2, y = 4
    Robot.reach_2_4()
      --> r.sol:35:4:
       |
    35 |            assert(!(x == 2 && y == 4));
       |            ^^^^^^^^^^^^^^^^^^^^^^^^^^^

注意，上面的路径不一定是确定性的，因为还有其他路径可以到达 (2, 4)。所显示的路径的选择可能会根据使用的求解器、其版本或仅仅是随机而变化。

外部调用和重入
=============================

每个外部调用都被 SMTChecker 视为对未知代码的调用。
这样做的原因是，即使被调用合约的代码在编译时可用，也不能保证已部署的合约确实与编译时接口来源的合约相同。

在某些情况下，可以自动推断出状态变量的属性，即使外部调用的代码可以做任何事情，包括重新进入调用合约。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    interface Unknown {
        function run() external;
    }

    contract Mutex {
        uint x;
        bool lock;

        Unknown immutable unknown;

        constructor(Unknown u) {
            require(address(u) != address(0));
            unknown = u;
        }

        modifier mutex {
            require(!lock);
            lock = true;
            _;
            lock = false;
        }

        function set(uint x_) mutex public {
            x = x_;
        }

        function run() mutex public {
            uint xPre = x;
            unknown.run();
            assert(xPre == x);
        }
    }

上面的例子展示了一个使用互斥标志来禁止重入的合约。
求解器能够推断出当调用 ``unknown.run()`` 时，合约已经“锁定”，因此无论未知调用代码做什么，都不可能更改 ``x`` 的值。

如果我们在函数 ``set`` 上“忘记”使用 ``mutex`` 修改器，SMTChecker 能够合成外部调用代码的行为，以使断言失败：

.. code-block:: text

    Warning: CHC: Assertion violation happens here.
    Counterexample:
    x = 1, lock = true, unknown = 1

    Transaction trace:
    Mutex.constructor(1)
    State: x = 0, lock = false, unknown = 1
    Mutex.run()
        unknown.run() -- 不可信的外部调用，合成为：
            Mutex.set(1) -- 重入调用
      --> m.sol:32:3:
       |
    32 | 		assert(xPre == x);
       | 		^^^^^^^^^^^^^^^^^


.. _smtchecker_options:

*****************************
SMTChecker 选项和调优
*****************************

超时
=======

SMTChecker 使用每个求解器选择的硬编码资源限制 (``rlimit``)，这与时间没有精确关系。我们选择 ``rlimit`` 选项作为默认值，因为它比求解器内部的时间提供了更多的确定性保证。

这个选项大致转换为“每个查询几秒的超时”。当然，许多属性非常复杂，需要大量时间才能解决，而确定性并不重要。
如果 SMTChecker 无法在默认的 ``rlimit`` 下解决合约属性，可以通过 CLI 选项 ``--model-checker-timeout <time>`` 或 JSON 选项 ``settings.modelChecker.timeout=<time>`` 提供超时，0 表示没有超时。

.. _smtchecker_targets:

验证目标
====================

SMTChecker 创建的验证目标类型也可以通过 CLI 选项 ``--model-checker-target <targets>`` 或 JSON 选项 ``settings.modelChecker.targets=<targets>`` 进行自定义。
在 CLI 的情况下，``<targets>`` 是一个不带空格的逗号分隔的一个或多个验证目标的列表，而在 JSON 输入中则是一个包含一个或多个目标的字符串数组。
表示目标的关键字有：

- 断言: ``assert``。
- 算术下溢: ``underflow``。
- 算术上溢: ``overflow``。
- 除以零: ``divByZero``。
- 平凡条件和不可达代码: ``constantCondition``。
- 从空数组弹出: ``popEmptyArray``。
- 超出边界的数组/固定字节索引访问: ``outOfBounds``。
- 转账资金不足: ``balance``。
- 以上所有: ``default``（仅限 CLI）。

一个常见的目标子集可能是，例如：
``--model-checker-targets assert,overflow``。

默认情况下，所有目标都会被检查，除了 Solidity >=0.8.7 的下溢和上溢。

关于如何以及何时拆分验证目标没有精确的启发式方法，但在处理大型合约时，这可能会很有用。

已证明的目标
==============

如果有任何已证明的目标，SMTChecker 会针对每个引擎发出一个警告，说明证明了多少个目标。如果用户希望查看所有具体的已证明目标，可以使用 CLI 选项 ``--model-checker-show-proved-safe`` 和 JSON 选项 ``settings.modelChecker.showProvedSafe = true``。

未证明的目标
================

如果有任何未证明的目标，SMTChecker 会发出一个警告，说明有多少个未证明的目标。如果用户希望查看所有具体的未证明目标，可以使用 CLI 选项 ``--model-checker-show-unproved`` 和 JSON 选项 ``settings.modelChecker.showUnproved = true``。

不支持的语言特性
=============================

某些 Solidity 语言特性并未被 SMTChecker 应用的 SMT 编码完全支持，例如汇编块。
不支持的构造通过过度近似进行抽象以保持健全性，这意味着报告安全的任何属性都是安全的，即使该特性不受支持。
然而，这种抽象可能会导致假阳性，当目标属性依赖于不支持特性的精确行为时。
如果编码器遇到这种情况，它将默认报告一个通用警告，说明它看到了多少个不支持的特性。
如果用户希望查看所有具体的不支持特性，可以使用 CLI 选项 ``--model-checker-show-unsupported`` 和 JSON 选项 ``settings.modelChecker.showUnsupported = true``，其默认值为 ``false``。

已验证的合约
==================

默认情况下，给定源中的所有可部署合约会被单独分析为将要部署的合约。这意味着如果一个合约有许多直接和间接的继承父类，所有这些合约都会被单独分析，即使只有最派生的合约会在区块链上被直接访问。
这给 SMTChecker 和求解器带来了不必要的负担。为了帮助这种情况，用户可以指定哪些合约应被分析为部署的合约。父合约当然仍然会被分析，但仅在最派生合约的上下文中进行分析，从而减少编码和生成查询的复杂性。请注意，抽象合约默认情况下不会被 SMTChecker 分析为最派生合约。

所选合约可以通过 CLI 中的以逗号分隔的列表（不允许空格）给出，格式为 <source>:<contract>：
``--model-checker-contracts "<source1.sol:contract1>,<source2.sol:contract2>,<source2.sol:contract3>"``，
并通过 :ref:`JSON 输入<compiler-api>` 中的对象 ``settings.modelChecker.contracts`` 给出，其格式如下：

.. code-block:: json

    "contracts": {
        "source1.sol": ["contract1"],
        "source2.sol": ["contract2", "contract3"]
    }

受信任的外部调用
======================

默认情况下，SMTChecker 不假设编译时可用的代码与外部调用的运行时代码相同。以下合约作为示例：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Ext {
        uint public x;
        function setX(uint _x) public { x = _x; }
    }
    contract MyContract {
        function callExt(Ext _e) public {
            _e.setX(42);
            assert(_e.x() == 42);
        }
    }

当调用 ``MyContract.callExt`` 时，作为参数给出一个地址。
在部署时，我们无法确定地址 ``_e`` 实际上包含合约 ``Ext`` 的部署。
因此，SMTChecker 会警告上述断言可能会被违反，这是真的，如果 ``_e`` 包含其他合约而不是 ``Ext``。

然而，将这些外部调用视为受信任的可能是有用的，例如，测试不同实现的接口是否符合相同的属性。
这意味着假设地址 ``_e`` 确实是作为合约 ``Ext`` 部署的。
可以通过 CLI 选项 ``--model-checker-ext-calls=trusted`` 或 JSON 字段 ``settings.modelChecker.extCalls: "trusted"`` 启用此模式。

请注意，启用此模式可能会使 SMTChecker 的分析计算成本大大增加。

此模式的重要部分是它适用于合约类型和对合约的高级外部调用，而不适用于低级调用，如 ``call`` 和 ``delegatecall``。地址的存储是按合约类型存储的，SMTChecker 假设被外部调用的合约具有调用表达式的类型。因此，将 ``address`` 或合约转换为不同的合约类型将产生不同的存储值，并且如果假设不一致，可能会导致不健全的结果，如下面的示例：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract D {
        constructor(uint _x) { x = _x; }
        uint public x;
        function setX(uint _x) public { x = _x; }
    }

    contract E {
        constructor() { x = 2; }
        uint public x;
        function setX(uint _x) public { x = _x; }
    }

    contract C {
        function f() public {
            address d = address(new D(42));

            // `d` 被部署为 `D`，所以它的 `x` 现在应该是 42。
            assert(D(d).x() == 42); // 应该成立
            assert(D(d).x() == 43); // 应该失败

            // E 和 D 具有相同的接口，因此以下
            // 调用在运行时也会工作。
            // 然而，对 `E(d)` 的更改不会反映在 `D(d)` 中。
            E(d).setX(1024);

            // 从 `D(d)` 读取现在将显示旧值。
            // 以下断言在运行时应该失败，
            // 但在此模式的分析中成功（不健全）。
            assert(D(d).x() == 42);
            // 以下断言在运行时应该成功，
            // 但在此模式的分析中失败（假阳性）。
            assert(D(d).x() == 1024);
        }
    }

由于上述原因，请确保对某个 ``address`` 或 ``contract`` 类型的受信任外部调用始终具有相同的调用表达式类型。
在继承的情况下，将被调用合约的变量转换为最派生类型的类型也是有帮助的。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    interface Token {
        function balanceOf(address _a) external view returns (uint);
        function transfer(address _to, uint _amt) external;
    }

    contract TokenCorrect is Token {
        mapping (address => uint) balance;
        constructor(address _a, uint _b) {
            balance[_a] = _b;
        }
        function balanceOf(address _a) public view override returns (uint) {
            return balance[_a];
        }
        function transfer(address _to, uint _amt) public override {
            require(balance[msg.sender] >= _amt);
            balance[msg.sender] -= _amt;
            balance[_to] += _amt;
        }
    }

    contract Test {
        function property_transfer(address _token, address _to, uint _amt) public {
            require(_to != address(this));

            TokenCorrect t = TokenCorrect(_token);

            uint xPre = t.balanceOf(address(this));
            require(xPre >= _amt);
            uint yPre = t.balanceOf(_to);

            t.transfer(_to, _amt);
            uint xPost = t.balanceOf(address(this));
            uint yPost = t.balanceOf(_to);

            assert(xPost == xPre - _amt);
            assert(yPost == yPre + _amt);
        }
    }

请注意，在函数 ``property_transfer`` 中，外部调用是在变量 ``t`` 上执行的。

这种模式的另一个警告是对合约类型的状态变量的调用，这些调用发生在分析合约之外。在下面的代码中，尽管 ``B`` 部署了 ``A``，但存储在 ``B.a`` 中的地址也可能被 ``B`` 之外的任何人调用，这可能发生在对 ``B`` 本身的交易之间。为了反映对 ``B.a`` 的可能更改，编码允许对 ``B.a`` 进行无限次外部调用。编码将跟踪 ``B.a`` 的存储，因此断言 (2) 应该成立。然而，目前编码允许从 ``B`` 进行这样的调用，因此断言 (3) 失败。使编码在逻辑上更强是受信模式的扩展，并正在开发中。请注意，编码不跟踪 ``address`` 变量的存储，因此如果 ``B.a`` 的类型是 ``address``，编码将假设其存储在对 ``B`` 的交易之间不会改变。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract A {
        uint public x;
        address immutable public owner;
        constructor() {
            owner = msg.sender;
        }
        function setX(uint _x) public {
            require(msg.sender == owner);
            x = _x;
        }
    }

    contract B {
        A a;
        constructor() {
            a = new A();
            assert(a.x() == 0); // (1) 应该成立
        }
        function g() public view {
            assert(a.owner() == address(this)); // (2) 应该成立
            assert(a.x() == 0); // (3) 应该成立，但由于误报而失败
        }
    }

报告的推断归纳不变式
====================

对于通过 CHC 引擎证明安全的属性，SMTChecker 可以检索由 Horn 求解器推断的归纳不变式。
目前仅有两种类型的不变式可以报告给用户：

- 合约不变式：这些是关于合约状态变量的属性，在合约可能运行的每个交易之前和之后都为真。例如，``x >= y``，其中 ``x`` 和 ``y`` 是合约的状态变量。
- 重入属性：它们表示合约在对未知代码的外部调用存在时的行为。这些属性可以表达外部调用之前和之后状态变量值之间的关系，其中外部调用可以自由执行任何操作，包括对被分析合约的重入调用。带撇号的变量表示外部调用后状态变量的值。例如：``lock -> x = x'``。

用户可以使用 CLI 选项 ``--model-checker-invariants "contract,reentrancy"`` 或在 :ref:`JSON 输入<compiler-api>` 的字段 ``settings.modelChecker.invariants`` 中作为数组选择要报告的不变式。
默认情况下，SMTChecker 不报告不变式。

带松弛变量的除法和取模
========================

SMTChecker 使用的默认 Horn 求解器 Spacer 通常不喜欢在 Horn 规则中进行除法和取模操作。因此，默认情况下，Solidity 的除法和取模操作使用约束 ``a = b * d + m`` 进行编码，其中 ``d = a / b`` 和 ``m = a % b``。
然而，其他求解器，如 Eldarica，更喜欢语法上精确的操作。
命令行标志 ``--model-checker-div-mod-no-slacks`` 和 JSON 选项 ``settings.modelChecker.divModNoSlacks`` 可用于根据所使用的求解器偏好切换编码。

Natspec 函数抽象
==================

某些函数，包括常见的数学方法，如 ``pow`` 和 ``sqrt``，可能过于复杂，无法以完全自动化的方式进行分析。
这些函数可以使用 Natspec 标签进行注释，指示 SMTChecker 这些函数应该被抽象化。这意味着函数的主体不被使用，当调用时，函数将：

- 返回一个非确定性值，并且如果抽象函数是视图/纯函数，则保持状态变量不变，否则还会将状态变量设置为非确定性值。可以通过注释 ``/// @custom:smtchecker abstract-function-nondet`` 使用此功能。
- 作为一个未解释的函数。这意味着函数的语义（由主体给出）被忽略，只有在给定相同输入时，该函数保证相同输出的属性。此功能目前正在开发中，将通过注释 ``/// @custom:smtchecker abstract-function-uf`` 提供。

.. _smtchecker_engines:

模型检查引擎
================

SMTChecker 模块实现了两种不同的推理引擎，有限模型检查器（BMC）和约束霍恩子句（CHC）系统。这两种引擎目前都在开发中，并具有不同的特性。
这两种引擎是独立的，每个属性警告状态都说明了它来自哪个引擎。请注意，上述所有带有反例的示例都是由 CHC 报告的，这是更强大的引擎。

默认情况下，使用这两种引擎，其中 CHC 首先运行，所有未证明的属性将被传递给 BMC。你可以通过 CLI 选项 ``--model-checker-engine {all,bmc,chc,none}`` 或 JSON 选项 ``settings.modelChecker.engine={all,bmc,chc,none}`` 选择特定引擎。

有限模型检查器（BMC）
----------------------

BMC 引擎独立分析函数，即在分析每个函数时不考虑合约在多个交易中的整体行为。目前，该引擎也忽略循环。
内部函数调用在不递归的情况下被内联，无论是直接还是间接。外部函数调用如果可能也会被内联。可能受重入影响的知识会被抹去。
上述特性使得 BMC 容易报告误报，但它也很轻量，应该能够快速找到小的局部错误。

约束霍恩子句 (CHC)
------------------------------

合约的控制流图 (CFG) 被建模为一个霍恩子句系统，其中合约的生命周期由一个循环表示，该循环可以非确定性地访问每个公共/外部函数。通过这种方式，在分析任何函数时，考虑了合约在无限数量的交易中的整体行为。该引擎完全支持循环。支持内部函数调用，外部函数调用假设被调用的代码是未知的，并且可以执行任何操作。

在证明能力方面，CHC 引擎比 BMC 更强大，可能需要更多的计算资源。

SMT 和霍恩求解器
====================

上述两个引擎使用自动定理证明器作为其逻辑后端。BMC 使用 SMT 求解器，而 CHC 使用霍恩求解器。通常同一个工具可以同时充当这两者，如 `z3 <https://github.com/Z3Prover/z3>`_，它主要是一个 SMT 求解器，并提供 `Spacer <https://spacer.bitbucket.io/>`_ 作为霍恩求解器，以及 `Eldarica <https://github.com/uuverifiers/eldarica>`_，它同时支持这两者。

用户可以通过 CLI 选项 ``--model-checker-solvers {all,cvc5,eld,smtlib2,z3}`` 或 JSON 选项 ``settings.modelChecker.solvers=[smtlib2,z3]`` 来选择要使用的求解器（如果可用），其中：

- ``cvc5`` 通过其二进制文件使用，必须在系统中安装。只有 BMC 使用 ``cvc5``。
- ``eld`` 通过其二进制文件使用，必须在系统中安装。只有 CHC 使用 ``eld``，并且仅在未启用 ``z3`` 的情况下。
- ``smtlib2`` 以 `smtlib2 <http://smtlib.cs.uiowa.edu/>`_ 格式输出 SMT/Horn 查询。这可以与编译器的 `callback mechanism <https://github.com/ethereum/solc-js>`_ 一起使用，以便系统中的任何求解器二进制文件可以同步返回查询结果给编译器。这可以被 BMC 和 CHC 使用，具体取决于调用了哪些求解器。
- ``z3`` 可用

  - 如果 ``solc`` 是用它编译的；
  - 如果在 Linux 系统中安装了版本 >=4.8.x 的动态 ``z3`` 库（从 Solidity 0.7.6 开始）；
  - 静态在 ``soljson.js`` 中（从 Solidity 0.6.9 开始），即编译器的 JavaScript 二进制文件。

.. note::
  z3 版本 4.8.16 打破了与之前版本的 ABI 兼容性，不能与 solc <=0.8.13 一起使用。如果你使用 z3 >=4.8.16，请使用 solc >=0.8.14，反之亦然，仅在较旧的 solc 版本中使用较旧的 z3 版本。我们还建议使用最新的 z3 版本，这也是 SMTChecker 的做法。

由于 BMC 和 CHC 都使用 ``z3``，并且 ``z3`` 在更广泛的环境中可用，包括浏览器，大多数用户几乎不需要担心此选项。更高级的用户可能会应用此选项以尝试在更复杂的问题上使用替代求解器。

请注意，某些引擎和求解器的组合将导致 SMTChecker 无法执行任何操作，例如选择 CHC 和 ``cvc5``。

*******************************
抽象和误报
*******************************

SMTChecker 以不完整和健全的方式实现了抽象：如果报告了一个错误，它可能是由抽象引入的误报（由于抹去知识或使用不精确的类型）。如果它确定一个验证目标是安全的，那么它确实是安全的，即没有误报（除非 SMTChecker 中存在错误）。

如果无法证明一个目标，你可以尝试通过使用上一节中的调优选项来帮助求解器。如果你确定是误报，在代码中添加 ``require`` 语句以提供更多信息也可能会增强求解器的能力。

SMT 编码和类型
======================

SMTChecker 编码尽量做到尽可能精确，将 Solidity 类型和表达式映射到其最接近的 `SMT-LIB <http://smtlib.cs.uiowa.edu/>`_ 表示，如下表所示。

+-----------------------+--------------------------------+-----------------------------+
|Solidity type          |SMT sort                        |Theories                     |
+=======================+================================+=============================+
|Boolean                |Bool                            |Bool                         |
+-----------------------+--------------------------------+-----------------------------+
|intN, uintN, address,  |Integer                         |LIA, NIA                     |
|bytesN, enum, contract |                                |                             |
+-----------------------+--------------------------------+-----------------------------+
|array, mapping, bytes, |Tuple                           |Datatypes, Arrays, LIA       |
|string                 |(Array elements, Integer length)|                             |
+-----------------------+--------------------------------+-----------------------------+
|struct                 |Tuple                           |Datatypes                    |
+-----------------------+--------------------------------+-----------------------------+
|other types            |Integer                         |LIA                          |
+-----------------------+--------------------------------+-----------------------------+

尚不支持的类型被抽象为单个 256 位无符号整数，其不支持的操作被忽略。

有关 SMT 编码如何在内部工作的更多详细信息，请参见论文 `SMT-based Verification of Solidity Smart Contracts <https://github.com/chriseth/solidity_isola/blob/master/main.pdf>`_。

函数调用
==============

在 BMC 引擎中，尽可能将对同一合约（或基合约）的函数调用内联，即在其实现可用时。对其他合约中函数的调用不会内联，即使其代码可用，因为我们无法保证实际部署的代码是相同的。

CHC 引擎创建使用被调用函数摘要的非线性霍恩子句，以支持内部函数调用。外部函数调用被视为对未知代码的调用，包括潜在的重入调用。

复杂的纯函数通过对参数的未解释函数 (UF) 进行抽象。

+-----------------------------------+--------------------------------------+
|Functions                          |BMC/CHC behavior                      |
+===================================+======================================+
|``assert``                         |Verification target.                  |
+-----------------------------------+--------------------------------------+
|``require``                        |Assumption.                           |
+-----------------------------------+--------------------------------------+
|internal call                      |BMC: Inline function call.            |
|                                   |CHC: Function summaries.              |
+-----------------------------------+--------------------------------------+
|external call to known code        |BMC: Inline function call or          |
|                                   |erase knowledge about state variables |
|                                   |and local storage references.         |
|                                   |CHC: Assume called code is unknown.   |
|                                   |Try to infer invariants that hold     |
|                                   |after the call returns.               |
+-----------------------------------+--------------------------------------+
|Storage array push/pop             |Supported precisely.                  |
|                                   |Checks whether it is popping an       |
|                                   |empty array.                          |
+-----------------------------------+--------------------------------------+
|ABI functions                      |Abstracted with UF.                   |
+-----------------------------------+--------------------------------------+
|``addmod``, ``mulmod``             |Supported precisely.                  |
+-----------------------------------+--------------------------------------+
|``gasleft``, ``blockhash``,        |Abstracted with UF.                   |
|``keccak256``, ``ecrecover``       |                                      |
|``ripemd160``                      |                                      |
+-----------------------------------+--------------------------------------+
|pure functions without             |Abstracted with UF                    |
|implementation (external or        |                                      |
|complex)                           |                                      |
+-----------------------------------+--------------------------------------+
|external functions without         |BMC: Erase state knowledge and assume |
|implementation                     |result is nondeterministic.           |
|                                   |CHC: Nondeterministic summary.        |
|                                   |Try to infer invariants that hold     |
|                                   |after the call returns.               |
+-----------------------------------+--------------------------------------+
|transfer                           |BMC: Checks whether the contract's    |
|                                   |balance is sufficient.                |
|                                   |CHC: does not yet perform the check.  |
+-----------------------------------+--------------------------------------+
|others                             |Currently unsupported                 |
+-----------------------------------+--------------------------------------+

使用抽象意味着失去精确的知识，但在许多情况下并不意味着失去证明能力。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Recover
    {
        function f(
            bytes32 hash,
            uint8 v1, uint8 v2,
            bytes32 r1, bytes32 r2,
            bytes32 s1, bytes32 s2
        ) public pure returns (address) {
            address a1 = ecrecover(hash, v1, r1, s1);
            require(v1 == v2);
            require(r1 == r2);
            require(s1 == s2);
            address a2 = ecrecover(hash, v2, r2, s2);
            assert(a1 == a2);
            return a1;
        }
    }

在上面的例子中，SMTChecker 的表达能力不足以实际计算 ``ecrecover``，但通过将函数调用建模为未解释的函数，我们知道在等效参数上调用时返回值是相同的。这足以证明上面的断言始终为真。

对于已知是确定性的函数，可以通过 UF 抽象函数调用，并且对于纯函数可以轻松做到。然而，对于一般的外部函数，这很难做到，因为它们可能依赖于状态变量。

引用类型和别名
============================

Solidity 对具有相同 :ref:`data location<data-location>` 的引用类型实现了别名。这意味着一个变量可以通过对同一数据区域的引用进行修改。SMTChecker 不跟踪哪些引用指向相同的数据。这意味着每当分配引用类型的局部引用或状态变量时，所有关于相同类型和数据位置的变量的知识都会被抹去。如果类型是嵌套的，知识的移除还包括所有前缀基本类型。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.0;

    contract Aliasing
    {
        uint[] array1;
        uint[][] array2;
        function f(
            uint[] memory a,
            uint[] memory b,
            uint[][] memory c,
            uint[] storage d
        ) internal {
            array1[0] = 42;
            a[0] = 2;
            c[0][0] = 2;
            b[0] = 1;
            // 抹去关于内存引用的知识不应
            // 抹去关于状态变量的知识。
            assert(array1[0] == 42);
            // 然而，对存储引用的赋值将相应地抹去存储知识。
            d[0] = 2;
            // 由于上面的赋值而错误地失败。
            assert(array1[0] == 42);
            // 由于可能存在 `a == b` 而失败。
            assert(a[0] == 2);
            // 由于可能存在 `c[i] == b` 而失败。
            assert(c[0][0] == 2);
            assert(d[0] == 2);
            assert(b[0] == 1);
        }
        function g(
            uint[] memory a,
            uint[] memory b,
            uint[][] memory c,
            uint x
        ) public {
            f(a, b, c, array2[x]);
        }
    }

在对 ``b[0]`` 赋值后，我们需要清除对 ``a`` 的知识，因为它具有相同的类型（``uint[]``）和数据位置（内存）。我们还需要清除对 ``c`` 的知识，因为它的基本类型也是位于内存中的 ``uint[]``。这意味着某些 ``c[i]`` 可能指向与 ``b`` 或 ``a`` 相同的数据。

请注意，我们不清除对 ``array`` 和 ``d`` 的知识，因为它们位于存储中，即使它们也具有类型 ``uint[]``。然而，如果对 ``d`` 进行了赋值，我们将需要清除对 ``array`` 的知识，反之亦然。

合约余额
================

合约可以在部署时接收资金，如果在部署交易中 ``msg.value`` > 0。然而，合约的地址在部署之前可能已经有资金，这些资金由合约保留。因此，SMTChecker 假设在构造函数中 ``address(this).balance >= msg.value`` 以与 EVM 规则保持一致。合约的余额也可能在不触发任何对合约的调用的情况下增加，如果

- ``selfdestruct`` 被另一个合约执行，且分析的合约是剩余资金的目标，
- 合约是某个区块的 coinbase（即 ``block.coinbase``）。

为了正确建模，SMTChecker 假设在每个新交易中合约的余额可能至少增加 ``msg.value``。

**********************
现实世界假设
**********************

某些场景可以在 Solidity 和 EVM 中表达，但预计在实践中永远不会发生。这样的情况之一是动态存储数组在推送时溢出长度：如果对长度为 2^256 - 1 的数组应用 ``push`` 操作，其长度会静默溢出。然而，这在实践中不太可能发生，因为将数组增长到该点所需的操作将需要数十亿年的时间来执行。SMTChecker 采取的另一个类似假设是地址的余额永远不会溢出。

类似的想法在 `EIP-1985 <https://eips.ethereum.org/EIPS/eip-1985>`_ 中提出。