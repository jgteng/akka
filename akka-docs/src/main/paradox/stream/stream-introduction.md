# Introduction
# 简介

## Motivation
## 动机

The way we consume services from the Internet today includes many instances of
streaming data, both downloading from a service as well as uploading to it or
peer-to-peer data transfers. Regarding data as a stream of elements instead of
in its entirety is very useful because it matches the way computers send and
receive them (for example via TCP), but it is often also a necessity because
data sets frequently become too large to be handled as a whole. We spread
computations or analyses over large clusters and call it “big data”, where the
whole principle of processing them is by feeding those data sequentially—as a
stream—through some CPUs.

我们今天从互联网上消费服务的方式包括许多流数据实例，包括从服务下载以及上传到服务或点对点数据传输。关于数据作为元素流而不是整体是非常有用的，
因为它匹配计算机发送和接收它们的方式（例如通过TCP），但它通常也是必需的，因为数据集经常变得太大而无法作为处理整个。
我们在大型集群上进行计算或分析并将其称为“大数据”，其中处理它们的整个原则是通过顺序地提供这些数据 - 作为流通过一些CPU。

Actors can be seen as dealing with streams as well: they send and receive
series of messages in order to transfer knowledge (or data) from one place to
another. We have found it tedious and error-prone to implement all the proper
measures in order to achieve stable streaming between actors, since in addition
to sending and receiving we also need to take care to not overflow any buffers
or mailboxes in the process. Another pitfall is that Actor messages can be lost
and must be retransmitted in that case. Failure to do so would lead to holes at
the receiving side. When dealing with streams of elements of a fixed given type,
Actors also do not currently offer good static guarantees that no wiring errors
are made: type-safety could be improved in this case.

演员也可以被视为处理流：它们发送和接收一系列消息，以便将知识（或数据）从一个地方传输到另一个地方。
我们发现实现所有适当的措施以便在actor之间实现稳定的流式传输是繁琐且容易出错的，因为除了发送和接收之外，
我们还需要注意不要在进程中溢出任何缓冲区或邮箱。另一个缺陷是Actor消息可能会丢失，在这种情况下必须重新传输，以免流在接收端有漏洞。
当处理固定给定类型的元素流时，Actors目前还没有提供良好的静态保证，没有发生布线错误：在这种情况下可以改善类型安全性。

For these reasons we decided to bundle up a solution to these problems as an
Akka Streams API. The purpose is to offer an intuitive and safe way to
formulate stream processing setups such that we can then execute them
efficiently and with bounded resource usage—no more OutOfMemoryErrors. In order
to achieve this our streams need to be able to limit the buffering that they
employ, they need to be able to slow down producers if the consumers cannot
keep up. This feature is called back-pressure and is at the core of the
[Reactive Streams](http://reactive-streams.org/) initiative of which Akka is a
founding member. For you this means that the hard problem of propagating and
reacting to back-pressure has been incorporated in the design of Akka Streams
already, so you have one less thing to worry about; it also means that Akka
Streams interoperate seamlessly with all other Reactive Streams implementations
(where Reactive Streams interfaces define the interoperability SPI while
implementations like Akka Streams offer a nice user API).

出于这些原因，我们决定将这些问题的解决方案捆绑为Akka Streams API。目的是提供一种直观且安全的方式来制定流处理设置，
以便我们可以有效地执行它们并且使用有限的资源 - 不再使用OutOfMemoryErrors。为了实现这一目标，我们的流需要能够限制他们使用的缓冲，
如果消费者无法跟上，他们需要能够减慢生产者的速度。此功能称为回压，是Akka作为创始成员的[Reactive Streams](htp://reactive-streams.org)计划的核心。
对你来说，这意味着传播和反压力的难题已经被纳入Akka Streams的设计中，所以你可以少担心一件事;它还意味着Akka Streams可以与所有其他
Reactive Streams实现无缝互操作（其中Reactive Streams接口定义了互操作性SPI，而Akka Streams等实现提供了一个不错的用户API）。

### Relationship with Reactive Streams
### 与Reactive Streams的关系

The Akka Streams API is completely decoupled from the Reactive Streams
interfaces. While Akka Streams focus on the formulation of transformations on
data streams the scope of Reactive Streams is to define a common mechanism
of how to move data across an asynchronous boundary without losses, buffering
or resource exhaustion.

Akka Streams API与Reactive Streams接口完全分离。虽然Akka Streams专注于数据流转换的制定，
但Reactive Streams的规范是定义如何跨异步边界移动数据的通用机制，而不会造成损失，缓冲或资源耗尽。

The relationship between these two is that the Akka Streams API is geared
towards end-users while the Akka Streams implementation uses the Reactive
Streams interfaces internally to pass data between the different operators.
For this reason you will not find any resemblance between the Reactive
Streams interfaces and the Akka Streams API. This is in line with the
expectations of the Reactive Streams project, whose primary purpose is to
define interfaces such that different streaming implementation can
interoperate; it is not the purpose of Reactive Streams to describe an end-user
API.

这两者之间的关系是Akka Streams API面向最终用户，而Akka Streams实现在内部使用Reactive Streams接口在不同提供商之间传递数据。因此，
你不会发现Reactive Streams接口和Akka Streams API之间存在任何相似之处。这符合Reactive Streams项目的期望，其主要目的是定义接口，
使不同的流实现可以互操作; Reactive Streams的目的不是描述最终用户API。

## How to read these docs
## 如何阅读这些文档

Stream processing is a different paradigm to the Actor Model or to Future
composition, therefore it may take some careful study of this subject until you
feel familiar with the tools and techniques. The documentation is here to help
and for best results we recommend the following approach:

流处理是Actor模型或Future组合的不同范例，因此在你熟悉工具和技术之前，可能需要仔细研究这个主题。本文档旨在提供帮助，为获得最佳结果，
我们建议采用以下方法：

 * Read the @ref:[Quick Start Guide](stream-quickstart.md#stream-quickstart) to get a feel for how streams
look like and what they can do.
 * The top-down learners may want to peruse the @ref:[Design Principles behind Akka Streams](../general/stream/stream-design.md) at this
point.
 * The bottom-up learners may feel more at home rummaging through the
@ref:[Streams Cookbook](stream-cookbook.md).
 * For a complete overview of the built-in processing operators you can look at the
@ref:[operator index](operators/index.md)
 * The other sections can be read sequentially or as needed during the previous
steps, each digging deeper into specific topics.

 * 阅读 @ref:[快速入门指南](stream-quickstart.md#stream-quickstart) ，了解流的外观以及它们可以执行的操作。
 * 自上而下的学习者可能希望在此时仔细阅读 @ref:[Akka Streams背后的设计原则](../general/stream/stream-design.md) 。
 * 通过 @ref:[Streams Cookbook](stream-cookbook.md) ，自下而上的学习者可能会感觉更有家的感觉。
 * 有关 @ref:[内置处理运算符](operators/index.md) 的完整概述，你可以查看运算符索引
 * 其他部分可以在前面的步骤中按顺序或根据需要进行读取，每个部分都深入研究特定主题。
