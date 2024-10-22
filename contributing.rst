############
贡献
############

欢迎任何形式的帮助，我们有很多方式可以为 Solidity 贡献。

特别是，我们非常感谢在以下领域的支持：

* 报告问题。
* 修复和回应 `Solidity 的 GitHub 问题 <https://github.com/ethereum/solidity/issues>`_，特别是那些标记为 `"good first issue" <https://github.com/ethereum/solidity/labels/good%20first%20issue>`_ 的问题，这些问题是为外部贡献者准备的入门问题。
* 改进文档。
* `将文档翻译 <https://github.com/solidity-docs>`_ 成更多语言。
* 回答其他用户在 `StackExchange <https://ethereum.stackexchange.com>`_ 和 `Solidity Gitter 聊天 <https://gitter.im/ethereum/solidity>`_ 中的问题。
* 通过在 `Solidity 论坛 <https://forum.soliditylang.org/>`_ 提出语言变更或新特性，参与语言设计过程并提供反馈。

要开始，你可以尝试 :ref:`从源代码构建`，以熟悉 Solidity 的组件和构建过程。此外，熟练编写 Solidity 智能合约也可能会很有用。

请注意，该项目发布时遵循 `贡献者行为准则 <https://raw.githubusercontent.com/ethereum/solidity/develop/CODE_OF_CONDUCT.md>`_。通过参与该项目——在问题、拉取请求或 Gitter 频道中——你同意遵守其条款。

团队会议
==========

如果你有问题或拉取请求需要讨论，或者对团队和贡献者正在进行的工作感兴趣，你可以加入我们的公开团队会议：

- 每周三下午 3 点 CET/CEST。

会议在 `Jitsi <https://meet.ethereum.org/solidity>`_ 上进行。

如何报告问题
====================

要报告问题，请使用 `GitHub 问题跟踪器 <https://github.com/ethereum/solidity/issues>`_。报告问题时，请提及以下详细信息：

* Solidity 版本。
* 源代码（如适用）。
* 操作系统。
* 重现问题的步骤。
* 实际行为与预期行为的对比。

将导致问题的源代码缩减到最小是非常有帮助的，有时甚至可以澄清误解。

关于语言设计的技术讨论，请在 `Solidity 论坛 <https://forum.soliditylang.org/>`_ 中发帖（见 :ref:`solidity_language_design`）。

拉取请求的工作流程
==========================

为了贡献，请从 ``develop`` 分支进行分叉并在其中进行更改。你的提交信息应详细说明你更改的 *原因* 和 *内容*（除非是微小的更改）。

如果在分叉后需要从 ``develop`` 中拉取任何更改（例如，解决潜在的合并冲突），请避免使用 ``git merge``，而是使用 ``git rebase`` 你的分支。这将帮助我们更轻松地审查你的更改。

此外，如果你正在编写新特性，请确保在 ``test/`` 下添加适当的测试用例（见下文）。

但是，如果你正在进行较大的更改，请先咨询 `Solidity 开发 Gitter 频道 <https://gitter.im/ethereum/solidity-dev>`_（与上面提到的不同——这个频道专注于编译器和语言开发，而不是语言使用）。

新特性和错误修复应添加到 ``Changelog.md`` 文件中：请在适用时遵循之前条目的风格。

最后，请确保遵循该项目的 `编码风格 <https://github.com/ethereum/solidity/blob/develop/CODING_STYLE.md>`_。此外，尽管我们进行 CI 测试，但请在提交拉取请求之前测试你的代码并确保它在本地构建。

我们强烈建议在提交拉取请求之前查看我们的 `审查清单 <https://github.com/ethereum/solidity/blob/develop/ReviewChecklist.md>`_。
我们会彻底审查每个 PR，并帮助你正确处理，但有许多常见问题可以轻松避免，从而使审查过程更加顺利。

感谢你的帮助！

运行编译器测试
==========================

先决条件
-------------

要运行所有编译器测试，你可能需要可选地安装一些依赖项（`evmone <https://github.com/ethereum/evmone/releases>`_，
`libz3 <https://github.com/Z3Prover/z3>`_，`Eldarica <https://github.com/uuverifiers/eldarica/>`_，
`cvc5 <https://github.com/cvc5/cvc5>`_）。

在 macOS 系统上，一些测试脚本期望安装 GNU coreutils。
这可以通过 Homebrew 最简单地完成：``brew install coreutils``。

在 Windows 系统上，请确保你有创建符号链接的权限，否则某些测试可能会失败。
管理员应该拥有该权限，但你也可以 `授予其他用户权限 <https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/create-symbolic-links#policy-management>`_
或 `启用开发者模式 <https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development>`_。

运行测试
-----------------

Solidity 包含不同类型的测试，其中大多数打包在 `Boost C++ 测试框架 <https://www.boost.org/doc/libs/release/libs/test/doc/html/index.html>`_ 应用程序 ``soltest`` 中。
运行 ``build/test/soltest`` 或其包装器 ``scripts/soltest.sh`` 对于大多数更改来说是足够的。

``./scripts/tests.sh`` 脚本自动执行大多数 Solidity 测试，包括那些打包在 `Boost C++ 测试框架 <https://www.boost.org/doc/libs/release/libs/test/doc/html/index.html>`_
应用程序 ``soltest``（或其包装器 ``scripts/soltest.sh``）中的测试，以及命令行测试和编译测试。

测试系统会自动尝试发现 `evmone <https://github.com/ethereum/evmone/releases>`_ 的位置以运行语义测试。

``evmone`` 库必须位于相对于当前工作目录的 ``deps`` 或 ``deps/lib`` 目录中，或者其父目录或父目录的父目录中。或者，可以通过 ``ETH_EVMONE`` 环境变量指定 ``evmone`` 共享对象的显式位置。

``evmone`` 主要用于运行语义和 gas 测试。
如果你没有安装它，可以通过将 ``--no-semantic-tests`` 标志传递给 ``scripts/soltest.sh`` 跳过这些测试。

``evmone`` 库在 Linux 上的文件名扩展名应为 ``.so``，在 Windows 系统上为 ``.dll``，在 macOS 上为 ``.dylib``。

要运行 SMT 测试，必须安装 ``libz3`` 库，并且在编译器配置阶段可以被 ``cmake`` 找到。
一些 SMT 测试使用 ``Eldarica`` 而不是 ``Z3``。
``Eldarica`` 是一个运行时依赖项，其可执行文件（``eld``）必须在 ``PATH`` 中以使测试通过。
但是，如果未找到 ``Eldarica``，这些测试将自动跳过。

如果你的系统上未安装 ``libz3`` 库，你应该通过在运行 ``./scripts/tests.sh`` 之前导出 ``SMT_FLAGS=--no-smt`` 或运行 ``./scripts/soltest.sh --no-smt`` 来禁用 SMT 测试。
这些测试位于 ``libsolidity/smtCheckerTests``。

.. note::

    要获取 Soltest 运行的所有单元测试的列表，请运行 ``./build/test/soltest --list_content=HRF``。

为了更快的结果，你可以运行一部分或特定的测试。

要运行一部分测试，你可以使用过滤器：
``./scripts/soltest.sh -t TestSuite/TestName``，
其中 ``TestName`` 可以是通配符 ``*``。
或者，例如，运行 yul 消歧义器的所有测试：
``./scripts/soltest.sh -t "yulOptimizerTests/disambiguator/*" --no-smt``.

``./build/test/soltest --help`` 提供了所有可用选项的详细帮助。

特别请参见：

- `show_progress (-p) <https://www.boost.org/doc/libs/release/libs/test/doc/html/boost_test/utf_reference/rt_param_reference/show_progress.html>`_ 显示测试完成情况，
- `run_test (-t) <https://www.boost.org/doc/libs/release/libs/test/doc/html/boost_test/utf_reference/rt_param_reference/run_test.html>`_ 运行特定测试用例，以及
- `report-level (-r) <https://www.boost.org/doc/libs/release/libs/test/doc/html/boost_test/utf_reference/rt_param_reference/report_level.html>`_ 提供更详细的报告。

.. note::

    在 Windows 环境中工作的人希望在没有 libz3 的情况下运行上述基本集。
    使用 Git Bash，你可以使用：``./build/test/Release/soltest.exe -- --no-smt``。
    如果你在普通命令提示符下运行，请使用 ``.\build\test\Release\soltest.exe -- --no-smt``。

如果你想使用 GDB 调试，请确保以不同于“通常”的方式构建。
例如，你可以在 ``build`` 文件夹中运行以下命令：

.. code-block:: bash

   cmake -DCMAKE_BUILD_TYPE=Debug ..
   make

这将创建符号，以便在使用 ``--debug`` 标志调试测试时，
你可以访问可以中断或打印的函数和变量。

CI 运行额外的测试（包括 ``solc-js`` 和测试第三方 Solidity
框架），这些测试需要编译 Emscripten 目标。

编写和运行语法测试
------------------

语法测试检查编译器是否为无效代码生成正确的错误消息
并正确接受有效代码。
它们存储在 ``tests/libsolidity/syntaxTests`` 文件夹中的单独文件中。
这些文件必须包含注释，说明各自测试的预期结果。
测试套件编译并检查它们是否符合给定的期望。

例如： ``./test/libsolidity/syntaxTests/double_stateVariable_declaration.sol``

.. code-block:: solidity

    contract test {
        uint256 variable;
        uint128 variable;
    }
    // ----
    // DeclarationError: (36-52): Identifier already declared.

语法测试必须至少包含被测试的合约本身，后面跟着分隔符 ``// ----``。分隔符后面的注释用于描述
预期的编译器错误或警告。数字范围表示错误发生在源代码中的位置。
如果你希望合约在没有任何错误或警告的情况下编译，你可以省略
分隔符和后面的注释。

在上述示例中，状态变量 ``variable`` 被声明了两次，这是不允许的。这导致出现 ``DeclarationError``，指出标识符已被声明。

``isoltest`` 工具用于这些测试，你可以在 ``./build/test/tools/`` 下找到它。它是一个交互式工具，允许
使用你喜欢的文本编辑器编辑失败的合约。让我们尝试通过删除第二个 ``variable`` 的声明来破坏此测试：

.. code-block:: solidity

    contract test {
        uint256 variable;
    }
    // ----
    // DeclarationError: (36-52): Identifier already declared.

再次运行 ``./build/test/tools/isoltest`` 会导致测试失败：

.. code-block:: text

    syntaxTests/double_stateVariable_declaration.sol: FAIL
        Contract:
            contract test {
                uint256 variable;
            }

        Expected result:
            DeclarationError: (36-52): Identifier already declared.
        Obtained result:
            Success


``isoltest`` 在获得结果旁边打印预期结果，并且还
提供了一种编辑、更新或跳过当前合约文件或退出应用程序的方法。

它为失败的测试提供了几种选项：

- ``edit``: ``isoltest`` 尝试在编辑器中打开合约，以便你可以进行调整。它可以使用命令行中给出的编辑器（如 ``isoltest --editor /path/to/editor``），环境变量 ``EDITOR`` 或仅 ``/usr/bin/editor``（按此顺序）。
- ``update``: 更新被测试合约的期望。这通过删除未满足的期望并添加缺失的期望来更新注释。然后再次运行测试。
- ``skip``: 跳过此特定测试的执行。
- ``quit``: 退出 ``isoltest``。

所有这些选项适用于当前合约，除了 ``quit``，它会停止整个测试过程。

自动更新上述测试将其更改为

.. code-block:: solidity

    contract test {
        uint256 variable;
    }
    // ----

并重新运行测试。它现在再次通过：

.. code-block:: text

    Re-running test case...
    syntaxTests/double_stateVariable_declaration.sol: OK


.. note::

    为合约文件选择一个解释其测试内容的名称，例如 ``double_variable_declaration.sol``。
    不要在单个文件中放入多个合约，除非你正在测试继承或跨合约调用。
    每个文件应测试新功能的一个方面。

命令行测试
------------

我们的端到端命令行测试套件检查编译器二进制文件在各种场景下的行为。
这些测试位于 `test/cmdlineTests/ <https://github.com/ethereum/solidity/tree/develop/test/cmdlineTests>`_，
每个子目录一个，可以使用 ``cmdlineTests.sh`` 脚本执行。

默认情况下，脚本运行所有可用测试。
你还可以提供一个或多个 `文件名模式 <https://www.gnu.org/software/bash/manual/bash.html#Filename-Expansion>`_，
在这种情况下，仅执行至少匹配一个模式的测试。
也可以通过在特定模式前加上 ``--exclude`` 来排除匹配的文件。

默认情况下，脚本假定 ``build/`` 子目录中有一个 ``solc`` 二进制文件
在工作副本中。
如果你在源树外构建编译器，可以使用 ``SOLIDITY_BUILD_DIR`` 环境
变量指定构建目录的不同位置。

示例：

.. code-block:: bash

    export SOLIDITY_BUILD_DIR=~/solidity/build/
    test/cmdlineTests.sh "standard_*" "*_yul_*" --exclude "standard_yul_*"

上述命令将运行来自以 ``test/cmdlineTests/standard_`` 开头的目录的测试和
``test/cmdlineTests/`` 的子目录中包含 ``_yul_`` 的测试，
但不会执行名称以 ``standard_yul_`` 开头的测试。
它还将假定你主目录中的文件 ``solidity/build/solc/solc`` 是
编译器二进制文件（除非你在 Windows 上 -- 那时是 ``solidity/build/solc/Release/solc.exe``）。

命令行测试有几种类型：

- *标准 JSON 测试*：至少包含一个 ``input.json`` 文件。
  通常可能包含：

    - ``input.json``：要传递给命令行上的 ``--standard-json`` 选项的输入文件。
    - ``output.json``：预期的标准 JSON 输出。
    - ``args``：传递给 ``solc`` 的额外命令行参数。

- *CLI 测试*：至少包含一个 ``input.*`` 文件（其他于 ``input.json``）。
  通常可能包含：

    - ``input.*``：单个输入文件，其名称将在命令行中提供给 ``solc``。
      通常是 ``input.sol`` 或 ``input.yul``。
    - ``args``：传递给 ``solc`` 的额外命令行参数。
    - ``stdin``：要通过标准输入传递给 ``solc`` 的内容。
    - ``output``：预期的标准输出内容。
    - ``err``：预期的标准错误输出内容。
    - ``exit``：预期的退出代码。如果未提供，则期望为零。
- *脚本测试*: 包含一个 ``test.*`` 文件。
  一般可以包含：

    - ``test.*``: 一个要运行的单一脚本，通常是 ``test.sh`` 或 ``test.py``。
      该脚本必须是可执行的。

通过 AFL 运行模糊测试器
==========================

模糊测试是一种技术，它在或多或少随机的输入上运行程序，以查找异常执行状态（段错误、异常等）。现代模糊测试器非常聪明，并在输入中进行有针对性的搜索。我们有一个专门的二进制文件 ``solfuzzer``，它以源代码作为输入，并在遇到内部编译器错误、段错误或类似情况时失败，但如果代码包含错误则不会失败。通过这种方式，模糊测试工具可以发现编译器中的内部问题。

我们主要使用 `AFL <https://lcamtuf.coredump.cx/afl/>`_ 进行模糊测试。你需要从你的软件库中下载并安装 AFL 包（afl，afl-clang）或手动构建它们。
接下来，使用 AFL 作为编译器构建 Solidity（或仅构建 ``solfuzzer`` 二进制文件）：

.. code-block:: bash

    cd build
    # 如果需要
    make clean
    cmake .. -DCMAKE_C_COMPILER=path/to/afl-gcc -DCMAKE_CXX_COMPILER=path/to/afl-g++
    make solfuzzer

在此阶段，你应该能够看到类似以下的消息：

.. code-block:: text

    Scanning dependencies of target solfuzzer
    [ 98%] Building CXX object test/tools/CMakeFiles/solfuzzer.dir/fuzzer.cpp.o
    afl-cc 2.52b by <lcamtuf@google.com>
    afl-as 2.52b by <lcamtuf@google.com>
    [+] Instrumented 1949 locations (64-bit, non-hardened mode, ratio 100%).
    [100%] Linking CXX executable solfuzzer

如果没有出现仪器消息，请尝试切换指向 AFL 的 clang 二进制文件的 cmake 标志：

.. code-block:: bash

    # 如果之前失败
    make clean
    cmake .. -DCMAKE_C_COMPILER=path/to/afl-clang -DCMAKE_CXX_COMPILER=path/to/afl-clang++
    make solfuzzer

否则，在执行时模糊测试器会因错误而停止，提示二进制文件未被仪器化：

.. code-block:: text

    afl-fuzz 2.52b by <lcamtuf@google.com>
    ... (truncated messages)
    [*] Validating target binary...

    [-] 看起来目标二进制文件未被仪器化！模糊测试器依赖于
        编译时仪器化来隔离有趣的测试用例，同时
        变异输入数据。有关更多信息，以及有关如何
        仪器化二进制文件的提示，请参见 /usr/share/doc/afl-doc/docs/README。

        当源代码不可用时，你可能能够利用 QEMU
        模式支持。请查阅 README 以获取有关如何启用此功能的提示。
        （也可以将 afl-fuzz 作为传统的“愚蠢”模糊测试器使用。
        为此，你可以使用 -n 选项 - 但期望结果会更差。）

    [-] 程序中止 : 未检测到仪器化
             位置 : check_binary(), afl-fuzz.c:6920


接下来，你需要一些示例源文件。这使得模糊测试器更容易找到错误。你可以从语法测试中复制一些文件，或从文档或其他测试中提取测试文件：

.. code-block:: bash

    mkdir /tmp/test_cases
    cd /tmp/test_cases
    # 从测试中提取：
    path/to/solidity/scripts/isolate_tests.py path/to/solidity/test/libsolidity/SolidityEndToEndTest.cpp
    # 从文档中提取：
    path/to/solidity/scripts/isolate_tests.py path/to/solidity/docs

AFL 文档指出，语料库（初始输入文件）不应过大。文件本身不应大于 1 kB，并且每个功能最多应有一个输入文件，因此最好从少量开始。
还有一个名为 ``afl-cmin`` 的工具，可以修剪导致二进制文件类似行为的输入文件。

现在运行模糊测试器（``-m`` 将内存大小扩展到 60 MB）：

.. code-block:: bash

    afl-fuzz -m 60 -i /tmp/test_cases -o /tmp/fuzzer_reports -- /path/to/solfuzzer

模糊测试器创建导致 ``/tmp/fuzzer_reports`` 中失败的源文件。
通常它会找到许多产生相同错误的相似源文件。你可以使用工具 ``scripts/uniqueErrors.sh`` 来过滤出唯一的错误。

Whiskers
========

*Whiskers* 是一个字符串模板系统，类似于 `Mustache <https://mustache.github.io>`_。它在编译器的多个地方使用，以帮助提高代码的可读性，从而提高可维护性和可验证性。

语法与 Mustache 有显著不同。模板标记 ``{{`` 和 ``}}`` 被替换为 ``<`` 和 ``>``，以帮助解析并避免与 :ref:`yul` 冲突（符号 ``<`` 和 ``>`` 在内联汇编中无效，而 ``{`` 和 ``}`` 用于分隔块）。另一个限制是列表仅解析一层深度，并且不递归。这在未来可能会改变。

粗略的规范如下：

任何出现的 ``<name>`` 都被替换为提供的变量 ``name`` 的字符串值，不进行任何转义和迭代替换。一个区域可以通过 ``<#name>...</name>`` 来分隔。它被替换为其内容的多个连接，数量与提供给模板系统的变量集的数量相同，每次替换任何 ``<inner>`` 项为其各自的值。顶层变量也可以在这样的区域内使用。

还有形式为 ``<?name>...<!name>...</name>`` 的条件，其中模板替换根据布尔参数 ``name`` 的值在第一个或第二个段落中递归进行。如果使用 ``<?+name>...<!+name>...</+name>``，则检查的是字符串参数 ``name`` 是否非空。

.. _documentation-style:

文档风格指南
=========================

在以下部分中，你会发现专门针对 Solidity 文档贡献的风格建议。

英语语言
----------------

使用国际英语，除非使用项目或品牌名称。尽量减少地方俚语和引用的使用，使你的语言对所有读者尽可能清晰。
以下是一些参考资料：

* `简化技术英语 <https://en.wikipedia.org/wiki/Simplified_Technical_English>`_
* `国际英语 <https://en.wikipedia.org/wiki/International_English>`_

.. note::

    虽然官方 Solidity 文档是用英语编写的，但还有社区贡献的 :ref:`翻译`
    以其他语言提供。有关如何为社区翻译做出贡献的信息，请参阅 `翻译指南 <https://github.com/solidity-docs#solidity-documentation-translation-guide>`_。

标题大小写
-----------------------

对标题使用 `标题大小写 <https://titlecase.com>`_。这意味着在标题中大写所有主要单词，但不大写文章、连词和介词，除非它们是标题的开头。

例如，以下都是正确的：

* 标题大小写。
* 对于标题使用标题大小写。
* 本地和状态变量名称。
* 布局顺序。

展开缩写
-------------------

对单词使用展开的缩写，例如：

* "不" 而不是 "Don't"。
* "不能" 而不是 "Can't"。

主动和被动语态
------------------------

通常建议在教程风格的文档中使用主动语态，因为它有助于读者理解谁或什么在执行任务。然而，由于 Solidity 文档是教程和参考内容的混合，因此有时被动语态更为适用。
作为总结：

* 对于技术参考，使用被动语态，例如语言定义和以太坊虚拟机的内部实现。
* 在描述如何应用 Solidity 的某个方面时，使用主动语态。

例如，下面是被动语态，因为它指定了 Solidity 的一个方面：

  函数可以被声明为 ``pure``，在这种情况下，它们承诺不读取
  或修改状态。

例如，下面是主动语态，因为它讨论了 Solidity 的应用：

  在调用编译器时，你可以指定如何发现路径的第一个元素，
  以及路径前缀重映射。

常用术语
------------

* “函数参数”和“返回变量”，而不是输入和输出参数。

代码示例
-------------

CI 过程测试所有以 ``pragma solidity``、``contract``、``library``
或 ``interface`` 开头的代码块格式的代码示例，当你创建 PR 时使用 ``./test/cmdlineTests.sh`` 脚本。如果你添加新的代码示例，
请确保它们能够正常工作并通过测试，然后再创建 PR。

确保所有代码示例以一个 ``pragma`` 版本开始，该版本涵盖合约代码有效的最大范围。
例如 ``pragma solidity >=0.4.0 <0.9.0;``。

运行文档测试
---------------------------

通过运行 ``./docs/docs.sh`` 确保你的贡献通过我们的文档测试，该脚本安装文档所需的依赖项
并检查任何问题，例如断开的链接或语法问题。

.. _solidity_language_design:

Solidity 语言设计
========================

要积极参与语言设计过程并分享你对 Solidity 未来的想法，
请加入 `Solidity 论坛 <https://forum.soliditylang.org/>`_。

Solidity 论坛是提出和讨论新语言特性及其在
构思早期阶段或现有特性修改中的实现的地方。

一旦提案变得更加具体，它们的
实现也将在 `Solidity GitHub 仓库 <https://github.com/ethereum/solidity>`_
以问题的形式进行讨论。

除了论坛和问题讨论，我们定期举办语言设计讨论电话会议，在会议中详细讨论选定的
主题、问题或特性实现。会议邀请通过论坛分享。

我们还在论坛中分享与语言设计相关的反馈调查和其他内容。

如果你想了解团队在实施新特性方面的进展，可以在 `Solidity GitHub 项目 <https://github.com/orgs/ethereum/projects/17>`_ 中关注实施状态。
设计待办事项中的问题需要进一步说明，并将在语言设计电话会议或常规团队会议中讨论。你可以
通过将默认分支（`develop`）更改为 `breaking branch <https://github.com/ethereum/solidity/tree/breaking>`_ 来查看下一个重大版本的即将更改。

对于临时情况和问题，你可以通过 `Solidity-dev Gitter 频道 <https://gitter.im/ethereum/solidity-dev>`_ 联系我们——这是一个
专门用于围绕 Solidity 编译器和语言开发进行对话的聊天室。

我们很高兴听到你对如何改进语言设计过程以使其更加协作和透明的想法。