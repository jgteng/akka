# Basics and working with Flows
# Flow的基础知识和使用

## Dependency
## 依赖

To use Akka Streams, add the module to your project:
要使用Akka Streams，添加以下模块到你的项目：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-stream_$scala.binary_version$"
  version="$akka.version$"
}

## Introduction
## 介绍

<a id="core-concepts"></a>
## Core concepts
## 核心概念

Akka Streams is a library to process and transfer a sequence of elements using bounded buffer space. This
latter property is what we refer to as *boundedness*, and it is the defining feature of Akka Streams. Translated to
everyday terms, it is possible to express a chain (or as we see later, graphs) of processing entities. Each of these
entities executes independently (and possibly concurrently) from the others while only buffering a limited number
of elements at any given time. This property of bounded buffers is one of the differences from the actor model, where each actor usually has
an unbounded, or a bounded, but dropping mailbox. Akka Stream processing entities have bounded "mailboxes" that
do not drop.

Akka Streams是一个使用有界缓冲区空间处理和传输元素序列的库。后一种属性就是我们所说的有界性，它是Akka Streams的定义特征。 
翻译成日常术语，可以表达处理实体的链（或者我们后面看到的图）。这些实体中的每一个独立地（并且可能同时地）从其他实体执行，
同时仅在任何给定时间缓冲有限数量的元素。有界缓冲区的这个属性是与actor模型的不同之处，
其中每个actor通常都有一个无界的或者有界的但是丢弃的邮箱。 Akka Stream处理实体限制了“邮箱”，不会丢失。

Before we move on, let's define some basic terminology which will be used throughout the entire documentation:

在我们继续之前，让我们定义一些将在整个文档中使用的基本术语：

Stream
: An active process that involves moving and transforming data.

一个涉及移动转换转换数据的活动过程。

Element
: An element is the processing unit of streams. All operations transform and transfer elements from upstream to
downstream. Buffer sizes are always expressed as number of elements independently from the actual size of the elements.

元素是流的处理单元。所有操作都将元素从上游转换到下游。缓冲区大小始终表示为独立于元素实际大小的元素数。

Back-pressure
: A means of flow-control, a way for consumers of data to notify a producer about their current availability, effectively
slowing down the upstream producer to match their consumption speeds.
In the context of Akka Streams back-pressure is always understood as *non-blocking* and *asynchronous*.

流量控制的一种方式，一种让数据消费者通知生产者当前可用性（消费者可处理数据量）的方法，
可有效地减慢上游生产者的速度以匹配它们的消息速度。在Akka Streams的背景下，回压始终被解释为 *非阻塞* 和 *异步* 。

Non-Blocking
: Means that a certain operation does not hinder the progress of the calling thread, even if it takes a long time to
finish the requested operation.

意味着某个操作不会妨碍调用线程的执行，即使完成所请求的操作需要很长时间。

Graph
: A description of a stream processing topology, defining the pathways through which elements shall flow when the stream
is running.

流处理拓扑的描述，定义流在运行时元素应渡过的路径。

Operator
: The common name for all building blocks that build up a Graph.
Examples of operators are `map()`, `filter()`, custom ones extending @ref[`GraphStage`s](stream-customize.md) and graph
junctions like `Merge` or `Broadcast`. For the full list of built-in operators see the @ref:[operator index](operators/index.md)

构建Graph的所有构建块的通用名称。运算符的示例包括`map()`，`filter()`，自定义的 @ref[`GraphStage`s](stream-customize.md)
和图表连接（如`Merge`或`Broadcast`）。有关内置运算符的完整列表，请参阅 @ref:[运算符索引](operators/index.md) 。

When we talk about *asynchronous, non-blocking backpressure*, we mean that the operators available in Akka
Streams will not use blocking calls but asynchronous message passing to exchange messages between each other.
This way they can slow down a fast producer without blocking its thread. This is a thread-pool friendly
design, since entities that need to wait (a fast producer waiting on a slow consumer) will not block the thread but
can hand it back for further use to an underlying thread-pool.

当我们谈论 *异步，非阻塞回压时* ，我们的意思是Akka Streams中可用的运算符不会使用阻塞调用，
而是使用异步消息传递来在彼此之间交换消息。这样他们就可以在不阻塞其（调用）线程的情况下减慢快速生产者的速度。
这是一个线程池友好的设计，因为需要等待的实体（快速生产者在慢速消费者上等待）不会阻塞线程，
但可以将其交还给底层线程池以供进一步使用。

<a id="defining-and-running-streams"></a>
## Defining and running streams
## 定义和运行流

Linear processing pipelines can be expressed in Akka Streams using the following core abstractions:

线性处理管道可以使用以下核心抽象在Akka Streams中表示：

Source
: An operator with *exactly one output*, emitting data elements whenever downstream operators are
ready to receive them.

*具有一个输出* 的运算符，每当下游运算符准备好接收它时发布数据元素。

Sink
: An operator with *exactly one input*, requesting and accepting data elements, possibly slowing down the upstream
producer of elements.

只有一个输入、请求和接受数据元素的运算符，可能会减慢上游元素生成的速度。

Flow
: An operator which has *exactly one input and output*, which connects its upstream and downstream by
transforming the data elements flowing through it.

一个 *只有一个输入和输出* 的运算符，通过转换流经它的数据元素来连接上游和下游。

RunnableGraph
: A Flow that has both ends "attached" to a Source and Sink respectively, and is ready to be `run()`.

一个流的两端分别“附加”到Source和Sink，并准备`run()`。

It is possible to attach a `Flow` to a `Source` resulting in a composite source, and it is also possible to prepend
a `Flow` to a `Sink` to get a new sink. After a stream is properly terminated by having both a source and a sink,
it will be represented by the `RunnableGraph` type, indicating that it is ready to be executed.

可以将`Flow`附加到`Source`，从而产生复合source，并且还可以将`Flow`添加到`Sink`以获得新的sink。
通过同时拥有source和sink正确终止流后，它将由`RunnableGraph`类型表示，表明它已准备好执行。

It is important to remember that even after constructing the `RunnableGraph` by connecting all the source, sink and
different operators, no data will flow through it until it is materialized. Materialization is the process of
allocating all resources needed to run the computation described by a Graph (in Akka Streams this will often involve
starting up Actors). Thanks to Flows being a description of the processing pipeline they are *immutable,
thread-safe, and freely shareable*, which means that it is for example safe to share and send them between actors, to have
one actor prepare the work, and then have it be materialized at some completely different place in the code.

重要的是要记住，即使在通过连接所有source，sink和不同的运算符构建`RunnableGraph`之后，在物化之前，没有数据将流过它。
实现（Materialization）是分配运行`Graph`所描述的计算所需的所有资源的过程（在Akka Streams中，这通常涉及启动Actors）。
由于Flows是对处理管道的描述，因此它们是 *不可变的，线程安全的，并且可以自由共享* ，
这意味着在演员之间共享和发送它们是安全的，让一个演员准备工作，然后拥有它的代码中的某个完全不同的地方物化（materialized）。

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #materialization-in-steps }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #materialization-in-steps }

@@@ div { .group-scala }

After running (materializing) the `RunnableGraph[T]` we get back the materialized value of type T. Every stream
operator can produce a materialized value, and it is the responsibility of the user to combine them to a new type.
In the above example, we used `toMat` to indicate that we want to transform the materialized value of the source and
sink, and we used the convenience function `Keep.right` to say that we are only interested in the materialized value
of the sink.

在运行（materializing）`RunnableGraph[T]`之后，我们返回类型`T`的物化值。每个流运算符都可以生成物化值，
用户有责任将它们组合到新类型。在上面的例子中，我们使用`toMat`来表示我们想要转换source和sink的物化值，
并且我们使用便利函数`Keep.right`来表示我们只对sink的物化值感兴趣。

In our example, the `FoldSink` materializes a value of type `Future` which will represent the result
of the folding process over the stream.  In general, a stream can expose multiple materialized values,
but it is quite common to be interested in only the value of the Source or the Sink in the stream. For this reason
there is a convenience method called `runWith()` available for `Sink`, `Source` or `Flow` requiring, respectively,
a supplied `Source` (in order to run a `Sink`), a `Sink` (in order to run a `Source`) or
both a `Source` and a `Sink` (in order to run a `Flow`, since it has neither attached yet).

在我们的示例中，`FoldSink`实现了`Future`类型的值，该值将表示流上的折叠过程的结果。通常，流可以公开多个物化值，
但是仅对流中的Source或Sink的值感兴趣是很常见的。出于这个原因，有一个名为｀runWith()`的方便方法可用`于Sink`，`Source`或
`Flow`，分别需要提供的`Source`（为了运行`Sink`），`Sink`（为了运行`Source`）或者同时需要`Source`和一个`Sink`
（为了运行一个`Flow`，因为它还没有附加）。

@@@

@@@ div { .group-java }

After running (materializing) the `RunnableGraph` we get a special container object, the `MaterializedMap`. Both
sources and sinks are able to put specific objects into this map. Whether they put something in or not is implementation
dependent. 

For example a `FoldSink` will make a `CompletionStage` available in this map which will represent the result
of the folding process over the stream.  In general, a stream can expose multiple materialized values,
but it is quite common to be interested in only the value of the Source or the Sink in the stream. For this reason
there is a convenience method called `runWith()` available for `Sink`, `Source` or `Flow` requiring, respectively,
a supplied `Source` (in order to run a `Sink`), a `Sink` (in order to run a `Source`) or
both a `Source` and a `Sink` (in order to run a `Flow`, since it has neither attached yet).
@@@

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #materialization-runWith }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #materialization-runWith }

It is worth pointing out that since operators are *immutable*, connecting them returns a new operator,
instead of modifying the existing instance, so while constructing long flows, remember to assign the new value to a variable or run it:

值得指出的是，由于运算符是不可变的，因此连接它们会返回一个新运算符，而不是修改现有实例，因此在构造长flow时，
请记住将新值分配给变量或运行它：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #source-immutable }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #source-immutable }

@@@ note

By default, Akka Streams elements support **exactly one** downstream operator.
Making fan-out (supporting multiple downstream operators) an explicit opt-in feature allows default stream elements to
be less complex and more efficient. Also, it allows for greater flexibility on *how exactly* to handle the multicast scenarios,
by providing named fan-out elements such as broadcast (signals all down-stream elements) or balance (signals one of available down-stream elements).

默认情况下，Akka Streams元素 **仅支持一个** 下游运算符。扇出（支持多个下游运算符）明确的选择加入功能允许默认流元素不那么复杂和高效。
此外，通过提供命名的扇出元素，例如广播（信号给所有下游元素）或平衡（发出可用下游元素之一的信号），它允许更精确地处理多播场景的准确性。

@@@

In the above example we used the `runWith` method, which both materializes the stream and returns the materialized value
of the given sink or source.

在上面的示例中，我们使用了`runWith`方法，该方法实现了流并返回给定sink或source的具体物化值。

Since a stream can be materialized multiple times, the @scala[materialized value will also be calculated anew] @java[`MaterializedMap` returned is different] for each such
materialization, usually leading to different values being returned each time.
In the example below, we create two running materialized instances of the stream that we described in the `runnable`
variable. Both materializations give us a different @scala[`Future`] @java[`CompletionStage`] from the map even though we used the same `sink`
to refer to the future:

由于流可以多次实现，因此每个这样的实现也将重新计算物化值，通常导致每次返回不同的值。在下面的示例中，
我们创建了两个在runnable变量中描述的流的实现实例化实例。 即使我们使用相同的sink来指代future，
这两种实现方式都为我们提供了不同的`Future`：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #stream-reuse }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #stream-reuse }

### Defining sources, sinks and flows
### 定义source，sink和flow

The objects `Source` and `Sink` define various ways to create sources and sinks of elements. The following
examples show some of the most useful constructs (refer to the API documentation for more details):

`Source`和`Sink` object定义了创建source和sink元素的各种方法。以下示例显示了一些最有用的结构
（有关更多详细信息，请参阅API文档）：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #source-sink }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #source-sink }

There are various ways to wire up different parts of a stream, the following examples show some of the available options:

有多种方法可以连接流的不同部分，以下示例显示了一些可用选项：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #flow-connecting }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #flow-connecting }

### Illegal stream elements
### 非法流元素

In accordance to the Reactive Streams specification ([Rule 2.13](https://github.com/reactive-streams/reactive-streams-jvm#2.13))
Akka Streams do not allow `null` to be passed through the stream as an element. In case you want to model the concept
of absence of a value we recommend using @scala[`scala.Option` or `scala.util.Either`] @java[`java.util.Optional` which is available since Java 8].

根据Reactive Streams规范（[规则2.13](https://github.com/reactive-streams/reactive-streams-jvm#2.13)），
Akka Streams不允许将`null`作为元素传递给流。如果你想模拟缺少值的概念，我们建议使用`scala.Option`或`scala.util.Either`。

## Back-pressure explained
## 回压解释

Akka Streams implement an asynchronous non-blocking back-pressure protocol standardised by the [Reactive Streams](http://reactive-streams.org/)
specification, which Akka is a founding member of.

Akka Streams实现了一个由Reactive Streams规范标准化的异步非阻塞回压协议，Akka是该协议的创始成员之一。

The user of the library does not have to write any explicit back-pressure handling code — it is built in
and dealt with automatically by all of the provided Akka Streams operators. It is possible however to add
explicit buffer operators with overflow strategies that can influence the behavior of the stream. This is especially important
in complex processing graphs which may even contain loops (which *must* be treated with very special
care, as explained in @ref:[Graph cycles, liveness and deadlocks](stream-graphs.md#graph-cycles)).

库的用户不必编写任何明确的回压处理代码 - 它由所有提供的Akka Streams运算符自动构建和处理。但是，
可以使用可能影响流行为的溢出策略添加显式缓冲区运算符。这在复杂的处理图中尤其重要，这些图甚至可能包含循环
（必须非常特别小心处理，如 @ref:[图循环，活跃度和死锁](stream-graphs.md#graph-cycles) 中所述）。

The back pressure protocol is defined in terms of the number of elements a downstream `Subscriber` is able to receive
and buffer, referred to as `demand`.
The source of data, referred to as `Publisher` in Reactive Streams terminology and implemented as `Source` in Akka
Streams, guarantees that it will never emit more elements than the received total demand for any given `Subscriber`.

回压协议根据下游`Subscriber`能够接收和缓冲的元素数量来定义，称为需求。数据源
（在Reactive Streams术语中称为`Publisher`，在Akka Streams中作为`Source`实现）
保证它不会发出比任何给定订阅者的接收总需求更多的元素。

@@@ note

The Reactive Streams specification defines its protocol in terms of `Publisher` and `Subscriber`.
These types are **not** meant to be user facing API, instead they serve as the low-level building blocks for
different Reactive Streams implementations.

Reactive Streams规范根据`Publisher`和`Subscriber`定义其协议。这些类型并 **不是** 面向用户的API，
而是作为不同Reactive Streams实现的低级构建块。

Akka Streams implements these concepts as `Source`, `Flow` (referred to as `Processor` in Reactive Streams)
and `Sink` without exposing the Reactive Streams interfaces directly.
If you need to integrate with other Reactive Stream libraries, read @ref:[Integrating with Reactive Streams](stream-integrations.md#reactive-streams-integration).

Akka Streams将这些概念实现为`Source`，`Flow`（在Reactive Streams中称为`Processor`）和`Sink`，
而不直接暴露Reactive Streams接口。如果需要与其他Reactive Stream库集成，请阅读 
@ref:[与Reactive Streams集成](stream-integrations.md#reactive-streams-integration) 。

@@@

The mode in which Reactive Streams back-pressure works can be colloquially described as "dynamic push / pull mode",
since it will switch between push and pull based back-pressure models depending on the downstream being able to cope
with the upstream production rate or not.

Reactive Streams回压工作的模式可以通俗地描述为“动态推/拉模式”，因为它将在基于推拉的回压模型之间切换，
具体取决于下游是否能够应对上游生产率或不能。

To illustrate this further let us consider both problem situations and how the back-pressure protocol handles them:

为了进一步说明这一点，让我们考虑问题情况以及回压协议如何处理它们：

### Slow Publisher, fast Subscriber
### 慢发布者，快速订阅者

This is the happy case – we do not need to slow down the Publisher in this case. However signalling rates are
rarely constant and could change at any point in time, suddenly ending up in a situation where the Subscriber is now
slower than the Publisher. In order to safeguard from these situations, the back-pressure protocol must still be enabled
during such situations, however we do not want to pay a high penalty for this safety net being enabled.

这是一个很好的例子 - 在这种情况下我们不需要减慢发布者的速度。然而，信令速率很少是恒定的，并且可能在任何时间点发生变化，
突然在订阅者现在比发布者慢的情况下结束。为了防止这些情况，在这种情况下仍然必须启用回压协议，
但是我们不希望为启用此安全功能付出高额代价。

The Reactive Streams protocol solves this by asynchronously signalling from the Subscriber to the Publisher
@scala[`Request(n:Int)`] @java[`Request(int n)`] signals. The protocol guarantees that the Publisher will never signal *more* elements than the
signalled demand. Since the Subscriber however is currently faster, it will be signalling these Request messages at a higher
rate (and possibly also batching together the demand - requesting multiple elements in one Request signal). This means
that the Publisher should not ever have to wait (be back-pressured) with publishing its incoming elements.

Reactive Streams协议通过从订阅者到发布者`Request(n：Int)`信号的异步信令来解决此问题。
该协议保证发布者永远不会发出比信号需求更多的信号。然而，由于订户当前更快，它将以更高的速率发信号通知这些请求消息
（并且还可能将需求批量聚合在一起 - 在一个请求信号中请求多个元素）。这意味着发布者不必等待（回压）发布（通知）其传入元素。

As we can see, in this scenario we effectively operate in so called push-mode since the Publisher can continue producing
elements as fast as it can, since the pending demand will be recovered just-in-time while it is emitting elements.

正如我们所看到的，在这种情况下，我们有效地在所谓的推模式下运行，因为发布者可以尽可能快地继续生成元素，
因为挂起的需求将在发送元素时及时恢复。

### Fast Publisher, slow Subscriber
### 快速发布者，慢速订阅者

This is the case when back-pressuring the `Publisher` is required, because the `Subscriber` is not able to cope with
the rate at which its upstream would like to emit data elements.

需要对`Publisher`进行回压时就是这种情况，因为`Subscriber`无法满足处理其上游要发出数据元素的速率。

Since the `Publisher` is not allowed to signal more elements than the pending demand signalled by the `Subscriber`,
it will have to abide to this back-pressure by applying one of the below strategies:

由于`Publisher`不允许发出比`Subscriber`发出的待处理请求更多的元素，因此必须通过应用以下策略之一来遵守回压协议：

 * not generate elements, if it is able to control their production rate,
 * try buffering the elements in a *bounded* manner until more demand is signalled,
 * drop elements until more demand is signalled,
 * tear down the stream if unable to apply any of the above strategies.

 * 如果能控制生产率，则不生成元素，
 * 尝试以 *有界* 的方式缓冲元素，直到发出更多需求信息，
 * 丢弃元素直到发出更多需求信息，
 * 如果无法应用上述任何策略，则拆除（以失败结束？）该流。

As we can see, this scenario effectively means that the `Subscriber` will *pull* the elements from the Publisher –
this mode of operation is referred to as pull-based back-pressure.

正如我们所看到的，这种情况有效地意味着`Subscriber`将从发布者中 *pull* 元素 - 这种操作模式称为基于拉的回压。

<a id="stream-materialization"></a>
## Stream Materialization
## 流物化

When constructing flows and graphs in Akka Streams think of them as preparing a blueprint, an execution plan.
Stream materialization is the process of taking a stream description (`RunnableGraph`) and allocating all the necessary resources
it needs in order to run. In the case of Akka Streams this often means starting up Actors which power the processing,
but is not restricted to that—it could also mean opening files or socket connections etc.—depending on what the stream needs.

在Akka Streams中构建flow和graph时，将它们视为准备蓝图，执行计划。流物化是获取流描述（`RunnableGraph`）
并分配运行所需的所有必要资源的过程。在Akka Streams的情况下，这通常意味着启动为处理提供动力的Actors，但不限于此 - 
它还可能意味着打开文件或套接字连接等 - 取决于流需要什么。

Materialization is triggered at so called "terminal operations". Most notably this includes the various forms of the `run()`
and `runWith()` methods defined on `Source` and `Flow` elements as well as a small number of special syntactic sugars for running with
well-known sinks, such as @scala[`runForeach(el => ...)`]@java[`runForeach(el -> ...)`]
(being an alias to @scala[`runWith(Sink.foreach(el => ...))`]@java[`runWith(Sink.foreach(el -> ...))`]).

物化在所谓的“终止运算符”中触发。最值得注意的的，这包括在`Source`和`Flow`元素上定义的各种形如`run()`和`runWith()`方法，
以及用于运行已知sink的少量特殊语法糖，例如：`runForeach(el => ...)`（作为`runWith(Sink.foreach(el => ...))`的别名）。

Materialization is currently performed synchronously on the materializing thread.
The actual stream processing is handled by actors started up during the streams materialization,
which will be running on the thread pools they have been configured to run on - which defaults to the dispatcher set in
`MaterializationSettings` while constructing the `ActorMaterializer`.

物化在当前物化线程上同步执行。实际的流处理由在流实现期间启动的actor处理，这些actor将在它们已配置为运行的线程池上运行 - 
默认为构造`ActorMaterializer`时在`MaterializationSettings`中设置的调度程序。

@@@ note

Reusing *instances* of linear computation operators (Source, Sink, Flow) inside composite Graphs is legal,
yet will materialize that operator multiple times.

在复合Graph中重用线性计算运算符（Source、Sink和Flow）的实例是合法的，但会多次实现该运算符。

@@@

<a id="operator-fusion"></a>
### Operator Fusion
### 运算符融合

By default, Akka Streams will fuse the stream operators. This means that the processing steps of a flow or
stream can be executed within the same Actor and has two consequences:

默认情况下，Akka Streams会融合流运算符。这意味着flow或stream的处理步骤可以在同一个Actor中执行，并有两个后果：

 * passing elements from one operator to the next is a lot faster between fused
operators due to avoiding the asynchronous messaging overhead
 * fused stream operators do not run in parallel to each other, meaning that
only up to one CPU core is used for each fused part

 * 出于避免了异步消息传递开销，因此在整合运算符之间将元素从一个运算符传递到下一个运算符要快得多
 * 整合流运算符不会彼此并行运行，这意味着每个整合部分最多只能使用一个CPU核发

To allow for parallel processing you will have to insert asynchronous boundaries manually into your flows and
operators by way of adding `Attributes.asyncBoundary` using the method `async` on `Source`, `Sink` and `Flow`
to operators that shall communicate with the downstream of the graph in an asynchronous fashion.

为了允许并行处理，你必须手动将异步边界插入flow和运算符，方法是使用`Source`、`Sink`和`Flow`上的方法`async`添加
`Attributes.asyncBoundary`，以便以异步方式与graph的下游通信。

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #flow-async }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #flow-async }

In this example we create two regions within the flow which will be executed in one Actor each—assuming that adding
and multiplying integers is an extremely costly operation this will lead to a performance gain since two CPUs can
work on the tasks in parallel. It is important to note that asynchronous boundaries are not singular places within a
flow where elements are passed asynchronously (as in other streaming libraries), but instead attributes always work
by adding information to the flow graph that has been constructed up to this point:

在这个例子中，我们在流程中创建两个区域，每个区域将在一个Actor中执行 - 假设添加和乘法是一个非常昂贵的操作，
这将导致性能提升，因为两个CPU可以并行处理任务。重要的是要注意异步边界不是异步传递元素的流中的单个位置（如在其他流式库中），
而是属性总是通过向到目前为止构造的流图添加信息来工作：

![asyncBoundary.png](../images/asyncBoundary.png)

This means that everything that is inside the red bubble will be executed by one actor and everything outside of it
by another. This scheme can be applied successively, always having one such boundary enclose the previous ones plus all
operators that have been added since then.

这意味着红色气泡内的所有内容都将由一个actor执行，之外的所有都由另一个actor执行。该方案可以连续应用，
总是有一个这样的边界包含先前的边界加上自那以后添加的所有操作符。

@@@ warning

Without fusing (i.e. up to version 2.0-M2) each stream operator had an implicit input buffer
that holds a few elements for efficiency reasons. If your flow graphs contain cycles then these buffers
may have been crucial in order to avoid deadlocks. With fusing these implicit buffers are no longer
there, data elements are passed without buffering between fused operators. In those cases where buffering
is needed in order to allow the stream to run at all, you will have to insert explicit buffers with the
`.buffer()` operator—typically a buffer of size 2 is enough to allow a feedback loop to function.

在没有融合（即2.0-M2版本之前）的情况下，每个流操作符都有一个隐式输入缓冲区，由于效率原因，它包含少量元素。
如果你的流程图包含循环，那么这些缓冲区可能是至关重要的，以避免死锁。通过融合这些隐式缓冲区不再存在，
传递数据元素而不在融合运算符之间进行缓冲。在需要缓冲以便允许流运行的情况下，你必须使用`.buffer()`运算符插入显式缓冲区 - 
通常，大小为2的缓冲区足以允许反馈循环起作用。

@@@

<a id="flow-combine-mat"></a>
### Combining materialized values
### 合并物化值

Since every operator in Akka Streams can provide a materialized value after being materialized, it is necessary
to somehow express how these values should be composed to a final value when we plug these operators together. For this,
many operator methods have variants that take an additional argument, a function, that will be used to combine the
resulting values. Some examples of using these combiners are illustrated in the example below.

由于Akka Streams中的每个运算符在物化后都可以提供物化值，因此当我们将这些运算符插入到一起时，
有必要以某种方式表达如何将这些值组合成最终值。为此，许多运算符方法都有变量，这些变量带有一个额外的参数，一个函数，
用于组合结果值。使用这些组合器的一些示例在下面的示例中说明。

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #flow-mat-combine }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #flow-mat-combine }

@@@ note

In Graphs it is possible to access the materialized value from inside the stream. For details see @ref:[Accessing the materialized value inside the Graph](stream-graphs.md#graph-matvalue).

@@@

### Source pre-materialization
### 源的预先物化

There are situations in which you require a `Source` materialized value **before** the `Source` gets hooked up to the rest of the graph.
This is particularly useful in the case of "materialized value powered" `Source`s, like `Source.queue`, `Source.actorRef` or `Source.maybe`.

在`Source`连接到图的其余部分 **之前**，有些情况下需要`Source`已物化值。这在“物化值驱动的”`Source`的情况下特别有用，
例如`Source.queue`，`Source.actorRef`或`Source.maybe`。

By using the `preMaterialize` operator on a `Source`, you can obtain its materialized value and another `Source`. The latter can be used
to consume messages from the original `Source`. Note that this can be materialized multiple times.

通过在`Source`上使用`preMaterialize`运算符，你可以获取其物化值和另一个`Source`。后者可用于使用原始`Source`中的消息。
请注意，这可以多次被物化。

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #source-prematerialization }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #source-prematerialization }

## Stream ordering
## 流的顺序

In Akka Streams almost all computation operators *preserve input order* of elements. This means that if inputs `{IA1,IA2,...,IAn}`
"cause" outputs `{OA1,OA2,...,OAk}` and inputs `{IB1,IB2,...,IBm}` "cause" outputs `{OB1,OB2,...,OBl}` and all of
`IAi` happened before all `IBi` then `OAi` happens before `OBi`.

在Akka Streams中，几乎所有计算运算符都保留了元素的输入顺序。这意味着如果输入`{IA1，IA2，...，IAn}`“导致”输出
`{OA1，OA2，...，OAk}`和`输入{IB1，IB2，...，IBm}`“导致”输出`{OB1 ，OB2，...，OBl}`以及所有`IAi`都发生在所有`IBi`之前，
然后`OAi`发生在`OBi`之前。

This property is even upheld by async operations such as `mapAsync`, however an unordered version exists
called `mapAsyncUnordered` which does not preserve this ordering.

这个属性甚至可以通过`mapAsync`之类的异步操作来支持，但是存在一个名为`mapAsyncUnordered`的无序版本，它不保留这种排序。

However, in the case of Junctions which handle multiple input streams (e.g. `Merge`) the output order is,
in general, *not defined* for elements arriving on different input ports. That is a merge-like operation may emit `Ai`
before emitting `Bi`, and it is up to its internal logic to decide the order of emitted elements. Specialized elements
such as `Zip` however *do guarantee* their outputs order, as each output element depends on all upstream elements having
been signalled already – thus the ordering in the case of zipping is defined by this property.

然而，在处理多个输入流（例如`Merge`）的Junction的情况下，元素到达不同输入端口的顺序是 **未定义** 的。类似合并的操作，
可以在发射`Bi`之前发射`Ai`，并且由内部逻辑决定发射元素的顺序。然而，诸如`Zip`的专用元素确保它们的输出顺序，
因为每个输出元素依赖于已经发出信号通知的所有上游元素 - 因此在压缩（zipping）的情况下的排序由该属性定义。

If you find yourself in need of fine grained control over order of emitted elements in fan-in
scenarios consider using `MergePreferred`, `MergePrioritized` or @ref[`GraphStage`](stream-customize.md) – which gives you full control over how the
merge is performed.

如果你发现自己需要对扇入场景中发出的元素的顺序进行细粒度控制，请考虑使用`MergePreferred`，`MergePrioritized`或
@ref:[`GraphStage`](stream-customize.md)  - 这使你可以完全控制合并的执行方式。

## Actor Materializer Lifecycle
## Actor Materializer生命周期

An important aspect of working with streams and actors is understanding an `ActorMaterializer`'s life-cycle.
The materializer is bound to the lifecycle of the `ActorRefFactory` it is created from, which in practice will
be either an `ActorSystem` or `ActorContext` (when the materializer is created within an `Actor`).

使用stream和actor的一个重要方面是理解`ActorMaterializer`的生命周期。
materializer绑定到它创建的`ActorRefFactory`的生命周期，实际上它将是`ActorSystem`或`ActorContext`
（当在actor中创建materializer时）。

The usual way of creating an `ActorMaterializer` is to create it next to your `ActorSystem`,
which likely is in a "main" class of your application:

创建`ActorMaterializer`的常用方法是在`ActorSystem`旁边创建它，它可能位于应用程序的“主”类中：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #materializer-from-system }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #materializer-from-system }

In this case the streams run by the materializer will run until it is shut down. When the materializer is shut down
*before* the streams have run to completion, they will be terminated abruptly. This is a little different than the
usual way to terminate streams, which is by cancelling/completing them. The stream lifecycles are bound to the materializer
like this to prevent leaks, and in normal operations you should not rely on the mechanism and rather use `KillSwitch` or
normal completion signals to manage the lifecycles of your streams.  

在这种情况下，由materializer运行的流将一直运行直到它关闭。当materializer在流完成之前关闭时，它们将突然终止。
这与通过取消/完成它们终止流的通常方式略有不同。流生命周期与这样的materializer绑定以防止泄漏。并且在正常操作中，
你不应该依赖于该机制，而是使用`KillSwitch`或正常完成信号来管理流的生命周期。

If we look at the following example, where we create the `ActorMaterializer` within an `Actor`:

如果我们看一下以下示例，我们在`Actor`中创建`ActorMaterializer`：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #materializer-from-actor-context }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #materializer-from-actor-context }

In the above example we used the `ActorContext` to create the materializer. This binds its lifecycle to the surrounding `Actor`. In other words, while the stream we started there would under normal circumstances run forever, if we stop the Actor it would terminate the stream as well. We have *bound the stream's lifecycle to the surrounding actor's lifecycle*.
This is a very useful technique if the stream is closely related to the actor, e.g. when the actor represents a user or other entity, that we continuously query using the created stream -- and it would not make sense to keep the stream alive when the actor has terminated already. The streams termination will be signalled by an "Abrupt termination exception" signaled by the stream.

在上面的例子中，我们使用`ActorContext`来创建materializer。这将其生命周期与外围的Actor绑定在一起。换句话说，
虽然我们在那里开始的流将在正常情况下永远运行，但如果我们停止Actor它也会终止流。我们将流的生命周期限制在外围的actor的生命周期中。
如果流与演员密切相关时，这将是非常有用的技术。当actor代表一个用户或其他实体时，我们不断使用创建的流进行查询 - 
当actor已经终止时保持流存活是没有意义的。流将由流发出的“突然终止异常”发出信号来终止。

You may also cause an `ActorMaterializer` to shut down by explicitly calling `shutdown()` on it, resulting in abruptly terminating all of the streams it has been running then. 

你还可以通过在其上显式调用`shutdown()`来关闭`ActorMaterializer`，从而导致突然终止它一直运行的所有流。

Sometimes, however, you may want to explicitly create a stream that will out-last the actor's life.
For example, you are using an Akka stream to push some large stream of data to an external service.
You may want to eagerly stop the Actor since it has performed all of its duties already:

但是，有时你可能希望显式创建一个超出演员生命的流。例如，你正在使用Akka流将一些大型数据流推送到外部服务。
你可能想要急切地停止Actor，因为它已经履行了所有职责：

Scala
:   @@snip [FlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/FlowDocSpec.scala) { #materializer-from-system-in-actor }

Java
:   @@snip [FlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/FlowDocTest.java) { #materializer-from-system-in-actor }

In the above example we pass in a materializer to the Actor, which results in binding its lifecycle to the entire `ActorSystem` rather than the single enclosing actor. This can be useful if you want to share a materializer or group streams into specific materializers,
for example because of the materializer's settings etc.

在上面的例子中，我们将一个materializer传递给Actor，这导致将其生命周期绑定到整个`ActorSystem`而不是单个封闭的actor。
如果要将materializer程序或组流共享到特定的materializers中，例如由于materializer设置等，这可能很有用。

@@@ warning

Do not create new actor materializers inside actors by passing the `context.system` to it. 
This will cause a new `ActorMaterializer` to be created and potentially leaked (unless you shut it down explicitly) for each such actor.
It is instead recommended to either pass-in the Materializer or create one using the actor's `context`.

不要在actor内部通过将`context.system`传递给actor materializers来创建它。
这将导致为每个这样的actor创建一个新的`ActorMaterializer`并可能泄露（除非你明确地将其关闭）。
相反，建议传入Materializer或使用actor的`context`创建一个。

@@@
