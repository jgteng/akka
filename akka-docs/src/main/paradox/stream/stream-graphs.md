# Working with Graphs
# 使用Graph工作

## Dependency
## 依赖

To use Akka Streams, add the module to your project:

要使用Akka Streams，将模块添加到你的项目：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-stream_$scala.binary_version$"
  version="$akka.version$"
}

## Introduction
## 介绍

In Akka Streams computation graphs are not expressed using a fluent DSL like linear computations are, instead they are
written in a more graph-resembling DSL which aims to make translating graph drawings (e.g. from notes taken
from design discussions, or illustrations in protocol specifications) to and from code simpler. In this section we'll
dive into the multiple ways of constructing and re-using graphs, as well as explain common pitfalls and how to avoid them.

在Akka Streams中，计算图（computation graphs）不是使用流畅的DSL表示，如线性计算，而是使用更类似图形（graph-resembling）的DSL编写，
旨在翻译graph图形（例如：从设计讨论中获取的注释或协议规范中的插图）到代码更简单。在本节中，我们将深入探讨构建和重用graph
的多种方法，并解释常见的陷阱以及如何避免它们。

Graphs are needed whenever you want to perform any kind of fan-in ("multiple inputs") or fan-out ("multiple outputs") operations.
Considering linear Flows to be like roads, we can picture graph operations as junctions: multiple flows being connected at a single point.
Some operators which are common enough and fit the linear style of Flows, such as `concat` (which concatenates two
streams, such that the second one is consumed after the first one has completed), may have shorthand methods defined on
`Flow` or `Source` themselves, however you should keep in mind that those are also implemented as graph junctions.

每当您想要执行任何类型的扇入（“多输入”）或扇出（“多输出”）操作时，都需要graph。考虑到线性flow就像道路一样，
我们可以将图形操作描绘为交汇点（junctions）：在单个点连接多个flow。一些足够通用且符合`Flow`的线性样式的运算符，
例如`concat`（连接两个stream，使得第二个流在第一个流完成后消耗），可能具有在`Flow`或`Source`本身上定义的简写方法，
但是你应该记住那些也被实现为graph连接（junctions）。

<a id="graph-dsl"></a>
## Constructing Graphs
## 构造Graph

Graphs are built from simple Flows which serve as the linear connections within the graphs as well as junctions
which serve as fan-in and fan-out points for Flows. Thanks to the junctions having meaningful types based on their behavior
and making them explicit elements these elements should be rather straightforward to use.

Graph由简单的Flows构成，这些Flow用作graph中的线性连接以及用作Flow的扇入和扇出点的连接点。
由于连接点具有基于其行为的有意义类型并使它们成为显式元素，因此这些元素应该相当简单易用。

Akka Streams currently provide these junctions (for a detailed list see the @ref[operator index](operators/index.md)):

Akka Streams目前提供这些联结（有关详细列表，请参阅 @ref:[运算符索引](operators/index.md) ）：

 * **Fan-out**

    * @scala[`Broadcast[T]`]@java[`Broadcast<T>`] – *(1 input, N outputs)* given an input element emits to each output
    * @scala[`Balance[T]`]@java[`Balance<T>`] – *(1 input, N outputs)* given an input element emits to one of its output ports
    * @scala[`UnzipWith[In,A,B,...]`]@java[`UnzipWith<In,A,B,...>`] – *(1 input, N outputs)* takes a function of 1 input that given a value for each input emits N output elements (where N <= 20)
    * @scala[`UnZip[A,B]`]@java[`UnZip<A,B>`] – *(1 input, 2 outputs)* splits a stream of @scala[`(A,B)`]@java[`Pair<A,B>`] tuples into two streams, one of type `A` and one of type `B`

    * `Broadcast[T]` - *(1个输入，N个输出)* 给定输入元素发射到每个输出
    * `Balance[T]` - *(1个输入，N个输出)* 给定输入元素发射到输出端口之一
    * `UnzipWith[In, A, B, ...]` - *(1个输入，N个输出)* 取1个输入的函数，给定每个输入的值发射到N个输出元素（其中N < 20）
    * `Unzip[A, B]` - *(1个输入，2个输出)* 将`(A, B)`元组分割成两个流，一个是类型`A`，一个是类型`B`

 * **Fan-in**

    * @scala[`Merge[In]`]@java[`Merge<In>`] – *(N inputs , 1 output)* picks randomly from inputs pushing them one by one to its output
    * @scala[`MergePreferred[In]`]@java[`MergePreferred<In>`] – like `Merge` but if elements are available on `preferred` port, it picks from it, otherwise randomly from `others`
    * @scala[`MergePrioritized[In]`]@java[`MergePrioritized<In>`] – like `Merge` but if elements are available on all input ports, it picks from them randomly based on their `priority`
    * @scala[`MergeLatest[In]`]@java[`MergeLatest<In>`] – *(N inputs, 1 output)* emits `List[In]`, when i-th input stream emits element, then i-th element in emitted list is updated
    * @scala[`ZipWith[A,B,...,Out]`]@java[`ZipWith<A,B,...,Out>`] – *(N inputs, 1 output)* which takes a function of N inputs that given a value for each input emits 1 output element
    * @scala[`Zip[A,B]`]@java[`Zip<A,B>`] – *(2 inputs, 1 output)* is a `ZipWith` specialised to zipping input streams of `A` and `B` into a @scala[`(A,B)`]@java[`Pair(A,B)`] tuple stream
    * @scala[`Concat[A]`]@java[`Concat<A>`] – *(2 inputs, 1 output)* concatenates two streams (first consume one, then the second one)
    
    * `Merge[In]` - *(N个输入，1个输出)* 从输入中随机选取它们并逐个推关到其输出
    * `MergePreferred[In]` - 与`Merge`类似，但如果元素在首先端口上可用，则从中选择，否则从其它端口随机选择
    * `MergePrioritized[In]` - 与`Merge`类似，但如果元素在所有端口上可用，它会根据优先级随机选择它们
    * `MergeLatest[In]` - *(N个输入，1个输出)* 发射`List[In]`，当第i个元素在所有输入端口上都可用，它会根据优先级随机选择它们
    * `ZipWith[A, B, ..., Out]` - *(N个输入，1个输出)* 取N个输入的函数，给出每个输入的值，发出一个输出元素
    * `Zip[A, B]` *(2个输入，1个输出)* 是一个`ZipWith`，专门用于将`A`和`B`的输入流压缩成`(A, B)`元组流
    * `Concat[A]` - *(2个输入，1个转出)* 连接两个流（首先消费一个流，然后消费第二个流）

One of the goals of the GraphDSL DSL is to look similar to how one would draw a graph on a whiteboard, so that it is
simple to translate a design from whiteboard to code and be able to relate those two. Let's illustrate this by translating
the below hand drawn graph into Akka Streams:

GraphDSL DSL的目标之一是看起来与在白板上绘制图形的方式类似，因此将设计从白板转换为代码并且能够将这两者联系起来很简单。
让我们通过将下面的手绘图转换成Akka Streams来说明这一点：

![simple-graph-example.png](../images/simple-graph-example.png)

Such graph is simple to translate to the Graph DSL since each linear element corresponds to a `Flow`,
and each circle corresponds to either a `Junction` or a `Source` or `Sink` if it is beginning
or ending a `Flow`. @scala[Junctions must always be created with defined type parameters, as otherwise the `Nothing` type
will be inferred.]

这样的图很容易转换为Graph DSL，因为每个线性元素对应一个`Flow`，并且每个圆对应于`Junction`或`Source`或`Sink`，
如果它是开始或结束`Flow`。必须始终使用定义的类型参数创建连接，否则将推断出`Nothing`类型。

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #simple-graph-dsl }

Java
:   @@snip [GraphDSLTest.java](/akka-stream-tests/src/test/java/akka/stream/javadsl/GraphDslTest.java) { #simple-graph-dsl }

@@@ note

Junction *reference equality* defines *graph node equality* (i.e. the same merge *instance* used in a GraphDSL
refers to the same location in the resulting graph).

连接 *引用相等* 定义了 *图节点相等* （即，GraphDSL中使用的相同合并 *实例* 指的是结果图中的相同位置）。

@@@

@scala[Notice the `import GraphDSL.Implicits._` which brings into scope the `~>` operator (read as "edge", "via" or "to")
and its inverted counterpart `<~` (for noting down flows in the opposite direction where appropriate).]

注意导入的`GraphDSL.Implicits._`，它将`~>`运算符（读作“edge”，“via”或“to”）及其倒置对应物`<~`
（在适当的情况下注意向下流向相反方向）引入范围。

By looking at the snippets above, it should be apparent that the @scala[`GraphDSL.Builder`]@java[`builder`] object is *mutable*.
@scala[It is used (implicitly) by the `~>` operator, also making it a mutable operation as well.]
The reason for this design choice is to enable simpler creation of complex graphs, which may even contain cycles.
Once the GraphDSL has been constructed though, the @scala[`GraphDSL`]@java[`RunnableGraph`] instance *is immutable, thread-safe, and freely shareable*.
The same is true of all operators—sources, sinks, and flows—once they are constructed.
This means that you can safely re-use one given Flow or junction in multiple places in a processing graph.

通过查看上面的代码片段，显然`GraphDSL.Builder`对象是 *可变* 的。它由（隐式）由`~>`运算符使用，也使它成为可变操作。
这种设计选择的原因是能够使用简单的方式创建复杂的图形，甚至可能包含循环。一旦构建了`GraphDSL`，`GraphDSL`实例就是不可变的，
线程安全的，并且可以自由共享。一旦构造它们，所有运算符 - source，sink和flow也是如此。
这意味着您可以安全地在处理图中的多个位置重复使用一个给定的Flow或交汇点。

We have seen examples of such re-use already above: the merge and broadcast junctions were imported
into the graph using `builder.add(...)`, an operation that will make a copy of the blueprint that
is passed to it and return the inlets and outlets of the resulting copy so that they can be wired up.
Another alternative is to pass existing graphs—of any shape—into the factory method that produces a
new graph. The difference between these approaches is that importing using `builder.add(...)` ignores the
materialized value of the imported graph while importing via the factory method allows its inclusion;
for more details see @ref[Stream Materialization](stream-flows-and-basics.md#stream-materialization).

我们已经看到了上面已经重复使用的示例：使用`builder.add(...)`将合并和广播联结导入到图形中，
该操作将生成传递给它的蓝图的副本并返回生成的副本的入口和出口使它们可以连接起来。
另一种方法是将任何形状的现有图形传递到生成新图形的工厂方法中。这些方法之间的区别在于使用`builder.add(...)`
导入时忽略graph图形的物化值，而通过工厂方法导入则允许包含它；有关更多详细信息，请参阅
@ref[Stream物化](stream-flows-and-basics.md#stream-materialization)。

In the example below we prepare a graph that consists of two parallel streams,
in which we re-use the same instance of `Flow`, yet it will properly be
materialized as two connections between the corresponding Sources and Sinks:

在下面的示例中，我们准备了一个由两个并行流组成的图，其中我们重用了相同的`Flow`实例，但它将正确地实现为相应的Source和Sink之间的两个连接：

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-reusing-a-flow }

Java
:   @@snip [GraphDSLTest.java](/akka-stream-tests/src/test/java/akka/stream/javadsl/GraphDslTest.java) { #graph-dsl-reusing-a-flow }

In some cases we may have a list of graph elements, for example if they are dynamically created. 
If these graphs have similar signatures, we can construct a graph collecting all their materialized values as a collection:

在某些情况下我们可能有一个graph元素列表，例如，如果它们是动态创建的。如果这些graph有相同的签名，我们可以构建一个graph，
将其物化值作为集合收集。

Scala
:   @@snip [GraphOpsIntegrationSpec.scala](/akka-stream-tests/src/test/scala/akka/stream/scaladsl/GraphOpsIntegrationSpec.scala) { #graph-from-list }

Java
:   @@snip [GraphDSLTest.java](/akka-stream-tests/src/test/java/akka/stream/javadsl/GraphDslTest.java) { #graph-from-list }


<a id="partial-graph-dsl"></a>
## Constructing and combining Partial Graphs
## 部分图的构造和组合

Sometimes it is not possible (or needed) to construct the entire computation graph in one place, but instead construct
all of its different phases in different places and in the end connect them all into a complete graph and run it.

有时不可能（或不需要）在一个地方构建整个计算图，而是在不同的地方构建它的所有不同阶段，
最后将它们连接到一个完整的图中并运行它。

This can be achieved by @scala[returning a different `Shape` than `ClosedShape`, for example `FlowShape(in, out)`, from the
function given to `GraphDSL.create`. See [Predefined shapes](#predefined-shapes) for a list of such predefined shapes.
Making a `Graph` a `RunnableGraph`]@java[using the returned `Graph` from `GraphDSL.create()` rather than
passing it to `RunnableGraph.fromGraph()` to wrap it in a `RunnableGraph`.The reason of representing it as a different type is that a
`RunnableGraph`] requires all ports to be connected, and if they are not
it will throw an exception at construction time, which helps to avoid simple
wiring errors while working with graphs. A partial graph however allows
you to return the set of yet to be connected ports from the code block that
performs the internal wiring.

这可以通过从给定给`GraphDSL.create`的函数中返回与`ClosedShape`不同的形状来实现，例如`FlowShape(in，out)`。
有关此类预定义形状的列表，请参见 @ref:[预定义形状](#predefined-shapes) 。
将一个图形制作成一个可运行的流程图需要连接所有的端口，如果没有，它将在构建时抛出一个异常，
这有助于在处理图形时避免简单的接线错误。但是，部分图允许您从执行内部接线的代码块返回尚未连接的端口集。

Let's imagine we want to provide users with a specialized element that given 3 inputs will pick
the greatest int value of each zipped triple. We'll want to expose 3 input ports (unconnected sources) and one output port
(unconnected sink).

假设我们想为用户提供一个专门的元素，给定3个输入，将选择每个压缩三元组的最大int值。
我们将要公开3个输入端口（未连接的源）和一个输出端口（未连接的接收器）。

Scala
:   @@snip [StreamPartialGraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/StreamPartialGraphDSLDocSpec.scala) { #simple-partial-graph-dsl }  

Java
:   @@snip [StreamPartialGraphDSLDocTest.java](/akka-docs/src/test/java/jdocs/stream/StreamPartialGraphDSLDocTest.java) { #simple-partial-graph-dsl }

@@@ note

While the above example shows composing two 2-input `ZipWith`s, in reality ZipWith already provides 
numerous overloads including a 3 (and many more) parameter versions. So this could be implemented 
using one ZipWith using the 3 parameter version, like this: @scala[`ZipWith((a, b, c) => out)`]@java[`ZipWith.create((a, b, c) -> out)`].
(The ZipWith with N input has N+1 type parameter; the last type param is the output type.)

虽然上面的示例显示了组成两个2输入的`ZipWith`，但实际上`ZipWith`已经提供了许多重载，包括一个3（或更多）参数的版本。因此，
可以使用一个使用3参数版本的`ZipWith`来实现这一点，比如：`ZipWith((a, b, c）=> out）`。
（具有N个输入的ZipWith具有N+1个类型参数；最后一个类型参数是输出类型。）

@@@

As you can see, first we construct the partial graph that @scala[contains all the zipping and comparing of stream
elements. This partial graph will have three inputs and one output, wherefore we use the `UniformFanInShape`]@java[describes how to compute the maximum of two input streams.
then we reuse that twice while constructing the partial graph that extends this to three input streams].
Then we import it (all of its nodes and connections) explicitly into the @scala[closed graph built in the second step]@java[last graph] in which all
the undefined elements are rewired to real sources and sinks. The graph can then be run and yields the expected result.

如您所见，首先我们构建包含流元素的所有zipping和comparing的部分图。这张局部图将有三个输入和一个输出，
因此我们使用了`UniformFanInShape`。然后我们将它（它的所有节点和连接）显式地导入到在第二步中构建的闭合图中，
其中所有未定义的元素都重新连接到实际的source和sink。然后可以运行该图并生成预期结果。

@@@ warning

Please note that `GraphDSL` is not able to provide compile time type-safety about whether or not all
elements have been properly connected—this validation is performed as a runtime check during the graph's instantiation.

请注意，`GraphDSL`无法提供编译时的类型安全性，说明是否所有元素都已正确连接。此验证在图形实例化期间作为运行时检查执行。

A partial graph also verifies that all ports are either connected or part of the returned `Shape`.

部分图还验证所有端口是否已连接或是返回`Shape`（形状）的一部分。

@@@

<a id="constructing-sources-sinks-flows-from-partial-graphs"></a>
## Constructing Sources, Sinks and Flows from Partial Graphs
## 从部分图构造Source，Sink和Flow

Instead of treating a @scala[partial graph]@java[`Graph`] as a collection of flows and junctions which may not yet all be
connected it is sometimes useful to expose such a complex graph as a simpler structure,
such as a `Source`, `Sink` or `Flow`.

有时，将这样一个复杂的图暴露为一个更简单的结构（如`Source`、`Sink`或`Flow`），
而不是将一个部分图视为可能还没有全部连接的flow和连接的集合。

In fact, these concepts can be expressed as special cases of a partially connected graph:

实际上，这些概念可以表示为部分连接图的特殊情况：

 * `Source` is a partial graph with *exactly one* output, that is it returns a `SourceShape`.
 * `Sink` is a partial graph with *exactly one* input, that is it returns a `SinkShape`.
 * `Flow` is a partial graph with *exactly one* input and *exactly one* output, that is it returns a `FlowShape`.

 * `Source` 是一个带有 *正好一个* 输出的部分图，即它返回一个`SourceShape`.
 * `Sink` 是一个带有 *正好一个* 输入的部分图，即它返回一个`SinkShape`.
 * `Flow` 是一个带有 *正好一个* 输入和 *正好一个* 输出的部分图，即它返回一个`FlowShape`.

Being able to hide complex graphs inside of simple elements such as Sink / Source / Flow enables you to create one
complex element and from there on treat it as simple compound operator for linear computations.

能够将复杂图形隐藏在简单元素（如sink/source/flow）中，可以创建一个复杂元素，并将其视为用于线性计算的简单复合运算符。

In order to create a Source from a graph the method `Source.fromGraph` is used, to use it we must have a
@scala[`Graph[SourceShape, T]`]@java[`Graph` with a `SourceShape`]. This is constructed using
@scala[`GraphDSL.create` and returning a `SourceShape` from the function passed in]@java[`GraphDSL.create` and providing building a `SourceShape` graph].
The single outlet must be provided to the `SourceShape.of` method and will become
“the sink that must be attached before this Source can run”.

为了从图中创建源，使用了`Source.fromGraph`方法，要使用它，我们必须有一个`Graph[SourceShape, T]`。
这是使用`GraphDSL.create`构造的，并从传入的函数返回`SourceShape`。必须为`SourceShape.of`方法提供单个出口，
并将成为“运行此Source之前必须连接的sink”。

Refer to the example below, in which we create a Source that zips together two numbers, to see this graph
construction in action:

请参阅下面的示例，其中我们创建了一个将两个数字压缩在一起的Source，查看此图结构的实际情况：

Scala
:   @@snip [StreamPartialGraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/StreamPartialGraphDSLDocSpec.scala) { #source-from-partial-graph-dsl }    

Java
:   @@snip [StreamPartialGraphDSLDocTest.java](/akka-docs/src/test/java/jdocs/stream/StreamPartialGraphDSLDocTest.java) { #source-from-partial-graph-dsl }


Similarly the same can be done for a @scala[`Sink[T]`]@java[`Sink<T>`], using `SinkShape.of` in which case the provided value
must be an @scala[`Inlet[T]`]@java[`Inlet<T>`]. For defining a @scala[`Flow[T]`]@java[`Flow<T>`] we need to expose both an @scala[inlet and an outlet]@java[undefined source and sink]:

同样，`Sink[T]`也可以采用`SinkShape.of`。在这种情况下，提供的值必须是`Inlet[T]`。为了定义`Flow[T]`，
我们需要暴露入口（inlet）和出口（outlet）：

Scala
:   @@snip [StreamPartialGraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/StreamPartialGraphDSLDocSpec.scala) { #flow-from-partial-graph-dsl }    

Java
:   @@snip [StreamPartialGraphDSLDocTest.java](/akka-docs/src/test/java/jdocs/stream/StreamPartialGraphDSLDocTest.java) { #flow-from-partial-graph-dsl }


## Combining Sources and Sinks with simplified API
## 使用简化的API组合Source和Sink

There is a simplified API you can use to combine sources and sinks with junctions like:
@scala[`Broadcast[T]`, `Balance[T]`, `Merge[In]` and `Concat[A]`]@java[`Broadcast<T>`, `Balance<T>`, `Merge<In>` and `Concat<A>`]
without the need for using the Graph DSL. The combine method takes care of constructing
the necessary graph underneath. In following example we combine two sources into one (fan-in):

您可以使用简化的API将source和sink与结点组合在一起，例如：`Broadcast[T]`，`Balance[T]`，`Merge[In]`和`Concat[A]`，
而无需使用Graph DSL。combine方法负责构建下面的必要图形。在下面的示例中，我们将两个source合并为一个（扇入）：

Scala
:   @@snip [StreamPartialGraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/StreamPartialGraphDSLDocSpec.scala) { #source-combine }   

Java
:   @@snip [StreamPartialGraphDSLDocTest.java](/akka-docs/src/test/java/jdocs/stream/StreamPartialGraphDSLDocTest.java) { #source-combine }


The same can be done for a @scala[`Sink[T]`]@java[`Sink`] but in this case it will be fan-out:

对于`Sink[T]`也可以这样做，但在这种情况下它将是扇出：

Scala
:   @@snip [StreamPartialGraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/StreamPartialGraphDSLDocSpec.scala) { #sink-combine }  

Java
:   @@snip [StreamPartialGraphDSLDocTest.java](/akka-docs/src/test/java/jdocs/stream/StreamPartialGraphDSLDocTest.java) { #sink-combine }


## Building reusable Graph components
## 构建可重用的Graph组件

It is possible to build reusable, encapsulated components of arbitrary input and output ports using the graph DSL.

可以使用图形DSL构建任意输入和输出端口的可重用封装组件。

As an example, we will build a graph junction that represents a pool of workers, where a worker is expressed
as a @scala[`Flow[I,O,_]`]@java[`Flow<I,O,M>`], i.e. a simple transformation of jobs of type `I` to results of type `O` (as you have seen
already, this flow can actually contain a complex graph inside). Our reusable worker pool junction will
not preserve the order of the incoming jobs (they are assumed to have a proper ID field) and it will use a `Balance`
junction to schedule jobs to available workers. On top of this, our junction will feature a "fastlane", a dedicated port
where jobs of higher priority can be sent.

例如，我们将构建一个表示工作池的图形连接，其中工作程序表示为`Flow[I，O，_]`，即将类型`I`的作业简单转换为类型`O`的结果
（当您已经看过，这个flow实际上可以包含一个复杂的图形）。我们的可重用工作池联合将不会保留传入作业的顺序
（假定它们具有正确的ID字段），并且它将使用`Balance`结点将作业调度到可用的工作程序。除此之外，我们的交叉路口还将设有一个
“fastlane”，一个专用端口，可以发送更高优先级的作业。

Altogether, our junction will have two input ports of type `I` (for the normal and priority jobs) and an output port
of type `O`. To represent this interface, we need to define a custom `Shape`. The following lines show how to do that.

总而言之，我们的联结将有两个类型为`I`的输入端口（用于普通和优先级作业）和一个类型为`O`的输出端口。要表示此接口，
我们需要定义一个自定义Shape。以下行显示了如何执行此操作。

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-components-shape }  



## Predefined shapes
## 预定义的形状

In general a custom `Shape` needs to be able to provide all its input and output ports, be able to copy itself, and also be
able to create a new instance from given ports. There are some predefined shapes provided to avoid unnecessary
boilerplate:

通常，自定义Shape需要能够提供其所有输入和输出端口，能够复制自身，并且还能够从给定端口创建新实例。
提供了一些预定义的形状以避免不必要的样板：

 * `SourceShape`, `SinkShape`, `FlowShape` for simpler shapes,
 * `UniformFanInShape` and `UniformFanOutShape` for junctions with multiple input (or output) ports
of the same type,
 * `FanInShape1`, `FanInShape2`, ..., `FanOutShape1`, `FanOutShape2`, ... for junctions
with multiple input (or output) ports of different types.

 * `SourceShape`，`SinkShape`，`FlowShape`用于简化形状，
 * `UniformFanInShape`和`UniformFanOutShape`用于与多个相同类型的输入（或输出）端口的连接，
 * `FanInShape1`，`FanInShape2`，...，`FanOutShape1`，`FanOutShape2`，...用于具有不同类型的多个输入（或输出）端口的交叉点。

Since our shape has two input ports and one output port, we can use the `FanInShape` DSL to define
our custom shape:

由于我们的形状有两个输入端口和一个输出端口，我们可以使用`FanInShape` DSL来定义我们的自定义形状：

Scala
:  @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-components-shape2 }  



Now that we have a `Shape` we can wire up a Graph that represents
our worker pool. First, we will merge incoming normal and priority jobs using `MergePreferred`, then we will send the jobs
to a `Balance` junction which will fan-out to a configurable number of workers (flows), finally we merge all these
results together and send them out through our only output port. This is expressed by the following code:

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-components-create }    




All we need to do now is to use our custom junction in a graph. The following code simulates some simple workers
and jobs using plain strings and prints out the results. Actually we used *two* instances of our worker pool junction
using `add()` twice.

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-components-use }




<a id="bidi-flow"></a>
## Bidirectional Flows

A graph topology that is often useful is that of two flows going in opposite
directions. Take for example a codec operator that serializes outgoing messages
and deserializes incoming octet streams. Another such operator could add a framing
protocol that attaches a length header to outgoing data and parses incoming
frames back into the original octet stream chunks. These two operators are meant
to be composed, applying one atop the other as part of a protocol stack. For
this purpose exists the special type `BidiFlow` which is a graph that
has exactly two open inlets and two open outlets. The corresponding shape is
called `BidiShape` and is defined like this:

@@snip [Shape.scala](/akka-stream/src/main/scala/akka/stream/Shape.scala) { #bidi-shape }   


A bidirectional flow is defined just like a unidirectional `Flow` as
demonstrated for the codec mentioned above:

Scala
:   @@snip [BidiFlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/BidiFlowDocSpec.scala) { #codec }

Java
:   @@snip [BidiFlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/BidiFlowDocTest.java) { #codec }


The first version resembles the partial graph constructor, while for the simple
case of a functional 1:1 transformation there is a concise convenience method
as shown on the last line. The implementation of the two functions is not
difficult either:

Scala
:   @@snip [BidiFlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/BidiFlowDocSpec.scala) { #codec-impl }  

Java
:   @@snip [BidiFlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/BidiFlowDocTest.java) { #codec-impl }


In this way you can integrate any other serialization library that
turns an object into a sequence of bytes.

The other operator that we talked about is a little more involved since reversing
a framing protocol means that any received chunk of bytes may correspond to
zero or more messages. This is best implemented using @ref[`GraphStage`](stream-customize.md)
(see also @ref[Custom processing with GraphStage](stream-customize.md#graphstage)).

Scala
:   @@snip [BidiFlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/BidiFlowDocSpec.scala) { #framing }  

Java
:   @@snip [BidiFlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/BidiFlowDocTest.java) { #framing }


With these implementations we can build a protocol stack and test it:

Scala
:   @@snip [BidiFlowDocSpec.scala](/akka-docs/src/test/scala/docs/stream/BidiFlowDocSpec.scala) { #compose }  

Java
:   @@snip [BidiFlowDocTest.java](/akka-docs/src/test/java/jdocs/stream/BidiFlowDocTest.java) { #compose }


This example demonstrates how `BidiFlow` subgraphs can be hooked
together and also turned around with the @scala[`.reversed`]@java[`.reversed()`] method. The test
simulates both parties of a network communication protocol without actually
having to open a network connection—the flows can be connected directly.

<a id="graph-matvalue"></a>
## Accessing the materialized value inside the Graph

In certain cases it might be necessary to feed back the materialized value of a Graph (partial, closed or backing a
Source, Sink, Flow or BidiFlow). This is possible by using `builder.materializedValue` which gives an `Outlet` that
can be used in the graph as an ordinary source or outlet, and which will eventually emit the materialized value.
If the materialized value is needed at more than one place, it is possible to call `materializedValue` any number of
times to acquire the necessary number of outlets.

Scala
:   @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-matvalue }

Java
:   @@snip [GraphDSLTest.java](/akka-stream-tests/src/test/java/akka/stream/javadsl/GraphDslTest.java) { #graph-dsl-matvalue }


Be careful not to introduce a cycle where the materialized value actually contributes to the materialized value.
The following example demonstrates a case where the materialized @scala[`Future`]@java[`CompletionStage`] of a fold is fed back to the fold itself.

Scala
:  @@snip [GraphDSLDocSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphDSLDocSpec.scala) { #graph-dsl-matvalue-cycle }

Java
:  @@snip [GraphDSLTest.java](/akka-stream-tests/src/test/java/akka/stream/javadsl/GraphDslTest.java) { #graph-dsl-matvalue-cycle }


<a id="graph-cycles"></a>
## Graph cycles, liveness and deadlocks

Cycles in bounded stream topologies need special considerations to avoid potential deadlocks and other liveness issues.
This section shows several examples of problems that can arise from the presence of feedback arcs in stream processing
graphs.

In the following examples runnable graphs are created but do not run because each have some issue and will deadlock after start.
`Source` variable is not defined as the nature and number of element does not matter for described problems.

The first example demonstrates a graph that contains a naïve cycle.
The graph takes elements from the source, prints them, then broadcasts those elements
to a consumer (we just used `Sink.ignore` for now) and to a feedback arc that is merged back into the main stream via
a `Merge` junction.

@@@ note

The graph DSL allows the connection arrows to be reversed, which is particularly handy when writing cycles—as we will
see there are cases where this is very helpful.

@@@

Scala
:   @@snip [GraphCyclesSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphCyclesSpec.scala) { #deadlocked }  

Java
:   @@snip [GraphCyclesDocTest.java](/akka-docs/src/test/java/jdocs/stream/GraphCyclesDocTest.java) { #deadlocked }


Running this we observe that after a few numbers have been printed, no more elements are logged to the console -
all processing stops after some time. After some investigation we observe that:

 * through merging from `source` we increase the number of elements flowing in the cycle
 * by broadcasting back to the cycle we do not decrease the number of elements in the cycle

Since Akka Streams (and Reactive Streams in general) guarantee bounded processing (see the "Buffering" section for more
details) it means that only a bounded number of elements are buffered over any time span. Since our cycle gains more and
more elements, eventually all of its internal buffers become full, backpressuring `source` forever. To be able
to process more elements from `source` elements would need to leave the cycle somehow.

If we modify our feedback loop by replacing the `Merge` junction with a `MergePreferred` we can avoid the deadlock.
`MergePreferred` is unfair as it always tries to consume from a preferred input port if there are elements available
before trying the other lower priority input ports. Since we feed back through the preferred port it is always guaranteed
that the elements in the cycles can flow.

Scala
:   @@snip [GraphCyclesSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphCyclesSpec.scala) { #unfair }

Java
:   @@snip [GraphCyclesDocTest.java](/akka-docs/src/test/java/jdocs/stream/GraphCyclesDocTest.java) { #unfair }


If we run the example we see that the same sequence of numbers are printed
over and over again, but the processing does not stop. Hence, we avoided the deadlock, but `source` is still
back-pressured forever, because buffer space is never recovered: the only action we see is the circulation of a couple
of initial elements from `source`.

@@@ note

What we see here is that in certain cases we need to choose between boundedness and liveness. Our first example would
not deadlock if there were an infinite buffer in the loop, or vice versa, if the elements in the cycle were 
balanced (as many elements are removed as many are injected) then there would be no deadlock.

@@@

To make our cycle both live (not deadlocking) and fair we can introduce a dropping element on the feedback arc. In this
case we chose the `buffer()` operation giving it a dropping strategy `OverflowStrategy.dropHead`.

Scala
:   @@snip [GraphCyclesSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphCyclesSpec.scala) { #dropping }

Java
:   @@snip [GraphCyclesDocTest.java](/akka-docs/src/test/java/jdocs/stream/GraphCyclesDocTest.java) { #dropping }


If we run this example we see that

 * The flow of elements does not stop, there are always elements printed
 * We see that some of the numbers are printed several times over time (due to the feedback loop) but on average
the numbers are increasing in the long term

This example highlights that one solution to avoid deadlocks in the presence of potentially unbalanced cycles
(cycles where the number of circulating elements are unbounded) is to drop elements. An alternative would be to
define a larger buffer with `OverflowStrategy.fail` which would fail the stream instead of deadlocking it after
all buffer space has been consumed.

As we discovered in the previous examples, the core problem was the unbalanced nature of the feedback loop. We
circumvented this issue by adding a dropping element, but now we want to build a cycle that is balanced from
the beginning instead. To achieve this we modify our first graph by replacing the `Merge` junction with a `ZipWith`.
Since `ZipWith` takes one element from `source` *and* from the feedback arc to inject one element into the cycle,
we maintain the balance of elements.

Scala
:   @@snip [GraphCyclesSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphCyclesSpec.scala) { #zipping-dead }    

Java
:   @@snip [GraphCyclesDocTest.java](/akka-docs/src/test/java/jdocs/stream/GraphCyclesDocTest.java) { #zipping-dead }


Still, when we try to run the example it turns out that no element is printed at all! After some investigation we
realize that:

 * In order to get the first element from `source` into the cycle we need an already existing element in the cycle
 * In order to get an initial element in the cycle we need an element from `source`

These two conditions are a typical "chicken-and-egg" problem. The solution is to inject an initial
element into the cycle that is independent from `source`. We do this by using a `Concat` junction on the backwards
arc that injects a single element using `Source.single`.

Scala
:   @@snip [GraphCyclesSpec.scala](/akka-docs/src/test/scala/docs/stream/GraphCyclesSpec.scala) { #zipping-live }    

Java
:   @@snip [GraphCyclesDocTest.java](/akka-docs/src/test/java/jdocs/stream/GraphCyclesDocTest.java) { #zipping-live }


When we run the above example we see that processing starts and never stops. The important takeaway from this example
is that balanced cycles often need an initial "kick-off" element to be injected into the cycle.
