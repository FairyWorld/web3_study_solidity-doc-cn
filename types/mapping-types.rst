.. include:: glossaries.rst

.. index:: !mapping
.. _mapping-types:

映射类型
=============

映射类型使用语法 ``mapping(KeyType KeyName? => ValueType ValueName?)``，映射类型的变量使用语法 ``mapping(KeyType KeyName? => ValueType ValueName?) VariableName`` 声明。 
``KeyType`` 可以是任何内置值类型、``bytes``、``string``，或任何合约或枚举类型。
其他用户定义或复杂类型，如映射、结构体或数组类型是不允许的。 
``ValueType`` 可以是任何类型，包括映射、数组和结构体。 ``KeyName`` 和 ``ValueName`` 是可选的（因此 ``mapping(KeyType => ValueType)`` 也可以使用），可以是任何有效的标识符，但不能是类型。

可以将映射视为 `哈希表 <https://en.wikipedia.org/wiki/Hash_table>`_，它们在逻辑上被初始化为每个可能的键都存在，并映射到一个字节表示全为零的值，即类型的 :ref:`默认值 <default-value>`。
相似之处到此为止，键数据并不存储在映射中，，仅其 `keccak256` 哈希被用来查找值。

因此，映射没有长度或键或值被设置的概念，因此不能在没有关于分配键的额外信息的情况下被擦除（见 :ref:`clearing-mappings`）。

映射只能具有 ``storage`` 的数据位置，因此允许作为状态变量、作为函数中的存储引用类型，或作为库函数的参数。
它们不能作为公开可见的合约函数的参数或返回参数。这些限制同样适用于包含映射的数组和结构体。

可以将映射类型的状态变量标记为 ``public``，Solidity 会为你创建一个 :ref:`getter <visibility-and-getters>`。 
``KeyType`` 成为 getter 的参数，名称为 ``KeyName`` （如果指定）。
如果 ``ValueType`` 是值类型或结构体，getter 返回 ``ValueType``，名称为 ``ValueName`` （如果指定）。
如果 ``ValueType`` 是数组或映射，getter 将需要递归地传入每个 ``KeyType`` 参数，　

在下面的示例中，``MappingExample`` 合约定义了一个公共的 ``balances`` 映射，键类型为 ``address``，值类型为 ``uint``，将以太坊地址映射到无符号整数值。
由于 ``uint`` 是值类型，getter 返回与该类型匹配的值，可以在 ``MappingUser`` 合约中看到，它返回指定地址的值。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;

    contract MappingExample {
        mapping(address => uint) public balances;

        function update(uint newBalance) public {
            balances[msg.sender] = newBalance;
        }
    }

    contract MappingUser {
        function f() public returns (uint) {
            MappingExample m = new MappingExample();
            m.update(100);
            return m.balances(address(this));
        }
    }

下面的示例是一个简化版本的 `ERC20 代币 <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol>`_。 ``_allowances`` 是另一个映射类型内部的映射类型的示例。

在下面的示例中，为映射提供了可选的 ``KeyName`` 和 ``ValueName``。这不会影响任何合约功能或字节码，它仅为映射的 getter 的输入和输出设置 ``name`` 字段。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.18;

    contract MappingExampleWithNames {
        mapping(address user => uint balance) public balances;

        function update(uint newBalance) public {
            balances[msg.sender] = newBalance;
        }
    }


下面的示例使用 ``_allowances`` 来记录其他人可以从你的账户中提取的金额。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.22 <0.9.0;

    contract MappingExample {

        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);

        function allowance(address owner, address spender) public view returns (uint256) {
            return _allowances[owner][spender];
        }

        function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: Allowance not high enough.");
            _allowances[sender][msg.sender] -= amount;
            _transfer(sender, recipient, amount);
            return true;
        }

        function approve(address spender, uint256 amount) public returns (bool) {
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }

        function _transfer(address sender, address recipient, uint256 amount) internal {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(_balances[sender] >= amount, "ERC20: Not enough funds.");

            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }


.. index:: !iterable mappings
.. _iterable-mappings:

可迭代映射
-----------------

不能遍历映射，即不能枚举它们的键。不过，可以在其上实现一个数据结构并对其进行迭代。
例如，下面的代码实现了一个 ``IterableMapping`` 库，``User`` 合约随后向其添加数据，而 ``sum`` 函数则对所有值进行迭代求和。

.. code-block:: solidity
    :force:

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.8;

    struct IndexValue { uint keyIndex; uint value; }
    struct KeyFlag { uint key; bool deleted; }

    struct itmap {
        mapping(uint => IndexValue) data;
        KeyFlag[] keys;
        uint size;
    }

    type Iterator is uint;

    library IterableMapping {
        function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
            uint keyIndex = self.data[key].keyIndex;
            self.data[key].value = value;
            if (keyIndex > 0)
                return true;
            else {
                keyIndex = self.keys.length;
                self.keys.push();
                self.data[key].keyIndex = keyIndex + 1;
                self.keys[keyIndex].key = key;
                self.size++;
                return false;
            }
        }

        function remove(itmap storage self, uint key) internal returns (bool success) {
            uint keyIndex = self.data[key].keyIndex;
            if (keyIndex == 0)
                return false;
            delete self.data[key];
            self.keys[keyIndex - 1].deleted = true;
            self.size --;
        }

        function contains(itmap storage self, uint key) internal view returns (bool) {
            return self.data[key].keyIndex > 0;
        }

        function iterateStart(itmap storage self) internal view returns (Iterator) {
            return iteratorSkipDeleted(self, 0);
        }

        function iterateValid(itmap storage self, Iterator iterator) internal view returns (bool) {
            return Iterator.unwrap(iterator) < self.keys.length;
        }

        function iterateNext(itmap storage self, Iterator iterator) internal view returns (Iterator) {
            return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
        }

        function iterateGet(itmap storage self, Iterator iterator) internal view returns (uint key, uint value) {
            uint keyIndex = Iterator.unwrap(iterator);
            key = self.keys[keyIndex].key;
            value = self.data[key].value;
        }

        function iteratorSkipDeleted(itmap storage self, uint keyIndex) private view returns (Iterator) {
            while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
                keyIndex++;
            return Iterator.wrap(keyIndex);
        }
    }

    // 如何使用
    contract User {
        // 只是一个结构体来保存我们的数据。
        itmap data;
        // 将库函数应用于数据类型。
        using IterableMapping for itmap;

        // 插入数据
        function insert(uint k, uint v) public returns (uint size) {
            // 这调用了 IterableMapping.insert(data, k, v)
            data.insert(k, v);
            // 我们仍然可以访问结构体的成员，
            // 但我们应该小心不要弄乱它们。
            return data.size;
        }

        // 计算所有存储数据的总和。
        function sum() public view returns (uint s) {
            for (
                Iterator i = data.iterateStart();
                data.iterateValid(i);
                i = data.iterateNext(i)
            ) {
                (, uint value) = data.iterateGet(i);
                s += value;
            }
        }
    }