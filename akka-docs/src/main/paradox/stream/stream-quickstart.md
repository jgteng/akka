# Streams Quickstart Guide
# Streams快速起步指南

## Dependency
## 依赖

To use Akka Streams, add the module to your project:

要使用Akka Streams，添加模块到你的项目：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-stream_$scala.binary_version$"
  version="$akka.version$"
}

@@@ note

Both the Java and Scala DSLs of Akka Streams are bundled in the same JAR. For a smooth development experience, when using an IDE such as Eclipse or IntelliJ, you can disable the auto-importer from suggesting `javadsl` imports when working in Scala,
or viceversa. See @ref:[IDE Tips](../additional/ide.md).

Akka Streams的Java和Scala DSL都捆绑在同一个JAR中。 为了获得顺畅的开发体验，在使用Eclipse或IntelliJ等IDE时，
你可以在Scala中工作时禁用自动导入器建议使用的javadsl，反之亦然。请参阅 @ref:[IDE提示](../additional/ide.md) 。

@@@

## First steps
## 第一步

A stream usually begins at a source, so this is also how we start an Akka
Stream. Before we create one, we import the full complement of streaming tools:

一个stream通常开始于一个source，所以这也是我们开始使用Akka Stream的方式。在我们创建一个之前，我们导入完整的stream工具：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #stream-imports }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #stream-imports }

If you want to execute the code samples while you read through the quick start guide, you will also need the following imports:

如果要在阅读快速入门指南时执行代码示例，还需要以下导入：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #other-imports }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #other-imports }

And @scala[an object]@java[a class] to hold your code, for example:

以及保存代码的对象，例如：


Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #main-app }

Java
:   @@snip [Main.java](/akka-docs/src/test/java/jdocs/stream/Main.java) { #main-app }

Now we will start with a rather simple source, emitting the integers 1 to 100:

现在我们将从一个相当简单的source开始，发出整数1到100：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #create-source }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #create-source }

The `Source` type is parameterized with two types: the first one is the
type of element that this source emits and the second one may signal that
running the source produces some auxiliary value (e.g. a network source may
provide information about the bound port or the peer’s address). Where no
auxiliary information is produced, the type `akka.NotUsed` is used—and a
simple range of integers surely falls into this category.

`Source`类型有两种类型化参数：第一种是此源发出的元素类型，第二种表示运行源可能产生的一些辅助值（例如，
网络源可能提供有关绑定端口或对等端口的地址信息）。如果没有产生辅助信息，则使用类型`akka.NotUsed`，并且一个简单的整数范围肯定属于这一类。

Having created this source means that we have a description of how to emit the
first 100 natural numbers, but this source is not yet active. In order to get
those numbers out we have to run it:

创建此源后意味着我们有一个如何发出前100个自然数的描述，但此源尚未激活。为了获得这些数字，我们必须运行它：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #run-source }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #run-source }

This line will complement the source with a consumer function—in this example
we print out the numbers to the console—and pass this little stream
setup to an Actor that runs it. This activation is signaled by having “run” be
part of the method name; there are other methods that run Akka Streams, and
they all follow this pattern.

该行将使用消费者函数来完成source - 在此示例中，我们将数字打印到控制台 - 并将此流设置传递给运行它的Actor。
通过将“`run`”作为方法名称的一部分来发信号通知激活这个流; 还有其他运行Akka Streams的方法，它们都遵循这种模式。

When running this @scala[source in a `scala.App`]@java[program] you might notice it does not
terminate, because the `ActorSystem` is never terminated. Luckily
`runForeach` returns a @scala[`Future[Done]`]@java[`CompletionStage<Done>`] which resolves when the stream finishes:

在`scala.App`中运行此source时，你可能会注意到它没有终止，因为`ActorSystem`永远不会终止。
幸运的是`runForeach`返回一个`Future[Done]`，它在流结束时解析（出结果）：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #run-source-and-terminate }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #run-source-and-terminate }

You may wonder where the Actor gets created that runs the stream, and you are
probably also asking yourself what this `materializer` means. In order to get
this value we first need to create an Actor system:

你可能想知道在哪里创建了运行流的Actor，并且你可能也在问自己这个`materializer`的含义。为了获得这个值，
我们首先需要创建一个Actor系统：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #create-materializer }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #create-materializer }

There are other ways to create a materializer, e.g. from an
`ActorContext` when using streams from within Actors. The
`Materializer` is a factory for stream execution engines, it is the
thing that makes streams run—you don’t need to worry about any of the details
right now apart from that you need one for calling any of the `run` methods on
a `Source`. @scala[The materializer is picked up implicitly if it is omitted
from the `run` method call arguments, which we will do in the following.]

还有其他方法可以创建一个materializer，例如：在Actors中使用流时从`ActorContext`
（`Actor#context`上下文生成`ActorMaterializer`）。Materializer是流执行引擎的工厂，它使流运行 - 你现在不需要担心任何细节，
除了你需要一个来调用Source上的任何`run`方法。如果从`run`方法调用参数中省略了`materializer`，则隐式获取它，
我们将在下面进行操作。

The nice thing about Akka Streams is that the `Source` is a
description of what you want to run, and like an architect’s blueprint it can
be reused, incorporated into a larger design. We may choose to transform the
source of integers and write it to a file instead:

关于Akka Streams的好处是`Source`描述了你想要运行的东西，就像建筑师的蓝图一样，它可以重复使用，并融入更大的设计中。
我们可以选择转换整数source并将其写入文件：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #transform-source }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #transform-source }

First we use the `scan` operator to run a computation over the whole
stream: starting with the number 1 (@scala[`BigInt(1)`]@java[`BigInteger.ONE`]) we multiply by each of
the incoming numbers, one after the other; the scan operation emits the initial
value and then every calculation result. This yields the series of factorial
numbers which we stash away as a `Source` for later reuse—it is
important to keep in mind that nothing is actually computed yet, this is a
description of what we want to have computed once we run the stream. Then we
convert the resulting series of numbers into a stream of `ByteString`
objects describing lines in a text file. This stream is then run by attaching a
file as the receiver of the data. In the terminology of Akka Streams this is
called a `Sink`. `IOResult` is a type that IO operations return in
Akka Streams in order to tell you how many bytes or elements were consumed and
whether the stream terminated normally or exceptionally.

首先，我们使用`scan`运算符对整个流进行计算：从数字1（`BigInt(1)`）开始，我们一个接一个乘以每个输入数字;
扫描操作发出初始值，然后发出（返回）每个计算结果。这产生了一系列因子数，我们将其作为后来重用的`Source`存储 -
重要的是要记住实际上没有任何实际计算，这是我们在运行流时想要计算的内容的描述。
然后我们将得到的数字序列转换为描述文本文件中的行的`ByteString`对象流。然后通过附加文件作为数据的接收者来运行该流。
在Akka Streams的术语中，这被称为`Sink`。`IOResult`是IO操作在Akka Streams中返回的类型，
用于告诉你消耗了多少字节或元素以及流是正常终止还是异常终止。

### Browser-embedded example
### 浏览器嵌入的示例

<a name="here-is-another-example-that-you-can-edit-and-run-in-the-browser-"></a>
Here is another example that you can edit and run in the browser:

以下是你可以在浏览器中编辑和运行的另一个示例：

@@fiddle [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #fiddle_code template=Akka layout=v75 minheight=400px }


## Reusable Pieces
## 可重复使用的片段

One of the nice parts of Akka Streams—and something that other stream libraries
do not offer—is that not only sources can be reused like blueprints, all other
elements can be as well. We can take the file-writing `Sink`, prepend
the processing steps necessary to get the `ByteString` elements from
incoming strings and package that up as a reusable piece as well. Since the
language for writing these streams always flows from left to right (just like
plain English), we need a starting point that is like a source but with an
“open” input. In Akka Streams this is called a `Flow`:

Akka Streams的一个不错的部分 - 以及其他流库没有提供的东西 - 不仅可以像蓝图一样重复使用source，所有其他元素也可以。
我们可以使用文件写入`Sink`，预先设置从传入字符串中获取`ByteString`元素所需的处理步骤，并将其打包为可重用的片段。
由于用于编写这些流的语言总是从左向右流动（就像普通英语一样），我们需要一个起点，就像一个source，但带有“`open`”输入。
在Akka Streams中，这被称为`Flow`：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #transform-sink }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #transform-sink }

Starting from a flow of strings we convert each to `ByteString` and then
feed to the already known file-writing `Sink`. The resulting blueprint
is a @scala[`Sink[String, Future[IOResult]]`]@java[`Sink<String, CompletionStage<IOResult>>`], which means that it
accepts strings as its input and when materialized it will create auxiliary
information of type @scala[`Future[IOResult]`]@java[`CompletionStage<IOResult>`] (when chaining operations on
a `Source` or `Flow` the type of the auxiliary information—called
the “materialized value”—is given by the leftmost starting point; since we want
to retain what the `FileIO.toPath` sink has to offer, we need to say
@scala[`Keep.right`]@java[`Keep.right()`]).

从字符串流开始，我们将每个字符串转换为`ByteString`，然后将其提供给已知的文件写入`Sink`。生成的蓝图是一个
`Sink[String, Future[IOResult]]`，这意味着它接受字符串作为其输入，并且在实现时它将创建`Future[IOResult]`类型的辅助信息
（当在`Source`或`Flow`上链接操作时的类型 辅助信息 - 称为“物化值” - 由最左边的起点给出；因为我们想要保留
`FileIO.toPath`接收器必须提供的内容，我们需要说`Keep.right`）。

We can use the new and shiny `Sink` we just created by
attaching it to our `factorials` source—after a small adaptation to turn the
numbers into strings:

我们可以使用我们刚创建的新的闪亮的`Sink`，将它附加到我们的`factorials` source - 经过一些小的改编后将数字转换为字符串：

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #use-transformed-sink }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #use-transformed-sink }

## Time-Based Processing
## 基于时间的处理

Before we start looking at a more involved example we explore the streaming
nature of what Akka Streams can do. Starting from the `factorials` source
we transform the stream by zipping it together with another stream,
represented by a `Source` that emits the number 0 to 100: the first
number emitted by the `factorials` source is the factorial of zero, the
second is the factorial of one, and so on. We combine these two by forming
strings like `"3! = 6"`.

在我们开始研究一个更为复杂的例子之前，我们将探讨Akka Streams可以做的streaming特性。从阶乘source开始，
我们通过将流与另一个流一起压缩来转换流，由发出数字0到100的`Source`表示：阶乘源发出的第一个数是阶乘0，第二个是阶乘1 ，等等。
我们通过形成像`"3！= 6"`这样的字符串来组合这两个元素。

Scala
:   @@snip [QuickStartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/QuickStartDocSpec.scala) { #add-streams }

Java
:   @@snip [QuickStartDocTest.java](/akka-docs/src/test/java/jdocs/stream/QuickStartDocTest.java) { #add-streams }

All operations so far have been time-independent and could have been performed
in the same fashion on strict collections of elements. The next line
demonstrates that we are in fact dealing with streams that can flow at a
certain speed: we use the `throttle` operator to slow down the stream to 1
element per second.

到目前为止，所有操作都与时间无关，并且可以在严格的元素集合上以相同的方式执行。
下一行表明我们实际上正在处理可以以特定速度流动的流：我们使用`throttle`（）运算符将流速减慢到每秒1个元素。

If you run this program you will see one line printed per second. One aspect
that is not immediately visible deserves mention, though: if you try and set
the streams to produce a billion numbers each then you will notice that your
JVM does not crash with an OutOfMemoryError, even though you will also notice
that running the streams happens in the background, asynchronously (this is the
reason for the auxiliary information to be provided as a @scala[`Future`]@java[`CompletionStage`], in the future). The
secret that makes this work is that Akka Streams implicitly implement pervasive
flow control, all operators respect back-pressure. This allows the throttle
operator to signal to all its upstream sources of data that it can only
accept elements at a certain rate—when the incoming rate is higher than one per
second the throttle operator will assert *back-pressure* upstream.

如果你运行此程序，你将看到每秒打印一行。但是，一个值得注意的方面值得一提：如果你尝试将流设置为每个产生十亿个数字，
那么你会注意到你的JVM不会因 **OutOfMemoryError** 而崩溃，即使你还会注意到流的运行在后台发生，异步
（这是辅助信息在未来作为`Future`提供的原因）。使这项工作的秘诀在于Akka Streams隐含地实施普遍的流量控制，
所有操作员都遵循回压。这允许油门操作员向其所有上游数据源发信号通知它只能以特定速率接收元件 - 当输入速率高于每秒一个时，
throttle操作员将断言上游的 *back-pressure* （回压）。

This is all there is to Akka Streams in a nutshell—glossing over the
fact that there are dozens of sources and sinks and many more stream
transformation operators to choose from, see also @ref:[operator index](operators/index.md).

这就是Akka Streams的全部内容，简而言之，因为有数十个sources和sinks以及更多的流转换运算符可供选择，另请参阅
@ref:[运算符索引](operators/index.md) 。

# Reactive Tweets
# 反应式推文

A typical use case for stream processing is consuming a live stream of data that we want to extract or aggregate some
other data from. In this example we'll consider consuming a stream of tweets and extracting information concerning Akka from them.

流处理的典型用例是消耗我们想要提取或聚合其他一些数据的实时数据流。在这个例子中，我们将考虑使用推文流并从中提取有关Akka的信息。

We will also consider the problem inherent to all non-blocking streaming
solutions: *"What if the subscriber is too slow to consume the live stream of
data?"*. Traditionally the solution is often to buffer the elements, but this
can—and usually will—cause eventual buffer overflows and instability of such
systems. Instead Akka Streams depend on internal backpressure signals that
allow to control what should happen in such scenarios.

我们还将考虑所有非阻塞流式传输解决方案固有的问题： *“如果订户太慢而无法使用实时数据流？”*。传统上，
解决方案通常是缓冲元素，但这最终会导致缓冲区溢出和此类系统的不稳定性。相反，Akka Streams依赖于内部回压信号，
可以控制在这种情况下应该发生的事情。

Here's the data model we'll be working with throughout the quickstart examples:

以下是我们将在快速入门示例中使用的数据模型：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #model }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #model }

@@@ note

If you would like to get an overview of the used vocabulary first instead of diving head-first
into an actual example you can have a look at the @ref:[Core concepts](stream-flows-and-basics.md#core-concepts) and @ref:[Defining and running streams](stream-flows-and-basics.md#defining-and-running-streams)
sections of the docs, and then come back to this quickstart to see it all pieced together into a simple example application.

如果你想首先了解使用过的词汇表，而不是首先进入实际示例，你可以查看 @ref:[核心概念](stream-flows-and-basics.md#core-concepts)
以及 @ref:[定义和运行流](stream-flows-and-basics.md#defining-and-running-streams) 文档的流部分，
然后再回到本快速入门看到它们拼凑成一个简单的示例应用程序。

@@@

## Transforming and consuming simple streams
## 转换和消费简单的流

The example application we will be looking at is a simple Twitter feed stream from which we'll want to extract certain information,
like for example finding all twitter handles of users who tweet about `#akka`.

我们将要看的示例应用程序是一个简单的Twitter feed流，我们将从中提取某些信息，例如查找推文包含有关`#akka`的用户的所有推文。

In order to prepare our environment by creating an `ActorSystem` and `ActorMaterializer`,
which will be responsible for materializing and running the streams we are about to create:

为了通过创建一个`ActorSystem`和`ActorMaterializer`来准备我们的环境，它们将负责实现和运行我们即将创建的流：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #materializer-setup }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #materializer-setup }

The `ActorMaterializer` can optionally take `ActorMaterializerSettings` which can be used to define
materialization properties, such as default buffer sizes (see also @ref:[Buffers for asynchronous operators](stream-rate.md#async-stream-buffers)), the dispatcher to
be used by the pipeline etc. These can be overridden with `withAttributes` on `Flow`, `Source`, `Sink` and `Graph`.

`ActorMaterializer`可以选择使用`ActorMaterializerSettings`，它可以用来定义materialization的属性，例如默认缓冲区大小
（参见 @ref:[异步运算符的缓冲区](stream-rate.md#async-stream-buffers) ），管道使用的调度程序等。这些可以在`Flow`，
`Source`、`Sink`和`Graph`上使用`withAttributes`进行覆盖。

Let's assume we have a stream of tweets readily available. In Akka this is expressed as a @scala[`Source[Out, M]`]@java[`Source<Out, M>`]:

让我们假设我们有一系列的推文随时可用。在Akka中，这表示为`Source[Out，M]`：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #tweet-source }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #tweet-source }

Streams always start flowing from a @scala[`Source[Out,M1]`]@java[`Source<Out,M1>`] then can continue through @scala[`Flow[In,Out,M2]`]@java[`Flow<In,Out,M2>`] elements or
more advanced operators to finally be consumed by a @scala[`Sink[In,M3]`]@java[`Sink<In,M3>`] @scala[(ignore the type parameters `M1`, `M2`
and `M3` for now, they are not relevant to the types of the elements produced/consumed by these classes – they are
"materialized types", which we'll talk about [below](#materialized-values-quick))]@java[. The first type parameter—`Tweet` in this case—designates the kind of elements produced
by the source while the `M` type parameters describe the object that is created during
materialization ([see below](#materialized-values-quick))—`NotUsed` (from the `scala.runtime`
package) means that no value is produced, it is the generic equivalent of `void`.]

流总是从`Source[Out，M1]`开始流动，然后可以继续通过`Flow[In，Out，M2]`元素或更高级的运算符，最终被`Sink[In，M3]`消费
（现在忽略类型参数`M1`，`M2`和`M3`，它们与这些类生成/消耗的元素类型无关 - 它们是“物化类型”，我们将在 [下面](#materialized-values-quick) 讨论）

The operations should look familiar to anyone who has used the Scala Collections library,
however they operate on streams and not collections of data (which is a very important distinction, as some operations
only make sense in streaming and vice versa):

对于使用过Scala Collections库的人来说，这些操作看起来应该很熟悉，但是它们在流而不是数据集合上运行
（这是一个非常重要的区别，因为有些操作只在流式传输中有意义，反之亦然）：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #authors-filter-map }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #authors-filter-map }

Finally in order to @ref:[materialize](stream-flows-and-basics.md#stream-materialization) and run the stream computation we need to attach
the Flow to a @scala[`Sink`]@java[`Sink<T, M>`] that will get the Flow running. The simplest way to do this is to call
`runWith(sink)` on a @scala[`Source`]@java[`Source<Out, M>`]. For convenience a number of common Sinks are predefined and collected as @java[static] methods on
the @scala[`Sink` companion object]@java[`Sink class`].
For now let's print each author:

最后，为了 @ref:[materialize](stream-flows-and-basics.md#stream-materialization) 和运行流计算，
我们需要将`Flow`附加到将使Flow运行的`Sink`上。 最简单的方法是在`Source`上调用`runWith(sink)`。为方便起见，
预定义了许多常用的`Sink`，并将其作为`Sink`伴身对象上的方法。现在让我们打印每个作者：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #authors-foreachsink-println }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #authors-foreachsink-println }

or by using the shorthand version (which are defined only for the most popular Sinks such as `Sink.fold` and `Sink.foreach`):

或者使用简短版本（仅为最流行的`Sinks`定义，例如`Sink.fold`和`Sink.foreach`）：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #authors-foreach-println }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #authors-foreach-println }

Materializing and running a stream always requires a `Materializer` to be @scala[in implicit scope (or passed in explicitly,
like this: `.run(materializer)`)]@java[passed in explicitly, like this: `.run(mat)`].

实现和运行流总是要求`Materializer`处于隐式作用域（或明确传递，如下所示：`.run(materializer)`）。

The complete snippet looks like this:

完整的代码片段如下所示：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #first-sample }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #first-sample }

## Flattening sequences in streams
## 在流中拉平序列

In the previous section we were working on 1:1 relationships of elements which is the most common case, but sometimes
we might want to map from one element to a number of elements and receive a "flattened" stream, similarly like `flatMap`
works on Scala Collections. In order to get a flattened stream of hashtags from our stream of tweets we can use the `mapConcat`
operator:

在上一节中，我们正在研究元素的1：1关系，这是最常见的情况，但有时我们可能希望从一个元素映射到多个元素并接收“扁平”流，
类似于在Scala上运行的`flatMap`集合。为了从我们的推文流中获得一个扁平的标签流，我们可以使用`mapConcat`运算符：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #hashtags-mapConcat }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #hashtags-mapConcat }

@@@ note

The name `flatMap` was consciously avoided due to its proximity with for-comprehensions and monadic composition.
It is problematic for two reasons: @scala[first]@java[firstly], flattening by concatenation is often undesirable in bounded stream processing
due to the risk of deadlock (with merge being the preferred strategy), and @scala[second]@java[secondly], the monad laws would not hold for
our implementation of flatMap (due to the liveness issues).

`flatMap`这个名字由于其理解和monadic组合接近而被有意识地避免了。这有两个原因：首先，由于存在死锁的风险（合并是首选策略），
有界流处理中的连接扁平化通常是不可取的；其次，monad定律不适用于我们的flatMap实现（到期） 到了活跃的问题）。

Please note that the `mapConcat` requires the supplied function to return @scala[an iterable (`f: Out => immutable.Iterable[T]`]@java[a strict collection (`Out f -> java.util.List<T>`)],
whereas `flatMap` would have to operate on streams all the way through.

请注意，`mapConcat`需要提供的函数返回一个iterable (`f：Out => immutable.Iterable[T]`)，
而`flatMap`必须在整个过程中对stream进行操作。

@@@

## Broadcasting a stream
## 广播流

Now let's say we want to persist all hashtags, as well as all author names from this one live stream.
For example we'd like to write all author handles into one file, and all hashtags into another file on disk.
This means we have to split the source stream into two streams which will handle the writing to these different files.

现在让我们说我们想要保留所有hashtags，以及来自这一个实时流的所有作者姓名。例如，我们想将所有作者句柄写入一个文件，
将所有主题标签写入磁盘上的另一个文件。这意味着我们必须将源流分成两个流，这两个流将处理对这些不同文件的写入。

Elements that can be used to form such "fan-out" (or "fan-in") structures are referred to as "junctions" in Akka Streams.
One of these that we'll be using in this example is called `Broadcast`, and it emits elements from its
input port to all of its output ports.

可用于形成这种“扇出”（或“扇入”）结构的元素在Akka Streams中被称为“交汇点”。
我们将在此示例中使用的其中一个`Broadcast`，它从其输入端口向其所有输出端口发出元素。

Akka Streams intentionally separate the linear stream structures (Flows) from the non-linear, branching ones (Graphs)
in order to offer the most convenient API for both of these cases. Graphs can express arbitrarily complex stream setups
at the expense of not reading as familiarly as collection transformations.

Akka Streams故意将线性流结构（Flows）与非线性流分支结构（Graphs）分开，以便为这两种情况提供最方便的API。
图形可以表达任意复杂的流设置，代价是不像集合转换那样熟悉。

Graphs are constructed using `GraphDSL` like this:

使用`GraphDSL`构建图形，如下所示：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #graph-dsl-broadcast }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #graph-dsl-broadcast }

As you can see, @scala[inside the `GraphDSL` we use an implicit graph builder `b` to mutably construct the graph
using the `~>` "edge operator" (also read as "connect" or "via" or "to"). The operator is provided implicitly
by importing `GraphDSL.Implicits._`]@java[we use graph builder `b` to construct the graph using `UniformFanOutShape` and `Flow` s].

如你所见，在`GraphDSL`内部，我们使用隐式图形构建器`b`并使用`~>`“边运算符”（也称为“connect（连接）”或“via（通过）”
或“to（到）”）可变地构造图形。通过导入`GraphDSL.Implicits._`提供隐式运算符。

`GraphDSL.create` returns a `Graph`, in this example a @scala[`Graph[ClosedShape, NotUsed]`]@java[`Graph<ClosedShape,NotUsed>`] where
`ClosedShape` means that it is *a fully connected graph* or "closed" - there are no unconnected inputs or outputs.
Since it is closed it is possible to transform the graph into a `RunnableGraph` using `RunnableGraph.fromGraph`.
The `RunnableGraph` can then be `run()` to materialize a stream out of it.

`GraphDSL.create`返回一个`Graph`，在本例中为`Graph[ClosedShape，NotUsed]`，其中`ClosedShape`表示它是完全连接的图形或
“已关闭” - 没有未连接的输入或输出。由于它已关闭，因此可以使用`RunnableGraph.fromGraph`将图形转换为`RunnableGraph`。
然后可以调用`run()`来运行`RunnableGraph`以实现流。

Both `Graph` and `RunnableGraph` are *immutable, thread-safe, and freely shareable*.

`Graph`和`RunnableGraph`都是不可变的，线程安全的，并且可以自由共享。

A graph can also have one of several other shapes, with one or more unconnected ports. Having unconnected ports
expresses a graph that is a *partial graph*. Concepts around composing and nesting graphs in large structures are
explained in detail in @ref:[Modularity, Composition and Hierarchy](stream-composition.md). It is also possible to wrap complex computation graphs
as Flows, Sinks or Sources, which will be explained in detail in
@scala[@ref:[Constructing Sources, Sinks and Flows from Partial Graphs](stream-graphs.md#constructing-sources-sinks-flows-from-partial-graphs)]@java[@ref:[Constructing and combining Partial Graphs](stream-graphs.md#partial-graph-dsl)].

图形也可以具有其他几种形状之一，具有一个或多个未连接的端口。具有未连接的端口表示作为部分图的图。在
@ref:[模块化，组合和层次结构](stream-composition.md) 中详细解释了在大型结构中组合和嵌套图形的概念。
还可以将复杂的计算图形包装为Flows，Sinks或Sources，这将在
@ref:[从部分图构造Source，Sink和Flows](stream-graphs.md#constructing-sources-sinks-flows-from-partial-graphs) 中详细说明。

## Back-pressure in action
## 回压实战

One of the main advantages of Akka Streams is that they *always* propagate back-pressure information from stream Sinks
(Subscribers) to their Sources (Publishers). It is not an optional feature, and is enabled at all times. To learn more
about the back-pressure protocol used by Akka Streams and all other Reactive Streams compatible implementations read
@ref:[Back-pressure explained](stream-flows-and-basics.md#back-pressure-explained).

Akka Streams的主要优点之一是它们总是将来自流Sinks（订阅者）的回压信息传播到其Sources（发布者）。它不是可选功能，
始终启用。要了解有关Akka Streams和所有其他Reactive Streams兼容实现所使用的回压协议的更多信息，请参阅
@ref:[Back-pressure](stream-flows-and-basics.md#back-pressure-explained) 。

A typical problem applications (not using Akka Streams) like this often face is that they are unable to process the incoming data fast enough,
either temporarily or by design, and will start buffering incoming data until there's no more space to buffer, resulting
in either `OutOfMemoryError` s or other severe degradations of service responsiveness. With Akka Streams buffering can
and must be handled explicitly. For example, if we are only interested in the "*most recent tweets, with a buffer of 10
elements*" this can be expressed using the `buffer` element:

这样的典型问题是应用程序（不使用Akka Streams）经常面临的，他们无法通过临时或设计来足够快地处理传入数据，
并且将开始缓冲传入数据，直到没有更多空间来缓冲，从而导致`OutOfMemoryError`或服务响应变慢。
使用Akka Streams缓冲是必须明确处理的。例如，如果我们只对“最新的推文，10个元素的缓冲区”感兴趣，可以使用buffer元素表示：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #tweets-slow-consumption-dropHead }

Java
:  @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #tweets-slow-consumption-dropHead }

The `buffer` element takes an explicit and required `OverflowStrategy`, which defines how the buffer should react
when it receives another element while it is full. Strategies provided include dropping the oldest element (`dropHead`),
dropping the entire buffer, signalling @scala[errors]@java[failures] etc. Be sure to pick and choose the strategy that fits your use case best.

`buffer`元素采用显式且必需的`OverflowStrategy`，它定义缓冲区在接收到另一个元素时应如何反应。提供的策略包括删除最旧的元素
（`dropHead`），删除整个缓冲区，发出错误信号等。确保选择最适合你的用例的策略。

<a id="materialized-values-quick"></a>
## Materialized values
## 物化值

So far we've been only processing data using Flows and consuming it into some kind of external Sink - be it by printing
values or storing them in some external system. However sometimes we may be interested in some value that can be
obtained from the materialized processing pipeline. For example, we want to know how many tweets we have processed.
While this question is not as obvious to give an answer to in case of an infinite stream of tweets (one way to answer
this question in a streaming setting would be to create a stream of counts described as "*up until now*, we've processed N tweets"),
but in general it is possible to deal with finite streams and come up with a nice result such as a total count of elements.

到目前为止，我们只使用Flows处理数据并将其用于某种外部接收器 - 无论是打印值还是将其存储在某些外部系统中。然而，
有时我们可能对可以从物化处理管道获得的某些值感兴趣。例如，我们想知道我们处理了多少推文。
虽然在无限量的推文中给出答案这个问题并不明显（在流媒体设置中回答这个问题的一种方法是创建一个描述为“到目前为止的计数流，
我们已经处理过了N个推文”），但一般情况下，有可能处理有限的流，并得出一个很好的结果，如元素的总数。

First, let's write such an element counter using @scala[`Sink.fold` and]@java[`Flow.of(Class)` and `Sink.fold` to]  see how the types look like:

首先，让我们使用`Sink.fold`编写这样一个元素计数器，看看类型如何：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #tweets-fold-count }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #tweets-fold-count }

@scala[First we prepare a reusable `Flow` that will change each incoming tweet into an integer of value `1`. We'll use this in
order to combine those with a `Sink.fold` that will sum all `Int` elements of the stream and make its result available as
a `Future[Int]`. Next we connect the `tweets` stream to `count` with `via`. Finally we connect the Flow to the previously
prepared Sink using `toMat`]@java[`Sink.fold` will sum all `Integer` elements of the stream and make its result available as
a `CompletionStage<Integer>`. Next we use the `map` method of `tweets` `Source` which will change each incoming tweet
into an integer value `1`.  Finally we connect the Flow to the previously prepared Sink using `toMat`].

首先，我们准备一个可重用的`Flow`，它将每个传入的推文更改为值为`1`的整数。我们将使用它来将这些与`Sink.fold`结合起来，
它将对stream的所有`Int`元素求和并使其结果可用为`Future[Int]`。接下来，我们将tweets流使用`via`连接到`count`。 最后，
我们使用`toMat`将`Flow`连接到之前准备的`Sink`。

Remember those mysterious `Mat` type parameters on @scala[`Source[+Out, +Mat]`, `Flow[-In, +Out, +Mat]` and `Sink[-In, +Mat]`]@java[`Source<Out, Mat>`, `Flow<In, Out, Mat>` and `Sink<In, Mat>`]?
They represent the type of values these processing parts return when materialized. When you chain these together,
you can explicitly combine their materialized values. In our example we used the @scala[`Keep.right`]@java[`Keep.right()`] predefined function,
which tells the implementation to only care about the materialized type of the operator currently appended to the right.
The materialized type of `sumSink` is @scala[`Future[Int]`]@java[`CompletionStage<Integer>`] and because of using @scala[`Keep.right`]@java[`Keep.right()`], the resulting `RunnableGraph`
has also a type parameter of @scala[`Future[Int]`]@java[`CompletionStage<Integer>`].

还记得`Source[+Out，+Mat]`，`Flow[-In，+Out，+Mat]`和`Sink[-In，+Mat]`上那些神秘的`Mat`类型参数？
它们表示这些处理部件在实现时返回的值的类型。将这些链接在一起时，你可以明确地组合它们的具体化值。在我们的示例中，
我们使用了`Keep.right`预定义函数，该函数告诉实现只关心当前附加到右侧的运算符的物化类型。`sumSink`的物化类型是`Future[Int]`，
由于使用了`Keep.right`，生成的`RunnableGraph`也有一个`Future[Int]`的类型参数。

This step does *not* yet materialize the
processing pipeline, it merely prepares the description of the Flow, which is now connected to a Sink, and therefore can
be `run()`, as indicated by its type: @scala[`RunnableGraph[Future[Int]]`]@java[`RunnableGraph<CompletionStage<Integer>>`]. Next we call `run()` which uses the @scala[implicit] `ActorMaterializer`
to materialize and run the Flow. The value returned by calling `run()` on a @scala[`RunnableGraph[T]`]@java[`RunnableGraph<T>`] is of type `T`.
In our case this type is @scala[`Future[Int]`]@java[`CompletionStage<Integer>`] which, when completed, will contain the total length of our `tweets` stream.
In case of the stream failing, this future would complete with a Failure.

此步骤尚`未`实现处理管道，它只是准备`Flow`的描述，现在连接到`Sink`，因此可以`run()`，如其类型所示：`RunnableGraph[Future[Int]]`。
接下来我们调用`run()`，它使用隐式的`ActorMaterializer`来实现和运行`Flow`。通过在`RunnableGraph[T]`上调用`run()`返回的值是T类型。
在我们的例子中，这个类型是`Future[Int]`，当完成时，它将包含我们的tweets流的总长度。如果流失败，这个Future将以`Failure`完成。

A `RunnableGraph` may be reused
and materialized multiple times, because it is only the "blueprint" of the stream. This means that if we materialize a stream,
for example one that consumes a live stream of tweets within a minute, the materialized values for those two materializations
will be different, as illustrated by this example:

`RunnableGraph`可以重复使用和物化多次，因为它只是流的“蓝图”。这意味着如果我们实现流，例如在一分钟内消耗实时推文流的流，
那么这两个实现的具体物化值将是不同的，如此示例所示：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #tweets-runnable-flow-materialized-twice }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #tweets-runnable-flow-materialized-twice }

Many elements in Akka Streams provide materialized values which can be used for obtaining either results of computation or
steering these elements which will be discussed in detail in @ref:[Stream Materialization](stream-flows-and-basics.md#stream-materialization). Summing up this section, now we know
what happens behind the scenes when we run this one-liner, which is equivalent to the multi line version above:

Akka Streams中的许多元素提供了物化值，可用于获得计算结果或控制这些元素，这将在
@ref:Stream Materialization](stream-flows-and-basics.md#stream-materialization) 中详细讨论。总结这一部分，
现在我们知道当我们运行这个单行时幕后发生的事情，这相当于上面的多行版本：

Scala
:   @@snip [TwitterStreamQuickstartDocSpec.scala](/akka-docs/src/test/scala/docs/stream/TwitterStreamQuickstartDocSpec.scala) { #tweets-fold-count-oneline }

Java
:   @@snip [TwitterStreamQuickstartDocTest.java](/akka-docs/src/test/java/jdocs/stream/TwitterStreamQuickstartDocTest.java) { #tweets-fold-count-oneline }

@@@ note

`runWith()` is a convenience method that automatically ignores the materialized value of any other operators except
those appended by the `runWith()` itself. In the above example it translates to using @scala[`Keep.right`]@java[`Keep.right()`] as the combiner
for materialized values.

`runWith()`是一人便捷方法，它自动忽略并移除`runWith()`本身附加的运算符之外的任何其他运算符的具体物化值。
在上面的例子中，它转换为使用`Keep.right`作为物化值的组合器。

@@@
