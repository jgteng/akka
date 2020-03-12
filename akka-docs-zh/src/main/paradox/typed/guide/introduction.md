# Introduction to Akka

Welcome to Akka, a set of open-source libraries for designing scalable, resilient systems that span processor cores and networks. Akka allows you to focus on meeting business needs instead of writing low-level code to provide reliable behavior, fault tolerance, and high performance.

欢迎来到 Akka，一套设计可扩展、跨处理器核心和网络的弹性系统的开源库。Akka 允许你专注于满足业务需求，而不是编写低级代码来提供可靠的行为、容错和高性能。

Many common practices and accepted programming models do not address important challenges
inherent in designing systems for modern computer architectures. To be
successful, distributed systems must cope in an environment where components
crash without responding, messages get lost without a trace on the wire, and
network latency fluctuates. These problems occur regularly in carefully managed
intra-datacenter environments - even more so in virtualized architectures.

很多常用实践和公认的编程模型并未解决为现代计算机体系结构设计系统所固有的重要挑战。为了成功，分布式系统必需应付这样的环境：组件崩溃而没有响应、
消息丢失而没有在线跟踪和网络延迟波动。这些问题经常发生在被小心管理的数据中心内部环境中 - 在虚拟化结构中更是如此。

To help you deal with these realities, Akka provides:

为了帮助你应对这些现实，Akka 提供：

 * Multi-threaded behavior without the use of low-level concurrency constructs like
   atomics or locks &#8212; relieving you from even thinking about memory visibility issues.
 * Transparent remote communication between systems and their components &#8212; relieving you from writing and maintaining difficult networking code.
 * A clustered, high-availability architecture that is elastic, scales in or out, on demand &#8212; enabling you to deliver a truly reactive system.

* 不用使用低级并发结构（如：原子或锁）的多线程行为 &#8212; 甚至不用考虑内存可见性问题。
* 系统和组件之间的透明远程通信 &#8212; 使你免于编写和维护困难的网络代码。
* 一种集群式、高可用的体系结构，具有弹性、可按需伸缩特性 &#8212; 使你能够交付一个真正的反应式系统。

Akka's use of the actor model provides a level of abstraction that makes it
easier to write correct concurrent, parallel and distributed systems. The actor
model spans the full set of Akka libraries, providing you with a consistent way
of understanding and using them. Thus, Akka offers a depth of integration that
you cannot achieve by picking libraries to solve individual problems and trying
to piece them together.

Akka 对 actor 模型的使用提供了一个抽像层，使得编写正确的并发、并行和分布式系统更加容易。

By learning Akka and how to use the actor model, you will gain access to a vast
and deep set of tools that solve difficult distributed/parallel systems problems
in a uniform programming model where everything fits together tightly and
efficiently.

## How to get started

If this is your first experience with Akka, we recommend that you start by
running a simple Hello World project. See the @scala[[Quickstart Guide](https://developer.lightbend.com/guides/akka-quickstart-scala)] @java[[Quickstart Guide](https://developer.lightbend.com/guides/akka-quickstart-java)] for
instructions on downloading and running the Hello World example. The *Quickstart* guide walks you through example code that introduces how to define actor systems, actors, and messages as well as how to use the test module and logging. Within 30 minutes, you should be able to run the Hello World example and learn how it is constructed.

This *Getting Started* guide provides the next level of information. It covers why the actor model fits the needs of modern distributed systems and includes a tutorial that will help further your knowledge of Akka. Topics include:

* @ref:[Why modern systems need a new programming model](actors-motivation.md)
* @ref:[How the actor model meets the needs of concurrent, distributed systems](actors-intro.md)
* @ref:[Overview of Akka libraries and modules](modules.md)
* A @ref:[more complex example](tutorial.md) that builds on the Hello World example to illustrate common Akka patterns.
