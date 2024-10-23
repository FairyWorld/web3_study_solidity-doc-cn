.. index:: style, coding style

#############
风格指南
#############

************
介绍
************

本指南旨在提供编写 Solidity 代码的编码规范。
本指南应被视为一个不断发展的文档，随着有用规范的发现和旧规范的淘汰而变化。

许多项目将实施自己的风格指南。在发生冲突时，项目特定的风格指南优先。

本风格指南的结构和许多建议来自 Python 的
`pep8 风格指南 <https://peps.python.org/pep-0008/>`_。

本指南的目标 **不推荐** 编写 Solidity 代码的正确方式或最佳方式。 本指南的目标是 **一致性**。 
Python 的 `pep8 <https://peps.python.org/pep-0008/#a-foolish-consistency-is-the-hobgoblin-of-little-minds>`_ 很好地捕捉了这一概念。

.. note::

    风格指南是关于一致性的。遵循本风格指南的一致性很重要。项目内部的一致性更为重要。模块或函数内部的一致性是最重要的。

    但最重要的是：**知道何时不一致** -- 有时风格指南根本不适用。当有疑问时，使用你的最佳判断。查看其他示例并决定什么看起来最好。并且不要犹豫去询问！


***********
代码布局
***********


缩进
===========

每个缩进级别使用 4 个空格。

制表符或空格
==============

空格是首选的缩进方法。

应避免混合使用制表符和空格。

空行
===========

在 Solidity 源代码的顶层声明周围留出两个空行。

推荐:

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract A {
        // ...
    }


    contract B {
        // ...
    }


    contract C {
        // ...
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract A {
        // ...
    }
    contract B {
        // ...
    }

    contract C {
        // ...
    }

在合约内部，函数声明之间留出一个空行。

在相关的一行代码组之间可以省略空行（例如抽象合约的存根函数）

推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    abstract contract A {
        function spam() public virtual pure;
        function ham() public virtual pure;
    }


    contract B is A {
        function spam() public pure override {
            // ...
        }

        function ham() public pure override {
            // ...
        }
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.6.0 <0.9.0;

    abstract contract A {
        function spam() virtual pure public;
        function ham() public virtual pure;
    }


    contract B is A {
        function spam() public pure override {
            // ...
        }
        function ham() public pure override {
            // ...
        }
    }

.. _maximum_line_length:

代码行的最大长度
===================

建议的最大行长度为 120 个字符。

换行应符合以下准则。

1. 第一个参数不应附加到开括号。
2. 应仅使用一个缩进。
3. 每个参数应单独占一行。
4. 终止元素 :code:`);` 应单独放在最后一行。

函数调用

推荐：

.. code-block:: solidity

    thisFunctionCallIsReallyLong(
        longArgument1,
        longArgument2,
        longArgument3
    );

不推荐：

.. code-block:: solidity

    thisFunctionCallIsReallyLong(longArgument1,
                                  longArgument2,
                                  longArgument3
    );

    thisFunctionCallIsReallyLong(longArgument1,
        longArgument2,
        longArgument3
    );

    thisFunctionCallIsReallyLong(
        longArgument1, longArgument2,
        longArgument3
    );

    thisFunctionCallIsReallyLong(
    longArgument1,
    longArgument2,
    longArgument3
    );

    thisFunctionCallIsReallyLong(
        longArgument1,
        longArgument2,
        longArgument3);

赋值语句

推荐：

.. code-block:: solidity

    thisIsALongNestedMapping[being][set][toSomeValue] = someFunction(
        argument1,
        argument2,
        argument3,
        argument4
    );

不推荐：

.. code-block:: solidity

    thisIsALongNestedMapping[being][set][toSomeValue] = someFunction(argument1,
                                                                       argument2,
                                                                       argument3,
                                                                       argument4);

事件定义和事件发射器

推荐：

.. code-block:: solidity

    event LongAndLotsOfArgs(
        address sender,
        address recipient,
        uint256 publicKey,
        uint256 amount,
        bytes32[] options
    );

    emit LongAndLotsOfArgs(
        sender,
        recipient,
        publicKey,
        amount,
        options
    );

不推荐：

.. code-block:: solidity

    event LongAndLotsOfArgs(address sender,
                            address recipient,
                            uint256 publicKey,
                            uint256 amount,
                            bytes32[] options);

    emit LongAndLotsOfArgs(sender,
                      recipient,
                      publicKey,
                      amount,
                      options);

源文件编码
====================

首选 UTF-8 或 ASCII 编码。

导入
=======

导入语句应始终放在文件的顶部。

推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    import "./Owned.sol";

    contract A {
        // ...
    }


    contract B is Owned {
        // ...
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract A {
        // ...
    }


    import "./Owned.sol";


    contract B is Owned {
        // ...
    }

函数顺序
==================

排序有助于读者识别可以调用的函数，并更容易找到构造函数和回退定义。

函数应根据其可见性进行分组并排序：

- 构造函数
- 接收函数（如果存在）
- 回退函数（如果存在）
- 外部
- 公共
- 内部
- 私有

在一个分组内，将 ``view`` 和 ``pure`` 函数放在最后。

推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    contract A {
        constructor() {
            // ...
        }

        receive() external payable {
            // ...
        }

        fallback() external {
            // ...
        }

        // 外部函数
        // ...

        // 视图的外部函数
        // ...

        // 纯的外部函数
        // ...

        // 公共函数
        // ...

        // 内部函数
        // ...

        // 私有函数
        // ...
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    contract A {

        // 外部函数
        // ...

        fallback() external {
            // ...
        }
        receive() external payable {
            // ...
        }

        // 私有函数
        // ...

        // 公共函数
        // ...

        constructor() {
            // ...
        }

        // 内部函数
        // ...
    }

表达式中的空格
=========================

避免在以下情况下出现多余的空格：

除单行函数声明外，紧接着小括号，中括号或者大括号的内容应该避免使用空格。

推荐：

.. code-block:: solidity

    spam(ham[1], Coin({name: "ham"}));

不推荐：

.. code-block:: solidity

    spam( ham[ 1 ], Coin( { name: "ham" } ) );

例外：

.. code-block:: solidity

    function singleLine() public { spam(); }

在逗号、分号之前：

推荐：

.. code-block:: solidity

    function spam(uint i, Coin coin) public;

推荐：

.. code-block:: solidity

    function spam(uint i , Coin coin) public ;

在赋值或其他运算符周围有多个空格以对齐另一个：

推荐：
.. code-block:: solidity

    x = 1;
    y = 2;
    longVariable = 3;

不推荐：

.. code-block:: solidity

    x            = 1;
    y            = 2;
    longVariable = 3;

在接收和回退函数中不要包含空白：

推荐：
.. code-block:: solidity

    receive() external payable {
        ...
    }

    fallback() external {
        ...
    }

不推荐：

.. code-block:: solidity

    receive () external payable {
        ...
    }

    fallback () external {
        ...
    }


控制结构
==================

表示合约、库、函数和结构体主体的大括号应：

* 在声明的同一行打开
* 在与声明开始相同的缩进级别上关闭
* 开括号前应有一个空格

推荐：
.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract Coin {
        struct Bank {
            address owner;
            uint balance;
        }
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract Coin
    {
        struct Bank {
            address owner;
            uint balance;
        }
    }

同样的建议适用于控制结构 ``if``, ``else``, ``while``, 和 ``for``。

此外，控制结构 ``if``, ``while``, 和 ``for`` 与表示条件的括号块之间应有一个空格，以及条件括号块与开括号之间也应有一个空格。

推荐：
.. code-block:: solidity

    if (...) {
        ...
    }

    for (...) {
        ...
    }

不推荐：

.. code-block:: solidity

    if (...)
    {
        ...
    }

    while(...){
    }

    for (...) {
        ...;}

对于包含单个语句的控制结构，*如果* 语句包含在单行中，则可以省略大括号。

推荐：
.. code-block:: solidity

    if (x < 10)
        x += 1;

不推荐：

.. code-block:: solidity

    if (x < 10)
        someArray.push(Coin({
            name: 'spam',
            value: 42
        }));

对于具有 ``else`` 或 ``else if`` 子句的 ``if`` 块，``else`` 应放在 ``if`` 的闭合大括号的同一行。这与其他块状结构的规则有所不同。

推荐：
.. code-block:: solidity

    if (x < 3) {
        x += 1;
    } else if (x > 7) {
        x -= 1;
    } else {
        x = 5;
    }


    if (x < 3)
        x += 1;
    else
        x -= 1;

不推荐：

.. code-block:: solidity

    if (x < 3) {
        x += 1;
    }
    else {
        x -= 1;
    }

函数声明
====================

对于短函数声明，建议将函数体的开括号与函数声明保持在同一行。

闭合大括号应与函数声明保持相同的缩进级别。

开括号前应有一个空格。

推荐：
.. code-block:: solidity

    function increment(uint x) public pure returns (uint) {
        return x + 1;
    }

    function increment(uint x) public pure onlyOwner returns (uint) {
        return x + 1;
    }

不推荐：

.. code-block:: solidity

    function increment(uint x) public pure returns (uint)
    {
        return x + 1;
    }

    function increment(uint x) public pure returns (uint){
        return x + 1;
    }

    function increment(uint x) public pure returns (uint) {
        return x + 1;
        }

    function increment(uint x) public pure returns (uint) {
        return x + 1;}

函数的修改器顺序应为：

1. 可见性
2. 可变性
3. 虚拟
4. 重写
5. 自定义修改器

推荐：
.. code-block:: solidity

    function balance(uint from) public view override returns (uint)  {
        return balanceOf[from];
    }

    function increment(uint x) public pure onlyOwner returns (uint) {
        return x + 1;
    }


不推荐：

.. code-block:: solidity

    function balance(uint from) public override view returns (uint)  {
        return balanceOf[from];
    }

    function increment(uint x) onlyOwner public pure returns (uint) {
        return x + 1;
    }

对于长函数声明，建议将每个参数放在与函数体相同的缩进级别的单独一行。闭合括号和开括号也应放在与函数声明相同的缩进级别的单独一行。

推荐：
.. code-block:: solidity

    function thisFunctionHasLotsOfArguments(
        address a,
        address b,
        address c,
        address d,
        address e,
        address f
    )
        public
    {
        doSomething();
    }

不推荐：

.. code-block:: solidity

    function thisFunctionHasLotsOfArguments(address a, address b, address c,
        address d, address e, address f) public {
        doSomething();
    }

    function thisFunctionHasLotsOfArguments(address a,
                                            address b,
                                            address c,
                                            address d,
                                            address e,
                                            address f) public {
        doSomething();
    }

    function thisFunctionHasLotsOfArguments(
        address a,
        address b,
        address c,
        address d,
        address e,
        address f) public {
        doSomething();
    }

如果长函数声明有修改器，则每个修改器应放在自己的行上。

推荐：
.. code-block:: solidity

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public
        onlyOwner
        priced
        returns (address)
    {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(
        address x,
        address y,
        address z
    )
        public
        onlyOwner
        priced
        returns (address)
    {
        doSomething();
    }

不推荐：

.. code-block:: solidity

    function thisFunctionNameIsReallyLong(address x, address y, address z)
                                          public
                                          onlyOwner
                                          priced
                                          returns (address) {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public onlyOwner priced returns (address)
    {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public
        onlyOwner
        priced
        returns (address) {
        doSomething();
    }

多行输出参数和返回语句应遵循 :ref:`代码行的最大长度 <maximum_line_length>` 部分推荐的长行换行样式。

推荐：
.. code-block:: solidity

    function thisFunctionNameIsReallyLong(
        address a,
        address b,
        address c
    )
        public
        returns (
            address someAddressName,
            uint256 LongArgument,
            uint256 Argument
        )
    {
        doSomething()

        return (
            veryLongReturnArg1,
            veryLongReturnArg2,
            veryLongReturnArg3
        );
    }

不推荐：

.. code-block:: solidity

    function thisFunctionNameIsReallyLong(
        address a,
        address b,
        address c
    )
        public
        returns (address someAddressName,
                uint256 LongArgument,
                uint256 Argument)
    {
        doSomething()

        return (veryLongReturnArg1,
                veryLongReturnArg1,
                veryLongReturnArg1);
    }

对于需要参数的继承合约的构造函数，如果函数声明较长或难以阅读，建议将基构造函数换行，方式与修改器相同。

推荐：
.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    // 基合约仅用于使其编译
    contract B {
        constructor(uint) {
        }
    }


    contract C {
        constructor(uint, uint) {
        }
    }


    contract D {
        constructor(uint) {
        }
    }


    contract A is B, C, D {
        uint x;

        constructor(uint param1, uint param2, uint param3, uint param4, uint param5)
            B(param1)
            C(param2, param3)
            D(param4)
        {
            // 使用 param5 做一些事情
            x = param5;
        }
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    // 基合约仅用于使其编译
    contract B {
        constructor(uint) {
        }
    }


    contract C {
        constructor(uint, uint) {
        }
    }


    contract D {
        constructor(uint) {
        }
    }


    contract A is B, C, D {
        uint x;

        constructor(uint param1, uint param2, uint param3, uint param4, uint param5)
        B(param1)
        C(param2, param3)
        D(param4) {
            x = param5;
        }


    contract X is B, C, D {
        uint x;

        constructor(uint param1, uint param2, uint param3, uint param4, uint param5)
            B(param1)
            C(param2, param3)
            D(param4) {
                x = param5;
            }
    }


在声明只有一条语句的短函数时，可以将其放在同一行。

允许：

.. code-block:: solidity

    function shortFunction() public { doSomething(); }

这些函数声明的指南旨在提高可读性。
作者应根据自己的最佳判断使用这些指南，因为该指南并未尝试涵盖所有可能的函数声明排列。

映射
========

在变量声明中，不要在关键字 ``mapping`` 和其类型之间添加空格。不要在任何嵌套的 ``mapping`` 关键字与其类型之间添加空格。

推荐：
.. code-block:: solidity

    mapping(uint => uint) map;
    mapping(address => bool) registeredAddresses;
    mapping(uint => mapping(bool => Data[])) public data;
    mapping(uint => mapping(uint => s)) data;

不推荐：

.. code-block:: solidity

    mapping (uint => uint) map;
    mapping( address => bool ) registeredAddresses;
    mapping (uint => mapping (bool => Data[])) public data;
    mapping(uint => mapping (uint => s)) data;

变量声明
=====================

数组变量的声明之间不应在类型和括号之间添加空格。

推荐：
.. code-block:: solidity

    uint[] x;

不推荐：

.. code-block:: solidity

    uint [] x;


其他建议
=====================

* 字符串应使用双引号而不推荐单引号。

推荐：
.. code-block:: solidity

    str = "foo";
    str = "Hamlet says, 'To be or not to be...'";

不推荐：

.. code-block:: solidity

    str = 'bar';
    str = '"Be yourself; everyone else is already taken." -Oscar Wilde';

* 操作符两侧应各有一个空格。

推荐：
.. code-block:: solidity
    :force:

    x = 3;
    x = 100 / 10;
    x += 3 + 4;
    x |= y && z;

不推荐：

.. code-block:: solidity
    :force:

    x=3;
    x = 100/10;
    x += 3+4;
    x |= y&&z;

* 优先级高于其他操作符的操作符可以省略周围的空格，以表示优先级。这是为了提高复杂语句的可读性。你应始终在操作符的两侧使用相同数量的空格：

推荐：
.. code-block:: solidity

        x = 2**3 + 5;
        x = 2*y + 3*z;
        x = (a+b) * (a-b);

不推荐：

.. code-block:: solidity

    x = 2** 3 + 5;
    x = y+z;
    x +=1;

***************
布局顺序
***************

合约元素应按以下顺序布局：

1. Pragma 语句
2. 导入语句
3. 事件
4. 错误
5. 接口
6. 库
7. 合约

在每个合约、库或接口内部，使用以下顺序：

1. 类型声明
2. 状态变量
3. 事件
4. 错误
5. 修改器
6. 函数

.. note::

    在事件或状态变量中，声明类型可能更清晰。

推荐：
.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.4 <0.9.0;

    abstract contract Math {
        error DivideByZero();
        function divide(int256 numerator, int256 denominator) public virtual returns (uint256);
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.8.4 <0.9.0;

    abstract contract Math {
        function divide(int256 numerator, int256 denominator) public virtual returns (uint256);
        error DivideByZero();
    }


******************
命名规范
******************

命名规范在广泛采用和使用时是强大的。使用不同的规范可以传达重要的 *元* 信息，这些信息在其他情况下可能不会立即可用。

这里给出的命名建议旨在提高可读性，因此它们不推荐规则，而是旨在帮助通过事物的名称传达最多信息的指南。

最后，代码库中的一致性应始终优先于本文件中概述的任何规范。


命名风格
=============

为避免混淆，以下名称将用于指代不同的命名风格。

* ``b`` (单个小写字母)
* ``B`` (单个大写字母)
* ``lowercase`` （小写）
* ``UPPERCASE`` （大写）
* ``UPPER_CASE_WITH_UNDERSCORES`` （大写和下划线）
* ``CapitalizedWords`` (驼峰式，首字母大写）
* ``mixedCase`` (混合式，与驼峰式的区别在于首字母小写！)

.. note:: 在使用 CapWords 中的首字母缩略词时，所有字母都应大写。
    因此，HTTPServerError 比 HttpServerError 更好。
    在使用 mixedCase 中的首字母缩略词时，所有字母都应大写，除非名称开头的第一个字母小写。
    因此，xmlHTTPRequest 比 XMLHTTPRequest 更好。

避免使用的名称
==============

* ``l`` - el的小写方式
* ``O`` - oh的大写方式
* ``I`` - eye的大写方式

切勿将这些用作单字母变量名。它们通常与数字 1 和 0 无法区分。


合约和库名称
==========================

* 合约和库应使用 CapWords 风格命名。示例：``SimpleToken``、``SmartBank``、``CertificateHashRepository``、``Player``、``Congress``、``Owned``。
* 合约和库名称应与其文件名匹配。
* 如果一个合约文件包含多个合约和/或库，则文件名应与 *核心合约* 匹配。然而，如果可以避免，这并不推荐。

如下面的示例所示，如果合约名称为 ``Congress``，库名称为 ``Owned``，则它们的关联文件名应为 ``Congress.sol`` 和 ``Owned.sol``。

推荐：
.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    // Owned.sol
    contract Owned {
        address public owner;

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        constructor() {
            owner = msg.sender;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
        }
    }

在 ``Congress.sol`` 中：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    import "./Owned.sol";


    contract Congress is Owned, TokenRecipient {
        //...
    }

不推荐：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;

    // owned.sol
    contract owned {
        address public owner;

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        constructor() {
            owner = msg.sender;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
        }
    }

在 ``Congress.sol`` 中：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.7.0;


    import "./owned.sol";


    contract Congress is owned, tokenRecipient {
        //...
    }

结构体名称
==========================

结构体名称应该使用驼峰式风格。示例：``MyCoin``、``Position``、``PositionXY``。


事件名称
===========

事件名称应该使用驼峰式风格。示例：``Deposit``、``Transfer``、``Approval``、``BeforeTransfer``、``AfterTransfer``。


函数名称
==============

函数应该使用混合式命名风格。示例：``getBalance``、``transfer``、``verifyOwner``、``addMember``、``changeOwner``。


函数参数名称
=======================

函数参数命名应该使用混合式命名风格。示例：``initialSupply``、``account``、``recipientAddress``、``senderAddress``、``newOwner``。

在编写操作自定义结构的库函数时，结构应为第一个参数，并始终命名为 ``self``。


局部和状态变量名称
==============================

使用混合式命名风格。示例：``totalSupply``、``remainingSupply``、``balancesOf``、``creatorAddress``、``isPreSale``、``tokenExchangeRate``。


常量
=========

常量应使用全大写字母，并用下划线分隔单词。示例：``MAX_BLOCKS``、``TOKEN_NAME``、``TOKEN_TICKER``、``CONTRACT_VERSION``。


修改器名称
==============

使用混合式命名风格。示例：``onlyBy``、``onlyAfter``、``onlyDuringThePreSale``。


枚举
=====

在声明简单类型时，枚举应该使用驼峰式风格。示例：``TokenGroup``、``Frame``、``HashStyle``、``CharacterLocation``。


避免命名冲突
==========================

* ``singleTrailingUnderscore_``

当所需名称与现有状态变量、函数、内置或其他保留名称冲突时，建议使用此规范。

非外部函数和变量的下划线前缀
==========================================================

* ``_singleLeadingUnderscore``

建议对非外部函数和状态变量（``private`` 或 ``internal``）使用此规范。未指定可见性的状态变量默认是 ``internal``。

在设计智能合约时，面向公众的 API（任何账户都可以调用的函数）是一个重要的考虑因素。
前导下划线使你能够立即识别此类函数的意图，但更重要的是，如果你将函数从非外部更改为外部（包括 ``public``）并相应重命名，这将迫使你在重命名时检查每个调用点。
这可以作为防止意外外部函数的重要手动检查，并且是常见的安全漏洞来源（避免使用查找替换所有工具进行此更改）。

.. _style_guide_natspec:

*******
NatSpec
*******

Solidity 合约还可以包含 NatSpec 注释。它们使用三重斜杠（``///``）或双星号块（``/** ... */``）编写，应该直接放在函数声明或语句上方。

例如，来自 :ref:`a simple smart contract <simple-smart-contract>` 的合约，添加注释后的样子如下：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.16 <0.9.0;

    /// @author The Solidity Team
    /// @title A simple storage example
    contract SimpleStorage {
        uint storedData;

        /// Store `x`.
        /// @param x the new value to store
        /// @dev stores the number in the state variable `storedData`
        function set(uint x) public {
            storedData = x;
        }

        /// Return the stored value.
        /// @dev retrieves the value of the state variable `storedData`
        /// @return the stored value
        function get() public view returns (uint) {
            return storedData;
        }
    }

建议 Solidity 合约对所有公共接口（ABI 中的所有内容）进行全面注释，使用 :ref:`NatSpec <natspec>`。

有关详细说明，请参见 :ref:`NatSpec <natspec>` 部分。