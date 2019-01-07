# Design Principles behind Akka Streams
# Akka Streams背后的设计原则

It took quite a while until we were reasonably happy with the look and feel of the API and the architecture of the implementation, and while being guided by intuition the design phase was very much exploratory research. This section details the findings and codifies them into a set of principles that have emerged during the process.

我们在直觉的指导下花了很长一段时间才对API的观感以及实现的架构感到相当满意，设计是非常探索性的研究阶段。
本节详细介绍了调研结果，并将其编入了一系列在此过程中出现的原则。

@@@ note

As detailed in the introduction keep in mind that the Akka Streams API is completely decoupled from the Reactive Streams interfaces which are an implementation detail for how to pass stream data between individual operators.

如引言所述，请记住，Akka Streams API与Reactive Streams接口完全分享，后者是如何在各个去处符之间传递流式数据的实现细节。

@@@

## What shall users of Akka Streams expect?
## Akka Streams的用户会期待什么？

Akka is built upon a conscious decision to offer APIs that are minimal and consistent—as opposed to easy or intuitive. The credo is that we favor explicitness over magic, and if we provide a feature then it must work always, no exceptions. Another way to say this is that we minimize the number of rules a user has to learn instead of trying to keep the rules close to what we think users might expect.

Akka建立时，在有意识地决定提供最小和一致的API——而不是简单或直观。我们的信箱是，我们倾向于明确而非魔术。
如果我们提供一个特性，那么它必须始终有效，没有例外。另一种说法是，我们最大限度地减少用户必须学习的规则数量，
而不是试图使规则接近我们认为用户可能期望的规则。

From this follows that the principles implemented by Akka Streams are:

由此可见，Akka Streams实施的原则是：

 * all features are explicit in the API, no magic
 * supreme compositionality: combined pieces retain the function of each part
 * exhaustive model of the domain of distributed bounded stream processing

 * 所有功能都在API中明确，没有魔力
 * 最高的组合性：组合部件保留了每个部件的功能
 * 分布式有界流处理领域的详尽模型

This means that we provide all the tools necessary to express any stream processing topology, that we model all the essential aspects of this domain (back-pressure, buffering, transformations, failure recovery, etc.) and that whatever the user builds is reusable in a larger context.

这意味着我们提供表达任何流处理拓扑所需的所有工具，我们为该领域的所有基本方面建模（回压，缓冲，转换，故障恢复等），
无论用户构建的是什么，都可以在更大的背景下重用。

### Akka Streams does not send dropped stream elements to the dead letter office
### Akka Streams不会将丢弃的流元素发送到dead letter办公室（office）

One important consequence of offering only features that can be relied upon is the restriction that Akka Streams cannot ensure that all objects sent through a processing topology will be processed. Elements can be dropped for a number of reasons:

仅提供可依赖的功能的一个重要限制结果是Akka Streams无法确保处理通过处理拓扑发送的所有对象。
可能丢失（dropped）元素的原因有很多：

 * plain user code can consume one element in a *map(...)* operator and produce an entirely different one as its result
 * common stream operators drop elements intentionally, e.g. take/drop/filter/conflate/buffer/…
 * stream failure will tear down the stream without waiting for processing to finish, all elements that are in flight will be discarded
 * stream cancellation will propagate upstream (e.g. from a *take* operator) leading to upstream processing steps being terminated without having processed all of their inputs

 * 普通用户代码可以使用 *map(...)* 运算符的一个元素，并生成一个完全不同的元素作为结果
 * 公共流运算符有意地丢弃元素，例如：`take/drop/filter/conflate/buffer/...`
 * 流故障将在不等待处理完成的情况下拆除流，所有正在运行的元素都将被丢弃
 * 流取消将向上游传播（如何：*take* 运算符），导致上游处理步骤终止而不处理它们的所有输入

This means that sending JVM objects into a stream that need to be cleaned up will require the user to ensure that this happens outside of the Akka Streams facilities (e.g. by cleaning them up after a timeout or when their results are observed on the stream output, or by using other means like finalizers etc.).

这意味着将JVM对象发送到需要清理的流中将要求用户确保在Akka Streams工具之外发生这种情况（例如，在超时后清除它们或在流输出上观察到它们的结果时，或者使用其他手段，如finalizers等）。

### Resulting Implementation Constraints
### 产生的实现约束

Compositionality entails reusability of partial stream topologies, which led us to the lifted approach of describing data flows as (partial) graphs that can act as composite sources, flows (a.k.a. pipes) and sinks of data. These building blocks shall then be freely shareable, with the ability to combine them freely to form larger graphs. The representation of these pieces must therefore be an immutable blueprint that is materialized in an explicit step in order to start the stream processing. The resulting stream processing engine is then also immutable in the sense of having a fixed topology that is prescribed by the blueprint. Dynamic networks need to be modeled by explicitly using the Reactive Streams interfaces for plugging different engines together.

组合性需要部分流拓扑的可重用性，这导致我们将数据流描述为（部分）图形的提升方法可以充当复合source，flow（管道）和数据sink。
然后，这些构建块可以自由共享，并能够自由组合它们以形成更大的图形。因此，这些部分的表示必须是一个不可变的蓝图，
它在明确的步骤中物化，以便开始流处理。然后，在具有由蓝图规定的固定拓扑的意义上，所得到的流处理引擎也是不可变的。动态网络需要通过显式使用Reactive Streams接口将不同引擎连接在一起来建模。

The process of materialization will often create specific objects that are useful to interact with the processing engine once it is running, for example for shutting it down or for extracting metrics. This means that the materialization function produces a result termed the *materialized value of a graph*.

实现过程通常会创建特定的对象，这些对象在处理引擎运行后可以与处理引擎进行交互，例如用于关闭处理引擎或提取指标。
这意味着实现功能产生称为 *图的物化值* 的结果。

## Interoperation with other Reactive Streams implementations
## 与其它Reactive Streams实现的互操作

Akka Streams fully implement the Reactive Streams specification and interoperate with all other conformant implementations. We chose to completely separate the Reactive Streams interfaces from the user-level API because we regard them to be an SPI that is not targeted at endusers. In order to obtain a `Publisher` or `Subscriber` from an Akka Stream topology, a corresponding `Sink.asPublisher` or `Source.asSubscriber` element must be used.

Akka Streams完整的实现了Reactive Streams规范，并可与所有其它符合要求的实现进行互操作。因为我们认为它们不是一个针对最终用户的SPI，
所以我们选择将Reactive Streams接口与用户级API完全分开。为了从Akka Streams拓扑获取`Publisher`和`Subscriber`，
必须使用相应的`Sink.asPublisher`或者`Source.asSubscriber`。

All stream Processors produced by the default materialization of Akka Streams are restricted to having a single Subscriber, additional Subscribers will be rejected. The reason for this is that the stream topologies described using our DSL never require fan-out behavior from the Publisher sides of the elements, all fan-out is done using explicit elements like `Broadcast[T]`.

由Akka Streams的默认实现生成的所有流处理器仅限于拥有一个订阅者，其他订阅者将被拒绝。
这样做的原因是使用我们的DSL描述的流拓扑从不需要来自元素的发布者端的扇出行为，所有扇出都是使用诸如
`Broadcast[T]`之类的显式元素完成的。

This means that `Sink.asPublisher(true)` (for enabling fan-out support) must be used where broadcast behavior is needed for interoperation with other Reactive Streams implementations.

这意味着必须使用`Sink.asPublisher(true)`（用于启用扇出支持），其中需要广播行为以与其他Reactive Streams实现进行互操作。

### Rationale and benefits from Sink/Source/Flow not directly extending Reactive Streams interfaces
### 不直接扩展Reactive Streams接口实现 Sink/Source/Flow 的原理与优势

A sometimes overlooked crucial piece of information about [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/) is that they are a [Service Provider Interface](https://en.m.wikipedia.org/wiki/Service_provider_interface), as explained in depth in one of the [early discussions](https://github.com/reactive-streams/reactive-streams-jvm/pull/25) about the specification.
Akka Streams was designed during the development of Reactive Streams, so they both heavily influenced one another.

关于 [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/) 的有时被忽视的关键信息是它是服务提供者接口，
正如在关于规范的早期讨论 [之一](https://github.com/reactive-streams/reactive-streams-jvm/pull/25) 中深入解释的那样。
Akka Streams是在Reactive Streams的开发过程中设计的，所以它们都相互影响很大。

It may be enlightening to learn that even within the Reactive Specification the types had initially attempted to hide `Publisher`, `Subscriber` and the other SPI types from users of the API.
Though since those internal SPI types would end up surfacing to end users of the standard in some cases, it was decided to [remove the API types, and only keep the SPI types](https://github.com/reactive-streams/reactive-streams-jvm/pull/25) which are the `Publisher`, `Subscriber` et al.

了解即使在Reactive Specification中，类型最初也试图隐藏来自API用户的`Publisher`，`Subscriber`和其他SPI类型，
这可能很有启发性。虽然在某些情况下，由于那些内部SPI类型最终会出现给标准的最终用户，但决定删除API类型，并且只保留
`Publisher`，`Subscriber`等的SPI类型。

With this historical knowledge and context about the purpose of the standard – being an internal detail of interoperable libraries - we can with certainty say that it can't be really said that an direct _inheritance_ relationship with these types can be considered some form of advantage or meaningful differentiator between libraries.
Rather, it could be seen that APIs which expose those SPI types to end-users are leaking internal implementation details accidentally. 

有了这个标准目的的历史知识和背景 - 作为可互操作库的内部细节 - 我们可以肯定地说，
不能真正说这些类型的直接继承关系可以被认为是某种形式的优势或库之间有意义的区别。相反，可以看出，
向最终用户公开这些SPI类型的API会意外泄露内部实现细节。

The `Source`, `Sink` and `Flow` types which are part of Akka Streams have the purpose of providing the fluent DSL, as well as to be "factories" for running those streams.
Their direct counterparts in Reactive Streams are, respectively, `Publisher`, `Subscriber` and `Processor`. 
In other words, Akka Streams operate on a lifted representation of the computing graph,
which then is materialized and executed in accordance to Reactive Streams rules. This also allows Akka Streams to perform optimizations like fusing and dispatcher configuration during the materialization step.

作为Akka Streams一部分的`Source`、`Sink`和`Flow`类型的目的是提供流畅的DSL，以及成为运行这些流的“工厂”。
他们在Reactive Streams中的直接对应物分别是`Publisher`，`Subscriber`和`Processor`。换句话说，
Akka Streams对计算图形的提升表示进行操作，然后根据Reactive Streams规则实现并执行。
这也允许Akka Streams在实现步骤期间执行优化，如融合和调度程序配置。

Another not obvious gain from hiding the Reactive Streams interfaces comes from the fact that `org.reactivestreams.Subscriber` (et al) have now been included in Java 9+, and thus become part of Java itself, so libraries should migrate to using the `java.util.concurrent.Flow.Subscriber` instead of `org.reactivestreams.Subscriber`.
Libraries which selected to expose and directly extend the Reactive Streams types will now have a tougher time to adapt the JDK9+ types -- all their classes that extend Subscriber and friends will need to be copied or changed to extend the exact same interface,
but from a different package. In Akka we simply expose the new type when asked to -- already supporting JDK9 types, from the day JDK9 was released.

从隐藏无流接口的另一个不明显收益来自于事实，`org.reactivestreams.Subscriber`（等）现已列入Java 9+，
因而成为Java本身的一部分，所以库应该迁移到使用`java.util.concurrent.Flow.Subscriber`而不是`org.reactivestreams.Subscriber`。
其中选择揭露和直接延长无流类型的库现在有一个艰难的时期，以适应JDK 9+类型 - 他们所有的类，
扩展用户和朋友将需要复制或改变以延长完全相同的接口，但是从不同包。在Akka中，我们只是在被要求时公开新类型 - 
从JDK 9发布之日起就已经支持JDK 9类型了。

The other, and perhaps more important reason for hiding the Reactive streams interfaces comes back to the first points of this explanation: the fact of Reactive Streams being an SPI, and as such is hard to "get right" in ad-hoc implementations. Thus Akka Streams discourages, the use of the hard to implement pieces of the underlying infrastructure, and offers simpler, more type-safe, yet more powerful abstractions for users to work with: GraphStages and operators. It is of course still (and easily) possible to accept or obtain Reactive Streams (or JDK+ Flow) representations of the stream operators by using methods like `asPublisher` or `fromSubscriber`.

隐藏Reactive流接口的另一个也许更重要的原因可以追溯到这个解释的第一点：Reactive Streams是一个SPI的事实，
因此很难在ad-hoc实现中“正确”。因此，Akka Streams不鼓励使用难以实现的底层基础架构，并为用户提供更简单，
更类型安全且更强大的抽象：`GraphStages`和运算符（operators）。当然，通过使用`asPublisher`或`fromSubscriber`等方法，
仍然（并且很容易）接受或获得流运算符的Reactive Streams（或JDK + Flow）表示。

## What shall users of streaming libraries expect?
## streaming库的用户期望什么？

We expect libraries to be built on top of Akka Streams, in fact Akka HTTP is one such example that lives within the Akka project itself. In order to allow users to profit from the principles that are described for Akka Streams above, the following rules are established:

我们希望（用户）库建立在Akka Streams之上，事实上Akka HTTP就是这样一个例子，它存在于Akka项目中。
为了使用户能够从上面针对Akka Streams描述的原则中获益，建立了以下规则：

 * libraries shall provide their users with reusable pieces, i.e. expose factories that return operators, allowing full compositionality
 * libraries may optionally and additionally provide facilities that consume and materialize operators

 * 库应为其用户提供可重复使用的部分，即暴露返回operator的工厂，从而实现完全的组合性
 * 库可以选择性地和其它地提供消费和实现运算符的设施
 
The reasoning behind the first rule is that compositionality would be destroyed if different libraries only accepted operators and expected to materialize them: using two of these together would be impossible because materialization can only happen once. As a consequence, the functionality of a library must be expressed such that materialization can be done by the user, outside of the library’s control.

第一条规则背后的原因是，如果不同的库只接受运算符并且期望实现它们，那么组合性就会被破坏：使用其中两个是不可能的，
因为实现只能发生一次。因此，必须表达库的功能，以便用户可以在库的控制之外完成实现。

The second rule allows a library to additionally provide nice sugar for the common case, an example of which is the Akka HTTP API that provides a `handleWith` method for convenient materialization.

第二个规则允许库为常见情况额外提供好的语法糖，其中一个例子是Akka HTTP API，它提供了`handleWith`方法以便于实现。

@@@ note

One important consequence of this is that a reusable flow description cannot be bound to “live” resources, any connection to or allocation of such resources must be deferred until materialization time. Examples of “live” resources are already existing TCP connections, a multicast Publisher, etc.; a TickSource does not fall into this category if its timer is created only upon materialization (as is the case for our implementation).

这样做的一个重要结果是，可重用的flow描述不能绑定到“实时”资源，这些资源的任何连接或分配必须推迟到实现时。
“实时”资源的示例是已经存在的TCP连接，多播Publisher等; 如果只在实现时创建了计时器，则TickSource不属于此类别（就我们的实现而言）。

Exceptions from this need to be well-justified and carefully documented.

这种例外需要充分证明并仔细记录。

@@@

### Resulting Implementation Constraints
### 产生的实现约束

Akka Streams must enable a library to express any stream processing utility in terms of immutable blueprints. The most common building blocks are

Akka Streams必须使库能够根据不可变蓝图表达任何流处理实用程序。最常见的构建块是

 * Source: something with exactly one output stream
 * Sink: something with exactly one input stream
 * Flow: something with exactly one input and one output stream
 * BidiFlow: something with exactly two input streams and two output streams that conceptually behave like two Flows of opposite direction
 * Graph: a packaged stream processing topology that exposes a certain set of input and output ports, characterized by an object of type `Shape`.

 * Source：只有一个输出流
 * Sink：只有一个输入流
 * Flow：只有一个输入和输出流
 * BidiFlow：具有两个输入和两个转出流，其概念上表现为两个相反方向的流
 * Graph：一种打包的流处理拓扑，它（分别）公开一组输入和输出端口，其特征是`Shape`类型的对象

@@@ note

A source that emits a stream of streams is still a normal Source, the kind of elements that are produced does not play a role in the static stream topology that is being expressed.

发出流的source仍然是普通的source，生成的元素类型在正在表达的静态流拓扑中不起作用。

@@@

## The difference between Error and Failure
## 错误和失败的区别

The starting point for this discussion is the [definition given by the Reactive Manifesto](http://www.reactivemanifesto.org/glossary#Failure). Translated to streams this means that an error is accessible within the stream as a normal data element, while a failure means that the stream itself has failed and is collapsing. In concrete terms, on the Reactive Streams interface level data elements (including errors) are signaled via `onNext` while failures raise the `onError` signal.

本讨论的出发点是 [“反应宣言”给出的定义](http://www.reactivemanifesto.org/glossary#Failure) 。
转换为流这意味着可以在流中将错误（error）作为普通数据元素访问，而失败（failure）意味着流本身已经失败并且正在崩溃。
具体而言，在Reactive Streams接口级别，数据元素（包括错误）通过`onNext`发出信号，而故障则会引发`onError`信号。

@@@ note

Unfortunately the method name for signaling *failure* to a Subscriber is called `onError` for historical reasons. Always keep in mind that the Reactive Streams interfaces (Publisher/Subscription/Subscriber) are modeling the low-level infrastructure for passing streams between execution units, and errors on this level are precisely the failures that we are talking about on the higher level that is modeled by Akka Streams.

遗憾的是，出于历史原因，将用于发信号通知订阅服务器 *失败（failure）* 的方法名称称为`onError`。始终记住，
Reactive Streams接口（Publisher/Subscription/Subscriber）正在为执行单元之间传递流的低级基础结构建模，
而这个级别的错误正是我们在更高级别上讨论的失败。由Akka Streams建模。

@@@

There is only limited support for treating `onError` in Akka Streams compared to the operators that are available for the transformation of data elements, which is intentional in the spirit of the previous paragraph. Since `onError` signals that the stream is collapsing, its ordering semantics are not the same as for stream completion: transformation operators of any kind will collapse with the stream, possibly still holding elements in implicit or explicit buffers. This means that data elements emitted before a failure can still be lost if the `onError` overtakes them.

与可用于转换数据元素的运算符相比，在Akka Streams中处理`onError`的支持有限，这在前一段的精神中是有意的。
由于onError信号表示流正在折叠，因此它的排序语义与流完成不同：任何类型的转换运算符都将与流一起崩溃，
可能仍然在隐式或显式缓冲区中保存元素。这意味着如果`onError`超过它们，则在失败之前发出的数据元素仍然可能丢失。

The ability for failures to propagate faster than data elements is essential for tearing down streams that are back-pressured—especially since back-pressure can be the failure mode (e.g. by tripping upstream buffers which then abort because they cannot do anything else; or if a dead-lock occurred).

故障传播速度比数据元素快的能力对于拆除反压流是必不可少的 - 特别是因为回压可以是故障模式（例如，
通过跳闸上游缓冲区然后中止，因为它们不能做任何其他事情；或者如果发生死锁）。

### The semantics of stream recovery
### stream恢复语义

A recovery element (i.e. any transformation that absorbs an `onError` signal and turns that into possibly more data elements followed normal stream completion) acts as a bulkhead that confines a stream collapse to a given region of the stream topology. Within the collapsed region buffered elements may be lost, but the outside is not affected by the failure.

恢复元素（即，吸收`onError`信号并且在正常流完成之后将其转换为可能更多数据元素的任何变换）充当将流折叠限制到流拓扑的给定区域的隔板。
在折叠区域内，缓冲元素可能会丢失，但外部不会受到故障的影响。

This works in the same fashion as a `try`–`catch` expression: it marks a region in which exceptions are caught, but the exact amount of code that was skipped within this region in case of a failure might not be known precisely—the placement of statements matters.

这与`try` - `catch`表达式的工作方式相同：它标记了一个捕获异常的区域，
但在发生故障时在此区域内跳过的确切代码量可能无法准确知道 - 语句的位置事项。
