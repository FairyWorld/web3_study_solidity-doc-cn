.. include:: glossaries.rst

.. index:: type

.. _types:

*****
类型
*****

Solidity 是一种静态类型语言，这意味着每个变量（状态变量和局部变量）的类型都需要被指定。
Solidity 提供了几种基本类型，可以组合形成复杂类型。

此外，类型可以在包含运算符的表达式中相互作用。有关各种运算符的快速参考，请参见 :ref:`order`。

“undefined”或“null”值的概念在 Solidity 中不存在，但新声明的变量总是具有依赖于其类型的 :ref:`默认值<default-value>`。
为了处理任何意外值，应该使用 :ref:`revert function<assert-and-require>` 来回滚整个交易，或者返回一个包含第二个 ``bool`` 值表示成功的元组。

.. include:: types/value-types.rst

.. include:: types/reference-types.rst

.. include:: types/mapping-types.rst

.. include:: types/operators.rst

.. include:: types/conversion.rst