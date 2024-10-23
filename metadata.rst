.. include:: glossaries.rst

.. _metadata:

#################
合约元数据
#################

.. index:: metadata, contract verification

Solidity 编译器会自动生成一个 JSON 文件。
该文件包含关于已编译合约的两种信息：

- 如何与合约交互：|ABI| 和 |natspec| 文档。
- 如何重现编译并验证已部署的合约：编译器版本、编译设置和使用的源文件。

编译器默认将元数据文件的 IPFS 哈希附加到每个合约的运行时字节码（不一定是创建字节码）的末尾，
这样，如果发布，你可以以经过身份验证的方式检索该文件，而无需依赖集中式数据提供者。
其他可用选项是 Swarm 哈希和不将元数据哈希附加到字节码。这些可以通过 :ref:`Standard JSON Interface<compiler-api>` 进行配置。

你必须将元数据文件发布到 IPFS、Swarm 或其他服务，以便其他人可以访问它。
可以使用 ``solc --metadata`` 命令和 ``--output-dir`` 参数创建该文件。
没有该参数时，元数据将写入标准输出。
元数据包含指向源代码的 IPFS 和 Swarm 引用，因此你必须上传所有源文件以及元数据文件。
对于 IPFS，``ipfs add`` 返回的 CID 中包含的哈希（而不是文件的直接 sha2-256 哈希）应与字节码中包含的哈希匹配。

元数据文件具有以下格式。下面的示例以人类可读的方式呈现。
正确格式化的元数据应正确使用引号，将空白减少到最小，并按字母顺序对所有对象的键进行排序，以达到规范格式。
注释不被允许，仅在此处用于解释目的。

.. code-block:: javascript

    {
      // 必需：关于编译器的详细信息，内容视语言而定。
      "compiler": {
        // 可选：生成此输出的编译器二进制文件的哈希
        "keccak256": "0x123...",
        // Solidity 必需：编译器版本
        "version": "0.8.2+commit.661d1103"
      },
      // 必需：源代码语言，基本上选择规范的“子版本”
      "language": "Solidity",
      // 必需：关于合约的生成信息。
      "output": {
        // 必需：合约的 ABI 定义。请参见“合约 ABI 规范”
        "abi": [/* ... */],
        // 必需：合约的 NatSpec 开发者文档。有关详细信息，请参见 https://docs.soliditylang.org/en/latest/natspec-format.html。
        "devdoc": {
          // 合约的 @author NatSpec 字段的内容
          "author": "John Doe",
          // 合约的 @dev NatSpec 字段的内容
          "details": "Interface of the ERC20 standard as defined in the EIP. See https://eips.ethereum.org/EIPS/eip-20 for details",
          "errors": {
            "MintToZeroAddress()" : {
              "details": "Cannot mint to zero address"
            }
          },
          "events": {
            "Transfer(address,address,uint256)": {
              "details": "Emitted when `value` tokens are moved from one account (`from`) toanother (`to`).",
              "params": {
                "from": "The sender address",
                "to": "The receiver address",
                "value": "The token amount"
              }
            }
          },
          "kind": "dev",
          "methods": {
            "transfer(address,uint256)": {
              // 方法的 @dev NatSpec 字段的内容
              "details": "Returns a boolean value indicating whether the operation succeeded. Must be called by the token holder address",
              // 方法的 @param NatSpec 字段的内容
              "params": {
                "_value": "The amount tokens to be transferred",
                "_to": "The receiver address"
              },
              // @return NatSpec 字段的内容。
              "returns": {
                // 返回变量名称（此处为“success”）如果存在。如果返回变量未命名，则使用 "_0" 作为键
                "success": "a boolean value indicating whether the operation succeeded"
              }
            }
          },
          "stateVariables": {
            "owner": {
              // 状态变量的 @dev NatSpec 字段的内容
              "details": "Must be set during contract creation. Can then only be changed by the owner"
            }
          },
          // 合约的 @title NatSpec 字段的内容
          "title": "MyERC20: an example ERC20",
          "version": 1 // NatSpec 版本
        },
        // 必需：合约的 NatSpec 用户文档。请参见“NatSpec 格式”
        "userdoc": {
          "errors": {
            "ApprovalCallerNotOwnerNorApproved()": [
              {
                "notice": "The caller must own the token or be an approved operator."
              }
            ]
          },
          "events": {
            "Transfer(address,address,uint256)": {
              "notice": "`_value` tokens have been moved from `from` to `to`"
            }
          },
          "kind": "user",
          "methods": {
            "transfer(address,uint256)": {
              "notice": "Transfers `_value` tokens to address `_to`"
            }
          },
          "version": 1 // NatSpec 版本
        }
      },
      // 必需：编译器设置。反映编译期间 JSON 输入中的设置。
      // 请查看标准 JSON 输入的“settings”字段的文档
      "settings": {
        // Solidity 必需：此元数据创建的合约或库的文件路径和名称。
        "compilationTarget": {
          "myDirectory/myFile.sol": "MyContract"
        },
        // Solidity 必需。
        "evmVersion": "london",
        // Solidity 必需：使用的库的地址。
        "libraries": {
          "MyLib": "0x123123..."
        },
        "metadata": {
          // 反映输入 json 中使用的设置，默认为 "true"
          "appendCBOR": true,
          // 反映输入 json 中使用的设置，默认为 "ipfs"
          "bytecodeHash": "ipfs",
          // 反映输入 json 中使用的设置，默认为 "false"
          "useLiteralContent": true
        },
        // 可选：优化器设置。“enabled”和“runs”字段已弃用
        // 仅为向后兼容而提供。
        "optimizer": {
          "details": {
            "constantOptimizer": false,
            "cse": false,
            "deduplicate": false,
            // inliner 默认为 "false"
            "inliner": false,
            // jumpdestRemover 默认为 "true"
            "jumpdestRemover": true,
            "orderLiterals": false,
            // peephole 默认为 "true"
            "peephole": true,
            "yul": true,
            // 可选：仅在 "yul" 为 "true" 时存在
            "yulDetails": {
              "optimizerSteps": "dhfoDgvulfnTUtnIf...",
              "stackAllocation": false
            }
          },
          "enabled": true,
          "runs": 500
        },
        // Solidity 必需：导入重映射的排序列表。
        "remappings": [ ":g=/dir" ]
      },
      // 必需：编译源文件/源单元，键为文件路径
      "sources": {
        "settable": {
          // 必需（除非使用 "url"）：源文件的文字内容
          "content": "contract settable is owned { uint256 private x = 0; function set(uint256 _x) public { if (msg.sender == owner) x = _x; } }",
          // 必需：源文件的 keccak256 哈希
          "keccak256": "0x234..."
        },
        "myDirectory/myFile.sol": {
          // 必需：源文件的 keccak256 哈希
          "keccak256": "0x123...",
          // 可选：源文件中给出的 SPDX 许可证标识符
          "license": "MIT",
          // 必需（除非使用 "content"，见上文）：指向源文件的已排序 URL(s)
          // 协议或多或少是任意的，但建议使用 IPFS URL
          "urls": [ "bzz-raw://7d7a...", "dweb:/ipfs/QmN..." ]
        }
      },
      // 必需：元数据格式的版本
      "version": 1
    }
.. warning::
  由于生成的合约的字节码默认包含元数据哈希，任何对元数据的更改可能会导致字节码的变化。
  这包括文件名或路径的更改，并且由于元数据包含所有使用的源代码的哈希，单个空格的变化会导致不同的元数据和不同的字节码。

.. note::
    上述 ABI 定义没有固定顺序。它可能会随着编译器版本的变化而变化。不过，从 Solidity 0.5.12 版本开始，数组保持一定的顺序。

.. _encoding-of-the-metadata-hash-in-the-bytecode:

元数据哈希在字节码中的编码
==========================

编译器当前默认将 `IPFS 哈希 (在 CID v0 中) <https://docs.ipfs.tech/concepts/content-addressing/#version-0-v0>`_ 附加到字节码的末尾，后面跟着编译器版本。
可选地，可以使用 Swarm 哈希代替 IPFS，或使用实验性标志。
以下是所有可能的字段：

.. code-block:: javascript

    {
      "ipfs": "<metadata hash>",
      // 如果编译器设置中的 "bytecodeHash" 是 "bzzr1"，则不是 "ipfs" 而是 "bzzr1"
      "bzzr1": "<metadata hash>",
      // 以前的版本使用 "bzzr0" 而不是 "bzzr1"
      "bzzr0": "<metadata hash>",
      // 如果使用了任何影响代码生成的实验性功能
      "experimental": true,
      "solc": "<compiler version>"
    }

因为我们可能在未来支持其他方式来检索元数据文件，所以这些信息以 `CBOR <https://tools.ietf.org/html/rfc7049>`_-编码存储。
字节码中的最后两个字节指示 CBOR 编码信息的长度。通过查看这个长度，可以使用 CBOR 解码器解码字节码的相关部分。

查看 `Metadata Playground <https://playground.sourcify.dev/>`_ 以查看其实际效果。

而 solc 的发布版本使用如上所示的 3 字节版本编码（每个主版本、次版本和补丁版本号各占一个字节），预发布版本则使用包括提交哈希和构建日期的完整版本字符串。

命令行标志 ``--no-cbor-metadata`` 可用于跳过将元数据附加到已部署字节码末尾。等效地，标准 JSON 输入中的布尔字段 ``settings.metadata.appendCBOR`` 可以设置为 false。

.. note::
  CBOR 映射还可以包含其他键，因此最好通过查看字节码末尾的 CBOR 长度来完全解码数据，并使用适当的 CBOR 解析器。不要依赖它以 ``0xa264`` 或 ``0xa2 0x64 'i' 'p' 'f' 's'`` 开头。

自动接口生成和 NatSpec 的使用
=============================

元数据的使用方式如下：希望与合约交互的组件（例如钱包）检索合约的代码。
它解码包含元数据文件的 IPFS/Swarm 哈希的 CBOR 编码部分。通过该哈希，检索元数据文件。该文件被 JSON 解码为如上所示的结构。

然后，组件可以使用 ABI 自动生成合约的基本用户界面。

此外，钱包可以使用 NatSpec 用户文档在用户与合约交互时显示可读的确认消息，并请求交易签名的授权。

有关更多信息，请阅读 :doc:`以太坊自然语言规范 (NatSpec) 格式 <natspec-format>`。

源代码验证的使用
==================

如果已固定（pinned）/发布，可以从 IPFS/Swarm 检索合约的元数据。
元数据文件还包含源文件的 URL 或 IPFS 哈希，以及编译设置，即重现编译所需的所有内容。

有了这些信息，就可以通过重现编译并将编译生成的字节码与已部署合约的字节码进行比较来验证合约的源代码。

这自动验证了元数据，因为其哈希是字节码以及源代码的一部分，因为它们的哈希是元数据的一部分。
文件或设置的任何更改都会导致不同的元数据哈希。这里的元数据作为整个编译的指纹。

`Sourcify <https://sourcify.dev>`_ 利用此功能进行“完全/完美验证”，并将文件公开固定在 IPFS 上，以便通过元数据哈希进行访问。