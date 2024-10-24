.. _path-resolution:

**********************
导入路径解析
**********************

为了能够在所有平台上支持可重现的构建，Solidity 编译器必须抽象出源文件存储的文件系统的细节。
在导入中使用的路径必须在各处以相同的方式工作，而命令行接口必须能够处理特定于平台的路径，以提供良好的用户体验。
本节旨在详细解释 Solidity 如何调和这些要求。

.. index:: ! virtual filesystem, ! VFS, ! source unit name
.. _virtual-filesystem:

虚拟文件系统
==================

编译器维护一个内部数据库（简称 *虚拟文件系统* 或 *VFS*），其中每个源单元都被分配一个唯一的 *源单元名称*，这是一个不透明且无结构的标识符。
当你使用 :ref:`import 语句 <import>` 时，你指定一个引用源单元名称的 *导入路径*。

.. index:: ! import callback, ! Host Filesystem Loader
.. _import-callback:

导入回调
---------------

VFS 最初仅由编译器接收到的输入文件填充。
在编译过程中，可以使用 **导入回调** 加载其他文件，具体取决于你使用的编译器类型（见下文）。
如果编译器在 VFS 中找不到与导入路径匹配的源单元名称，它会调用回调，该回调负责获取要放置在该名称下的源代码。
导入回调可以自由地以任意方式解释源单元名称，而不仅仅是作为路径。
如果在需要时没有可用的回调，或者回调未能找到源代码，则编译失败。

默认情况下，命令行编译器提供 **主机文件系统加载器** - 一个基本的回调，它将源单元名称解释为本地文件系统中的路径。
可以使用 ``--no-import-callback`` 命令行选项禁用此回调。
`JavaScript 接口 <https://github.com/ethereum/solc-js>`_ 默认不提供任何回调，但用户可以提供一个。
此机制可用于从本地文件系统以外的位置获取源代码（例如，当编译器在浏览器中运行时，可能根本无法访问本地文件系统）。
例如，`Remix IDE <https://remix.ethereum.org/>`_ 提供了一个多功能回调，允许你 `从 HTTP、IPFS 和 Swarm URL 导入文件或直接引用 NPM 注册表中的包 <https://remix-ide.readthedocs.io/en/latest/import.html>`_。

.. note::

    主机文件系统加载器的文件查找依赖于平台。
    例如，源单元名称中的反斜杠可以被解释为目录分隔符，也可以不被解释，并且查找可能是区分大小写的，也可能不是，这取决于底层平台。

    为了可移植性，建议避免使用仅在特定导入回调或仅在一个平台上正确工作的导入路径。
    例如，你应该始终使用正斜杠，因为它们在支持反斜杠的平台上也可以作为路径分隔符。

虚拟文件系统的初始内容
-----------------------------------------

VFS 的初始内容取决于你如何调用编译器：

#. **solc / 命令行接口**

   当你使用编译器的命令行接口编译文件时，你提供一个或多个包含 Solidity 代码的文件路径：

   .. code-block:: bash

       solc contract.sol /usr/local/dapp-bin/token.sol

   以这种方式加载的文件的源单元名称是通过将其路径转换为规范形式构造的，并且如果可能的话，使其相对于基本路径或其中一个包含路径。
   有关此过程的详细描述，请参见 :ref:`CLI 路径规范化和剥离 <cli-path-normalization-and-stripping>`。

   .. index:: 标准 JSON

#. **标准 JSON**

   当使用 :ref:`标准 JSON <compiler-api>` API（通过 `JavaScript 接口 <https://github.com/ethereum/solc-js>`_ 或 ``--standard-json`` 命令行选项）时，你以 JSON 格式提供输入，其中包含所有源文件的内容：

   .. code-block:: json

       {
           "language": "Solidity",
           "sources": {
               "contract.sol": {
                   "content": "import \"./util.sol\";\ncontract C {}"
               },
               "util.sol": {
                   "content": "library Util {}"
               },
               "/usr/local/dapp-bin/token.sol": {
                   "content": "contract Token {}"
               }
           },
           "settings": {"outputSelection": {"*": { "*": ["metadata", "evm.bytecode"]}}}
       }

   ``sources`` 字典成为虚拟文件系统的初始内容，其键用作源单元名称。

   .. _initial-vfs-content-standard-json-with-import-callback:

#. **标准 JSON（通过导入回调）**

   使用标准 JSON 也可以告诉编译器使用导入回调来获取源代码：

   .. code-block:: json

       {
           "language": "Solidity",
           "sources": {
               "/usr/local/dapp-bin/token.sol": {
                   "urls": [
                       "/projects/mytoken.sol",
                       "https://example.com/projects/mytoken.sol"
                   ]
               }
           },
           "settings": {"outputSelection": {"*": { "*": ["metadata", "evm.bytecode"]}}}
       }

   如果有可用的导入回调，编译器将逐个提供 ``urls`` 中指定的字符串，直到成功加载一个或到达列表末尾。

   源单元名称的确定方式与使用 ``content`` 时相同 - 它们是 ``sources`` 字典的键，而 ``urls`` 的内容对它们没有影响。

   .. index:: standard input, stdin, <stdin>

#. **标准输入**

   在命令行上，也可以通过将源发送到编译器的标准输入来提供源：

   .. code-block:: bash

       echo 'import "./util.sol"; contract C {}' | solc -

   ``-`` 作为参数之一指示编译器将标准输入的内容放置在虚拟文件系统中的特殊源单元名称下： ``<stdin>``。

一旦 VFS 初始化，仍然只能通过导入回调向其添加其他文件。

.. index:: ! import; path

导入
=======

导入语句指定一个 **导入路径**。
根据导入路径的指定方式，我们可以将导入分为两类：

- :ref:`直接导入 <direct-imports>`，你直接指定完整的源单元名称。
- :ref:`相对导入 <relative-imports>`，你指定一个以 ``./`` 或 ``../`` 开头的路径，以与导入文件的源单元名称结合。

.. code-block:: solidity
    :caption: contracts/contract.sol

    import "./math/math.sol";
    import "contracts/tokens/token.sol";

在上面的 ``./math/math.sol`` 和 ``contracts/tokens/token.sol`` 是导入路径，而它们转换为的源单元名称分别是 ``contracts/math/math.sol`` 和 ``contracts/tokens/token.sol``。

.. index:: ! direct import, import; direct
.. _direct-imports:

直接导入
--------------
一个不以 ``./`` 或 ``../`` 开头的导入是 **直接导入**。

.. code-block:: solidity

    import "/project/lib/util.sol";         // 源单元名称: /project/lib/util.sol
    import "lib/util.sol";                  // 源单元名称: lib/util.sol
    import "@openzeppelin/address.sol";     // 源单元名称: @openzeppelin/address.sol
    import "https://example.com/token.sol"; // 源单元名称: https://example.com/token.sol

在应用任何 :ref:`导入重映射 <import-remapping>` 后，导入路径简单地变为源单元名称。

.. note::

    源单元名称只是一个标识符，即使其值看起来像路径，它也不受你通常在 shell 中期望的规范化规则的约束。
    任何 ``/./`` 或 ``/../`` 段或多个斜杠的序列仍然是其一部分。
    当通过标准 JSON 接口提供源时，完全有可能将不同的内容与源单元名称关联，这些名称可能指向磁盘上的同一文件。

当源在虚拟文件系统中不可用时，编译器将源单元名称传递给导入回调。
主机文件系统加载器将尝试将其用作路径并在磁盘上查找文件。
此时，特定于平台的规范化规则生效，在 VFS 中被视为不同的名称实际上可能导致加载同一文件。
例如 ``/project/lib/math.sol`` 和 ``/project/lib/../lib///math.sol`` 在 VFS 中被视为完全不同，尽管它们指向磁盘上的同一文件。

.. note::

    即使导入回调最终从磁盘上的同一文件加载两个不同源单元名称的源代码，编译器仍会将它们视为独立的源单元。
    重要的是源单元名称，而不是代码的物理位置。

.. index:: ! relative import, ! import; relative
.. _relative-imports:

相对导入
----------------

以 ``./`` 或 ``../`` 开头的导入是 **相对导入**。
这样的导入指定相对于导入源单元的源单元名称的路径：

.. code-block:: solidity
    :caption: /project/lib/math.sol

    import "./util.sol" as util;    // 源单元名称: /project/lib/util.sol
    import "../token.sol" as token; // 源单元名称: /project/token.sol

.. code-block:: solidity
    :caption: lib/math.sol

    import "./util.sol" as util;    // 源单元名称: lib/util.sol
    import "../token.sol" as token; // 源单元名称: token.sol

.. note::

    相对导入 **始终** 以 ``./`` 或 ``../`` 开头，因此 ``import "util.sol"``, 与 ``import "./util.sol"`` 不同，是直接导入。
    虽然在主机文件系统中这两个路径都被视为相对路径，但 ``util.sol`` 在 VFS 中实际上是绝对的。

让我们将 *路径段* 定义为路径中任何不包含分隔符的非空部分，并且由两个路径分隔符界定。
分隔符是正斜杠或字符串的开始/结束。
例如在 ``./abc/..//`` 中有三个路径段: ``.``, ``abc`` 和 ``..``。

编译器根据导入路径将导入解析为源单元名称，方式如下：

#. 我们从导入源单元的源单元名称开始。
#. 从解析名称中删除最后一个带前导斜杠的路径段。
#. 然后，对于导入路径中的每个段，从最左边的段开始：

    - 如果段是 ``.``, 则跳过。
    - 如果段是 ``..``, 则从解析名称中删除最后一个带前导斜杠的路径段。
    - 否则，将该段（如果解析名称不为空，则前面加一个斜杠）附加到解析名称。

删除最后一个带前导斜杠的路径段的理解如下：

1. 删除最后一个斜杠之后的所有内容（即 ``a/b//c.sol`` 变为 ``a/b//``）。
2. 删除所有尾随斜杠（即 ``a/b//`` 变为 ``a/b``）。

请注意，该过程根据 UNIX 路径的常规规则规范化来自导入路径的解析源单元名称部分，即所有 ``.`` 和 ``..`` 被删除，多个斜杠被压缩为一个。
另一方面，来自导入模块的源单元名称的部分保持未规范化。
这确保了 ``protocol://`` 部分不会变成 ``protocol:/``，如果导入文件是通过 URL 识别的。

如果你的导入路径已经规范化，你可以期待上述算法产生非常直观的结果。
以下是一些示例，如果它们没有规范化，你可以期待的结果：

.. code-block:: solidity
    :caption: lib/src/../contract.sol

    import "./util/./util.sol";         // 源单元名称: lib/src/../util/util.sol
    import "./util//util.sol";          // 源单元名称: lib/src/../util/util.sol
    import "../util/../array/util.sol"; // 源单元名称: lib/src/array/util.sol
    import "../.././../util.sol";       // 源单元名称: util.sol
    import "../../.././../util.sol";    // 源单元名称: util.sol

.. note::

    不推荐使用包含前导 ``..`` 段的相对导入。
    可以通过使用直接导入和 :ref:`基本路径和包含路径 <base-and-include-paths>` 以更可靠的方式实现相同的效果。

.. index:: ! base path, ! --base-path, ! include paths, ! --include-path
.. _base-and-include-paths:

基本路径和包含路径
===========================

基本路径和包含路径表示主机文件系统加载器将从中加载文件的目录。
当源单元名称传递给加载器时，它会将基本路径添加到源单元名称前面并执行文件系统查找。
如果查找不成功，则对包含路径列表中的所有目录执行相同操作。

建议将基本路径设置为项目的根目录，并使用包含路径指定可能包含项目依赖库的其他位置。
这使你可以以统一的方式从这些库中导入，无论它们在文件系统中相对于项目的位置如何。
例如，如果你使用 npm 安装包，并且你的合约导入 ``@openzeppelin/contracts/utils/Strings.sol``，你可以使用这些选项告诉编译器库可以在 npm 包目录之一中找到：

.. code-block:: bash

    solc contract.sol \
        --base-path . \
        --include-path node_modules/ \
        --include-path /usr/local/lib/node_modules/

无论你是在本地包目录、全局包目录还是直接在项目根目录下安装库，你的合约都将编译（具有完全相同的元数据）。

默认情况下，基本路径为空，这使源单元名称保持不变。
当源单元名称是相对路径时，这会导致在编译器被调用的目录中查找文件。
它也是唯一一个使源单元名称中的绝对路径实际上被解释为磁盘上的绝对路径的值。
如果基本路径本身是相对的，则相对于编译器的当前工作目录进行解释。

.. note::

    包含路径不能有空值，必须与非空基本路径一起使用。

.. note::

    包含路径和基本路径可以重叠，只要不使导入解析模糊。
    例如，你可以将基本路径中的目录指定为包含目录，或者有一个包含目录是另一个包含目录的子目录。
    只有当传递给主机文件系统加载器的源单元名称与多个包含路径或包含路径和基本路径结合时表示现有路径时，编译器才会发出错误。
.. _cli-path-normalization-and-stripping:

CLI 路径规范化和剥离
--------------------

在命令行中，编译器的行为与你对其他程序的期望一致：
它接受平台本地格式的路径，相对路径相对于当前工作目录。
然而，命令行中指定路径的文件所分配的源单元名称不应因项目在不同平台上编译或编译器从不同目录调用而改变。
为此，来自命令行的源文件路径必须转换为规范形式，并且如果可能，变为相对于基本路径或某个包含路径。

规范化规则如下：

- 如果路径是相对的，则通过在其前面添加当前工作目录来使其变为绝对路径。
- 内部的 ``.`` 和 ``..`` 段被折叠。
- 平台特定的路径分隔符被替换为正斜杠。
- 多个连续的路径分隔符序列被压缩为一个分隔符（除非它们是 `UNC 路径 <https://en.wikipedia.org/wiki/Path_(computing)#UNC>`_ 的前导斜杠）。
- 如果路径包含根名称（例如 Windows 上的驱动器字母），并且根与当前工作目录的根相同，则根被替换为 ``/``。
- 路径中的符号链接 **不** 被解析。

  - 唯一的例外是相对路径前面添加的当前工作目录路径，以使其变为绝对路径。
    在某些平台上，工作目录总是报告为解析了符号链接，因此为了保持一致性，编译器在所有地方解析它们。

- 即使文件系统不区分大小写，路径的原始大小写也会被保留，但 `保留大小写 <https://en.wikipedia.org/wiki/Case_preservation>`_ 和磁盘上的实际大小写不同。

.. note::

    有些情况下路径无法变得平台无关。
    例如在 Windows 上，编译器可以通过将当前驱动器的根目录称为 ``/`` 来避免使用驱动器字母，但指向其他驱动器的路径仍然需要驱动器字母。
    你可以通过确保所有文件都在同一驱动器上的单个目录树中来避免这种情况。

在规范化后，编译器尝试使源文件路径相对。
它首先尝试基本路径，然后按给定顺序尝试包含路径。
如果基本路径为空或未指定，则将其视为等于当前工作目录的路径（所有符号链接已解析）。
只有当规范化的目录路径是规范化的文件路径的确切前缀时，结果才被接受。
否则，文件路径保持绝对。这使得转换没有歧义，并确保相对路径不以 ``../`` 开头。
结果文件路径成为源单元名称。

.. note::

    通过剥离生成的相对路径必须在基本路径和包含路径中保持唯一。
    例如，如果 ``/project/contract.sol`` 和 ``/lib/contract.sol`` 都存在，编译器将对以下命令发出错误：

    .. code-block:: bash

        solc /project/contract.sol --base-path /project --include-path /lib

.. note::

    在版本 0.8.8 之前，未执行 CLI 路径剥离，唯一应用的规范化是路径分隔符的转换。
    在使用旧版本编译器时，建议从基本路径调用编译器，并仅在命令行上使用相对路径。

.. index:: ! allowed paths, ! --allow-paths, remapping; target
.. _allowed-paths:

允许的路径
==========

作为安全措施，主文件系统加载器将拒绝从默认认为安全的几个位置之外加载文件：

- 在标准 JSON 模式下：

  - 命令行中列出的输入文件所在的目录。
  - 用作 :ref:`重映射 <import-remapping>` 目标的目录。
    如果目标不是目录（即不以 ``/``, ``/.`` 或 ``/..`` 结尾），则使用包含目标的目录。
  - 基本路径和包含路径。

- 在标准 JSON 模式下：

  - 基本路径和包含路径。

可以使用 ``--allow-paths`` 选项将其他目录列入白名单。
该选项接受以逗号分隔的路径列表：

.. code-block:: bash

    cd /home/user/project/
    solc token/contract.sol \
        lib/util.sol=libs/util.sol \
        --base-path=token/ \
        --include-path=/lib/ \
        --allow-paths=../utils/,/tmp/libraries

当使用上述命令调用编译器时，主文件系统加载器将允许从以下目录导入文件：

- ``/home/user/project/token/`` （因为 ``token/`` 包含输入文件，并且它是基本路径），
- ``/lib/`` （因为 ``/lib/`` 是包含路径之一），
- ``/home/user/project/libs/`` （因为 ``libs/`` 是包含重映射目标的目录），
- ``/home/user/utils/`` （因为 ``../utils/`` 被传递给 ``--allow-paths``），
- ``/tmp/libraries/`` （因为 ``/tmp/libraries`` 被传递给 ``--allow-paths``），

.. note::

    编译器的工作目录只有在它恰好是基本路径（或基本路径未指定或为空值）时，才是默认允许的路径之一。

.. note::

    编译器不会检查允许的路径是否实际存在以及它们是否是目录。
    不存在或为空的路径将被简单忽略。
    如果允许的路径匹配文件而不是目录，则该文件也被视为列入白名单。

.. note::

    允许的路径是区分大小写的，即使文件系统不区分大小写。
    大小写必须与你在导入中使用的完全匹配。
    例如 ``--allow-paths tokens`` 将不匹配 ``import "Tokens/IERC20.sol"``。

.. warning::

    仅通过符号链接从允许的目录访问的文件和目录不会自动列入白名单。
    例如，如果上述示例中的 ``token/contract.sol`` 实际上是指向 ``/etc/passwd`` 的符号链接，则编译器将拒绝加载它，除非 ``/etc/`` 也是允许的路径之一。

.. index:: ! remapping; import, ! import; remapping, ! remapping; context, ! remapping; prefix, ! remapping; target
.. _import-remapping:

导入重映射
==========

导入重映射允许你将导入重定向到虚拟文件系统中的不同位置。
该机制通过改变导入路径与源单元名称之间的转换来工作。
例如，你可以设置重映射，使得来自虚拟目录 ``github.com/ethereum/dapp-bin/library/`` 的任何导入都被视为来自 ``dapp-bin/library/`` 的导入。

你可以通过指定 *上下文* 来限制重映射的范围。
这允许创建仅适用于特定库或特定文件中导入的重映射。
没有上下文的重映射适用于虚拟文件系统中所有文件中每个匹配的导入。

导入重映射的形式为 ``context:prefix=target``：

- ``context`` 必须匹配包含导入的文件的源单元名称的开头。
- ``prefix`` 必须匹配导入所产生的源单元名称的开头。
- ``target`` 是前缀被替换的值。

例如，如果你将 https://github.com/ethereum/dapp-bin/ 克隆到本地的 ``/project/dapp-bin`` 并使用以下命令运行编译器：

.. code-block:: bash

    solc github.com/ethereum/dapp-bin/=dapp-bin/ --base-path /project source.sol

你可以在源文件中使用以下内容：

.. code-block:: solidity

    import "github.com/ethereum/dapp-bin/library/math.sol"; // 源单元名称: dapp-bin/library/math.sol

编译器将在 VFS 中查找该文件，路径为 ``dapp-bin/library/math.sol``。
如果该文件不存在，源单元名称将传递给主文件系统加载器，后者将查找 ``/project/dapp-bin/library/math.sol``。

.. warning::

    有关重映射的信息存储在合约元数据中。
    由于编译器生成的二进制文件中嵌入了元数据的哈希，因此对重映射的任何修改都会导致不同的字节码。

    因此，你应该小心不要在重映射目标中包含任何本地信息。
    例如，如果你的库位于 ``/home/user/packages/mymath/math.sol``，则重映射
    如 ``@math/=/home/user/packages/mymath/`` 会导致你的主目录被包含在元数据中。
    要能够在另一台机器上使用这样的重映射重现相同的字节码，你需要在 VFS 中重建本地目录结构的部分，
    并且（如果你依赖于主文件系统加载器）也需要在主文件系统中重建。

    为了避免将本地目录结构嵌入元数据，建议将包含库的目录指定为 **包含路径**。
    例如，在上面的示例中，``--include-path /home/user/packages/`` 将允许你使用以 ``mymath/`` 开头的导入。
    与重映射不同，单独的选项不会使 ``mymath`` 显示为 ``@math``，但这可以通过创建符号链接或重命名包子目录来实现。

作为一个更复杂的示例，假设你依赖于一个使用旧版本 dapp-bin 的模块，
你将其检出到 ``/project/dapp-bin_old``，然后你可以运行：

.. code-block:: bash

    solc module1:github.com/ethereum/dapp-bin/=dapp-bin/ \
         module2:github.com/ethereum/dapp-bin/=dapp-bin_old/ \
         --base-path /project \
         source.sol

这意味着 ``module2`` 中的所有导入指向旧版本，而 ``module1`` 中的导入指向新版本。

以下是管理重映射行为的详细规则：

#. **重映射仅影响导入路径与源单元名称之间的转换。**

   以其他方式添加到 VFS 的源单元名称无法重映射。
   例如，你在命令行上指定的路径和标准 JSON 中的 ``sources.urls`` 不受影响。

   .. code-block:: bash

       solc /project/=/contracts/ /project/contract.sol # 源单元名称: /project/contract.sol

   在上面的示例中，编译器将从 ``/project/contract.sol`` 加载源代码，并将其放置在 VFS 中的确切源单元名称下，而不是 ``/contract/contract.sol`` 下。

#. **上下文和前缀必须与源单元名称匹配，而不是导入路径。**

   - 这意味着你不能直接重映射 ``./`` 或 ``../``，因为它们在转换为源单元名称时被替换，但你可以重映射它们被替换的名称部分：

     .. code-block:: bash

         solc ./=a/ /project/=b/ /project/contract.sol # 源单元名称: /project/contract.sol

     .. code-block:: solidity
         :caption: /project/contract.sol

         import "./util.sol" as util; // 源单元名称: b/util.sol

   - 你不能重映射基路径或任何其他仅由导入回调内部添加的路径部分：

     .. code-block:: bash

         solc /project/=/contracts/ /project/contract.sol --base-path /project # 源单元名称: contract.sol

     .. code-block:: solidity
         :caption: /project/contract.sol

         import "util.sol" as util; // 源单元名称: util.sol

#. **目标直接插入源单元名称中，并不一定必须是有效路径。**

   - 它可以是任何内容，只要导入回调可以处理它。
     在主文件系统加载器的情况下，这也包括相对路径。
     使用 JavaScript 接口时，如果你的回调可以处理，你甚至可以使用 URL 和抽象标识符。

   - 重映射发生在相对导入已经解析为源单元名称之后。
     这意味着以 ``./`` 和 ``../`` 开头的目标没有特殊含义，并且是相对于基路径而不是源文件的位置。

   - 重映射目标未被规范化，因此 ``@root/=./a/b//`` 将重映射 ``@root/contract.sol``
     为 ``./a/b//contract.sol`` 而不是 ``a/b/contract.sol``。

   - 如果目标不以斜杠结尾，编译器不会自动添加一个：

     .. code-block:: bash

         solc /project/=/contracts /project/contract.sol # 源单元名称: /project/contract.sol

     .. code-block:: solidity
         :caption: /project/contract.sol

         import "/project/util.sol" as util; // 源单元名称: /contractsutil.sol

#. **上下文和前缀是模式，匹配必须完全一致。**

   - ``a//b=c`` 不会匹配 ``a/b``。
   - 源单元名称未被规范化，因此 ``a/b=c`` 也不会匹配 ``a//b``。
   - 文件和目录名称的部分也可以匹配。
     ``/newProject/con:/new=old`` 将匹配 ``/newProject/contract.sol`` 并重映射为
     ``oldProject/contract.sol``。

#. **最多对单个导入应用一个重映射。**

   - 如果多个重映射匹配同一源单元名称，则选择匹配前缀最长的那个。
   - 如果前缀相同，则最后指定的那个胜出。
   - 重映射不适用于其他重映射。例如 ``a=b b=c c=d`` 不会导致 ``a`` 被重映射为 ``d``。

#. **前缀不能为空，但上下文和目标是可选的。**

   - 如果 ``target`` 是空字符串，则 ``prefix`` 仅从导入路径中删除。
   - 空 ``context`` 意味着重映射适用于所有源单元中的所有导入。

.. index:: Remix IDE, file://

在导入中使用 URL
=====================

大多数 URL 前缀，如 ``https://`` 或 ``data://`` 在导入路径中没有特殊含义。
唯一的例外是 ``file://``，它在主文件系统加载器中会从源单元名称中去除。

在本地编译时，你可以使用导入重映射将协议和域部分替换为本地路径：

.. code-block:: bash

    solc :https://github.com/ethereum/dapp-bin=/usr/local/dapp-bin contract.sol

请注意前面的 ``:``, 当重映射上下文为空时，这是必要的。
否则，``https:`` 部分将被编译器解释为上下文。