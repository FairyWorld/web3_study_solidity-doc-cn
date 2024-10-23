******************
使用编译器
******************

.. index:: ! commandline compiler, compiler;commandline, ! solc

.. _commandline-compiler:

使用命令行编译器
******************************

.. note::
    本节不适用于 :ref:`solcjs <solcjs>`，即使在命令行模式下使用也不适用。

基本用法
-----------

Solidity 仓库的构建目标之一是 ``solc``，即 Solidity 命令行编译器。
使用 ``solc --help`` 可以为你提供所有选项的解释。编译器可以生成各种输出，从简单的二进制文件和汇编到抽象语法树（解析树）以及 gas 使用量的估算。
如果你只想编译单个文件，可以运行 ``solc --bin sourceFile.sol``，它将打印出二进制文件。如果你想获取 ``solc`` 的一些更高级的输出变体，最好告诉它将所有内容输出到单独的文件中，使用 ``solc -o outputDirectory --bin --ast-compact-json --asm sourceFile.sol``。

优化器选项
-----------------

在部署合约之前，使用 ``solc --optimize --bin sourceFile.sol`` 编译时激活优化器。
默认情况下，优化器将优化合约，假设它在其生命周期内被调用 200 次（更具体地说，它假设每个操作码大约执行 200 次）。
如果你希望初始合约部署成本更低，而后续函数执行成本更高，请将其设置为 ``--optimize-runs=1``。
如果你预计会有许多交易，并且不在乎更高的部署成本和大小，请将 ``--optimize-runs`` 设置为一个较大的数字。
该参数对以下内容有影响（未来可能会改变）：

- 函数调度例程中的二进制搜索大小
- 大数或字符串等常量的存储方式

.. index:: allowed paths, --allow-paths, base path, --base-path, include paths, --include-path


基本路径和导入重映射
------------------------------

命令行编译器将自动从文件系统读取导入的文件，但也可以使用 ``prefix=path`` 提供 :ref:`路径重定向 <import-remapping>`，方式如下：

.. code-block:: bash

    solc github.com/ethereum/dapp-bin/=/usr/local/lib/dapp-bin/ file.sol

这基本上指示编译器在 ``/usr/local/lib/dapp-bin`` 下搜索以 ``github.com/ethereum/dapp-bin/`` 开头的任何内容。

在访问文件系统以搜索导入时，:ref:`不以 ./ 或 ../ 开头的路径 <direct-imports>` 被视为相对于使用 ``--base-path`` 和 ``--include-path`` 选项指定的目录（如果未指定基路径，则相对于当前工作目录）。
此外，通过这些选项添加的路径部分将不会出现在合约元数据中。

出于安全原因，编译器对其可以访问的目录有 :ref:`限制 <allowed-paths>`。
在命令行上指定的源文件目录和重映射的目标路径将自动允许文件读取器访问，但其他所有内容默认被拒绝。
可以通过 ``--allow-paths /sample/path,/another/sample/path`` 开关允许额外的路径（及其子目录）。
通过 ``--base-path`` 指定的路径中的所有内容始终被允许。

以上只是编译器处理导入路径的简化说明。
有关详细的解释、示例和边界情况的讨论，请参阅 :ref:`路径解析 <path-resolution>` 部分。

.. index:: ! linker, ! --link, ! --libraries

.. _library-linking:

库链接
---------------

如果你的合约使用 :ref:`库 <libraries>`，你会注意到字节码包含形式为 ``__$53aea86b7d70b31448b230b20ae141a537$__`` 的子字符串 `(格式不同 <v0.5.0) <https://docs.soliditylang.org/en/v0.4.26/contracts.html#libraries>`_。这些是实际库地址的占位符。
占位符是完全限定库名称的 keccak256 哈希的十六进制编码的 34 字符前缀。
字节码文件的末尾还将包含形式为 ``// <placeholder> -> <fq library name>`` 的行，以帮助识别占位符代表哪些库。
请注意，完全限定库名称是其源文件的路径和库名称用 ``:`` 分隔。
你可以使用 ``solc`` 作为链接器，这意味着它将在这些点为你插入库地址：

要么在命令中添加 ``--libraries "file.sol:Math=0x1234567890123456789012345678901234567890 file.sol:Heap=0xabCD567890123456789012345678901234567890"`` 为每个库提供地址（使用逗号或空格作为分隔符），要么将字符串存储在文件中（每行一个库），并使用 ``--libraries fileName`` 运行 ``solc``。

.. note::
    从 Solidity 0.8.1 开始，接受 ``=`` 作为库和地址之间的分隔符，``:`` 作为分隔符已被弃用。未来将被移除。目前 ``--libraries "file.sol:Math:0x1234567890123456789012345678901234567890 file.sol:Heap:0xabCD567890123456789012345678901234567890"`` 也可以工作。

.. index:: --standard-json, --base-path

如果 ``solc`` 使用选项 ``--standard-json`` 被调用，它将期望在标准输入上接收 JSON 输入（如下所述），并在标准输出上返回 JSON 输出。这是更复杂和特别是自动化使用的推荐接口。该过程将始终以“成功”状态终止，并通过 JSON 输出报告任何错误。
选项 ``--base-path`` 也在标准-json 模式下处理。

如果 ``solc`` 使用选项 ``--link`` 被调用，所有输入文件都被解释为未链接的二进制文件（十六进制编码），格式为 ``__$53aea86b7d70b31448b230b20ae141a537$__``，并在原地链接（如果输入是从 stdin 读取，则写入 stdout）。在这种情况下，除了 ``--libraries`` 之外的所有选项都将被忽略（包括 ``-o``）。

.. warning::
    不建议手动链接生成的字节码中的库，因为这不会变更日志合约元数据
    。由于元数据包含在编译时指定的库列表，而字节码包含元数据哈希，因此你将获得不同的二进制文件，具体取决于链接何时执行。

    你应该在合约编译时请求编译器链接库，方法是使用 ``solc`` 的 ``--libraries`` 选项或如果使用标准 JSON 接口，则使用 ``libraries`` 键。

.. note::
    库占位符曾经是库本身的完全限定名称，而不是其哈希。此格式仍然被 ``solc --link`` 支持，但编译器将不再输出它。此更改是为了减少库之间发生冲突的可能性，因为只能使用完全限定库名称的前 36 个字符。

.. _evm-version:
.. index:: ! EVM version, compile target


设置 EVM 版本为目标版本
*********************************

当你编译合约代码时，可以指定以避免特定功能或行为的以太坊虚拟机版本。

.. warning::

   为错误的 EVM 版本编译可能会导致错误、奇怪和失败的行为。
   请确保，特别是在运行私有链时，你使用匹配的 EVM 版本。

在命令行中，你可以按如下方式选择 EVM 版本：

.. code-block:: shell

  solc --evm-version <VERSION> contract.sol

在 :ref:`标准 JSON 接口 <compiler-api>` 中，使用 ``"evmVersion"`` 键在 ``"settings"`` 字段中：

.. code-block:: javascript

    {
      "sources": {/* ... */},
      "settings": {
        "optimizer": {/* ... */},
        "evmVersion": "<VERSION>"
      }
    }

目标选项
--------------

以下是目标 EVM 版本的列表以及每个版本引入的与编译器相关的更改。不同版本之间不保证向后兼容。

- ``homestead`` (**支持已弃用**)
   - （最旧版本）
- ``tangerineWhistle`` (**支持已弃用**)
   - 访问其他账户的 gas 成本增加，这与 gas 估算和优化器相关。
   - 默认情况下，所有 gas 都用于外部调用，之前必须保留一定数量的 gas。
- ``spuriousDragon`` (**支持已弃用**)
   - ``exp`` 操作码的 gas 成本增加，这与 gas 估算和优化器相关。
- ``byzantium`` (**支持已弃用**)
   - 操作码 ``returndatacopy``、``returndatasize`` 和 ``staticcall`` 在汇编中可用。
   - 当调用非库的视图或纯函数时，使用 ``staticcall`` 操作码，这防止函数在 EVM 级别修改状态，即使在使用无效类型转换时也适用。
   - 可以访问从函数调用返回的动态数据。
   - 引入了 ``revert`` 操作码，这意味着 ``revert()`` 不会浪费 gas。
- ``constantinople``
   - 操作码 ``create2``、``extcodehash``、``shl``、``shr`` 和 ``sar`` 在汇编中可用。
   - 移位运算符使用移位操作码，因此需要更少的 gas。
- ``petersburg``
   - 编译器的行为与 constantinople 相同。
- ``istanbul``
   - 操作码 ``chainid`` 和 ``selfbalance`` 在汇编中可用。
- ``berlin``
   - ``SLOAD``、``*CALL``、``BALANCE``、``EXT*`` 和 ``SELFDESTRUCT`` 的 gas 成本增加。编译器假设这些操作的冷 gas 成本。这与 gas 估算和优化器相关。
- ``london``
   - 块的基础费用（`EIP-3198 <https://eips.ethereum.org/EIPS/eip-3198>`_ 和 `EIP-1559 <https://eips.ethereum.org/EIPS/eip-1559>`_）可以通过全局 ``block.basefee`` 或 ``basefee()`` 在内联汇编中访问。
- ``paris``
   - 引入 ``prevrandao()`` 和 ``block.prevrandao``，并更改了现已弃用的 ``block.difficulty`` 的语义，禁止在内联汇编中使用 ``difficulty()`` （见 `EIP-4399 <https://eips.ethereum.org/EIPS/eip-4399>`_）。
- ``shanghai``
   - 由于引入了 ``push0``，代码大小和 gas 节省更小（见 `EIP-3855 <https://eips.ethereum.org/EIPS/eip-3855>`_）。
- ``cancun`` (**默认**)
   - 块的 blob 基础费用（`EIP-7516 <https://eips.ethereum.org/EIPS/eip-7516>`_ 和 `EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）可以通过全局 ``block.blobbasefee`` 或 ``blobbasefee()`` 在内联汇编中访问。
   - 在内联汇编中引入 ``blobhash()`` 及相应的全局函数以检索与交易相关的版本哈希（见 `EIP-4844 <https://eips.ethereum.org/EIPS/eip-4844>`_）。
   - 操作码 ``mcopy`` 在汇编中可用（见 `EIP-5656 <https://eips.ethereum.org/EIPS/eip-5656>`_）。
   - 操作码 ``tstore`` 和 ``tload`` 在汇编中可用（见 `EIP-1153 <https://eips.ethereum.org/EIPS/eip-1153>`_）。
- ``prague`` (**实验性**)

.. index:: ! standard JSON, ! --standard-json
.. _compiler-api:

编译器输入和输出 JSON 描述
******************************************

与 Solidity 编译器接口的推荐方式，特别是对于更复杂和自动化的设置，是所谓的 JSON 输入输出接口。所有编译器的发行版都提供相同的接口。

字段通常会发生变化，有些是可选的（如上所述），但我们尽量只进行向后兼容的更改。

编译器 API 期望 JSON 格式的输入，并以 JSON 格式的输出返回编译结果。标准错误输出不被使用，进程将始终以“成功”状态终止，即使存在错误。错误始终作为 JSON 输出的一部分报告。

以下小节通过示例描述格式。注释当然是不允许的，仅用于解释目的。

输入描述
-----------------

.. code-block:: javascript

    {
      // 必需：源代码语言。目前支持的有 "Solidity"、"Yul"、"SolidityAST"（实验性）、"EVMAssembly"（实验性）。
      "language": "Solidity",
      // 必需
      "sources":
      {
        // 这里的键是源文件的“全局”名称，
        // 导入可以通过重映射使用其他文件（见下文）。
        "myFile.sol":
        {
          // 可选：源文件的 keccak256 哈希
          // 用于验证通过 URL 导入的内容。
          "keccak256": "0x123...",
          // 必需（除非使用 "content"，见下文）：源文件的 URL。
          // URL 应按此顺序导入，并检查结果是否与 keccak256 哈希（如果可用）匹配。
          // 如果哈希不匹配或没有 URL 成功，则应引发错误。
          // 仅支持文件系统路径的命令行接口。
          // 在 JavaScript 接口中，URL 将传递给用户提供的读取回调，
          // 因此可以使用回调支持的任何 URL。
          "urls":
          [
            "bzzr://56ab...",
            "ipfs://Qma...",
            "/tmp/path/to/file.sol"
            // 如果使用文件，则应通过
            // `--allow-paths <path>` 将其目录添加到命令行。
          ]
        },
        "settable":
        {
          // 可选：源文件的 keccak256 哈希
          "keccak256": "0x234...",
          // 必需（除非使用 "urls"）：源文件的字面内容
          "content": "contract settable is owned { uint256 private x = 0; function set(uint256 _x) public { if (msg.sender == owner) x = _x; } }"
        },
        "myFile.sol_json.ast":
        {
          // 如果语言设置为 "SolidityAST"，则需要在 "ast" 键下提供 AST
          // 并且只能存在一个源文件。
          // 格式与 `ast` 输出使用的格式相同。
          // 请注意，导入 AST 是实验性的，特别是：
          // - 导入无效的 AST 可能会产生未定义的结果，并且
          // - 对无效 AST 没有适当的错误报告。
          // 此外，请注意，AST 导入仅消耗由
          // 编译器在 "stopAfter": "parsing" 模式下生成的 AST 字段，然后重新执行分析，
          // 因此在导入时忽略任何基于分析的 AST 注释。
          "ast": { ... }
        },
        "myFile_evm.json":
        {
          // 如果语言设置为 "EVMAssembly"，则需要在 "assemblyJson" 键下提供 EVM 汇编 JSON 对象
          // 并且只能存在一个源文件。
          // 格式与 `evm.legacyAssembly` 输出或命令行上的 `--asm-json`
          // 输出使用的格式相同。
          // 请注意，导入 EVM 汇编是实验性的。
          "assemblyJson":
          {
            ".code": [ ... ],
            ".data": { ... }, // 可选
            "sourceList": [ ... ] // 可选（如果在任何 `.code` 对象中未定义 `source` 节点）
          }
        }
      },
      // 可选
      "settings":
      {
        // 可选：在给定阶段后停止编译。目前只有 "parsing" 在这里有效
        "stopAfter": "parsing",
        // 可选：重映射的排序列表
        "remappings": [ ":g=/dir" ],
        // 可选：优化器设置
        "optimizer": {
          // 默认情况下禁用。
          // 注意：enabled=false 仍然保留某些优化。请参见下面的注释。
          // 警告：在版本 0.8.6 之前，省略 'enabled' 键并不等同于将其设置为 false，
          // 实际上会禁用所有优化。
          "enabled": true,
          // 根据你打算运行代码的次数进行优化。
          // 较低的值将更优化初始部署成本，较高的
          // 值将更优化高频使用。
          "runs": 200,
          // 详细开关优化器组件的开关。
          // 上面的 "enabled" 开关提供两个默认值，可以在这里进行调整。
          // 如果给定 "details"，则可以省略 "enabled"。
          "details": {
            // 如果未给出详细信息，窥视优化器始终开启，
            // 使用详细信息将其关闭。
            "peephole": true,
            // 如果未给出详细信息，内联器始终关闭，
            // 使用详细信息将其打开。
            "inliner": false,
            // 如果未给出详细信息，未使用的跳转目标移除器始终开启，
            // 使用详细信息将其关闭。
            "jumpdestRemover": true,
            // 有时在可交换操作中重新排序字面量。
            "orderLiterals": false,
            // 移除重复的代码块
            "deduplicate": false,
            // 常见子表达式消除，这是最复杂的步骤，但
            // 也可以提供最大的收益。
            "cse": false,
            // 优化代码中字面数字和字符串的表示。
            "constantOptimizer": false,
            // 在某些情况下，在递增 for 循环的计数器时使用未检查的算术。
            // 如果未给出详细信息，则始终开启。
            "simpleCounterForLoopUncheckedIncrement": true,
            // 新的 Yul 优化器。主要在 ABI 编码器 v2
            // 和内联汇编的代码上操作。
            // 它与全局优化器设置一起激活
            // 并可以在这里停用。
            // 在 Solidity 0.6.0 之前，必须通过此开关激活。
            "yul": false,
            // Yul 优化器的调优选项。
            "yulDetails": {
              // 改善变量的堆栈槽分配，可以提前释放堆栈槽。
              // 如果激活 Yul 优化器，则默认启用。
              "stackAllocation": true,
              // 选择要应用的优化步骤。也可以修改优化序列和清理序列。
              // 每个序列的指令用 ":" 分隔，值以
              // 优化序列:清理序列的形式提供。有关更多信息，请参见
              // "优化器 > 选择优化"。
              // 此字段是可选的，如果未提供，则使用优化和清理的默认序列。
              // 如果只提供一个序列，则不会运行另一个序列。
              // 如果只提供分隔符 ":"，则不会运行优化或清理
              // 序列。
              // 如果设置为空值，则仅使用默认清理序列，
              // 不应用任何优化步骤。
              "optimizerSteps": "dhfoDgvulfnTUtnIf..."
            }
          }
        },
        // 要编译的 EVM 版本。
        // 影响类型检查和代码生成。可以是 homestead、
        // tangerineWhistle、spuriousDragon、byzantium、constantinople、
        // petersburg、istanbul、berlin、london、paris、shanghai、cancun（默认）或 prague。
        "evmVersion": "cancun",
        // 可选：更改编译管道以通过 Yul 中间表示。
        // 默认情况下为 false。
        "viaIR": true,
        // 可选：调试设置
        "debug": {
          // 如何处理 revert（和 require）原因字符串。设置为
          // "default"、"strip"、"debug" 和 "verboseDebug"。
          // "default" 不注入编译器生成的 revert 字符串，并保留用户提供的字符串。
          // "strip" 移除所有 revert 字符串（如果可能，即如果使用字面量），保留副作用
          // "debug" 注入编译器生成的内部 revert 字符串，当前为 ABI 编码器 V1 和 V2 实现。
          // "verboseDebug" 甚至将进一步信息附加到用户提供的 revert 字符串（尚未实现）
          "revertStrings": "default",
          // 可选：在生成的 EVM
          // 汇编和 Yul 代码的注释中包含多少额外的调试信息。可用组件有：
          // - `location`：形式为 `@src <index>:<start>:<end>` 的注释，指示
          //    对应元素在原始 Solidity 文件中的位置，其中：
          //     - `<index>` 是与 `@use-src` 注释匹配的文件索引，
          //     - `<start>` 是该位置的第一个字节的索引，
          //     - `<end>` 是该位置后第一个字节的索引。
          // - `snippet`：来自 `@src` 指示位置的单行代码片段。
          //     该片段被引用并跟随相应的 `@src` 注释。
          // - `*`：可以用作请求所有内容的通配符值。
          "debugInfo": ["location", "snippet"]
        },
        // 元数据设置（可选）
        "metadata": {
          // 默认情况下，CBOR 元数据附加在字节码的末尾。
          // 将此设置为 false 会从运行时和部署时代码中省略元数据。
          "appendCBOR": true,
          // 仅使用字面内容而不使用 URL（默认值为 false）
          "useLiteralContent": true,
          // 使用给定的哈希方法生成附加到字节码的元数据哈希。
          // 可以通过选项 "none" 从字节码中移除元数据哈希。
          // 其他选项为 "ipfs" 和 "bzzr1"。
          // 如果省略该选项，则默认使用 "ipfs"。
          "bytecodeHash": "ipfs"
        },
        // 库的地址。如果未在此处给出所有库，
        // 可能会导致未链接的对象，其输出数据不同。
        "libraries": {
          // 顶级键是使用库的源文件的名称。
          // 如果使用了重映射，则此源文件应在应用重映射后与全局路径匹配。
          // 如果此键为空字符串，则指的是全局级别。
          "myFile.sol": {
            "MyLib": "0x123123..."
          }
        },
        // 以下可以根据文件和合约名称选择所需的输出。
        // 如果省略此字段，则编译器将加载并进行类型检查，
        // 但不会生成任何输出，除了错误。
        // 第一层键是文件名，第二层键是合约名。
        // 空合约名称用于与合约无关的输出
        // 而是与整个源文件相关的输出，如 AST。
        // 合约名称为星号表示文件中的所有合约。
        // 同样，文件名为星号表示所有文件。
        // 要选择编译器可能生成的所有输出，
        // 排除 Yul 中间表示输出，请使用
        // "outputSelection: { "*": { "*": [ "*" ], "": [ "*" ] } }"
        // 但请注意，这可能会不必要地减慢编译过程。
        //
        // 可用的输出类型如下：
        //
        // 文件级（需要空字符串作为合约名称）：
        //   ast - 所有源文件的 AST
        //
        // 合约级（需要合约名称或 "*"）：
        //   abi - ABI
        //   devdoc - 开发者文档（natspec）
        //   userdoc - 用户文档（natspec）
        //   metadata - 元数据
        //   ir - 优化前代码的 Yul 中间表示
        //   irAst - 优化前代码的 Yul 中间表示的 AST
        //   irOptimized - 优化后的中间表示
        //   irOptimizedAst - 优化后中间表示的 AST
        //   storageLayout - 合约状态变量在存储中的槽、偏移量和类型。
        //   transientStorageLayout - 合约状态变量在临时存储中的槽、偏移量和类型。
        //   evm.assembly - 新的汇编格式
        //   evm.legacyAssembly - 旧式汇编格式 JSON
        //   evm.bytecode.functionDebugData - 函数级调试信息
        //   evm.bytecode.object - 字节码对象
        //   evm.bytecode.opcodes - 操作码列表
        //   evm.bytecode.sourceMap - 源映射（对调试有用）
        //   evm.bytecode.linkReferences - 链接引用（如果未链接对象）
        //   evm.bytecode.generatedSources - 编译器生成的源
        //   evm.deployedBytecode* - 部署字节码（具有 evm.bytecode 的所有选项）
        //   evm.deployedBytecode.immutableReferences - 从 AST id 到引用不可变的字节码范围的映射
        //   evm.methodIdentifiers - 函数哈希列表
        //   evm.gasEstimates - 函数 gas 估算
        //
        // 请注意，使用 `evm`、`evm.bytecode` 等将选择该输出的每个目标部分。此外，`*` 可以用作通配符请求所有内容。
        //
        "outputSelection": {
          "*": {
            "*": [
              "metadata", "evm.bytecode" // 启用每个合约的元数据和字节码输出。
              , "evm.bytecode.sourceMap" // 启用每个合约的源映射输出。
            ],
            "": [
              "ast" // 启用每个文件的 AST 输出。
            ]
          },
          // 启用在文件 def 中定义的 MyContract 的 abi 和 opcodes 输出。
          "def": {
            "MyContract": [ "abi", "evm.bytecode.opcodes" ]
          }
        },
        // modelChecker 对象是实验性的，可能会发生变化。
        "modelChecker":
        {
          // 选择哪些合约应作为已部署的合约进行分析。
          "contracts":
          {
            "source1.sol": ["contract1"],
            "source2.sol": ["contract2", "contract3"]
          },
          // 选择如何编码除法和取模操作。
          // 使用 `false` 时，它们被替换为与松弛
          // 变量的乘法。这是默认值。
          // 如果你使用 CHC 引擎并且不使用 Spacer 作为 Horn 求解器（例如使用 Eldarica），
          // 在这里使用 `true` 是推荐的。
          // 有关此选项的更详细说明，请参见形式验证部分。
          "divModNoSlacks": false,
          // 选择要使用的模型检查器引擎：all（默认）、bmc、chc、none。
          "engine": "chc",
          // 选择在调用函数的代码在编译时可用的情况下，外部调用是否应被视为可信。
          // 有关详细信息，请参见 SMTChecker 部分。
          "extCalls": "trusted",
          // 选择应向用户报告哪些类型的不变性：合约、重入。
          "invariants": ["contract", "reentrancy"],
          // 选择是否输出所有已证明的目标。默认值为 `false`。
          "showProvedSafe": true,
          // 选择是否输出所有未证明的目标。默认值为 `false`。
          "showUnproved": true,
          // 选择是否输出所有不支持的语言特性。默认值为 `false`。
          "showUnsupported": true,
          // 选择应使用哪些求解器（如果可用）。
          // 有关求解器描述，请参见形式验证部分。
          "solvers": ["cvc5", "smtlib2", "z3"],
          // 选择应检查哪些目标：constantCondition、
          // underflow、overflow、divByZero、balance、assert、popEmptyArray、outOfBounds。
          // 如果未给出选项，则默认检查所有目标，
          // 除了 Solidity >=0.8.7 的 underflow/overflow。
          // 有关目标描述，请参见形式验证部分。
          "targets": ["underflow", "overflow", "assert"],
          // 每个 SMT 查询的超时（以毫秒为单位）。
          // 如果未给出此选项，SMTChecker 将默认使用确定性的
          // 资源限制。
          // 给定的超时为 0 意味着对任何查询没有资源/时间限制。
          "timeout": 20000
        }
      }
    }
输出描述
------------------

.. code-block:: javascript

    {
      // 可选：如果没有遇到错误/警告/信息，则不出现
      "errors": [
        {
          // 可选：源文件中的位置
          "sourceLocation": {
            "file": "sourceFile.sol",
            "start": 0,
            "end": 100
          },
          // 可选：进一步的位置（例如，冲突声明的位置）
          "secondarySourceLocations": [
            {
              "file": "sourceFile.sol",
              "start": 64,
              "end": 92,
              "message": "其他声明在这里："
            }
          ],
          // 必需：错误类型，例如 "TypeError"、"InternalCompilerError"、"Exception" 等
          // 请参见下面的完整类型列表
          "type": "TypeError",
          // 必需：错误来源的组件，例如 "general" 等
          "component": "general",
          // 必需（"error"、"warning" 或 "info"，但请注意，这可能在将来扩展）
          "severity": "error",
          // 可选：导致错误的唯一代码
          "errorCode": "3141",
          // 必需
          "message": "无效的关键字",
          // 可选：带有源位置的格式化消息
          "formattedMessage": "sourceFile.sol:100: 无效的关键字"
        }
      ],
      // 这包含文件级输出
      // 可以通过 outputSelection 设置进行限制/过滤
      "sources": {
        "sourceFile.sol": {
          // 源的标识符（用于源映射）
          "id": 1,
          // AST 对象
          "ast": {}
        }
      },
      // 这包含合约级输出
      // 可以通过 outputSelection 设置进行限制/过滤
      "contracts": {
        "sourceFile.sol": {
          // 如果使用的语言没有合约名称，则此字段应等于空字符串
          "ContractName": {
            // 以太坊合约 ABI。如果为空，则表示为空数组
            // 请参见 https://docs.soliditylang.org/en/develop/abi-spec.html
            "abi": [],
            // 请参见元数据输出文档（序列化 JSON 字符串）
            "metadata": "{/* ... */}",
            // 用户文档（natspec）
            "userdoc": {},
            // 开发者文档（natspec）
            "devdoc": {},
            // 优化前的中间表示（字符串）
            "ir": "",
            // 优化前中间表示的 AST
            "irAst":  {/* ... */},
            // 优化后的中间表示（字符串）
            "irOptimized": "",
            // 优化后中间表示的 AST
            "irOptimizedAst": {/* ... */},
            // 请参见存储布局文档
            "storageLayout": {"storage": [/* ... */], "types": {/* ... */} },
            // 请参见存储布局文档
            "transientStorageLayout": {"storage": [/* ... */], "types": {/* ... */} },
            // EVM 相关输出
            "evm": {
              // 汇编（字符串）
              "assembly": "",
              // 旧式汇编（对象）
              "legacyAssembly": {},
              // 字节码及相关细节
              "bytecode": {
                // 函数级别的调试数据
                "functionDebugData": {
                  // 现在跟随一组函数，包括编译器内部和用户定义的函数。该集合不必完整
                  "@mint_13": { // 函数的内部名称
                    "entryPoint": 128, // 字节码中函数开始的字节偏移（可选）
                    "id": 13, // 函数定义的 AST ID 或 null（对于编译器内部函数）（可选）
                    "parameterSlots": 2, // 函数参数的 EVM 堆栈槽数量（可选）
                    "returnSlots": 1 // 返回值的 EVM 堆栈槽数量（可选）
                  }
                },
                // 字节码作为十六进制字符串
                "object": "00fe",
                // 操作码列表（字符串）
                "opcodes": "",
                // 源映射作为字符串。请参见源映射定义
                "sourceMap": "",
                // 编译器生成的源数组。目前仅包含一个 Yul 文件
                "generatedSources": [{
                  // Yul AST
                  "ast": {/* ... */},
                  // 以文本形式的源文件（可能包含注释）
                  "contents":"{ function abi_decode(start, end) -> data { data := calldataload(start) } }",
                  // 源文件 ID，用于源引用，与 Solidity 源文件相同的 "namespace"
                  "id": 2,
                  "language": "Yul",
                  "name": "#utility.yul"
                }],
                // 如果给出，这是一个未链接的对象
                "linkReferences": {
                  "libraryFile.sol": {
                    // 字节码中的字节偏移
                    // 链接替换位于此处的 20 字节
                    "Library1": [
                      { "start": 0, "length": 20 },
                      { "start": 200, "length": 20 }
                    ]
                  }
                }
              },
              "deployedBytecode": {
                /* ..., */ // 与上面相同的布局
                "immutableReferences": {
                  // 有两个对 AST ID 3 的不可变引用，均为 32 字节长。一个在字节码偏移 42，另一个在字节码偏移 80
                  "3": [{ "start": 42, "length": 32 }, { "start": 80, "length": 32 }]
                }
              },
              // 函数哈希列表
              "methodIdentifiers": {
                "delegate(address)": "5c19a95c"
              },
              // 函数 gas 估算
              "gasEstimates": {
                "creation": {
                  "codeDepositCost": "420000",
                  "executionCost": "infinite",
                  "totalCost": "infinite"
                },
                "external": {
                  "delegate(address)": "25000"
                },
                "internal": {
                  "heavyLifting()": "infinite"
                }
              }
            }
          }
        }
      }
    }


错误类型
~~~~~~~~~~~

1. ``JSONError``：JSON 输入不符合所需格式，例如输入不是 JSON 对象，语言不受支持等
2. ``IOError``：IO 和导入处理错误，例如无法解析的 URL 或提供的源中的哈希不匹配
3. ``ParserError``：源代码不符合语言规则
4. ``DocstringParsingError``：注释块中的 NatSpec 标签无法解析
5. ``SyntaxError``：语法错误，例如 ``continue`` 在 ``for`` 循环外使用
6. ``DeclarationError``：无效、无法解析或冲突的标识符名称。例如 ``Identifier not found``
7. ``TypeError``：类型系统内的错误，例如无效的类型转换、无效的赋值等
8. ``UnimplementedFeatureError``：编译器不支持的特性，但预计在未来版本中会得到支持
9. ``InternalCompilerError``：编译器中触发的内部错误 - 应作为问题报告
10. ``Exception``：编译期间的未知故障 - 应作为问题报告
11. ``CompilerError``：编译器堆栈的无效使用 - 应作为问题报告
12. ``FatalError``：致命错误未正确处理 - 应作为问题报告
13. ``YulException``：Yul 代码生成期间的错误 - 应作为问题报告
14. ``Warning``：警告，未停止编译，但如果可能应予以解决
15. ``Info``：编译器认为用户可能会发现有用的信息，但并不危险且不一定需要解决