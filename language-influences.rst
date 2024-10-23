###################
语言影响
###################

Solidity 是一种 `大括号语言 <https://en.wikipedia.org/wiki/List_of_programming_languages_by_type#Curly_bracket_languages>`_，受到了几种知名编程语言的影响和启发。

Solidity 最深刻的影响来自 C++，但也借鉴了 Python、JavaScript 等语言的概念。

C++ 的影响可以在变量声明的语法、for 循环、函数重载的概念、隐式和显式类型转换以及许多其他细节中看到。

在语言的早期，Solidity 部分受到 JavaScript 的影响。这是由于变量的函数级作用域和使用关键字 ``var``。
从版本 0.4.0 开始，JavaScript 的影响减少了。
现在，唯一剩下的与 JavaScript 的相似之处是函数使用关键字 ``function`` 定义。
Solidity 还支持与 JavaScript 中可用的类似的导入语法和语义。
除此之外，Solidity 看起来与大多数其他大括号语言相似，并且不再受到 JavaScript 的主要影响。

另一个对 Solidity 的影响是 Python。
Solidity 的修改器是试图模拟 Python 的装饰器，但功能受到更严格的限制。
此外，多重继承、C3 线性化和 ``super`` 关键字也来自 Python，以及值类型和引用类型的一般赋值和复制语义。