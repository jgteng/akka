---
project.description: Akka dispatchers and how to choose the right ones.
---
# Dispatchers

For the Akka Classic documentation of this feature see @ref:[Classic Dispatchers](../dispatchers.md).

此功能的 Akka Classic 文档见 @ref:[Classic Dispatchers](../dispatchers.md) 。

## Dependency

Dispatchers are part of core Akka, which means that they are part of the `akka-actor` dependency. This
page describes how to use dispatchers with `akka-actor-typed`, which has dependency:

Dispatchers（调度器）是 Akka 核心的一部分，这意味着它们是 `akka-actor` 依赖项的一部分。本页描述怎样使用具有 `akka-actor-typed` 依赖的 dispatcher：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-actor-typed_$scala.binary_version$"
  version="$akka.version$"
}

## Introduction 

An Akka `MessageDispatcher` is what makes Akka Actors "tick", it is the engine of the machine so to speak.
All `MessageDispatcher` implementations are also an @scala[`ExecutionContext`]@java[`Executor`], which means that they can be used
to execute arbitrary code, for instance @scala[`Future`s]@java[`CompletableFuture`s].

Akka `MessageDispatcher` 制造 Akka Actor "tick"，它是机器的引擎。
所有 `MessageDispatcher` 都实现了 @scala[`ExecutionContext`]@java[`Executor`]，这意味着它们能执行任意（并发）代码，例如 @scala[`Future`]@java[`CompletableFuture`]。

## Default dispatcher

Every `ActorSystem` will have a default dispatcher that will be used in case nothing else is configured for an `Actor`.
The default dispatcher can be configured, and is by default a `Dispatcher` with the configured `akka.actor.default-dispatcher.executor`.
If no executor is selected a "fork-join-executor" is selected, which
gives excellent performance in most cases.

每个 `ActorSystem` 都有一个默认的 dispatcher，在没有为 `Actor` 配置其它（dispatcher）内容时被使用。
默认 dispatcher 可被配置，默认的 `Dispatcher` 由 `akka.actor.default-dispatcher.executor` 配置。
如果没有选择任何执行器（executor），则 **fork-join-executor" 被选择，大多情况下能给予更优异的性能。

## Internal dispatcher

To protect the internal Actors that are spawned by the various Akka modules, a separate internal dispatcher is used by default.
The internal dispatcher can be tuned in a fine-grained way with the setting `akka.actor.internal-dispatcher`, it can also
be replaced by another dispatcher by making `akka.actor.internal-dispatcher` an @ref[alias](#dispatcher-aliases).

为了保护被各种 Akka 模块生成的内部 Actor，默认情况下使用一个单独的内部 dispatcher。
通过设置 `akka.actor.internal-dispatcher` 内部 dispatcher 可被细粒度的优化，它也可以通过设置 `akka.actor.internal-dispatcher` 的 @ref[alias](#dispatcher-aliases) 被替换为其它 dispatcher。

<a id="dispatcher-lookup"></a>
## Looking up a Dispatcher

Dispatchers implement the @scala[`ExecutionContext`]@java[`Executor`] interface and can thus be used to run @scala[`Future`]@java[`CompletableFuture`] invocations etc.

Dispatchers 实现了 @scala[`ExecutionContext`]@java[`Executor`] 接口，因此可用于运行 @scala[`Future`]@java[`CompletableFuture`] 调用等。

Scala
:  @@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/actor/typed/DispatcherDocSpec.scala) { #lookup }

Java
:  @@snip [DispatcherDocTest.java](/akka-docs/src/test/java/jdocs/actor/typed/DispatcherDocTest.java) { #lookup }

## Selecting a dispatcher

A default dispatcher is used for all actors that are spawned without specifying a custom dispatcher.
This is suitable for all actors that don't block. Blocking in actors needs to be carefully managed, more
details @ref:[here](#blocking-needs-careful-management).

默认 dispatcher 被用于在未指定自定义 dispatcher 下生成的所有 actor。
这适用于所有非阻塞的 actor。阻塞 actor 需要被仔细管理，更多详细内容见 @ref:[这里](#blocking-needs-careful-management) 。

To select a dispatcher use `DispatcherSelector` to create a `Props` instance for spawning your actor:

要选择一个 dispatcher（不使用默认的），请使用 `DispatcherSelector` 来创建一个 `Props` 实例来生成你的 actor：

Scala
:  @@snip [DispatcherDocSpec.scala](/akka-actor-typed-tests/src/test/scala/docs/akka/typed/DispatchersDocSpec.scala) { #spawn-dispatcher }

Java
:  @@snip [DispatcherDocTest.java](/akka-actor-typed-tests/src/test/java/jdocs/akka/typed/DispatchersDocTest.java) { #spawn-dispatcher }

`DispatcherSelector` has a few convenience methods:

`DispatcherSelector` 有几个便利方法：

* @scala[`DispatcherSelector.default`]@java[`DispatcherSelector.defaultDispatcher`] to look up the default dispatcher
* `DispatcherSelector.blocking` can be used to execute actors that block e.g. a legacy database API that does not support @scala[`Future`]@java[`CompletionStage`]s
* `DispatcherSelector.sameAsParent` to use the same dispatcher as the parent actor

* @scala[`DispatcherSelector.default`]@java[`DispatcherSelector.defaultDispatcher`] 查找默认 dispatcher
* `DispatcherSelector.blocking` 可用于执行阻塞 actor，例如：不支持 @scala[`Future`]@java[`CompletionStage`] 的遗留数据库 API
* `DispatcherSelector.sameAsParent` 使用与父 actor 相同的 dispatcher

The final example shows how to load a custom dispatcher from configuration and relies on this being in your `application.conf`:

最后的示例显示怎样从配置文件里加载自定义 dispatcher，且你的 `application.conf` 里存在（这个配置）。

<!-- Same between Java and Scala -->
@@snip [DispatcherDocSpec.scala](/akka-actor-typed-tests/src/test/scala/docs/akka/typed/DispatchersDocSpec.scala) { #config }

## Types of dispatchers

There are 2 different types of message dispatchers:

存在2种不同类型的消息 dispatcher：

* **Dispatcher**

    This is an event-based dispatcher that binds a set of Actors to a thread
    pool. The default dispatcher is used if no other is specified.

    * Shareability: Unlimited
    * Mailboxes: Any, creates one per Actor
    * Use cases: Default dispatcher, Bulkheading
    * Driven by: `java.util.concurrent.ExecutorService`.
      Specify using "executor" using "fork-join-executor", "thread-pool-executor" or the fully-qualified
      class name of an `akka.dispatcher.ExecutorServiceConfigurator` implementation.
    
    这是基于事件的 dispatcher，将一组 actor 绑定到一个线程池。如果没有指定其它 dispatcher 则使用默认 dispatcher。
    
    * 共享性：无限制
    * 邮箱：任意类型，每个 actor 创建一个（邮箱）
    * 用例：默认 dispatcher，隔板（Bulkheading）
    * 驱动：`java.util.concurrent.ExecutorService`。使用 "executor" 指定， "fork-join-executor"、"thread-pool-executor"或实现了 `akka.dispatcher.ExecutorServiceConfigurator` 的完全限定类名。

* **PinnedDispatcher**

    This dispatcher dedicates a unique thread for each actor using it; i.e.
    each actor will have its own thread pool with only one thread in the pool.

    * Shareability: None
    * Mailboxes: Any, creates one per Actor
    * Use cases: Bulkheading
    * Driven by: Any `akka.dispatch.ThreadPoolExecutorConfigurator`.
      By default a "thread-pool-executor".
    
    这个 dispatcher 为使用它的每个 actor 都分配一个唯一的线程；既，每个 actor 都有它自己专属的线程池，该线程池只有一个线程。
    
    * 共享性：无
    * 邮箱：任意类型，每个 actor 创建一个（邮箱）
    * 用例：隔板（Bulkheading）
    * 驱动：任何 `akka.dispatch.ThreadPoolExecutorConfigurator`。默认为 "thread-pool-executor"。

Here is an example configuration of a Fork Join Pool dispatcher:

这是一个 Fork Join Pool dispatcher 的配置示例：

<!--same config text for Scala & Java-->
@@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/dispatcher/DispatcherDocSpec.scala) { #my-dispatcher-config }

For more configuration options, see the @ref:[More dispatcher configuration examples](#more-dispatcher-configuration-examples)
section and the `default-dispatcher` section of the @ref:[configuration](../general/configuration.md).

有关更多配置选项，见 @ref:[More dispatcher configuration examples](#more-dispatcher-configuration-examples) 节和 @ref:[configuration](../general/configuration.md) 的 `default-dispatcher` 节。

@@@ note

The `parallelism-max` for the `fork-join-executor` does not set the upper bound on the total number of threads
allocated by the ForkJoinPool. It is a setting specifically talking about the number of *hot*
threads the pool will keep running in order to reduce the latency of handling a new incoming task.
You can read more about parallelism in the JDK's [ForkJoinPool documentation](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ForkJoinPool.html).

`fork-join-executor` 的 `parallelism-max` 不是设置分配给 ForkJoinPool 的线程的上限数量。此设置专门讨论线程池将保持运行的 *热* 线程数，以降低新传入任务的处理延迟。你可在 JDK 的 [ForkJoinPool 文档](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ForkJoinPool.html) 读到关于并行度（parallelism）的更多信息。 

@@@

@@@ note

The `thread-pool-executor` dispatcher is implemented using by a `java.util.concurrent.ThreadPoolExecutor`.
You can read more about it in the JDK's [ThreadPoolExecutor documentation](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ThreadPoolExecutor.html).

`thread-pool-executor` 使用 `java.util.concurrent.ThreadPoolExecutor` 实现。你可在 JDK 的 [ThreadPoolExecutor 文档](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ThreadPoolExecutor.html) 读到有关它的更多信息。

@@@

## Dispatcher aliases

When a dispatcher is looked up, and the given setting contains a string rather than a dispatcher config block,
the lookup will treat it as an alias, and follow that string to an alternate location for a dispatcher config.
If the dispatcher config is referenced both through an alias and through the absolute path only one dispatcher will
be used and shared among the two ids.

查找 dispatcher 时，给定的设置包含一个字符串而不是 dispatcher 配置块，查找将视它为一个别名，并跟随字符串到 dispatcher 配置的备用位置。如果 dispatcher 配置被通过别名和绝对路径引用，则两个 id 将使用和共享同一个 dispatcher。

Example: configuring `internal-dispatcher` to be an alias for `default-dispatcher`:

示例：`internal-dispatcher` 配置为 `default-dispatcher` 的别名：

```
akka.actor.internal-dispatcher = akka.actor.default-dispatcher
```

## Blocking Needs Careful Management

In some cases it is unavoidable to do blocking operations, i.e. to put a thread
to sleep for an indeterminate time, waiting for an external event to occur.
Examples are legacy RDBMS drivers or messaging APIs, and the underlying reason
is typically that (network) I/O occurs under the covers.

在某些情况下，不可避免使用阻塞操作，既：使线程休眠一段不确定的时间，等待外部事件发生。
示例是遗留数据库驱动或消息API，根本原因通常是（网络）I/O 发生在幕后。

### Problem: Blocking on default dispatcher

Simply adding blocking calls to your actor message processing like this is problematic:

像这样简单的添加阻塞调用到你的 actor 的消息处理中是有问题的：

Scala
:   @@snip [BlockingDispatcherSample.scala](/akka-docs/src/test/scala/docs/actor/typed/BlockingActor.scala) { #blocking-in-actor }

Java
:   @@snip [BlockingActor.java](/akka-docs/src/test/java/jdocs/actor/typed/BlockingActor.java) { #blocking-in-actor }

Without any further configuration the default dispatcher runs this actor along
with all other actors. This is very efficient when all actor message processing is
non-blocking. When all of the available threads are blocked, however, then all the actors on the same dispatcher will starve for threads and
will not be able to process incoming messages.

没有任何进一步配置，默认 dispatcher 将此 actor 与所有其它 actor 一起运行。当所有 actor 的消息处理都是非阻塞时，这是非常有效率的。然而，当所有可用线程都被阻塞，则所有 actor 在相同的 dispatcher 上将饿死线程，并且将无法处理传入消息。

@@@ note

Blocking APIs should also be avoided if possible. Try to find or build Reactive APIs,
such that blocking is minimised, or moved over to dedicated dispatchers.

阻塞 API 应尽量避免使用。尝试查找或构建反应式 API，以使阻塞最小化，或移至专用的 dispatcher。

Often when integrating with existing libraries or systems it is not possible to
avoid blocking APIs. The following solution explains how to handle blocking
operations properly.

通常与已存在的库或系统集成时，阻塞 API 是无法避免的。下面的解决方案说明了怎样合适地处理阻塞操作。

Note that the same hints apply to managing blocking operations anywhere in Akka,
including Streams, Http and other reactive libraries built on top of it.

注意，相同的提示适用于在 Akka 里的任何地方管理阻塞操作，包括 Streams、Http 和构建在其之上的其它反应式库。

@@@

To demonstrate this problem, let's set up an application with the above `BlockingActor` and the following `PrintActor`:

为演示这个问题，让我们使用上述 `BlockingActor` 和下面的 `PrintActor` 设置应用程序 。

Scala
:   @@snip [PrintActor.scala](/akka-docs/src/test/scala/docs/actor/typed/PrintActor.scala) { #print-actor }

Java
:   @@snip [PrintActor.java](/akka-docs/src/test/java/jdocs/actor/typed/PrintActor.java) { #print-actor }


Scala
:   @@snip [BlockingDispatcherSample.scala](/akka-docs/src/test/scala/docs/actor/typed/BlockingDispatcherSample.scala) { #blocking-main }

Java
:   @@snip [BlockingDispatcherTest.java](/akka-docs/src/test/java/jdocs/actor/typed/BlockingDispatcherTest.java) { #blocking-main }


Here the app is sending 100 messages to `BlockingActor`s and `PrintActor`s and large numbers
of `akka.actor.default-dispatcher` threads are handling requests. When you run the above code,
you will likely to see the entire application gets stuck somewhere like this:

这里应用发送 100 条消息到 `BlockingActor` 和 `PrintActor` ，大量 `akka.actor.default-dispatcher` 线程正在处理请求。当你运行上述代码，你将可能看到整个应用程序卡住，就像这样：

```
>　PrintActor: 44
>　PrintActor: 45
```

`PrintActor` is considered non-blocking, however it is not able to proceed with handling the remaining messages,
since all the threads are occupied and blocked by the other blocking actors - thus leading to thread starvation.

`PrintActor` 被认为是非阻塞的，然而它无法继续处理剩余的消息，自所有线程都被其它阻塞 actor 占用和阻塞以后 - 从而导致线程饥饿。

In the thread state diagrams below the colours have the following meaning:

线程状态图中，颜色具有下列含义：

 * Turquoise - Sleeping state
 * Orange - Waiting state
 * Green - Runnable state
 
 * 绿松石 - 休眠状态
 * 橙色 - 等待状态
 * 绿色 - 运行状态

The thread information was recorded using the YourKit profiler, however any good JVM profiler
has this feature (including the free and bundled with the Oracle JDK [VisualVM](https://visualvm.github.io/), as well as [Java Mission Control](https://openjdk.java.net/projects/jmc/)).

线程信息使用 Yourkit 分析器记录，但是任何好的 JVM 分析器都有这个功能（包括免费捆绑在Oracle JDK里的[VisualVM](https://visualvm.github.io/)，以及 [Java Mission Control](https://openjdk.java.net/projects/jmc/)）。

The orange portion of the thread shows that it is idle. Idle threads are fine -
they're ready to accept new work. However, a large number of turquoise (blocked, or sleeping as in our example) threads
leads to thread starvation.

橙色部分的线程显示它处于空闲。空闲的线程是好的 - 他们准备好应用新的工作。然而，大量的绿松石色（在我们的例子里是阻塞或休眠）线程导致线饥饿。

@@@ note

If you own a Lightbend subscription you can use the commercial [Thread Starvation Detector](https://doc.akka.io/docs/akka-enhancements/current/starvation-detector.html)
which will issue warning log statements if it detects any of your dispatchers suffering from starvation and other.
It is a helpful first step to identify the problem is occurring in a production system,
and then you can apply the proposed solutions as explained below.

如果你拥有 Lightbend 订阅，你可使用商业的 [Thread Starvation Detector](https://doc.akka.io/docs/akka-enhancements/current/starvation-detector.html)。如果它检测到你的任何 dispatcher 遭受饥饿和其它痛苦，它将发出警告日志语句。
这是在生产系统里确定问题发生的有益的第一步，然后你可以按照说明应用建议的解决方案。

@@@

![dispatcher-behaviour-on-bad-code.png](../images/dispatcher-behaviour-on-bad-code.png)

In the above example we put the code under load by sending hundreds of messages to blocking actors
which causes threads of the default dispatcher to be blocked.
The fork join pool based dispatcher in Akka then attempts to compensate for this blocking by adding more threads to the pool
(`default-akka.actor.default-dispatcher 18,19,20,...`).
This however is not able to help if those too will immediately get blocked,
and eventually the blocking operations will dominate the entire dispatcher.

在上面的例子里，我们发送数百个消息到阻塞 actor 使代码处于负载状态，这导致默认 dispatcher 的线程被阻塞。然后，Akka 里基于 fork join 线程池的 dispatcher，尝试增加更多线程到线程池里来弥补这种阻塞 (`default-akka.actor.default-dispatcher 18,19,20,...`)。但是，如果那些（新添加线程）被立即阻塞，最终阻塞操作将主导整个 dispatcher，这没有帮助。

In essence, the `Thread.sleep` operation has dominated all threads and caused anything
executing on the default dispatcher to starve for resources (including any actor
that you have not configured an explicit dispatcher for).

实质上，`Thread.sleep` 操作控制了所有线程，并导致默认 dispatcher 上执行的任何操作都会饿死资源（包括任何没有配置显示 dispatcher 的 actor）。

@@@ div { .group-scala }

### Non-solution: Wrapping in a Future

### 非解决方案：包装在 Future 里

<!--
  A CompletableFuture by default on ForkJoinPool.commonPool(), so
  because that is already separate from the default dispatcher
  the problem described in these sections do not apply:
-->

When facing this, you
may be tempted to wrap the blocking call inside a `Future` and work
with that instead, but this strategy is too simplistic: you are quite likely to
find bottlenecks or run out of memory or threads when the application runs
under increased load.

当面对这种情况时，你也许尝试把阻塞调用包装到 `Future` 里面，并替代阻塞方式使用。但是，这种策略过于简单：当应用程序在负载增加下运行时，你很可能发现瓶颈或内存不足或线程不足。

Scala
:   @@snip [BlockingDispatcherSample.scala](/akka-docs/src/test/scala/docs/actor/typed/BlockingDispatcherSample.scala) { #blocking-in-future }

The key problematic line here is this:

这里的关键问题行是：

```scala
implicit val executionContext: ExecutionContext = context.executionContext
```

Using @scala[`context.executionContext`] as the dispatcher on which the blocking `Future`
executes can still be a problem, since this dispatcher is by default used for all other actor processing
unless you @ref:[set up a separate dispatcher for the actor](../dispatchers.md#setting-the-dispatcher-for-an-actor).

使用 @scala[`context.executionContext`] 作为在阻塞 `Future` 上执行调用的 dispatcher 是一个问题, 因为默认 dispatcher 将用于其它所有 actor 处理（消息），除非你 @ref:[为 actor 设置单独的 dispatcher](../dispatchers.md#setting-the-dispatcher-for-an-actor)。

@@@

### Solution: Dedicated dispatcher for blocking operations

### 解决方案：专用的 dispatcher 用于阻塞操作

An efficient method of isolating the blocking behavior, such that it does not impact the rest of the system,
is to prepare and use a dedicated dispatcher for all those blocking operations.
This technique is often referred to as "bulk-heading" or simply "isolating blocking".

隔离阻塞行为以使它不影响系统其余部分的有效方法，是为所有这些阻塞准备并操作使用专用的 dispatcher。该技术通常称为 "批量处理"（"bulk-heading"）或简称 "隔离阻塞"（"isolating blocking"）。

In `application.conf`, the dispatcher dedicated to blocking behavior should
be configured as follows:

在 `application.conf` 里，专用与阻塞行为的 dispatcher 应配置如下：

<!--same config text for Scala & Java-->
@@snip [BlockingDispatcherSample.scala](/akka-docs/src/test/scala/docs/actor/typed/BlockingDispatcherSample.scala) { #my-blocking-dispatcher-config }

A `thread-pool-executor` based dispatcher allows us to limit the number of threads it will host,
and this way we gain tight control over the maximum number of blocked threads the system may use.

基于 `thread-pool-executor` 的 dispatcher 允许我们限制它将托管的线程数量，这样我们就可以严格控制系统可使用的最大阻塞线程数。

The exact size should be fine tuned depending on the workload you're expecting to run on this dispatcher.

准确的数量应该依赖你期待在这个 dispatcher 上运行的工作量进行微调。 

Whenever blocking has to be done, use the above configured dispatcher
instead of the default one:

每当必需进行阻塞时，使用上面配置的 dispatcher 替代默认的（dispatcher）。

Scala
:   @@snip [BlockingDispatcherSample.scala](/akka-docs/src/test/scala/docs/actor/typed/BlockingDispatcherSample.scala) { #separate-dispatcher }

Java
:   @@snip [SeparateDispatcherCompletionStageActor.java](/akka-docs/src/test/java/jdocs/actor/typed/SeparateDispatcherCompletionStageActor.java) { #separate-dispatcher }

The thread pool behavior is shown in the below diagram.

线程池行为显示在下面图里。

![dispatcher-behaviour-on-good-code.png](../images/dispatcher-behaviour-on-good-code.png)

Messages sent to @scala[`SeparateDispatcherFutureActor`]@java[`SeparateDispatcherCompletionStageActor`] and `PrintActor` are handled by the default dispatcher - the
green lines, which represent the actual execution.

消息发送到 @scala[`SeparateDispatcherFutureActor`]@java[`SeparateDispatcherCompletionStageActor`] 到 `PrintActor` 被默认 dispatcher 处理 - 绿线，代表实际执行。

When blocking operations are run on the `my-blocking-dispatcher`,
it uses the threads (up to the configured limit) to handle these operations.
The sleeping in this case is nicely isolated to just this dispatcher, and the default one remains unaffected,
allowing the rest of the application to proceed as if nothing bad was happening. After
a certain period of idleness, threads started by this dispatcher will be shut down.

当阻塞操作在 `my-blocking-dispatcher` 上运行时，它使用线程（配置的上限）处理这些操作。
这种情况下休眠地这个 dispatcher 里被很好地隔离，默认的 dispatcher 不受影响，从而允许应用程序的剩余部分继续进行，就像没有不好的事发生一样。
空闲一定时期后，已启动的线程将被这个 dispatcher 关闭。

In this case, the throughput of other actors was not impacted -
they were still served on the default dispatcher.

这种情况下，其它 actor 的吞吐量不受影响 - 它们仍然由默认的 dispatcher 提供服务。

This is the recommended way of dealing with any kind of blocking in reactive
applications.

这是在反应式程序里处理任何阻塞情况的推荐方式。

For a similar discussion specifically about Akka HTTP, refer to @extref[Handling blocking operations in Akka HTTP](akka.http:handling-blocking-operations-in-akka-http-routes.html).

关于 Akka HTTP 里的相似讨论，参考 @extref[Handling blocking operations in Akka HTTP](akka.http:handling-blocking-operations-in-akka-http-routes.html)。

### Available solutions to blocking operations
**阻塞操作可用的解决方案**

The non-exhaustive list of adequate solutions to the “blocking problem”
includes the following suggestions:

足够解决“阻塞操作”的不完全列表包括以下建议：

 * Do the blocking call within a @scala[`Future`]@java[`CompletionStage`], ensuring an upper bound on
the number of such calls at any point in time (submitting an unbounded
number of tasks of this nature will exhaust your memory or thread limits).
 * Do the blocking call within a `Future`, providing a thread pool with
an upper limit on the number of threads which is appropriate for the
hardware on which the application runs, as explained in detail in this section.
 * Dedicate a single thread to manage a set of blocking resources (e.g. a NIO
selector driving multiple channels) and dispatch events as they occur as
actor messages.
 * Do the blocking call within an actor (or a set of actors) managed by a
@ref:[router](../routing.md), making sure to
configure a thread pool which is either dedicated for this purpose or
sufficiently sized.

 * 在 @scala[`Future`]@java[`CompletionStage`] 里进行阻塞调用，确保在任何时间点上这样的调用数量上限（提交无数此类任务将耗尽你的内存或线程限制）。
 * 在 `Future` 里进行阻塞调用，为线程池提供一个上限数量，该上奶适用于运行应用程序的硬件，如本节详细说明。
 * 专用一个线程来管理一系列阻塞资源（例如：驱动多个通道的 NIO 选择器），并在事件作为 actor 消息发生时对其进行分派。
 * 在被 @ref:[router](../routing.md) 管理的 actor（或一系列 actor）里进行阻塞调用，请确保配置的线程池专用于此目的或有足够数量（的线程）。

The last possibility is especially well-suited for resources which are
single-threaded in nature, like database handles which traditionally can only
execute one outstanding query at a time and use internal synchronization to
ensure this. A common pattern is to create a router for N actors, each of which
wraps a single DB connection and handles queries as sent to the router. The
number N must then be tuned for maximum throughput, which will vary depending
on which DBMS is deployed on what hardware.

@@@ note

Configuring thread pools is a task best delegated to Akka, configure
it in `application.conf` and instantiate through an
@ref:[`ActorSystem`](#dispatcher-lookup)

@@@

## More dispatcher configuration examples

### Fixed pool size

Configuring a dispatcher with fixed thread pool size, e.g. for actors that perform blocking IO:

@@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/dispatcher/DispatcherDocSpec.scala) { #fixed-pool-size-dispatcher-config }

### Cores

Another example that uses the thread pool based on the number of cores (e.g. for CPU bound tasks)

<!--same config text for Scala & Java-->
@@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/dispatcher/DispatcherDocSpec.scala) {#my-thread-pool-dispatcher-config }

### Pinned

A separate thread is dedicated for each actor that is configured to use the pinned dispatcher.  

Configuring a `PinnedDispatcher`:

<!--same config text for Scala & Java-->
@@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/dispatcher/DispatcherDocSpec.scala) {#my-pinned-dispatcher-config }

Note that `thread-pool-executor` configuration as per the above `my-thread-pool-dispatcher` example is
NOT applicable. This is because every actor will have its own thread pool when using `PinnedDispatcher`,
and that pool will have only one thread.

Note that it's not guaranteed that the *same* thread is used over time, since the core pool timeout
is used for `PinnedDispatcher` to keep resource usage down in case of idle actors. To use the same
thread all the time you need to add `thread-pool-executor.allow-core-timeout=off` to the
configuration of the `PinnedDispatcher`.

### Thread shutdown timeout

Both the `fork-join-executor` and `thread-pool-executor` may shutdown threads when they are not used.
If it's desired to keep the threads alive longer there are some timeout settings that can be adjusted.

<!--same config text for Scala & Java-->
@@snip [DispatcherDocSpec.scala](/akka-docs/src/test/scala/docs/dispatcher/DispatcherDocSpec.scala) {#my-dispatcher-with-timeouts-config }
 
When using the dispatcher as an `ExecutionContext` without assigning actors to it the `shutdown-timeout` should
typically be increased, since the default of 1 second may cause too frequent shutdown of the entire thread pool.
