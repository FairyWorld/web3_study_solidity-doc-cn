.. index:: ! installing

.. _installing-solidity:

################################
安装 Solidity 编译器
################################

版本控制
==========

Solidity 版本遵循 `语义版本控制 <https://semver.org>`_。此外，主版本为 0 的补丁级发布（即 0.x.y）将不会包含破坏性更改。这意味着使用版本 0.x.y 编译的代码可以预期在 0.x.z 中编译，其中 z > y。

除了发布版本外，我们还提供 **夜间开发构建**，以便开发人员轻松尝试即将推出的功能并提供早期反馈。然而，请注意，尽管夜间构建通常非常稳定，但它们包含来自开发分支的前沿代码，并不保证始终有效。
尽管我们尽力而为，它们可能包含未记录和/或损坏的更改，这些更改不会成为实际发布的一部分。它们不适合生产使用。

在部署合约时，应该使用最新发布的 Solidity 版本。这是新版本会定期引入因为突破性的更新以及新功能和错误修复。
我们目前使用 0.x 版本号 `来表示这种快速变化的步伐 <https://semver.org/#spec-item-4>`_。

Remix
=====

*我们推荐使用 Remix 来处理小型合约和快速学习 Solidity。*

`在线访问 Remix <https://remix.ethereum.org/>`_，无需安装任何东西。
如果希望在没有互联网连接的情况下使用它，请访问 https://github.com/ethereum/remix-live/tree/gh-pages#readme 并按照该页面上的说明进行操作。
Remix 也是测试夜间构建的便捷选项，无需安装多个 Solidity 版本。

本页面的进一步选项详细说明了如何在计算机上安装命令行 Solidity 编译器软件。如果正在处理较大的合约或需要更多编译选项，请选择命令行编译器。

.. _solcjs:

npm / Node.js
=============

使用 ``npm`` 以方便和可移植的方式安装 ``solcjs``，这是一个 Solidity 编译器。
`solcjs` 程序的功能少于本页面下方描述的访问编译器的方式。:ref:`commandline-compiler` 文档假设正在使用功能齐全的编译器 ``solc``。
``solcjs`` 的使用在其自己的 `repository <https://github.com/ethereum/solc-js>`_ 中有文档说明。

注意：solc-js 项目是通过使用 Emscripten 从 C++ `solc` 派生的，这意味着两者使用相同的编译器源代码。
`solc-js` 可以直接在 JavaScript 项目中使用（例如 Remix）。请参考 solc-js 仓库以获取说明。

.. code-block:: bash

    npm install -g solc

.. note::

    命令行可执行文件名为 ``solcjs``。

    ``solcjs`` 的命令行选项与 ``solc`` 不兼容，期望 ``solc`` 行为的工具（如 ``geth``）将无法与 ``solcjs`` 一起使用。

Docker
======

Solidity 构建的 Docker 镜像可通过 ``ethereum`` 组织的 ``solc`` 镜像获得。
使用 ``stable`` 标签获取最新发布版本，使用 ``nightly`` 标签获取 ``develop`` 分支中可能不稳定的更改。

Docker 镜像运行编译器可执行文件，因此可以将所有编译器参数传递给它。
例如，下面的命令拉取 ``solc`` 镜像的稳定版本（如果尚未拥有它），并在新容器中运行它，传递 ``--help`` 参数。

.. code-block:: bash

    docker run ethereum/solc:stable --help

可以在标签中指定发布构建版本。例如：

.. code-block:: bash

    docker run ethereum/solc:stable --help

注意

特定编译器版本作为 Docker 镜像标签得到支持，例如 `ethereum/solc:0.8.23`。
我们将在这里传递 ``stable`` 标签，而不是特定版本标签，以确保用户默认获得最新版本，避免过时版本的问题。

要使用 Docker 镜像在主机上编译 Solidity 文件，请挂载一个本地文件夹用于输入和输出，并指定要编译的合约。例如：

.. code-block:: bash

    docker run -v /local/path:/sources ethereum/solc:stable -o /sources/output --abi --bin /sources/Contract.sol

还可以使用标准 JSON 接口（在与工具一起使用编译器时推荐使用）。
使用此接口时，只要 JSON 输入是自包含的（即不引用任何必须通过 :ref:`loaded by the import callback <initial-vfs-content-standard-json-with-import-callback>` 加载的外部文件），则无需挂载任何目录。

.. code-block:: bash

    docker run ethereum/solc:stable --standard-json < input.json > output.json

Linux 包
==============

Solidity 的二进制包可在 `solidity/releases <https://github.com/ethereum/solidity/releases>`_ 中获得。

我们还为 Ubuntu 提供 PPA，可以使用以下命令获取最新的稳定版本：

.. code-block:: bash

    sudo add-apt-repository ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install solc

夜间版本可以使用以下命令安装：

.. code-block:: bash

    sudo add-apt-repository ppa:ethereum/ethereum
    sudo add-apt-repository ppa:ethereum/ethereum-dev
    sudo apt-get update
    sudo apt-get install solc

此外，一些 Linux 发行版提供自己的软件包。这些软件包并不是由我们直接维护，但通常由各自的软件包维护者保持最新。

例如，Arch Linux 有最新开发版本的 AUR 软件包： `solidity <https://aur.archlinux.org/packages/solidity>`_ 和 `solidity-bin <https://aur.archlinux.org/packages/solidity-bin>`_。

.. note::

    请注意，`AUR <https://wiki.archlinux.org/title/Arch_User_Repository>`_ 软件包是用户生成的内容和非官方软件包。使用时请谨慎。

还有一个 `snap package <https://snapcraft.io/solc>`_，但是它 **目前未维护**。
它可以在所有 `supported Linux distros <https://snapcraft.io/docs/core/install>`_ 中安装。要安装最新的稳定版本 solc：

.. code-block:: bash

    sudo snap install solc

如果你想帮助测试最新的开发版本 Solidity 及其最新更改，请使用以下命令：

.. code-block:: bash

    sudo snap install solc --edge

.. note::

    ``solc`` snap 使用严格的隔离。这是 snap 包的最安全模式，但它有一些限制，例如只能访问 ``/home`` 和 ``/media`` 目录中的文件。
    有关更多信息，请访问 `揭开 Snap 隔离的神秘面纱 <https://snapcraft.io/blog/demystifying-snap-confinement>`_。

macOS 包
==============

我们通过 Homebrew 分发 Solidity 编译器，作为从源代码构建的版本。当前不支持预编译的软件包（bottles）。

.. code-block:: bash

    brew update
    brew upgrade
    brew tap ethereum/ethereum
    brew install solidity

要安装最新的 0.4.x / 0.5.x 版本的 Solidity，还可以分别使用 ``brew install solidity@4`` 和 ``brew install solidity@5``。

如果需要特定版本的 Solidity，可以直接从 Github 安装 Homebrew 配方。

查看 `solidity.rb 在 GitHub 上的提交 <https://github.com/ethereum/homebrew-ethereum/commits/master/solidity.rb>`_。
复制想要的版本的提交哈希，下载（checkout）到本地。

.. code-block:: bash

    git clone https://github.com/ethereum/homebrew-ethereum.git
    cd homebrew-ethereum
    git checkout <your-hash-goes-here>

使用 ``brew`` 安装：

.. code-block:: bash

    brew unlink solidity
    # 例如，安装 0.4.8
    brew install solidity.rb

静态二进制文件
===============

我们维护一个包含所有支持平台的过去和当前编译器版本的静态构建的仓库，位于 `solc-bin`_。这也是可以找到夜间构建的位置。

该仓库不仅是终端用户获取开箱即用的二进制文件的快速简便方法，而且还旨在对第三方工具友好：

- 内容被镜像到 https://binaries.soliditylang.org，用户可以轻松通过 HTTPS 下载，无需任何身份验证、速率限制或使用 git。
- 内容以正确的 `Content-Type` 头和宽松的 CORS 配置提供，以便可以直接由在浏览器中运行的工具加载。
- 二进制文件不需要安装或解压（旧版 Windows 构建中捆绑了必要的 DLL 除外）。
- 我们努力保持高水平的向后兼容性。文件一旦添加，就不会在不提供旧位置的符号链接/重定向的情况下被删除或移动。它们也不会被就地修改，并且应始终与原始校验和匹配。唯一的例外是损坏或无法使用的文件，如果不处理可能会造成比好处更大的伤害。
- 文件通过 HTTP 和 HTTPS 提供。只要以安全的方式获取文件列表（通过 git、HTTPS、IPFS 或仅在本地缓存）并在下载后验证二进制文件的哈希，你就不必对二进制文件本身使用 HTTPS。

在大多数情况下，相同的二进制文件也可以在 `GitHub 上的 Solidity 发布页面`_ 找到。不同之处在于，我们通常不会在 GitHub 发布页面上更新旧版本。这意味着如果命名约定发生变化，我们不会重命名它们，并且我们不会为发布时不支持的平台添加构建。这仅在 ``solc-bin`` 中发生。

``solc-bin`` 仓库包含几个顶级目录，每个目录代表一个单独的平台。每个目录中都有一个 ``list.json`` 文件，列出可用的二进制文件。
例如，在 ``emscripten-wasm32/list.json`` 中，将找到关于版本 0.7.4 的以下信息：

.. code-block:: json

    {
      "path": "solc-emscripten-wasm32-v0.7.4+commit.3f05b770.js",
      "version": "0.7.4",
      "build": "commit.3f05b770",
      "longVersion": "0.7.4+commit.3f05b770",
      "keccak256": "0x300330ecd127756b824aa13e843cb1f43c473cb22eaf3750d5fb9c99279af8c3",
      "sha256": "0x2b55ed5fec4d9625b6c7b3ab1abd2b7fb7dd2a9c68543bf0323db2c7e2d55af2",
      "urls": [
        "dweb:/ipfs/QmTLs5MuLEWXQkths41HiACoXDiH8zxyqBHGFDRSzVE5CS"
      ]
    }

这意味着：

- 可以在同一目录中找到名为 `solc-emscripten-wasm32-v0.7.4+commit.3f05b770.js <https://github.com/ethereum/solc-bin/blob/gh-pages/emscripten-wasm32/solc-emscripten-wasm32-v0.7.4+commit.3f05b770.js>`_ 的二进制文件。请注意，该文件可能是符号链接，如果不是使用 git 下载它，或者文件系统不支持符号链接，需要自己解析。
- 该二进制文件也在 https://binaries.soliditylang.org/emscripten-wasm32/solc-emscripten-wasm32-v0.7.4+commit.3f05b770.js 处被镜像。在这种情况下，不需要 git，符号链接会透明地解析，或者通过提供文件的副本或返回 HTTP 重定向。
- 该文件也可以在 IPFS 上找到，地址为 `QmTLs5MuLEWXQkths41HiACoXDiH8zxyqBHGFDRSzVE5CS`_。请注意，``urls`` 数组中项目的顺序不是预定或保证的，用户不应依赖它。
- 可以通过将其 keccak256 哈希与 ``0x300330ecd127756b824aa13e843cb1f43c473cb22eaf3750d5fb9c99279af8c3`` 进行比较来验证二进制文件的完整性。可以使用 `sha3sum`_ 提供的 ``keccak256sum`` 工具或 JavaScript 中的 `keccak256() function from ethereumjs-util`_ 在命令行上计算哈希。
- 还可以通过将其 sha256 哈希与 ``0x2b55ed5fec4d9625b6c7b3ab1abd2b7fb7dd2a9c68543bf0323db2c7e2d55af2`` 进行比较来验证二进制文件的完整性。

.. warning::

   由于强大的向后兼容性要求，仓库中包含一些遗留元素，但在编写新工具时应避免使用它们：

   - 如果想要最佳性能，请使用 ``emscripten-wasm32/`` （并回退到 ``emscripten-asmjs/``）。在 0.6.1 版本之前，我们只提供 asm.js 二进制文件。从 0.6.2 开始，我们切换到 `WebAssembly builds`_，性能大大提高。我们已经为 wasm 重新构建了旧版本，但原始的 asm.js 文件仍保留在 ``bin/`` 中。新的文件必须放在单独的目录中以避免名称冲突。
   - 如果想确保下载的是 wasm 还是 asm.js 二进制文件，请使用 ``emscripten-asmjs/`` 和 ``emscripten-wasm32/``，而不是 ``bin/`` 和 ``wasm/`` 目录。
   - 使用 ``list.json`` 而不是 ``list.js`` 和 ``list.txt``。JSON 列表格式包含所有旧格式的信息以及更多信息。
   - 使用 https://binaries.soliditylang.org 而不是 https://solc-bin.ethereum.org。为了简化，我们将几乎所有与编译器相关的内容移到了新的 ``soliditylang.org`` 域名下，这也适用于 ``solc-bin``。虽然推荐使用新域名，但旧域名仍然完全支持，并保证指向相同的位置。

.. warning::

    二进制文件也可以在 https://ethereum.github.io/solc-bin/ 找到，但该页面在 0.7.2 版本发布后停止更新，不会为任何平台接收新的发布或夜间构建，并且不提供新的目录结构，包括非 emscripten 构建。

    如果正在使用它，请切换到 https://binaries.soliditylang.org，这是一个直接替代品。这使我们能够以透明的方式对底层托管进行更改，并最小化干扰。与我们无法控制的 ``ethereum.github.io`` 域名不同，``binaries.soliditylang.org`` 保证在长期内有效并保持相同的 URL 结构。

.. _IPFS: https://ipfs.io
.. _solc-bin: https://github.com/ethereum/solc-bin/
.. _GitHub 上的 Solidity 发布页面: https://github.com/ethereum/solidity/releases
.. _sha3sum: https://github.com/maandree/sha3sum
.. _keccak256() function from ethereumjs-util: https://github.com/ethereumjs/ethereumjs-util/blob/master/docs/modules/_hash_.md#const-keccak256
.. _WebAssembly builds: https://emscripten.org/docs/compiling/WebAssembly.html
.. _QmTLs5MuLEWXQkths41HiACoXDiH8zxyqBHGFDRSzVE5CS: https://gateway.ipfs.io/ipfs/QmTLs5MuLEWXQkths41HiACoXDiH8zxyqBHGFDRSzVE5CS

.. _从源代码构建:

从源代码构建
====================
前提条件 - 所有操作系统
-------------------------------------

以下是所有 Solidity 构建的依赖项：

+-----------------------------------+-------------------------------------------------------+
| Software                          | Notes                                                 |
+-----------------------------------+-------------------------------------------------------+
| `CMake`_ (version 3.21.3+ on      | Cross-platform build file generator.                  |
| Windows, 3.13+ otherwise)         |                                                       |
+-----------------------------------+-------------------------------------------------------+
| `Boost`_ (version 1.77+ on        | C++ libraries.                                        |
| Windows, 1.67+ otherwise)         |                                                       |
+-----------------------------------+-------------------------------------------------------+
| `Git`_                            | Command-line tool for retrieving source code.         |
+-----------------------------------+-------------------------------------------------------+
| `z3`_ (version 4.8.16+, Optional) | For use with SMT checker.                             |
+-----------------------------------+-------------------------------------------------------+

.. _Git: https://git-scm.com/download
.. _Boost: https://www.boost.org
.. _CMake: https://cmake.org/download/
.. _z3: https://github.com/Z3Prover/z3

.. note::
    Solidity 版本低于 0.5.10 可能无法正确链接 Boost 版本 1.70 及以上。
    一个可能的解决方法是在运行 cmake 命令配置 Solidity 之前，暂时重命名 ``<Boost 安装路径>/lib/cmake/Boost-1.70.0``。

    从 0.5.10 开始，链接 Boost 1.70 及以上版本应该无需手动干预。

.. note::
    默认构建配置需要特定的 Z3 版本（在代码最后更新时的最新版本）。Z3 发布之间引入的更改通常会导致返回略有不同（但仍然有效）的结果。我们的 SMT 测试没有考虑这些差异，可能会在与其编写时不同的版本上失败。这并不意味着使用不同版本的构建是有缺陷的。如果你将 ``-DSTRICT_Z3_VERSION=OFF`` 选项传递给 CMake，你可以使用满足上表中给定要求的任何版本进行构建。但是，如果你这样做，请记得将 ``--no-smt`` 选项传递给 ``scripts/tests.sh`` 以跳过 SMT 测试。

.. note::
    默认情况下，构建是在 *pedantic mode* 下进行的，这会启用额外的警告并告诉编译器将所有警告视为错误。
    这迫使开发人员在警告出现时修复它们，以免它们积累“稍后修复”。
    如果只对创建发布构建感兴趣，并且不打算修改源代码以处理此类警告，可以将 ``-DPEDANTIC=OFF`` 选项传递给 CMake 以禁用此模式。
    这样做不推荐用于一般使用，但在使用我们未测试的工具链或尝试使用较新工具构建旧版本时可能是必要的。
    如果遇到此类警告，请考虑
    `报告它们 <https://github.com/ethereum/solidity/issues/new>`_。

最低编译器版本
^^^^^^^^^^^^^^^^^^^^^^^^^

以下 C++ 编译器及其最低版本可以构建 Solidity 代码库：

- `GCC <https://gcc.gnu.org>`_, 版本 8+
- `Clang <https://clang.llvm.org/>`_, 版本 7+
- `MSVC <https://visualstudio.microsoft.com/vs/>`_, 版本 2019+

前提条件 - macOS
---------------------

对于 macOS 构建，请确保已安装最新版本的
`Xcode <https://developer.apple.com/xcode/resources/>`_。
这包含 `Clang C++ 编译器 <https://en.wikipedia.org/wiki/Clang>`_、`Xcode IDE <https://en.wikipedia.org/wiki/Xcode>`_ 和其他 Apple 开发工具，这些工具是构建 C++ 应用程序所必需的。
如果是第一次安装 Xcode，或者刚刚安装了新版本，则需要在进行命令行构建之前同意许可协议：

.. code-block:: bash

    sudo xcodebuild -license accept

我们的 OS X 构建脚本使用 `Homebrew <https://brew.sh>`_ 包管理器来安装外部依赖项。
如果想从头开始重新安装，可以参考以下内容 `卸载 Homebrew <https://docs.brew.sh/FAQ#how-do-i-uninstall-homebrew>`_。

前提条件 - Windows
-----------------------

需要为 Solidity 的 Windows 构建安装以下依赖项：

+-----------------------------------+-------------------------------------------------------+
| Software                          | Notes                                                 |
+===================================+=======================================================+
| `Visual Studio 2019 Build Tools`_ | C++ compiler                                          |
+-----------------------------------+-------------------------------------------------------+
| `Visual Studio 2019`_  (Optional) | C++ compiler and dev environment.                     |
+-----------------------------------+-------------------------------------------------------+
| `Boost`_ (version 1.77+)          | C++ libraries.                                        |
+-----------------------------------+-------------------------------------------------------+

如果已经有一个 IDE 并且只需要编译器和库，可以安装 Visual Studio 2019 Build Tools。

Visual Studio 2019 提供了 IDE 以及必要的编译器和库。
因此，如果没有 IDE 并且希望开发 Solidity，Visual Studio 2019 可能是轻松设置一切的选择。

以下是应在 Visual Studio 2019 Build Tools 或 Visual Studio 2019 中安装的组件列表：

* Visual Studio C++ 核心功能
* VC++ 2019 v141 工具集 (x86,x64)
* Windows Universal CRT SDK
* Windows 8.1 SDK
* C++/CLI 支持

.. _Visual Studio 2019: https://www.visualstudio.com/vs/
.. _Visual Studio 2019 Build Tools: https://visualstudio.microsoft.com/vs/older-downloads/#visual-studio-2019-and-other-products

我们有一个辅助脚本，可以使用它来安装所有所需的外部依赖项：

.. code-block:: bat

    scripts\install_deps.ps1

这将把 ``boost`` 和 ``cmake`` 安装到 ``deps`` 子目录中。

克隆代码库
--------------------

要克隆源代码，请执行以下命令：

.. code-block:: bash

    git clone --recursive https://github.com/ethereum/solidity.git
    cd solidity

如果你想帮助开发 Solidity，你应该 fork Solidity 并将你的个人 fork 添加为第二个远程：

.. code-block:: bash

    git remote add personal git@github.com:[username]/solidity.git

.. note::
    此方法将导致预发布构建，从而在此类编译器生成的每个字节码中设置标志。
    如果你想重新构建已发布的 Solidity 编译器，请使用 GitHub 发布页面上的源 tarball：

    https://github.com/ethereum/solidity/releases/download/v0.X.Y/solidity_0.X.Y.tar.gz

    （而不是 GitHub 提供的“源代码”）。

命令行构建
------------------

**在构建之前，请确保安装外部依赖项（见上文）。**

Solidity 项目使用 CMake 来配置构建。
你可能想安装 `ccache`_ 以加快重复构建的速度。
CMake 会自动检测到它。
在 Linux、macOS 和其他 Unix 系统上构建 Solidity 非常相似：

.. _ccache: https://ccache.dev/

.. code-block:: bash

    mkdir build
    cd build
    cmake .. && make

或者在 Linux 和 macOS 上更简单，你可以运行：

.. code-block:: bash

    #注意：这将把二进制文件 solc 和 soltest 安装到 usr/local/bin
    ./scripts/build.sh

.. warning::

    BSD 构建应该可以工作，但未经过 Solidity 团队的测试。

对于 Windows：

.. code-block:: bash

    mkdir build
    cd build
    cmake -G "Visual Studio 16 2019" ..

如果想使用 ``scripts\install_deps.ps1`` 安装的 Boost 版本，还需要将 ``-DBoost_DIR="deps\boost\lib\cmake\Boost-*"``
和 ``-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded`` 作为参数传递给 ``cmake`` 调用。

这应该会在该构建目录中创建 **solidity.sln**。
双击该文件应该会启动 Visual Studio。我们建议构建 **Release** 配置，但其他所有配置也可以工作。

或者，可以在命令行上为 Windows 构建，如下所示：

.. code-block:: bash

    cmake --build . --config Release
CMake 选项
==========

如果想了解可用的 CMake 选项，请运行 ``cmake .. -LH``.

.. _smt_solvers_build:

SMT 求解器
-----------
Solidity 可以针对 Z3 SMT 求解器进行构建，如果在系统中找到它，默认情况下将使用 Z3。可以通过 ``cmake`` 选项禁用 Z3。

*注意：在某些情况下，这也可以作为构建失败的潜在解决方法。*

在构建文件夹中，可以禁用 Z3，因为默认情况下它是启用的：

.. code-block:: bash

    # 禁用 Z3 SMT 求解器。
    cmake .. -DUSE_Z3=OFF

.. note::

    Solidity 可以选择性地使用其他求解器，即 ``cvc5`` 和 ``Eldarica``，
    但它们的存在仅在运行时检查，构建成功并不需要它们。

版本字符串详细信息
===================

Solidity 版本字符串包含四个部分：

- 版本号
- 预发布标签，通常设置为 ``develop.YYYY.MM.DD`` 或 ``nightly.YYYY.MM.DD``
- 以 ``commit.GITHASH`` 格式表示的提交
- 平台，包含任意数量的项目，包含有关平台和编译器的详细信息

如果有本地修改，提交将以 ``.mod`` 结尾。

这些部分根据 SemVer 的要求组合，其中 Solidity 的预发布标签等于 SemVer 的预发布，
而 Solidity 的提交和平台组合构成 SemVer 的构建元数据。

发布示例： ``0.4.8+commit.60cc1668.Emscripten.clang``。

预发布示例： ``0.4.9-nightly.2017.1.17+commit.6ecb4aa3.Emscripten.clang``。

关于版本控制的重要信息
========================

发布后，补丁版本级别会增加，因为我们假设只有补丁级别的更改会跟随。当更改被合并时，版本应根据 SemVer 和更改的严重性进行增加。最后，发布总是使用当前夜间构建的版本，但不带 ``prerelease`` 说明符。

示例：

1. 发布 0.4.0。
2. 从现在起，夜间构建的版本为 0.4.1。
3. 引入非破坏性更改 --> 版本不变。
4. 引入破坏性更改 --> 版本增加到 0.5.0。
5. 发布 0.5.0。

这种行为与 :ref:`version pragma <version_pragma>` 很好地配合。