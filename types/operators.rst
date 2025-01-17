.. index:: ! operator

运算符
=========

即使两个操作数的类型不一样，也可以进行算术和位操作运算。
例如，你可以计算 ``y = x + z``，其中 ``x`` 是 ``uint8`` 类型，而 ``z`` 的类型是 ``uint32``。
在这些情况下，将使用以下机制来确定操作计算的类型（在溢出的情况下这很重要）和运算符结果的类型：

1. 如果右操作数的类型可以隐式转换为左操作数的类型，则使用左操作数的类型，
2. 如果左操作数的类型可以隐式转换为右操作数的类型，则使用右操作数的类型，
3. 否则，操作是不允许的。

如果其中一个操作数是 :ref:`literal number <rational_literals>`，它首先会被转换为其“移动类型”，即可以容纳该值的最小类型（相同位宽的无符号类型被视为比有符号类型“更小”）。如果两个都是字面量数字，则操作将在有效的无限精度下计算，即表达式会被评估到所需的任何精度，以确保在与非字面量类型一起使用时没有损失。

运算符的结果类型与操作执行的类型相同，比较运算符的结果类型始终为 ``bool``。

运算符 ``**`` （指数运算）、``<<`` 和 ``>>`` 使用左操作数的类型进行操作和结果。

三元运算符
----------------
三元运算符用于形式为 ``<expression> ? <trueExpression> : <falseExpression>`` 的表达式。
它根据主 ``<expression>`` 的评估结果来评估后两个给定表达式中的一个。
如果 ``<expression>`` 评估为 ``true``，则将评估 ``<trueExpression>``，否则评估 ``<falseExpression>``。

三元运算符的结果没有有理数类型，即使它的所有操作数都是有理数字面量。
结果类型根据两个操作数的类型以与上述相同的方式确定，如果需要，首先转换为它们的移动类型。

因此，``255 + (true ? 1 : 0)`` 将因算术溢出而回退。
原因是 ``(true ? 1 : 0)`` 是 ``uint8`` 类型，这迫使加法也在 ``uint8`` 中进行，
而 256 超出了该类型允许的范围。

另一个结果是像 ``1.5 + 1.5`` 这样的表达式是有效的，但 ``1.5 + (true ? 1.5 : 2.5)`` 不是。
这是因为前者是以无限精度评估的有理表达式，只有其最终值才重要。
后者涉及将一个分数有理数转换为整数，这在目前是不允许的。

.. index:: assignment, lvalue, ! compound operators

复合和增量/减量运算符
------------------------------------------

如果 ``a`` 是 LValue（即变量或可以赋值的东西），则可以使用以下运算符作为简写：

``a += e`` 等价于 ``a = a + e``。运算符 ``-=``, ``*=``, ``/=``, ``%=``,
``|=``, ``&=``, ``^=``, ``<<=`` 和 ``>>=`` 也相应地定义。 ``a++`` 和 ``a--`` 等价于
``a += 1`` / ``a -= 1``，但表达式本身仍然具有 ``a`` 的先前值。
相反，``--a`` 和 ``++a`` 对 ``a`` 的影响相同，但返回更改后的值。

.. index:: !delete

.. _delete:

delete
------

``delete a`` 将类型的初始值分配给 ``a``。即对于整数，它等价于 ``a = 0``，但它也可以用于数组，在这种情况下，它分配一个长度为零的动态数组或一个所有元素都设置为其初始值的相同长度的静态数组。 
``delete a[x]`` 删除数组中索引为 ``x`` 的项，并保持所有其他元素和数组的长度不变。这尤其意味着它在数组中留下了一个空隙。如果你计划删除项， :ref:`mapping <mapping-types>` 可能是更好的选择。

对于结构体，它会分配一个所有成员重置的结构体。
换句话说，``delete a`` 之后 ``a`` 的值与 ``a`` 被声明而没有赋值时相同，但有以下警告：

``delete`` 对映射没有影响（因为映射的键可能是任意的，通常是未知的）。
因此，如果你删除一个结构体，它将重置所有非映射的成员，并且也会递归到成员中，除非它们是映射。
然而，单个键及其映射的值可以被删除：如果 ``a`` 是一个映射，则 ``delete a[x]`` 将删除存储在 ``x`` 的值。

重要的是要注意，``delete a`` 实际上表现得像对 ``a`` 的赋值，即它在 ``a`` 中存储一个新对象。
这种区别在 ``a`` 是引用变量时是显而易见的：它只会重置 ``a`` 本身，而不会影响它之前所引用的值。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract DeleteExample {
        uint data;
        uint[] dataArray;

        function f() public {
            uint x = data;
            delete x; // 将 x 设为 0，并不影响数据
            delete data; // 将 data 设为 0，并不影响数据
            uint[] storage y = dataArray;
            delete dataArray; 
            // 将 dataArray.length 设为 0，但由于 uint[] 是一个复杂的对象，y 也将受到影响，
            // 因为它是一个存储位置是 storage 的对象的别名。
            // 另一方面："delete y" 是非法的，引用了 storage 对象的局部变量只能由已有的 storage 对象赋值。
            assert(y.length == 0);
        }
    }

.. index:: ! operator; precedence
.. _order:

运算符优先级顺序
--------------------------------

.. include:: types/operator-precedence-table.rst