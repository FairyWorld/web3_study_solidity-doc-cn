.. include:: glossaries.rst

.. index:: ! contract

.. _contracts:

##########
合约
##########

Solidity 合约类似于面向对象语言中的类。它包含状态变量中的持久数据，以及可以修改这些变量的函数。
在不同合约（实例）上调用函数将执行 EVM 函数调用，从而切换上下文，使得调用合约中的状态变量不可访问。
必须调用合约及其函数才能触发变化。以太坊中没有“cron”概念来自动在特定事件下调用函数。

.. include:: contracts/creating-contracts.rst

.. include:: contracts/visibility-and-getters.rst

.. include:: contracts/function-modifiers.rst

.. include:: contracts/transient-storage.rst

.. include:: contracts/constant-state-variables.rst
.. include:: contracts/functions.rst

.. include:: contracts/events.rst
.. include:: contracts/errors.rst

.. include:: contracts/inheritance.rst

.. include:: contracts/abstract-contracts.rst
.. include:: contracts/interfaces.rst

.. include:: contracts/libraries.rst

.. include:: contracts/using-for.rst