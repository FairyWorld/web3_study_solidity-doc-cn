.. index:: optimizer, optimiser, common subexpression elimination, constant propagation
.. _optimizer:

*************
优化器
*************

Solidity 编译器在三个不同的层面上进行优化（按执行顺序）：

- 基于对 Solidity 代码的直接分析进行的代码生成优化。
- 对 Yul IR 代码的优化变换。
- 在操作码级别的优化。

基于操作码的优化器对操作码应用一组 `简化规则 <https://github.com/ethereum/solidity/blob/develop/libevmasm/RuleList.h>`_。
它还会合并相等的代码集并移除未使用的代码。

基于 Yul 的优化器更为强大，因为它可以跨函数调用进行工作。
例如，在 Yul 中不可能进行任意跳转，因此可以计算每个函数的副作用。
考虑两个函数调用，第一个不修改存储，第二个修改存储。
如果它们的参数和返回值彼此不依赖，我们可以重新排序函数调用。
同样，如果一个函数是无副作用的，并且其结果乘以零，则可以完全移除该函数调用。

基于代码生成的优化器影响从 Solidity 输入生成的初始低级代码。
在传统管道中，字节码立即生成，并且这种类型的大多数优化是隐式的且不可配置，唯一的例外是改变二进制操作中字面量顺序的优化。
基于 IR 的管道采取不同的方法，生成与 Solidity 代码结构紧密匹配的 Yul IR，几乎所有优化都推迟到 Yul 优化器模块。
在这种情况下，代码生成级别的优化仅在一些难以在 Yul IR 中处理的非常有限的情况下进行，但在分析阶段有高层信息时则很简单。
这样的优化示例是绕过在某些习惯用法的 ``for`` 循环中递增计数器时的检查算术。

目前，参数 ``--optimize`` 激活生成字节码的基于操作码的优化器，以及为内部生成的 Yul 代码（例如 ABI 编码器 v2）激活 Yul 优化器。
可以使用 ``solc --ir-optimized --optimize`` 为 Solidity 源生成优化的 Yul IR。同样，可以使用 ``solc --strict-assembly --optimize`` 进行独立的 Yul 模式。

.. note::
    一些优化器步骤，例如 `peephole optimizer <https://en.wikipedia.org/wiki/Peephole_optimization>`_ 和 :ref:`unchecked loop increment optimizer <unchecked-loop-optimizer>` 默认始终启用，
    并且只能通过 :ref:`Standard JSON <compiler-api>` 关闭。

.. note::
    空的优化器序列，即 ``:``, 即使没有 ``--optimize`` 也被接受，以完全禁用用户提供的 Yul :ref:`optimizer sequence <selecting-optimizations>`，
    因为默认情况下，即使优化器未开启， :ref:`unused pruner <unused-pruner>` 步骤也会运行。

你可以在下面找到有关两个优化器模块及其优化步骤的更多详细信息。

优化 Solidity 代码的好处
=========================

总体而言，优化器试图简化复杂的表达式，从而减少代码大小和执行成本，即，它可以减少合约部署所需的 gas 以及对合约进行的外部调用所需的 gas。
它还会专门化或内联函数。特别是函数内联是一种可能导致代码变大的操作，但通常会这样做，因为它会带来更多简化的机会。

优化代码与非优化代码的区别
=============================

通常，最明显的区别是常量表达式在编译时被评估。当涉及 ASM 输出时，还可以注意到等效或重复代码块的减少（比较标志 ``--asm`` 和 ``--asm --optimize`` 的输出）。
然而，当涉及 Yul/中间表示时，可能会有显著的差异，例如，函数可能被内联、合并或重写以消除冗余等（比较标志 ``--ir`` 和 ``--optimize --ir-optimized`` 之间的输出）。

.. _optimizer-parameter-runs:

优化器参数运行
=================

运行次数（``--optimize-runs``）大致指定每个操作码在合约生命周期内将被执行的频率。
这意味着这是一个在代码大小（部署成本）和代码执行成本（部署后的成本）之间的权衡参数。
“运行”参数为“1”将生成短但昂贵的代码。相反，较大的“运行”参数将生成更长但更节省 gas 的代码。
该参数的最大值为 ``2**32-1``。

.. note::

    一个常见的误解是该参数指定优化器的迭代次数。这并不正确：优化器将始终运行尽可能多次，只要它仍然可以改善代码。

基于操作码的优化器模块
=========================

基于操作码的优化器模块在汇编代码上操作。它在 ``JUMPs`` 和 ``JUMPDESTs`` 处将指令序列拆分为基本块。
在这些块内，优化器分析指令并记录对堆栈、内存或存储的每次修改，作为由指令和指向其他表达式的参数列表组成的表达式。

此外，基于操作码的优化器使用一个名为“CommonSubexpressionEliminator”的组件，该组件在其他任务中，查找在每个输入上始终相等的表达式，并将它们合并为一个表达式类。
它首先尝试在已知表达式列表中查找每个新表达式。如果没有找到这样的匹配项，它会根据规则简化表达式，例如 ``constant + constant = sum_of_constants`` 或 ``X * 1 = X``。
由于这是一个递归过程，我们还可以在第二个因子是我们知道始终评估为一的更复杂表达式时应用后一个规则。

某些优化器步骤符号跟踪存储和内存位置。例如，这些信息用于计算可以在编译时评估的 Keccak-256 哈希。考虑以下序列：

.. code-block:: none

    PUSH 32
    PUSH 0
    CALLDATALOAD
    PUSH 100
    DUP2
    MSTORE
    KECCAK256

或等效的 Yul

.. code-block:: yul

    let x := calldataload(0)
    mstore(x, 100)
    let value := keccak256(x, 32)

在这种情况下，优化器跟踪内存位置 ``calldataload(0)`` 的值，然后意识到 Keccak-256 哈希可以在编译时评估。
只有在 ``mstore`` 和 ``keccak256`` 之间没有其他指令修改内存时，这才有效。
因此，如果有一条指令写入内存（或存储），则我们需要抹去当前内存（或存储）的知识。
然而，在我们可以轻松看到指令不写入某个位置时，这种抹去是有例外的。

例如，

.. code-block:: yul

    let x := calldataload(0)
    mstore(x, 100)
    // 当前知识内存位置 x -> 100
    let y := add(x, 32)
    // 不会清除 x -> 100 的知识，因为 y 不写入 [x, x + 32)
    mstore(y, 200)
    // 现在可以评估这个 Keccak-256
    let value := keccak256(x, 32)

因此，对存储和内存位置的修改，例如位置 ``l``，必须抹去关于可能等于 ``l`` 的存储或内存位置的知识。
更具体地说，对于存储，优化器必须抹去所有可能等于 ``l`` 的符号位置的知识；而对于内存，优化器必须抹去所有可能距离至少不小于 32 字节的符号位置的知识。
如果 ``m`` 表示一个任意位置，那么通过计算值 ``sub(l, m)`` 来决定是否抹去知识。
对于存储，如果该值计算为一个非零的字面量，则关于 ``m`` 的知识将被保留。
对于内存，如果该值计算为一个在 ``32`` 和 ``2**256 - 32`` 之间的字面量，则关于 ``m`` 的知识将被保留。
在所有其他情况下，关于 ``m`` 的知识将被抹去。

经过这个过程后，我们知道在最后必须在栈上的表达式，并且有一份对内存和存储的修改列表。
这些信息与基本块一起存储，并用于链接它们。此外，关于栈、存储和内存配置的知识会被转发到下一个块。

如果我们知道所有 ``JUMP`` 和 ``JUMPI`` 指令的目标，我们可以构建程序的完整控制流图。
如果只有一个目标我们不知道（这可能发生，因为原则上，跳转目标可以从输入计算得出），我们必须抹去一个块的输入状态的所有知识，因为它可能是未知 ``JUMP`` 的目标。
如果基于操作码的优化器模块发现一个条件计算为常量的 ``JUMPI``，它会将其转换为无条件跳转。

作为最后一步，每个块中的代码会被重新生成。优化器从块末尾栈上的表达式创建一个依赖图，并删除所有不属于该图的操作。
它生成的代码按原始代码中进行修改的顺序应用于内存和存储（删除那些被发现不需要的修改）。
最后，它在正确的位置生成所有需要在栈上的值。

这些步骤应用于每个基本块，如果新生成的代码更小，则用其替换。
如果在 ``JUMPI`` 处拆分了一个基本块，并且在分析过程中，条件计算为常量，则 ``JUMPI`` 将根据常量的值进行替换。
因此，像这样的代码

.. code-block:: solidity

    uint x = 7;
    data[7] = 9;
    if (data[x] != x + 2) // 这个条件永远为假
      return 2;
    else
      return 1;

简化为：

.. code-block:: solidity

    data[7] = 9;
    return 1;

简单内联
---------------

自 Solidity 版本 0.8.2 起，另一个优化步骤将某些跳转到包含以“跳转”结尾的“简单”指令的块替换为这些指令的副本。
这对应于简单、小型 Solidity 或 Yul 函数的内联。
特别是，当 ``JUMP`` 被标记为“进入”一个函数，并且 ``tag`` 后面有一个基本块（如上面所述的“公共子表达式消除器”）以另一个标记为“退出”一个函数的 ``JUMP`` 结束时，序列 ``PUSHTAG(tag) JUMP`` 可以被替换。

特别地，考虑以下为调用内部 Solidity 函数生成的汇编的原型示例：

.. code-block:: text

      tag_return
      tag_f
      jump      // 进入
    tag_return:
      ...调用 f 后的操作码...

    tag_f:
      ...函数 f 的主体...
      jump      // 退出

只要函数的主体是一个连续的基本块，“内联器”就可以用 ``tag_f`` 处的块替换 ``tag_f jump``，结果为：

.. code-block:: text

      tag_return
      ...函数 f 的主体...
      jump
    tag_return:
      ...调用 f 后的操作码...

    tag_f:
      ...函数 f 的主体...
      jump      // 退出

理想情况下，上述其他优化步骤将导致返回标记推送向剩余跳转移动，结果为：

.. code-block:: text

      ...函数 f 的主体...
      tag_return
      jump
    tag_return:
      ...调用 f 后的操作码...

    tag_f:
      ...函数 f 的主体...
      jump      // 退出

在这种情况下，“窥视优化器”将删除返回跳转。
理想情况下，所有对 ``tag_f`` 的引用都可以这样处理，使其未被使用，从而可以删除，得到：

.. code-block:: text

    ...函数 f 的主体...
    ...调用 f 后的操作码...

因此，调用函数 ``f`` 被内联，原始的 ``f`` 定义可以被删除。

每当启发式算法建议在合约的生命周期内内联比不内联更便宜时，就会尝试进行这样的内联。
这种启发式算法依赖于函数主体的大小、对其标签的其他引用数量（近似函数调用次数）以及合约的预期执行次数（全局优化器参数“运行次数”）。

基于 Yul 的优化器模块
==========================

基于 Yul 的优化器由多个阶段和组件组成，这些组件以语义等价的方式转换 AST。
目标是最终得到更短的代码，或者至少只稍微长一些，但将允许进一步的优化步骤。

.. warning::

    由于优化器正在进行大量开发，这里的信息可能已经过时。
    如果你依赖某种功能，请直接联系团队。

优化器目前遵循纯粹的贪婪策略，不进行任何回溯。

基于 Yul 的优化器模块的所有组件在下面进行了解释。
以下转换步骤是主要组件：

- SSA Transform
- Common Subexpression Eliminator
- Expression Simplifier
- Redundant Assign Eliminator
- Full Inliner

.. _optimizer-steps:

优化器步骤
---------------

这是基于 Yul 的优化器的所有步骤的字母顺序列表。你可以在下面找到有关各个步骤及其顺序的更多信息。

============ ===============================
缩写 全名
============ ===============================
``f``        :ref:`block-flattener`
``l``        :ref:`circular-references-pruner`
``c``        :ref:`common-subexpression-eliminator`
``C``        :ref:`conditional-simplifier`
``U``        :ref:`conditional-unsimplifier`
``n``        :ref:`control-flow-simplifier`
``D``        :ref:`dead-code-eliminator`
``E``        :ref:`equal-store-eliminator`
``v``        :ref:`equivalent-function-combiner`
``e``        :ref:`expression-inliner`
``j``        :ref:`expression-joiner`
``s``        :ref:`expression-simplifier`
``x``        :ref:`expression-splitter`
``I``        :ref:`for-loop-condition-into-body`
``O``        :ref:`for-loop-condition-out-of-body`
``o``        :ref:`for-loop-init-rewriter`
``i``        :ref:`full-inliner`
``g``        :ref:`function-grouper`
``h``        :ref:`function-hoister`
``F``        :ref:`function-specializer`
``T``        :ref:`literal-rematerialiser`
``L``        :ref:`load-resolver`
``M``        :ref:`loop-invariant-code-motion`
``m``        :ref:`rematerialiser`
``V``        :ref:`ssa-reverser`
``a``        :ref:`ssa-transform`
``t``        :ref:`structural-simplifier`
``r``        :ref:`unused-assign-eliminator`
``p``        :ref:`unused-function-parameter-pruner`
``S``        :ref:`unused-store-eliminator`
``u``        :ref:`unused-pruner`
``d``        :ref:`var-decl-initializer`
============ ===============================

一些步骤依赖于 ``BlockFlattener``、``FunctionGrouper``、``ForLoopInitRewriter`` 确保的属性。
因此，Yul 优化器总是在应用用户提供的任何步骤之前先应用它们。

.. _selecting-optimizations:

选择优化
-----------------------

默认情况下，优化器将其预定义的优化步骤序列应用于生成的汇编。
可以使用 ``--yul-optimizations`` 选项覆盖此序列并提供自己的序列：

.. code-block:: bash

    solc --optimize --ir-optimized --yul-optimizations 'dhfoD[xarrscLMcCTU]uljmul:fDnTOcmu'

步骤的顺序是重要的，并且会影响输出的质量。此外，应用一个步骤可能会为已经应用的其他步骤揭示新的优化机会，因此重复步骤通常是有益的。

``[...]`` 内的序列将被多次应用于循环，直到 Yul 代码保持不变或达到最大轮数（当前为 12）。括号（``[]``）可以在序列中多次使用，但不能嵌套。

需要注意的一件重要事情是，有一些硬编码的步骤总是在用户提供的序列之前和之后运行，或者在用户未提供序列时运行默认序列。

清理序列分隔符 ``:`` 是可选的，用于提供自定义清理序列以替换默认序列。如果省略，优化器将简单地应用默认清理序列。
此外，分隔符可以放在用户提供的序列的开头，这将导致优化序列为空；相反，如果放在序列的末尾，将被视为空清理序列。

预处理
-------------

预处理组件执行转换，以使程序进入某种标准形式，以便更容易处理。
此标准形式在优化过程的其余部分中保持不变。

.. _disambiguator:

Disambiguator
^^^^^^^^^^^^^

Disambiguator 接受一个 AST，并返回一个新副本，其中所有标识符在输入 AST 中具有唯一名称。
这是所有其他优化器阶段的先决条件。其好处之一是标识符查找不需要考虑作用域，这简化了其他步骤所需的分析。

所有后续阶段都有一个属性，即所有名称保持唯一。这意味着如果需要引入一个新标识符，则会生成一个新的唯一名称。

.. _function-hoister:

函数提升器
^^^^^^^^^^^^^^^

函数提升器将所有函数定义移动到最顶层块的末尾。这是一个语义上等效的转换，只要在消歧义阶段之后执行。
原因是将定义移动到更高层级的块不会降低其可见性，并且不可能引用在不同函数中定义的变量。

此阶段的好处是可以更轻松地查找函数定义，并且可以在不必完全遍历 AST 的情况下独立优化函数。

.. _function-grouper:

函数分组器
^^^^^^^^^^^^^^^

函数分组器必须在 disambiguator 和函数提升器之后应用。
其效果是将所有不是函数定义的顶层元素移动到一个单独的块中，该块是根块的第一条语句。

经过此步骤后，程序具有以下标准形式：

.. code-block:: text

    { I F... }

其中 ``I`` 是一个（可能为空的）不包含任何函数定义的块（甚至不是递归的），而 ``F`` 是一个函数定义的列表，其中没有函数包含函数定义。

此阶段的好处是我们始终知道函数列表的开始位置。

.. _for-loop-condition-into-body:

将 For 循环条件移入主体
^^^^^^^^^^^^^^^^^^^^^^^^

此转换将 ``for`` 循环的循环迭代条件移入循环主体。我们需要此转换，因为 :ref:`expression-splitter` 不会应用于迭代条件表达式（以下示例中的 ``C``）。

.. code-block:: text

    for { Init... } C { Post... } {
        Body...
    }

被转换为

.. code-block:: text

    for { Init... } 1 { Post... } {
        if iszero(C) { break }
        Body...
    }

此转换在与 LoopInvariantCodeMotion 配对时也很有用，因为循环不变条件中的不变项可以移出循环。

.. _for-loop-init-rewriter:

For 循环初始化重写器
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

此转换将 ``for`` 循环的初始化部分移动到循环之前：

.. code-block:: text

    for { Init... } C { Post... } {
        Body...
    }

被转换为

.. code-block:: text

    Init...
    for {} C { Post... } {
        Body...
    }

这简化了其余的优化过程，因为我们可以忽略 ``for`` 循环初始化块的复杂作用域规则。

.. _var-decl-initializer:

变量声明初始化器
^^^^^^^^^^^^^^^^^^
此步骤重写变量声明，以便所有变量都被初始化。像 ``let x, y`` 这样的声明被拆分为多个声明语句。

目前仅支持用零字面量初始化。

伪 SSA 转换
-------------------------

此组件的目的是将程序转换为更长的形式，以便其他组件可以更轻松地处理它。最终表示将类似于静态单赋值（SSA）形式，区别在于它不使用显式的“phi”函数来组合来自不同控制流分支的值，因为 Yul 语言中不存在此类功能。相反，当控制流合并时，如果在某个分支中重新分配了变量，则声明一个新的 SSA 变量以保存其当前值，以便后续表达式仍然只需引用 SSA 变量。

一个示例转换如下：

.. code-block:: yul

    {
        let a := calldataload(0)
        let b := calldataload(0x20)
        if gt(a, 0) {
            b := mul(b, 0x20)
        }
        a := add(a, 1)
        sstore(a, add(b, 0x20))
    }


当应用所有以下转换步骤时，程序将如下所示：

.. code-block:: yul

    {
        let _1 := 0
        let a_9 := calldataload(_1)
        let a := a_9
        let _2 := 0x20
        let b_10 := calldataload(_2)
        let b := b_10
        let _3 := 0
        let _4 := gt(a_9, _3)
        if _4
        {
            let _5 := 0x20
            let b_11 := mul(b_10, _5)
            b := b_11
        }
        let b_12 := b
        let _6 := 1
        let a_13 := add(a_9, _6)
        let _7 := 0x20
        let _8 := add(b_12, _7)
        sstore(a_13, _8)
    }

请注意，此代码片段中唯一被重新分配的变量是 ``b``。此重新分配无法避免，因为 ``b`` 的值取决于控制流。所有其他变量在定义后从未更改其值。此属性的优点是变量可以自由移动，并且对它们的引用可以用其初始值（反之亦然）进行交换，只要这些值在新上下文中仍然有效。

当然，这里的代码远未优化。相反，它要长得多。希望此代码更易于处理，并且还有优化步骤可以撤消这些更改，并在最后使代码更紧凑。

.. _expression-splitter:

ExpressionSplitter
^^^^^^^^^^^^^^^^^^

表达式分割器将像 ``add(mload(0x123), mul(mload(0x456), 0x20))`` 这样的表达式
转换为一系列唯一变量的声明，这些变量被赋值为该表达式的子表达式，以便每个函数调用仅有变量作为参数。

上述表达式将被转换为

.. code-block:: yul

    {
        let _1 := 0x20
        let _2 := 0x456
        let _3 := mload(_2)
        let _4 := mul(_3, _1)
        let _5 := 0x123
        let _6 := mload(_5)
        let z := add(_6, _4)
    }

请注意，这种转换不会改变操作码或函数调用的顺序。

它不应用于循环迭代条件，因为循环控制流在所有情况下都不允许这种“外部化”内部表达式。
我们可以通过应用 :ref:`for-loop-condition-into-body` 将迭代条件移动到循环体中来规避这一限制。

最终程序应该处于 *表达式分割形式*，在这种形式下（循环条件除外）函数调用不能嵌套在表达式内部，所有函数调用参数必须是变量。

这种形式的好处在于，它更容易重新排序操作码序列，
并且更容易执行函数调用内联。此外，更容易替换表达式的单个部分或重新组织“表达式树”。
缺点是这种代码对人类来说更难以阅读。

.. _ssa-transform:

SSATransform
^^^^^^^^^^^^

此阶段尝试尽可能用新变量的声明替换对现有变量的重复赋值。
重新赋值仍然存在，但对重新赋值变量的所有引用都被新声明的变量替换。

示例：

.. code-block:: yul

    {
        let a := 1
        mstore(a, 2)
        a := 3
    }

被转换为

.. code-block:: yul

    {
        let a_1 := 1
        let a := a_1
        mstore(a_1, 2)
        let a_3 := 3
        a := a_3
    }

确切语义：

对于代码中某处被赋值的任何变量 ``a`` （用值声明且从未重新赋值的变量不被修改），执行以下转换：

- 将 ``let a := v`` 替换为 ``let a_i := v   let a := a_i``
- 将 ``a := v`` 替换为 ``let a_i := v   a := a_i``，其中 ``i`` 是一个数字，使得 ``a_i`` 尚未使用。

此外，始终记录用于 ``a`` 的当前值 ``i``，并将每个对 ``a`` 的引用替换为 ``a_i``。
在每个赋值结束的块末尾以及在 ``for`` 循环初始化块的末尾，如果它在 ``for`` 循环体或后块中被赋值，则清除变量 ``a`` 的当前值映射。
如果根据上述规则清除了变量的值，并且该变量在块外声明，则将在控制流连接的位置创建一个新的 SSA 变量，这包括循环后/体块的开始位置以及 ``if``/``switch``/``for``/块语句之后的位置。

在此阶段之后，建议使用 UnusedAssignEliminator 来删除不必要的中间赋值。

如果在此之前运行 ExpressionSplitter 和 CommonSubexpressionEliminator，则此阶段提供最佳结果，因为这样不会生成过多的变量。
另一方面，如果在 SSA 转换之后运行 CommonSubexpressionEliminator，可能会更有效。

.. _unused-assign-eliminator:

UnusedAssignEliminator
^^^^^^^^^^^^^^^^^^^^^^

SSA 转换始终生成形式为 ``a := a_i`` 的赋值，即使在许多情况下这些可能是不必要的，例如以下示例：

.. code-block:: yul

    {
        let a := 1
        a := mload(a)
        a := sload(a)
        sstore(a, 1)
    }

SSA 转换将此代码片段转换为：

.. code-block:: yul

    {
        let a_1 := 1
        let a := a_1
        let a_2 := mload(a_1)
        a := a_2
        let a_3 := sload(a_2)
        a := a_3
        sstore(a_3, 1)
    }

UnusedAssignEliminator 删除对 ``a`` 的所有三个赋值，因为 ``a`` 的值未被使用，
从而将此代码片段转换为严格的 SSA 形式：

.. code-block:: yul

    {
        let a_1 := 1
        let a_2 := mload(a_1)
        let a_3 := sload(a_2)
        sstore(a_3, 1)
    }

当然，确定赋值是否未使用的复杂部分与控制流的连接有关。

该组件的详细工作方式如下：

AST 被遍历两次：在信息收集步骤和实际删除步骤。
在信息收集期间，我们维护一个从赋值语句到三种状态“未使用”、“未决定”和“已使用”的映射，
这表示赋值的值是否会在后续通过对变量的引用中使用。

当访问赋值时，它被添加到映射中的“未决定”状态（请参见下面关于 ``for`` 循环的备注），并且对同一变量的每个其他赋值
如果仍处于“未决定”状态，则更改为“未使用”。
当引用变量时，仍处于“未决定”状态的任何赋值的状态更改为“已使用”。

在控制流分裂的点，映射的副本被传递给每个分支。在控制流连接的点，来自两个分支的两个映射以以下方式组合：
仅在一个映射中或具有相同状态的语句保持不变。
冲突值以以下方式解决：

- “未使用”、“未决定” -> “未决定”
- “未使用”、“已使用” -> “已使用”
- “未决定”、“已使用” -> “已使用”

对于 ``for`` 循环，条件、主体和后部分被访问两次，考虑到条件的连接控制流。
换句话说，我们创建三条控制流路径：零次循环、一次循环和两次循环，然后在最后将它们组合。

模拟第三次运行或更多是没有必要的，可以如下所示：

在迭代开始时赋值的状态将确定性地导致该赋值在迭代结束时的状态。
让这个状态映射函数称为 ``f``。
如上所述，三种不同状态“未使用”、“未决定”和“已使用”的组合是 ``max`` 操作，其中 `` 未使用 = 0``，`` 未决定 = 1`` 和 `` 已使用 = 2``。

正确的方法是计算

.. code-block:: none

    max(s, f(s), f(f(s)), f(f(f(s))), ...)

作为循环后的状态。由于 ``f`` 只有三种不同的值，迭代它必须在最多三次迭代后达到循环，
因此 ``f(f(f(s)))`` 必须等于 ``s``、``f(s)`` 或 ``f(f(s))`` 中的一个，
因此

.. code-block:: none

    max(s, f(s), f(f(s))) = max(s, f(s), f(f(s)), f(f(f(s))), ...)

总之，最多运行循环两次就足够了，因为只有三种不同的状态。

对于具有默认情况的 ``switch`` 语句，没有控制流部分跳过 ``switch``。

当变量超出作用域时，所有仍处于“未决定”状态的语句都更改为“未使用”，
除非该变量是函数的返回参数 - 在这种情况下，状态更改为“已使用”。

在第二次遍历中，所有处于“未使用”状态的赋值都被删除。

此步骤通常在 SSA 转换之后立即运行，以完成伪 SSA 的生成。

工具
-----

可移动性
^^^^^^^^^^

可移动性是表达式的一个属性。它大致意味着该表达式是无副作用的，并且其评估仅依赖于变量的值和环境的调用常量状态。大多数表达式都是可移动的。以下部分使表达式变得不可移动：

- 函数调用（如果函数中的所有语句都是可移动的，未来可能会放宽）
- 可能具有副作用的操作码（如 ``call`` 或 ``selfdestruct``）
- 读取或写入内存、存储或外部状态信息的操作码
- 依赖于当前 PC、内存大小或返回数据大小的操作码

数据流分析器
^^^^^^^^^^^^^^^^

数据流分析器本身不是一个优化步骤，而是被其他组件作为工具使用。在遍历 AST 时，它跟踪每个变量的当前值，只要该值是可移动表达式。它记录当前分配给每个其他变量的表达式中包含的变量。在每次对变量 ``a`` 的赋值时，变更日志 ``a`` 的当前存储值，并且每当 ``a`` 是当前存储的 ``b`` 的表达式的一部分时，清除所有变量 ``b`` 的存储值。

在控制流合并处，如果变量在任何控制流路径中被赋值或将被赋值，则清除关于变量的知识。例如，在进入 ``for`` 循环时，清除在主体或后块中将被赋值的所有变量。

表达式级简化
--------------------------------

这些简化步骤改变表达式并用等效且希望更简单的表达式替换它们。

.. _common-subexpression-eliminator:

公共子表达式消除器
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

此步骤使用数据流分析器，并用对当前变量值的引用替换在语法上与之匹配的子表达式。这是一个等价变换，因为这样的子表达式必须是可移动的。

所有自身是标识符的子表达式都将被其当前值替换，如果该值是标识符。

上述两个规则的组合允许计算局部值编号，这意味着如果两个变量具有相同的值，其中一个将始终未使用。未使用修剪器或未使用赋值消除器将能够完全消除这些变量。

如果在此之前运行了表达式分割器，此步骤特别高效。如果代码处于伪 SSA 形式，变量的值可用时间更长，因此我们有更高的机会使表达式可替换。

如果在其之前运行了公共子表达式消除器，表达式简化器将能够执行更好的替换。

.. _expression-simplifier:

表达式简化器
^^^^^^^^^^^^^^^^^^^^

表达式简化器使用数据流分析器，并利用一系列对表达式的等价变换，如 ``X + 0 -> X`` 来简化代码。

它尝试在每个子表达式上匹配模式，如 ``X + 0``。在匹配过程中，它将变量解析为其当前分配的表达式，以便能够匹配更深层嵌套的模式，即使代码处于伪 SSA 形式。

一些模式，如 ``X - X -> 0`` 只能在表达式 ``X`` 是可移动的情况下应用，因为否则它将移除其潜在的副作用。由于变量引用始终是可移动的，即使其当前值可能不是，表达式简化器在分割或伪 SSA 形式下再次更强大。

.. _literal-rematerialiser:

字面量重新物化器
^^^^^^^^^^^^^^^^^^^^^

待收入文档。

.. _load-resolver:

加载解析器
^^^^^^^^^^^^

优化阶段，替换类型为 ``sload(x)`` 和 ``mload(x)`` 的表达式为当前存储在存储或内存中的值（如果已知）。

在 SSA 形式下效果最佳。

前提条件：消歧器，ForLoopInitRewriter。

语句级简化
-------------------------------

.. _circular-references-pruner:

循环引用修剪器
^^^^^^^^^^^^^^^^^^^^^^^^

此阶段移除相互调用但既不被外部引用也不被最外层上下文引用的函数。

.. _conditional-simplifier:

条件简化器
^^^^^^^^^^^^^^^^^^^^^

条件简化器在可以从控制流中确定值时，插入对条件变量的赋值。

破坏 SSA 形式。

目前，此工具非常有限，主要是因为我们尚未支持布尔类型。由于条件仅检查表达式是否非零，我们无法分配特定值。

当前功能：

- ``switch`` 案例：插入 ``<condition> := <caseLabel>``
- 在具有终止控制流的 ``if`` 语句后，插入 ``<condition> := 0``

未来功能：

- 允许用 ``1`` 替换
- 考虑用户定义函数的终止

在 SSA 形式下效果最佳，并且如果在此之前运行了死代码移除。

前提条件：消歧器。

.. _conditional-unsimplifier:

条件非简化器
^^^^^^^^^^^^^^^^^^^^^^^

条件简化器的反向操作。

.. _control-flow-simplifier:

控制流简化器
^^^^^^^^^^^^^^^^^^^^^

简化多个控制流结构：

- 用 ``pop(condition)`` 替换空主体的 ``if``
- 移除空的默认 ``switch`` 案例
- 如果没有默认案例，移除空的 ``switch`` 案例
- 用 ``pop(expression)`` 替换没有案例的 ``switch``
- 将单案例的 ``switch`` 转换为 ``if``
- 用 ``pop(expression)`` 和主体替换只有默认案例的 ``switch``
- 用匹配案例主体替换常量表达式的 ``switch``
- 用 ``if`` 替换具有终止控制流且没有其他 ``break``/``continue`` 的 ``for``
- 移除函数末尾的 ``leave``。

这些操作都不依赖于数据流。结构简化器执行类似的任务，但依赖于数据流。

控制流简化器在遍历过程中记录 ``break`` 和 ``continue`` 语句的存在或缺失。

前提条件：消歧器，函数提升器，ForLoopInitRewriter。

重要：引入 EVM 操作码，因此目前只能用于 EVM 代码。

.. _dead-code-eliminator:

死代码消除器
^^^^^^^^^^^^^^^^^^

此优化阶段移除不可达代码。

不可达代码是指在块内的任何代码，该代码之前有 ``leave``、``return``、``invalid``、``break``、``continue``、``selfdestruct``、``revert`` 或调用无限递归的用户定义函数。

函数定义被保留，因为它们可能被早期代码调用，因此被视为可达。

由于在 ``for`` 循环的初始化块中声明的变量的作用域扩展到循环主体，我们要求在此步骤之前运行 ForLoopInitRewriter。

前提条件：ForLoopInitRewriter，函数提升器，函数分组器。

.. _equal-store-eliminator:

相等存储消除器
^^^^^^^^^^^^^^^^^^^^

此步骤移除 ``mstore(k, v)`` 和 ``sstore(k, v)`` 调用，如果之前有对 ``mstore(k, v)`` / ``sstore(k, v)`` 的调用，且之间没有其他存储，并且 ``k`` 和 ``v`` 的值没有改变。

如果在 SSATransform 和公共子表达式消除器之后运行，此简单步骤是有效的，因为 SSA 将确保变量不会改变，而公共子表达式消除器在值已知相同的情况下重新使用完全相同的变量。
Prerequisites: Disambiguator, ForLoopInitRewriter.

.. _unused-pruner:

UnusedPruner
^^^^^^^^^^^^

此步骤移除所有从未被引用的函数定义。

它还会移除所有从未被引用的变量声明。
如果一个声明赋值了一个不可移动的值，则保留该表达式，但其值会被丢弃。

所有可移动的表达式语句（未被赋值的表达式）都会被移除。

.. _structural-simplifier:

StructuralSimplifier
^^^^^^^^^^^^^^^^^^^^

这是一个通用步骤，在结构层面执行各种简化：

- 用 ``pop(condition)`` 替换空体的 ``if`` 语句
- 用其主体替换条件为真的 ``if`` 语句
- 移除条件为假的 ``if`` 语句
- 将只有一个案例的 ``switch`` 转换为 ``if``
- 用 ``pop(expression)`` 和主体替换只有默认案例的 ``switch``
- 用匹配的案例主体替换字面表达式的 ``switch``
- 用其初始化部分替换条件为假的 ``for`` 循环

该组件使用 DataflowAnalyzer。

.. _block-flattener:

BlockFlattener
^^^^^^^^^^^^^^

此阶段通过将内部块中的语句插入到外部块的适当位置来消除嵌套块。它依赖于 FunctionGrouper，并且不会扁平化最外层块，以保持 FunctionGrouper 生成的形式。

.. code-block:: yul

    {
        {
            let x := 2
            {
                let y := 3
                mstore(x, y)
            }
        }
    }

被转换为

.. code-block:: yul

    {
        {
            let x := 2
            let y := 3
            mstore(x, y)
        }
    }

只要代码经过消歧，这不会造成问题，因为变量的作用域只能扩大。

.. _loop-invariant-code-motion:

LoopInvariantCodeMotion
^^^^^^^^^^^^^^^^^^^^^^^
此优化将可移动的 SSA 变量声明移出循环。

仅考虑循环主体或后块中的顶层语句，即条件分支中的变量声明不会被移出循环。

ExpressionSplitter 和 SSATransform 应该提前运行以获得更好的结果。

Prerequisites: Disambiguator, ForLoopInitRewriter, FunctionHoister.


Function-Level Optimizations
----------------------------

.. _function-specializer:

FunctionSpecializer
^^^^^^^^^^^^^^^^^^^

此步骤专门化带有字面参数的函数。

如果一个函数，例如 ``function f(a, b) { sstore (a, b) }``，被字面参数调用，例如 ``f(x, 5)``，其中 ``x`` 是一个标识符，它可以通过创建一个只接受一个参数的新函数 ``f_1`` 来专门化，即：

.. code-block:: yul

    function f_1(a_1) {
        let b_1 := 5
        sstore(a_1, b_1)
    }

其他优化步骤将能够对该函数进行更多简化。该优化步骤主要对不会被内联的函数有用。

Prerequisites: Disambiguator, FunctionHoister.

建议将 LiteralRematerialiser 作为先决条件，尽管它不是正确性所必需的。

.. _unused-function-parameter-pruner:

UnusedFunctionParameterPruner
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

此步骤移除函数中未使用的参数。

如果一个参数未被使用，例如 ``function f(a,b,c) -> x, y { x := div(a,b) }`` 中的 ``c`` 和 ``y``，我们将移除该参数并创建一个新的“链接”函数，如下所示：

.. code-block:: yul

    function f(a,b) -> x { x := div(a,b) }
    function f2(a,b,c) -> x, y { x := f(a,b) }

并将所有对 ``f`` 的引用替换为 ``f2``。
内联器应在之后运行，以确保所有对 ``f2`` 的引用都被替换为 ``f``。

Prerequisites: Disambiguator, FunctionHoister, LiteralRematerialiser.

步骤 LiteralRematerialiser 对于正确性不是必需的。它有助于处理诸如：``function f(x) -> y { revert(y, y} }`` 的情况，其中字面量 ``y`` 将被其值 ``0`` 替换，从而允许我们重写该函数。

.. index:: ! UnusedStoreEliminator
.. _unused-store-eliminator:

UnusedStoreEliminator
^^^^^^^^^^^^^^^^^^^^^

优化器组件，移除冗余的 ``sstore`` 和内存存储语句。
在 ``sstore`` 的情况下，如果所有外部代码路径都回退（由于显式的 ``revert()``, ``invalid()``, 或无限递归）或导致另一个 ``sstore``，而优化器可以判断它将覆盖第一个存储，则该语句将被移除。
然而，如果在初始 ``sstore`` 和回退或覆盖的 ``sstore`` 之间存在读取操作，则该语句将不会被移除。
此类读取操作包括：外部调用、具有任何存储访问的用户定义函数，以及无法证明与初始 ``sstore`` 写入的槽不同的槽的 ``sload``。

例如，以下代码

.. code-block:: yul

    {
        let c := calldataload(0)
        sstore(c, 1)
        if c {
            sstore(c, 2)
        }
        sstore(c, 3)
    }

在运行 UnusedStoreEliminator 步骤后将被转换为以下代码

.. code-block:: yul

    {
        let c := calldataload(0)
        if c { }
        sstore(c, 3)
    }

对于内存存储操作，情况通常更简单，至少在最外层 Yul 块中，因为所有此类语句如果在任何代码路径中未被读取，则将被移除。
然而，在函数分析级别，方法与 ``sstore`` 类似，因为我们不知道一旦离开函数作用域，内存位置是否会被读取，因此只有在所有代码路径都导致内存覆盖时，语句才会被移除。

最好在 SSA 形式下运行。

Prerequisites: Disambiguator, ForLoopInitRewriter.

.. _equivalent-function-combiner:

EquivalentFunctionCombiner
^^^^^^^^^^^^^^^^^^^^^^^^^^

如果两个函数在语法上是等价的，允许变量重命名但不允许任何重新排序，则对其中一个函数的任何引用都将被另一个函数替换。

函数的实际移除由 UnusedPruner 执行。

Function Inlining
-----------------

.. _expression-inliner:

ExpressionInliner
^^^^^^^^^^^^^^^^^

优化器的这个组件执行受限的函数内联，通过在功能表达式内部内联可以内联的函数，即：

- 返回单个值的函数。
- 其主体类似于 ``r := <functional expression>`` 的函数。
- 在右侧既不引用自身也不引用 ``r``。

此外，对于所有参数，以下所有条件都需要成立：

- 参数是可移动的。
- 参数在函数主体中被引用少于两次，或者参数相对便宜（“成本”最多为 1，例如常量不超过 ``0xff``）。

示例：要内联的函数形式为 ``function f(...) -> r { r := E }``，其中 ``E`` 是一个不引用 ``r`` 的表达式，且函数调用中的所有参数都是可移动表达式。

此内联的结果始终是一个单一的表达式。

该组件只能用于具有唯一名称的源。

.. _full-inliner:

FullInliner
^^^^^^^^^^^

FullInliner 将某些函数的某些调用替换为函数的主体。在大多数情况下，这并没有太大帮助，因为它只是增加了代码大小，但没有带来好处。此外，代码通常是非常昂贵的，我们通常宁愿要更短的代码而不是更高效的代码。然而，在某些情况下，内联一个函数可能对后续的优化步骤产生积极影响。例如，如果其中一个函数参数是常量。
在内联过程中，使用启发式方法来判断函数调用是否应该内联。当前的启发式方法不会将“较大”的函数内联，除非被调用的函数非常小。仅使用一次的函数会被内联，中等大小的函数也会被内联，而具有常量参数的函数调用则允许稍大的函数。

未来，我们可能会包含一个回溯组件，该组件不会立即内联函数，而是仅对其进行特化，这意味着生成一个函数的副本，其中某个参数始终被替换为常量。之后，我们可以在这个特化的函数上运行优化器。如果结果带来了显著的收益，则保留特化的函数，否则使用原始函数。

建议将 FunctionHoister 和 ExpressionSplitter 作为前置条件，因为它们使步骤更高效，但并不是正确性的必要条件。特别是，带有其他函数调用作为参数的函数调用不会被内联，但在此之前运行 ExpressionSplitter 可以确保输入中没有此类调用。

清理
-------

清理在优化器运行结束时执行。它尝试将拆分的表达式重新组合成深度嵌套的表达式，并通过尽可能消除变量来改善堆栈机器的“可编译性”。

.. _expression-joiner:

ExpressionJoiner
^^^^^^^^^^^^^^^^

这是 ExpressionSplitter 的相反操作。它将一系列只有一个引用的变量声明转换为复杂表达式。此阶段完全保留函数调用和操作码执行的顺序。它不使用任何关于操作码的交换律的信息；如果将变量的值移动到其使用位置会改变任何函数调用或操作码执行的顺序，则不执行该转换。

请注意，该组件不会移动变量赋值的赋值值或被引用多次的变量。

代码片段 ``let x := add(0, 2) let y := mul(x, mload(2))`` 不会被转换，因为这会导致对操作码 ``add`` 和 ``mload`` 的调用顺序被交换——即使这不会造成差异，因为 ``add`` 是可移动的。

在像这样重新排序操作码时，变量引用和字面量会被忽略。因此，代码片段 ``let x := add(0, 2) let y := mul(x, 3)`` 被转换为 ``let y := mul(add(0, 2), 3)``，即使 ``add`` 操作码会在字面量 ``3`` 的评估之后执行。

.. _ssa-reverser:

SSAReverser
^^^^^^^^^^^

这是一个小步骤，帮助逆转 SSATransform 的效果，如果与 CommonSubexpressionEliminator 和 UnusedPruner 结合使用。

我们生成的 SSA 形式对代码生成是有害的，因为它产生了许多局部变量。最好是重用现有变量的赋值，而不是新的变量声明。

SSATransform 将

.. code-block:: yul

    let a := calldataload(0)
    mstore(a, 1)

重写为

.. code-block:: yul

    let a_1 := calldataload(0)
    let a := a_1
    mstore(a_1, 1)
    let a_2 := calldataload(0x20)
    a := a_2

问题在于，每当引用 ``a`` 时，使用的是变量 ``a_1``。SSATransform 通过简单地交换声明和赋值来改变这种形式的语句。上述代码片段被转换为

.. code-block:: yul

    let a := calldataload(0)
    let a_1 := a
    mstore(a_1, 1)
    a := calldataload(0x20)
    let a_2 := a

这是一个非常简单的等价转换，但当我们现在运行 CommonSubexpressionEliminator 时，它会将所有 ``a_1`` 的出现替换为 ``a``（直到 ``a`` 被重新赋值）。UnusedPruner 然后会完全消除变量 ``a_1``，从而完全逆转 SSATransform。

.. _stack-compressor:

StackCompressor
^^^^^^^^^^^^^^^

使以太坊虚拟机进行代码生成的一个问题是表达式堆栈的访问有一个硬限制，即 16 个槽。这或多或少地转化为 16 个局部变量的限制。堆栈压缩器将 Yul 代码编译为 EVM 字节码。每当堆栈差异过大时，它会记录发生此情况的函数。

对于每个导致此类问题的函数，Rematerialiser 会被调用，并带有特殊请求，以根据其值的成本积极消除特定变量。

在失败的情况下，该过程会重复多次。

.. _rematerialiser:

Rematerialiser
^^^^^^^^^^^^^^

重材料化阶段尝试用最后赋值给变量的表达式替换变量引用。当然，只有在该表达式相对便宜时，这才是有益的。此外，只有在赋值点和使用点之间表达式的值没有变化时，这才在语义上等价。此阶段的主要好处是，如果它导致变量完全消除（见下文），则可以节省堆栈槽，但如果表达式非常便宜，它也可以节省 EVM 上的 ``DUP`` 操作码。

Rematerialiser 使用 DataflowAnalyzer 跟踪变量的当前值，这些值始终是可移动的。如果值非常便宜或变量被明确请求消除，则变量引用将被其当前值替换。

.. _for-loop-condition-out-of-body:

ForLoopConditionOutOfBody
^^^^^^^^^^^^^^^^^^^^^^^^^

逆转 ForLoopConditionIntoBody 的转换。

对于任何可移动的 ``c``，它将

.. code-block:: none

    for { ... } 1 { ... } {
    if iszero(c) { break }
    ...
    }

转换为

.. code-block:: none

    for { ... } c { ... } {
    ...
    }

并将

.. code-block:: none

    for { ... } 1 { ... } {
    if c { break }
    ...
    }

转换为

.. code-block:: none

    for { ... } iszero(c) { ... } {
    ...
    }

在此步骤之前应运行 LiteralRematerialiser。

基于代码生成的优化器模块
==============================

目前，基于代码生成的优化器模块提供了两种优化。

第一种，在遗留代码生成器中可用，将字面量移动到可交换二元操作符的右侧，这有助于利用它们的结合性。

另一种，在基于 IR 的代码生成器中可用，允许在为某些惯用的 ``for`` 循环生成代码时使用不检查的算术。这通过识别一些条件来避免浪费 gas，这些条件保证计数器变量不会溢出。这消除了在循环体内使用冗长的不检查算术块来递增计数器变量的需要。

.. _unchecked-loop-optimizer:

不检查的循环递增
------------------------

在 Solidity ``0.8.22`` 中引入，溢出检查优化步骤关注于识别在不进行溢出检查的情况下可以安全递增 ``for`` 循环计数器的条件。

此优化 **仅** 应用于一般形式的 ``for`` 循环：

.. code-block:: solidity

    for (uint i = X; i < Y; ++i) {
        // 变量 i 在循环体内未被修改
    }

该条件以及计数器变量仅在循环中递增的事实保证它永远不会溢出。循环符合优化的精确要求如下：
- 循环条件是形式为 ``i < Y`` 的比较，其中 ``i`` 是一个局部计数变量（以下简称“循环计数器”），而 ``Y`` 是一个表达式。
- 循环条件中必须使用内置运算符 ``<``，并且这是唯一触发优化的运算符。 ``<=`` 等运算符被故意排除在外。此外，自定义运算符 **不** 适用。
- 循环表达式是计数变量的前缀或后缀递增，即 ``i++`` 或 ``++i``。
- 循环计数器是内置整数类型的局部变量。
- 循环计数器 **不** 会被循环体或用作循环条件的表达式修改。
- 比较是在与循环计数器相同的类型上进行的，这意味着右侧表达式的类型可以隐式转换为计数器的类型，以便在比较之前，计数器的类型不会被隐式扩展。

为了澄清最后一个条件，考虑以下示例：

.. code-block:: solidity

    for (uint8 i = 0; i < uint16(1000); i++) {
        // ...
    }

在这种情况下，计数器 ``i`` 的类型在比较之前隐式转换为 ``uint16``，因此条件实际上永远不会为假，因此无法移除递增的溢出检查。