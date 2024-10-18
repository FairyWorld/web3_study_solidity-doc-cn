.. include:: ../glossaries.rst

.. index:: storage, state variable, mapping, transient storage

**********************************************************
状态变量在存储和瞬态存储中的布局
**********************************************************

.. _storage-inplace-encoding:

.. note::
    本节中描述的规则适用于存储和瞬态存储数据位置。
    两者布局是完全独立的，彼此之间的变量位置不相互干扰。
    因此，存储和瞬态存储状态变量可以安全地交错而不会产生任何副作用。
    仅支持值类型用于瞬态存储。

合约的状态变量以紧凑的方式存储在存储中，以至于多个值有时使用相同的存储槽。
除了动态大小的数组和 |mapping| （见下文）外，数据是连续存储的，逐项存储，从第一个状态变量开始，该变量存储在槽 ``0`` 中。
对于每个变量，根据其类型确定以字节为单位的大小。
多个连续的项如果少于 32 字节，则尽可能打包到一个存储槽中，遵循以下规则：

- 存储槽中的第一项是低位对齐存储的。
- 值类型仅使用存储它们所需的字节数。
- 如果存储槽中的剩余空间不足以储存一个值类型，那么它会存储在下一个存储槽中。
- 结构体和数组数据总是会开启一个新槽，并且它们的数据根据这些规则紧密打包。
- 紧随结构体或数组数据的数据总是开始一个新的存储槽。

对于使用继承的合约，状态变量的顺序由从最基础合约开始的 C3 线性化顺序决定。
如果上述规则允许，来自不同合约的状态变量可以共享同一个存储槽。

结构体和数组的元素是依次存储的，就像它们单独声明时一样。

.. warning::
    当使用小于 32 字节的元素时，合约的 gas 使用量可能会更高。
    这是因为 EVM 一次处理 32 字节。
    因此，如果元素小于 32 字节，EVM 必须执行额外的操作来将元素的大小从 32 字节减少到所需大小。

    如果处理存储值，使用缩小大小的类型可能是有益的，
    因为编译器会将多个元素打包到一个存储槽中，从而将多个读取或写入合并为一个操作。
    但是，如果不是同时读取或写入槽中的所有值，这可能会产生相反的效果：
    当一个值被写入多值存储槽时，必须先读取存储槽，然后与新值结合，以确保不破坏同一槽中的其他数据。

    在处理函数参数或 |memory| 中的值时，没有额外的好处，因为编译器不会打包这些值。

    最后，为了让 EVM 进行优化，请确保 |storage| 中的变量和 ``struct`` 成员的书写顺序允许它们被紧密地打包。
    例如，按 ``uint128, uint128, uint256`` 的顺序声明存储变量，而不是 ``uint128, uint256, uint128``，
    因为前者只占用两个存储槽，而后者占用三个。

.. note::
     |storage| 中状态变量的布局被视为 Solidity 外部接口的一部分，这是因为 |storage| 指针可以传递给库。
     这意味着对本节中概述的规则的任何更改都被视为语言的重大更改，由于其关键性质，应在执行之前仔细考虑。
     在发生此类重大更改时，我们希望发布一个兼容模式，其中编译器将生成支持旧布局的字节码。


映射和动态数组
===========================

.. _storage-hashed-encoding:

由于不可预测大小，|mapping| 和动态数组类型不能存储在它们前后的状态变量之间。
相反，它们被视为仅占用 32 字节，关于 :ref:`上述规则 <storage-inplace-encoding>`，
它们包含的元素从一个不同的存储槽开始存储，该槽是使用 Keccak-256 哈希计算得出的。

假设 |mapping| 或数组的存储位置在应用 :ref:`存储布局规则 <storage-inplace-encoding>` 后最终为槽 ``p``。
对于动态数组，该槽存储数组中的元素数量（字节数组和字符串是例外，见 :ref:`下文 <bytes-and-string>`）。
对于 |mapping|，槽保持为空，但它仍然是必要的，以确保即使有两个 |mapping| 相邻，它们的内容最终位于不同的存储位置。

数组数据从 ``keccak256(p)`` 开始定位，其布局与静态大小数组数据的布局相同：一个元素接一个元素，如果元素不超过 16 字节，则可能共享存储槽。动态数组的动态数组递归应用此规则。
元素 ``x[i][j]`` 的位置，其中 ``x`` 的类型为 ``uint24[][]``，计算如下（再次假设 ``x`` 本身存储在槽 ``p``）：
该槽为 ``keccak256(keccak256(p) + i) + floor(j / floor(256 / 24))``，
并且可以使用 ``(v >> ((j % floor(256 / 24)) * 24)) & type(uint24).max`` 从槽数据 ``v`` 中获取该元素。

|mapping| 中的键 ``k`` 对应的值位于 ``keccak256(h(k) . p)``，
其中 ``.`` 是连接，``h`` 是根据键的类型应用于键的函数：

- 对于值类型，``h`` 以与在内存中存储值时相同的方式将值填充到 32 字节。
- 对于字符串和字节数组，``h(k)`` 只是未填充的数据。

如果映射值是非值类型，则计算出的槽标记数据的开始。
例如，如果值是结构体类型，必须添加一个对应于结构体成员的偏移量以到达该成员。

作为示例，考虑以下合约：

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.4.0 <0.9.0;


    contract C {
        struct S { uint16 a; uint16 b; uint256 c; }
        uint x;
        mapping(uint => mapping(uint => S)) data;
    }

让我们计算 ``data[4][9].c`` 的存储位置。
映射本身的位置是 ``1``（变量 ``x`` 占用 32 字节在它之前）。
这意味着 ``data[4]`` 存储在 ``keccak256(uint256(4) . uint256(1))``。
``data[4]`` 的类型又是一个映射，``data[4][9]`` 的数据从槽 ``keccak256(uint256(9) . keccak256(uint256(4) . uint256(1)))`` 开始。
结构 ``S`` 中成员 ``c`` 的槽偏移量是 ``1``，因为 ``a`` 和 ``b`` 被打包在一个槽中。
这意味着 ``data[4][9].c`` 的槽为 ``keccak256(uint256(9) . keccak256(uint256(4) . uint256(1))) + 1``。
值的类型是 ``uint256``，因此它使用一个槽。


.. _bytes-and-string:

``bytes`` 和 ``string``
------------------------

``bytes`` 和 ``string`` 的编码是相同的。
一般来说，编码类似于 ``bytes1[]``，因为数组本身有一个槽，数据区域是通过该槽位置的 ``keccak256`` 哈希计算得出的。
然而，对于短值（短于 32 字节），数组元素与长度一起存储在同一个槽中。
特别地：如果数据长度小于等于 ``31`` 字节，则元素存储在高位字节中（左对齐），最低位字节存储值 ``length * 2``。
对于存储 ``32`` 字节或更多字节的数据的字节数组，主槽 ``p`` 存储 ``length * 2 + 1``，数据则按常规存储在 ``keccak256(p)`` 中。
这意味着可以通过检查最低位是否被设置来区分短数组和长数组：短数组（未设置）和长数组（已设置）。

.. note::
  目前不支持处理无效编码的槽，但未来可能会添加此功能。
  如果通过 IR 编译，读取无效编码的槽将导致 ``Panic(0x22)`` 错误。

JSON 输出
===========

.. _storage-layout-top-level:

可以通过 :ref:`标准 JSON 接口 <compiler-api>` 请求合约的存储（或瞬态存储）布局。
输出是一个包含两个字段的 JSON 对象，``storage`` 和 ``types``。
``storage`` 对象是一个数组，其中每个元素具有以下形式：

.. code-block:: json


    {
        "astId": 2,
        "contract": "fileA:A",
        "label": "x",
        "offset": 0,
        "slot": "0",
        "type": "t_uint256"
    }

上面的示例是来自源单元 ``fileA`` 的 ``contract A { uint x; }`` 的存储布局，并且

- ``astId`` 是状态变量声明的 AST 节点的 ID
- ``contract`` 是合约的名称，包括其路径作为前缀
- ``label`` 是状态变量的名称
- ``offset`` 是根据编码在存储槽内的字节偏移量
- ``slot`` 是状态变量所在或开始的存储槽。这个数字可能非常大，因此其 JSON 值表示为字符串。
- ``type`` 是用于变量类型信息的标识符（在下面描述）

给定的 ``type``，在这种情况下为 ``t_uint256``，表示 ``types`` 中的一个元素，其形式为：

.. code-block:: json

    {
        "encoding": "inplace",
        "label": "uint256",
        "numberOfBytes": "32",
    }

其中

- ``encoding`` 是数据在存储中的编码方式，可能的值有：

  - ``inplace``：数据在存储中连续布局（见 :ref:`上面 <storage-inplace-encoding>`）。
  - ``mapping``：基于 Keccak-256 哈希的方法（见 :ref:`上面 <storage-hashed-encoding>`）。
  - ``dynamic_array``：基于 Keccak-256 哈希的方法（见 :ref:`上面 <storage-hashed-encoding>`）。
  - ``bytes``：单槽或基于 Keccak-256 哈希，具体取决于数据大小（见 :ref:`上面 <bytes-and-string>`）。

- ``label`` 是规范类型名称。
- ``numberOfBytes`` 是使用的字节数（作为十进制字符串）。
  请注意，如果 ``numberOfBytes > 32``，这意味着使用了多个槽。

某些类型除了上述四个外还有额外信息。映射包含其 ``key`` 和 ``value`` 类型（再次引用此映射类型中的条目），数组具有其 ``base`` 类型，结构体列出其 ``members``，格式与顶层 ``storage`` 相同（见 :ref:`above <storage-layout-top-level>`）。

.. note::
  合约存储布局的 JSON 输出格式仍被视为实验性，并可能在 Solidity 的非破坏性版本中发生变化。

以下示例展示了一个合约及其存储和瞬态存储布局，包含值类型和引用类型、打包编码的类型以及嵌套类型。

.. code-block:: solidity

    // SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.28;
    contract A {
        struct S {
            uint128 a;
            uint128 b;
            uint[2] staticArray;
            uint[] dynArray;
        }

        uint x;
        uint transient y;
        uint w;
        uint transient z;

        S s;
        address addr;
        address transient taddr;
        mapping(uint => mapping(address => bool)) map;
        uint[] array;
        string s1;
        bytes b1;
    }

存储布局
--------------

.. code-block:: json

    {
      "storage": [
        {
          "astId": 15,
          "contract": "fileA:A",
          "label": "x",
          "offset": 0,
          "slot": "0",
          "type": "t_uint256"
        },
        {
          "astId": 19,
          "contract": "fileA:A",
          "label": "w",
          "offset": 0,
          "slot": "1",
          "type": "t_uint256"
        },
        {
          "astId": 24,
          "contract": "fileA:A",
          "label": "s",
          "offset": 0,
          "slot": "2",
          "type": "t_struct(S)13_storage"
        },
        {
          "astId": 26,
          "contract": "fileA:A",
          "label": "addr",
          "offset": 0,
          "slot": "6",
          "type": "t_address"
        },
        {
          "astId": 34,
          "contract": "fileA:A",
          "label": "map",
          "offset": 0,
          "slot": "7",
          "type": "t_mapping(t_uint256,t_mapping(t_address,t_bool))"
        },
        {
          "astId": 37,
          "contract": "fileA:A",
          "label": "array",
          "offset": 0,
          "slot": "8",
          "type": "t_array(t_uint256)dyn_storage"
        },
        {
          "astId": 39,
          "contract": "fileA:A",
          "label": "s1",
          "offset": 0,
          "slot": "9",
          "type": "t_string_storage"
        },
        {
          "astId": 41,
          "contract": "fileA:A",
          "label": "b1",
          "offset": 0,
          "slot": "10",
          "type": "t_bytes_storage"
        }
      ],
      "types": {
        "t_address": {
          "encoding": "inplace",
          "label": "address",
          "numberOfBytes": "20"
        },
        "t_array(t_uint256)2_storage": {
          "base": "t_uint256",
          "encoding": "inplace",
          "label": "uint256[2]",
          "numberOfBytes": "64"
        },
        "t_array(t_uint256)dyn_storage": {
          "base": "t_uint256",
          "encoding": "dynamic_array",
          "label": "uint256[]",
          "numberOfBytes": "32"
        },
        "t_bool": {
          "encoding": "inplace",
          "label": "bool",
          "numberOfBytes": "1"
        },
        "t_bytes_storage": {
          "encoding": "bytes",
          "label": "bytes",
          "numberOfBytes": "32"
        },
        "t_mapping(t_address,t_bool)": {
          "encoding": "mapping",
          "key": "t_address",
          "label": "mapping(address => bool)",
          "numberOfBytes": "32",
          "value": "t_bool"
        },
        "t_mapping(t_uint256,t_mapping(t_address,t_bool))": {
          "encoding": "mapping",
          "key": "t_uint256",
          "label": "mapping(uint256 => mapping(address => bool))",
          "numberOfBytes": "32",
          "value": "t_mapping(t_address,t_bool)"
        },
        "t_string_storage": {
          "encoding": "bytes",
          "label": "string",
          "numberOfBytes": "32"
        },
        "t_struct(S)13_storage": {
          "encoding": "inplace",
          "label": "struct A.S",
          "members": [
            {
              "astId": 3,
              "contract": "fileA:A",
              "label": "a",
              "offset": 0,
              "slot": "0",
              "type": "t_uint128"
            },
            {
              "astId": 5,
              "contract": "fileA:A",
              "label": "b",
              "offset": 16,
              "slot": "0",
              "type": "t_uint128"
            },
            {
              "astId": 9,
              "contract": "fileA:A",
              "label": "staticArray",
              "offset": 0,
              "slot": "1",
              "type": "t_array(t_uint256)2_storage"
            },
            {
              "astId": 12,
              "contract": "fileA:A",
              "label": "dynArray",
              "offset": 0,
              "slot": "3",
              "type": "t_array(t_uint256)dyn_storage"
            }
          ],
          "numberOfBytes": "128"
        },
        "t_uint128": {
          "encoding": "inplace",
          "label": "uint128",
          "numberOfBytes": "16"
        },
        "t_uint256": {
          "encoding": "inplace",
          "label": "uint256",
          "numberOfBytes": "32"
        }
      }
    }

瞬态存储布局
------------------------

.. code-block:: json

    {
      "storage": [
        {
          "astId": 17,
          "contract": "fileA:A",
          "label": "y",
          "offset": 0,
          "slot": "0",
          "type": "t_uint256"
        },
        {
          "astId": 21,
          "contract": "fileA:A",
          "label": "z",
          "offset": 0,
          "slot": "1",
          "type": "t_uint256"
        },
        {
          "astId": 28,
          "contract": "fileA:A",
          "label": "taddr",
          "offset": 0,
          "slot": "2",
          "type": "t_address"
        }
      ],
      "types": {
        "t_address": {
          "encoding": "inplace",
          "label": "address",
          "numberOfBytes": "20"
        },
        "t_uint256": {
          "encoding": "inplace",
          "label": "uint256",
          "numberOfBytes": "32"
        }
      }
    }