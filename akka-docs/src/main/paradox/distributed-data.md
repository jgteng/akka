# Distributed Data

# 分布式数据

## Dependency

## 依赖

To use Akka Distributed Data, you must add the following dependency in your project:

要使用Akka分布式数据，你必须在你的项目中添加以下依赖项：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-distributed-data_$scala.binary_version$"
  version="$akka.version$"
}

## Sample project

## 示例项目

You can look at the
@java[@extref[Distributed Data example project](samples:akka-samples-distributed-data-java)]
@scala[@extref[Distributed Data example project](samples:akka-samples-distributed-data-scala)]
to see what this looks like in practice.

你查看 @extref[Distributed Data example project](samples:akka-samples-distributed-data-scala) 示例项目，以了解实际情况。

## Introduction

## 介绍

*Akka Distributed Data* is useful when you need to share data between nodes in an
Akka Cluster. The data is accessed with an actor providing a key-value store like API.
The keys are unique identifiers with type information of the data values. The values
are *Conflict Free Replicated Data Types* (CRDTs).

当你需要在Akka集群中的节点之间共享数据时，Akka分布式数据非常有用。使用提供像API这样的键值存储的actor来访问数据。
key是具有数据值的类型信息的唯一标识符。值是 *无冲突复制数据类型*（CRDT）。

All data entries are spread to all nodes, or nodes with a certain role, in the cluster
via direct replication and gossip based dissemination. You have fine grained control
of the consistency level for reads and writes.

所有数据条目都通过直接复制和基于gossip传播到集群中的所有节点或具有特定角色的节点。
你可以对读取和写入的一致性级别进行精细控制。

The nature CRDTs makes it possible to perform updates from any node without coordination.
Concurrent updates from different nodes will automatically be resolved by the monotonic
merge function, which all data types must provide. The state changes always converge.
Several useful data types for counters, sets, maps and registers are provided and
you can also implement your own custom data types.

自然CRDT使得可以在没有协调的情况下从任何节点执行更新。
来自不同节点的并发更新将由所有数据类型必须提供的单调合并功能自动解析。状态变化总是趋同。提供了计数器，集合，
映射和寄存器等几种有用的数据类型，你还可以实现自己的自定义数据类型。

It is eventually consistent and geared toward providing high read and write availability
(partition tolerance), with low latency. Note that in an eventually consistent system a read may return an
out-of-date value.

它是最终一致的，旨在提供高读取和写入可用性（分区容错性），并具备低延迟。请注意，在最终一致的系统中，
读取可能会返回过时的值。

## Using the Replicator

## 使用 Replicator

The `akka.cluster.ddata.Replicator` actor provides the API for interacting with the data.
The `Replicator` actor must be started on each node in the cluster, or group of nodes tagged
with a specific role. It communicates with other `Replicator` instances with the same path
(without address) that are running on other nodes . For convenience it can be used with the
`akka.cluster.ddata.DistributedData` extension but it can also be started as an ordinary
actor using the `Replicator.props`. If it is started as an ordinary actor it is important
that it is given the same name, started on same path, on all nodes.

`akka.cluster.ddata.Replicator` actor提供用于与数据交互的API。必须在集群中的每个节点或标记有特定角色的节点组上启动
`Replicator` actor。它与其他`Replicator`实例通信，这些实例具有在其他节点上运行的相同路径（无地址）。为方便起见，
它可以与`akka.cluster.ddata.DistributedData`扩展一起使用，但也可以使用`Replicator.props`作为普通actor启动。
如果它作为普通的actor启动，那么在所有节点上给它起相同的名称，在相同的路径上启动是很重要的。

Cluster members with status @ref:[WeaklyUp](cluster-usage.md#weakly-up),
will participate in Distributed Data. This means that the data will be replicated to the
@ref:[WeaklyUp](cluster-usage.md#weakly-up) nodes with the background gossip protocol. Note that it
will not participate in any actions where the consistency mode is to read/write from all
nodes or the majority of nodes. The @ref:[WeaklyUp](cluster-usage.md#weakly-up) node is not counted
as part of the cluster. So 3 nodes + 5 @ref:[WeaklyUp](cluster-usage.md#weakly-up) is essentially a
3 node cluster as far as consistent actions are concerned.

状态为 @ref:[WeaklyUp](cluster-usage.md#weakly-up) 的集群成员将参与分布式数据。这意味着数据将使用后台gossip协议复制到
@ref:[WeaklyUp](cluster-usage.md#weakly-up) 节点。请注意，它不会参与任何一致性模式从所有节点或大多数节点读取/写入的操作。
`WeaklyUp`节点不计入集群的一部分。因此，就一致的动作而言，3个节点 + 5个`WeaklyUp`节点本质上是一个3节点集群。

Below is an example of an actor that schedules tick messages to itself and for each tick
adds or removes elements from a `ORSet` (observed-remove set). It also subscribes to
changes of this.

下面是一个actor的例子，它调度自己的tick信息，并为每个tick添加或删除`ORSet`中的元素（观察-删除 集）。它还订阅了此更改。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #data-bot }

Java
: @@snip [DataBot.java](/akka-docs/src/test/java/jdocs/ddata/DataBot.java) { #data-bot }

<a id="replicator-update"></a>
### Update

### 更新

To modify and replicate a data value you send a `Replicator.Update` message to the local
`Replicator`.

要修改或复写数据值，你要将`Replicator.Update`消息发送给本地`Replicator`。

The current data value for the `key` of the `Update` is passed as parameter to the `modify`
function of the `Update`. The function is supposed to return the new value of the data, which
will then be replicated according to the given consistency level.

`Update`的键（代表）的当前数据值作为参数传递给`Update`的`modify`函数。该函数应该返回修改后的新值，
然后根据给定的一致性组织复制该值。

The `modify` function is called by the `Replicator` actor and must therefore be a pure
function that only uses the data parameter and stable fields from enclosing scope. It must
for example not access the sender (@scala[`sender()`]@java[`getSender()`]) reference of an enclosing actor.

`modify`函数由`Replicator` actor调用，因此必须是纯函数，仅使用数据参数和封闭范围内的稳定字段。例如：
它不能够访问封闭范围内的 `sender()` *（当前actor上下文中的`sender()`）* 。

`Update` is intended to only be sent from an actor running in same local `ActorSystem`
 as the `Replicator`, because the `modify` function is typically not serializable.

更新仅用于发送到与`Replicator`相同的本地ActorSystem中运行的actor，因为`modify`函数通常是不可序列化的。

You supply a write consistency level which has the following meaning:

你可以提供写入一致性级别，其含义如下：

 * @scala[`WriteLocal`]@java[`writeLocal`] the value will immediately only be written to the local replica,
and later disseminated with gossip
 * `WriteTo(n)` the value will immediately be written to at least `n` replicas,
including the local replica
 * `WriteMajority` the value will immediately be written to a majority of replicas, i.e.
at least **N/2 + 1** replicas, where N is the number of nodes in the cluster
(or cluster role group)
 * `WriteAll` the value will immediately be written to all nodes in the cluster
(or all nodes in the cluster role group)

 * `WriteLocal`会将值立即写入本地副本（并返回），然后用gossip来传播
 * `WriteTo(n)`将该值立即写入至少N个副本，包括本地副本
 * `WriteMajority`将值立即写入大多数副本，即至少 **N/2 + 1** 个副本，其中 N 是集群（或集群角色组）的节点数。
 * `WriteAll`将值立即写入集群（或集群角色组）的所有节点

When you specify to write to `n` out of `x`  nodes, the update will first replicate to `n` nodes.
If there are not enough Acks after a 1/5th of the timeout, the update will be replicated to `n` other
nodes. If there are less than n nodes left all of the remaining nodes are used. Reachable nodes
are preferred over unreachable nodes.

当你指定从x个节点中写入n时，更新将首先复制到n个节点。如果在超时到达后没有收到足够的1/5个Ack，则更新将复制到其他n个节点。
如果剩余（未收到Ack）少于n个节点，则使用所有剩余节点。可达节点优先于不可达节点（被复制）。

Note that `WriteMajority` has a `minCap` parameter that is useful to specify to achieve better safety for small clusters.

请注意，`WriteMajority`有一个`minCap`参数，可用于指定（最小复制节点数）为小型集群提供更好的安全性。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #update }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #update }

As reply of the `Update` a `Replicator.UpdateSuccess` is sent to the sender of the
`Update` if the value was successfully replicated according to the supplied consistency
level within the supplied timeout. Otherwise a `Replicator.UpdateFailure` subclass is
sent back. Note that a `Replicator.UpdateTimeout` reply does not mean that the update completely failed
or was rolled back. It may still have been replicated to some nodes, and will eventually
be replicated to all nodes with the gossip protocol.

如果在提供的一致性级别内设置的超时值（结束前）成功复制了值，则`Replicator.UpdateSuccess`将会作为`Update`的回复发送给更新的发送者。
否则，将发回`Replicator.UpdateFailure`的子类。请注意，`Replicator.UpdateTimeout`回复并不意味着更新完全失败或已回滚。
它可能仍然被复制到某些节点，并最终将使用gossip协议复制到所有节点。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #update-response1 }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #update-response1 }


Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #update-response2 }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #update-response2 }

You will always see your own writes. For example if you send two `Update` messages
changing the value of the same `key`, the `modify` function of the second message will
see the change that was performed by the first `Update` message.

你总会看到自己的写。例如，如果发送两条`Update`消息，更改同一`key`的值，
则第二条消息的`modify`功能将看到第一条`Update`消息所执行的更改。

In the `Update` message you can pass an optional request context, which the `Replicator`
does not care about, but is included in the reply messages. This is a convenient
way to pass contextual information (e.g. original sender) without having to use `ask`
or maintain local correlation data structures.

在`Update`消息中，你可以传递可选的请求上下文，`Replicator`不关心该上下文，但是会包含在回复消息中。
这是传递上下文信息（例如：原始发送者）的便捷方式，而不必使用`ask`或维护本地相关数据结构。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #update-request-context }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #update-request-context }

<a id="replicator-get"></a>
### Get

### Get（得到）

To retrieve the current value of a data you send `Replicator.Get` message to the
`Replicator`. You supply a consistency level which has the following meaning:

要检索数据的当前值，请将`Replicator.Get`消息发送到`Replicator`。你提供的一致性级别具有以下含义：

 * @scala[`ReadLocal`]@java[`readLocal`] the value will only be read from the local replica
 * `ReadFrom(n)` the value will be read and merged from `n` replicas,
including the local replica
 * `ReadMajority` the value will be read and merged from a majority of replicas, i.e.
at least **N/2 + 1** replicas, where N is the number of nodes in the cluster
(or cluster role group)
 * `ReadAll` the value will be read and merged from all nodes in the cluster
(or all nodes in the cluster role group)

 * `ReadLocal`将只从本地副本读取值
 * `ReadFrom(n)`将从`n`个复本读取并合并值（其中包括本地副本）
 * `ReadMajority`将从大多数副本读取并合并值。即至少 **N/2 + 1** 个副本。其中N是集群（或集群角色组）内所有节点的个数。
 * `ReadAll`将从集群（或集群角色组）内所有节点读取并合并值。

Note that `ReadMajority` has a `minCap` parameter that is useful to specify to achieve better safety for small clusters.

注意，`ReadMajority`有一个`minCap`参数，可用于指定（要读取的最小副本数）为小型集群实现更好的安全性。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #get }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #get }

As reply of the `Get` a `Replicator.GetSuccess` is sent to the sender of the
`Get` if the value was successfully retrieved according to the supplied consistency
level within the supplied timeout. Otherwise a `Replicator.GetFailure` is sent.
If the key does not exist the reply will be `Replicator.NotFound`.

如果根据在提供的一致性级别设置的超时内成功检索到值，则将`Replicator.GetSuccess`回复发送给`Get`的发送方。否则将发送
`Replicator.GetFailure`。如果`key`不存在，则回复将为`Replicator.NotFound`。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #get-response1 }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #get-response1 }


Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #get-response2 }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #get-response2 }

You will always read your own writes. For example if you send a `Update` message
followed by a `Get` of the same `key` the `Get` will retrieve the change that was
performed by the preceding `Update` message. However, the order of the reply messages are
not defined, i.e. in the previous example you may receive the `GetSuccess` before
the `UpdateSuccess`.

你将永远阅读自己的写。例如，如果你发送`Update`消息后马上跟`Get`来获取相同的`key`的值，
则`Get`将检索由前面的`Update`消息执行的更改。但是，未定义回复消息的顺序，即在前面的示例中，
你可能会在`UpdateSuccess`之前收到`GetSuccess`。

In the `Get` message you can pass an optional request context in the same way as for the
`Update` message, described above. For example the original sender can be passed and replied
to after receiving and transforming `GetSuccess`.

在`Get`消息中，你可以按照与上述更新消息相同的方式传递可选的请求上下文。例如，
可以在接收和转换`GetSuccess`之后传递和回复原始发件者。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #get-request-context }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #get-request-context }

### Consistency

### 一致性

The consistency level that is supplied in the [Update](#replicator-update) and [Get](#replicator-get)
specifies per request how many replicas that must respond successfully to a write and read request.

[Update](#replicator-update) 和 [Get](#replicator-get) 中提供的一致性级别指定每个请求必须成功响应写入和读取请求的副本数量。

For low latency reads you use @scala[`ReadLocal`]@java[`readLocal`] with the risk of retrieving stale data, i.e. updates
from other nodes might not be visible yet.

对于低延迟读取，你使用`ReadLocal`存在检索过时数据的风险，即可能尚未显示来自其他节点的更新。

When using @scala[`WriteLocal`]@java[`writeLocal`] the update is only written to the local replica and then disseminated
in the background with the gossip protocol, which can take few seconds to spread to all nodes.

使用`WriteLocal`时，更新仅写入本地副本，然后使用gossip协议在后台传播，这可能需要几秒钟才能传播到所有节点。

`WriteAll` and `ReadAll` is the strongest consistency level, but also the slowest and with
lowest availability. For example, it is enough that one node is unavailable for a `Get` request
and you will not receive the value.

`WriteAll`和`ReadAll`是最强的一致性级别，但也是最慢且可用性最低的。例如，当一个节点不可用时`Get`请求就失败了，
你将不会收到该值。

If consistency is important, you can ensure that a read always reflects the most recent
write by using the following formula:

如果一致性很重要，则可以使用以下公式确保读取始终反映最近的写入：

```
(nodes_written + nodes_read) > N
```

where N is the total number of nodes in the cluster, or the number of nodes with the role that is
used for the `Replicator`.

其中N是集群中的节点总数，或具有用于`Replicator`的角色的节点数。

For example, in a 7 node cluster this these consistency properties are achieved by writing to 4 nodes
and reading from 4 nodes, or writing to 5 nodes and reading from 3 nodes.

例如，在7个节点集群中，这些一致性属性是通过写入4个节点并从4个节点读取，或写入5个节点并从3个节点读取来实现的。

By combining `WriteMajority` and `ReadMajority` levels a read always reflects the most recent write.
The `Replicator` writes and reads to a majority of replicas, i.e. **N / 2 + 1**. For example,
in a 5 node cluster it writes to 3 nodes and reads from 3 nodes. In a 6 node cluster it writes
to 4 nodes and reads from 4 nodes.

通过组合`WriteMajority`和`ReadMajority`级别，读取始终反映最近的写入。`Replicator`写入和读取大多数副本，即 **N / 2 + 1** 。
例如，在5个节点集群中，它写入3个节点并从3个节点读取；在6节点集群中，它写入4个节点并从4个节点读取。

You can define a minimum number of nodes for `WriteMajority` and `ReadMajority`,
this will minimize the risk of reading stale data. Minimum cap is
provided by minCap property of `WriteMajority` and `ReadMajority` and defines the required majority.
If the minCap is higher then **N / 2 + 1** the minCap will be used.

你可以为`WriteMajority`和`ReadMajority`定义最小数量的节点，这将最大程度地降低读取过时数据的风险。
最小上限由`WriteMajority`和`ReadMajority`的`minCap`属性提供，并定义所需的数量。
如果`minCap`高于 **N / 2 + 1**（且小于等于N），则将使用`minCap`。

For example if the minCap is 5 the `WriteMajority` and `ReadMajority` for cluster of 3 nodes will be 3, for
cluster of 6 nodes will be 5 and for cluster of 12 nodes will be 7 ( **N / 2 + 1** ).

例如，如果`minCap`为5，则3个节点的集群的`WriteMajority`和`ReadMajority`将为3，对于6个节点的集群将为5，
对于12个节点的集群将为7（N / 2 + 1）。

For small clusters (<7) the risk of membership changes between a WriteMajority and ReadMajority
is rather high and then the nice properties of combining majority write and reads are not
guaranteed. Therefore the `ReadMajority` and `WriteMajority` have a `minCap` parameter that
is useful to specify to achieve better safety for small clusters. It means that if the cluster
size is smaller than the majority size it will use the `minCap` number of nodes but at most
the total size of the cluster.

对于小型集群（<7），`WriteMajority`和`ReadMajority`之间成员状态变化的风险相当高，
然后无法保证组合多数写入和读取的良好属性。 因此，ReadMajority和WriteMajority有一个minCap参数，可用于指定为小型集群实现更好的安全性。 这意味着如果集群大小小于大多数大小，它将使用minCap节点数，但最多使用集群的总大小。

Here is an example of using `WriteMajority` and `ReadMajority`:

以下是使用`WriteMajority`和`ReadMajority`的示例：

Scala
: @@snip [ShoppingCart.scala](/akka-docs/src/test/scala/docs/ddata/ShoppingCart.scala) { #read-write-majority }

Java
: @@snip [ShoppingCart.java](/akka-docs/src/test/java/jdocs/ddata/ShoppingCart.java) { #read-write-majority }


Scala
: @@snip [ShoppingCart.scala](/akka-docs/src/test/scala/docs/ddata/ShoppingCart.scala) { #get-cart }

Java
: @@snip [ShoppingCart.java](/akka-docs/src/test/java/jdocs/ddata/ShoppingCart.java) { #get-cart }


Scala
: @@snip [ShoppingCart.scala](/akka-docs/src/test/scala/docs/ddata/ShoppingCart.scala) { #add-item }

Java
: @@snip [ShoppingCart.java](/akka-docs/src/test/java/jdocs/ddata/ShoppingCart.java) { #add-item }

In some rare cases, when performing an `Update` it is needed to first try to fetch latest data from
other nodes. That can be done by first sending a `Get` with `ReadMajority` and then continue with
the `Update` when the `GetSuccess`, `GetFailure` or `NotFound` reply is received. This might be
needed when you need to base a decision on latest information or when removing entries from an `ORSet`
or `ORMap`. If an entry is added to an `ORSet` or `ORMap` from one node and removed from another
node the entry will only be removed if the added entry is visible on the node where the removal is
performed (hence the name observed-removed set).

在极少数情况下，执行更新时需要先尝试从其他节点获取最新数据。这可以通过先使用`ReadMajority`发送`Get`请求来完成，
然后在收到`GetSuccess`，`GetFailure`或`NotFound`回复后再继续更新。
当你需要根据最新信息或从`ORSet`或`ORMap`中删除条目时可能需要这样做。如果条目从一个节点添加到`ORSet`或`ORMap`
并从另一个节点中删除，则只有在执行删除的节点上显示添加的条目时才会删除该条目（因此名称为observe-removed set）。

The following example illustrates how to do that:

以下示例说明了如何执行此操作：

Scala
: @@snip [ShoppingCart.scala](/akka-docs/src/test/scala/docs/ddata/ShoppingCart.scala) { #remove-item }

Java
: @@snip [ShoppingCart.java](/akka-docs/src/test/java/jdocs/ddata/ShoppingCart.java) { #remove-item }

@@@ warning

*Caveat:* Even if you use `WriteMajority` and `ReadMajority` there is small risk that you may
read stale data if the cluster membership has changed between the `Update` and the `Get`.
For example, in cluster of 5 nodes when you `Update` and that change is written to 3 nodes:
n1, n2, n3. Then 2 more nodes are added and a `Get` request is reading from 4 nodes, which
happens to be n4, n5, n6, n7, i.e. the value on n1, n2, n3 is not seen in the response of the
`Get` request.

*警告：* 即使你使用`WriteMajority`和`ReadMajority`，如果集群成员资格在`Update`和`Get`之间发生了变化，
你也可能会读取过时数据。例如，当你在5个节点的集群中做更新操作时，该更改将写入3个节点：n1，n2，n3。然后再添加2个节点，
Get请求从4个节点读取，恰好是n4，n5，n6，n7，即在Get请求的响应中看不到n1，n2，n3上的值。
（这时需要调整副本的数量来覆盖7个节点的大多数）
@@@

### Subscribe

### 订阅

You may also register interest in change notifications by sending `Replicator.Subscribe`
message to the `Replicator`. It will send `Replicator.Changed` messages to the registered
subscriber when the data for the subscribed key is updated. Subscribers will be notified
periodically with the configured `notify-subscribers-interval`, and it is also possible to
send an explicit `Replicator.FlushChanges` message to the `Replicator` to notify the subscribers
immediately.

你还可以通过向`Replicator`发送`Replicator.Subscribe`消息来注册感兴趣的更改通知。当订阅的key的数据更新时，
它将向注册订户发送`Replicator.Changed`消息。将使用配置的`notify-subscribers-interval`定期通知订户，
并且还可以向`Replicator`发送显式`Replicator.FlushChanges`消息以立即通知订户。

The subscriber is automatically removed if the subscriber is terminated. A subscriber can
also be deregistered with the `Replicator.Unsubscribe` message.

如果订户终止，则自动删除订户。订户也可以使用`Replicator.Unsubscribe`消息注销订阅。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #subscribe }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #subscribe }

### Delete

### 删除

A data entry can be deleted by sending a `Replicator.Delete` message to the local
local `Replicator`. As reply of the `Delete` a `Replicator.DeleteSuccess` is sent to
the sender of the `Delete` if the value was successfully deleted according to the supplied
consistency level within the supplied timeout. Otherwise a `Replicator.ReplicationDeleteFailure`
is sent. Note that `ReplicationDeleteFailure` does not mean that the delete completely failed or
was rolled back. It may still have been replicated to some nodes, and may eventually be replicated
to all nodes.

可以通过向本地`Replicator`发送`Replicator.Delete`消息来删除数据条目。如果在根据提供一致性级别设置的超时内成功删除了值，
则将`Delete`操作的`Replicator.DeleteSuccess`的回复发送给`Delete`的发送方。否则，
将发送`Replicator.ReplicationDeleteFailure`。请注意，`ReplicationDeleteFailure`并不意味着删除完全失败或已回滚。
它可能仍然被复制到某些节点，并最终可能会复制到所有节点。

A deleted key cannot be reused again, but it is still recommended to delete unused
data entries because that reduces the replication overhead when new nodes join the cluster.
Subsequent `Delete`, `Update` and `Get` requests will be replied with `Replicator.DataDeleted`.
Subscribers will receive `Replicator.Deleted`.

删除的key不能再次重用，但仍建议删除未使用的数据条目，因为这会减少新节点加入集群时的复制开销。
将使用`Replicator.DataDeleted`回复后续的`Delete`，`Update`和`Get`请求。订阅者将收到`Replicator.Deleted`。

In the *Delete* message you can pass an optional request context in the same way as for the
*Update* message, described above. For example the original sender can be passed and replied
to after receiving and transforming *DeleteSuccess*.

在 *Delete* 消息中，你可以按照与上述更新消息相同的方式传递可选的请求上下文。例如，在接收和转换`DeleteSuccess`之后，
可以传递和回复原始发送者。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #delete }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #delete }

@@@ warning

As deleted keys continue to be included in the stored data on each node as well as in gossip
messages, a continuous series of updates and deletes of top-level entities will result in
growing memory usage until an ActorSystem runs out of memory. To use Akka Distributed Data
where frequent adds and removes are required, you should use a fixed number of top-level data
types that support both updates and removals, for example `ORMap` or `ORSet`.

由于删除的key继续包含在每个节点上的存储数据以及gossip消息中，顶级实体在连接一系列更新和删除时将导致内存使用量增加，
直到ActorSystem耗尽内存。要使用需要频繁添加和删除的Akka分布式数据，你应该使用固定数量的支持更新和删除的顶级数据类型，
例如`ORMap`或`ORSet`。

@@@

<a id="delta-crdt"></a>
### delta-CRDT

### Δ-CRDT

[Delta State Replicated Data Types](http://arxiv.org/abs/1603.01529)
are supported. A delta-CRDT is a way to reduce the need for sending the full state
for updates. For example adding element `'c'` and `'d'` to set `{'a', 'b'}` would
result in sending the delta `{'c', 'd'}` and merge that with the state on the
receiving side, resulting in set `{'a', 'b', 'c', 'd'}`.

支持 [增量状态复制数据类型](http://arxiv.org/abs/1603.01529)。delta-CRDT是一种减少发送更新完整状态的方法。例如，
添加元素`'c'`和`'d'`到set `{'a'，'b'}`将导致发送delta `{'c'，'d'}`并将其与接收端的状态合并，
最终结果是set `{'a'，'b'，'c'，'d'}`。

The protocol for replicating the deltas supports causal consistency if the data type
is marked with `RequiresCausalDeliveryOfDeltas`. Otherwise it is only eventually
consistent. Without causal consistency it means that if elements `'c'` and `'d'` are
added in two separate *Update* operations these deltas may occasionally be propagated
to nodes in a different order to the causal order of the updates. For this example it
can result in that set `{'a', 'b', 'd'}` can be seen before element 'c' is seen. Eventually
it will be `{'a', 'b', 'c', 'd'}`.

如果数据类型标记为`RequiresCausalDeliveryOfDeltas`，则复制增量的协议支持因果一致性。否则它是最终一致性的。
如果没有因果一致性，则意味着如果在两个单独的`Update`操作中分别添加元素`'c'`和`'d'`，
则这些增量可能偶尔以不同的顺序传播到节点，以更新的因果顺序。对于这个例子，它可以导致在看到元素`'c'`之前可以看到set
`{'a'，'b'，'d'}`。最终它将是 `{'a'，'b'，'c'，'d'}`。

Note that the full state is occasionally also replicated for delta-CRDTs, for example when
new nodes are added to the cluster or when deltas could not be propagated because
of network partitions or similar problems.

请注意，有时也会为delta-CRDT复制完整状态，例如，当新节点添加到集群或由于网络分区或类似问题而无法传播增量时。

The the delta propagation can be disabled with configuration property:

可以使用配置属性禁用增量传播：

```
akka.cluster.distributed-data.delta-crdt.enabled=off
```

## Data Types

## 数据类型

The data types must be convergent (stateful) CRDTs and implement the @scala[`ReplicatedData` trait]@java[`AbstractReplicatedData` interface],
i.e. they provide a monotonic merge function and the state changes always converge.

数据类型必须是收敛的（有状态的）CRDT并实现 @scala[`ReplicatedData` trait] ，即它们提供单调合并函数并且状态变化总是收敛。

You can use your own custom @scala[`ReplicatedData` or `DeltaReplicatedData`]@java[`AbstractReplicatedData` or `AbstractDeltaReplicatedData`] types, and several types are provided
by this package, such as:

你可以使用自己的自定义 @scala[`ReplicatedData` or `DeltaReplicatedData`] 类型，此包提供了几种类型，例如：

 * Counters: `GCounter`, `PNCounter`
 * Sets: `GSet`, `ORSet`
 * Maps: `ORMap`, `ORMultiMap`, `LWWMap`, `PNCounterMap`
 * Registers: `LWWRegister`, `Flag`

### Counters
### 计数器

`GCounter` is a "grow only counter". It only supports increments, no decrements.

`GCounter`是一个“成长专用型计数器”。它只支持增加，不支持减少。

It works in a similar way as a vector clock. It keeps track of one counter per node and the total
value is the sum of these counters. The `merge` is implemented by taking the maximum count for
each node.

它的工作方式与矢量时钟类似。它跟踪每个节点的计数器，总值是这些计数器的总和。通过获取每个节点的最大计数来实现合并。

If you need both increments and decrements you can use the `PNCounter` (positive/negative counter).

如果你需要增加和减少，你可以使用PNCounter（正/负计数器）。

It is tracking the increments (P) separate from the decrements (N). Both P and N are represented
as two internal `GCounter`s. Merge is handled by merging the internal P and N counters.
The value of the counter is the value of the P counter minus the value of the N counter.

它分开跟踪增加（P）与减少（N）。P和N都表示为两个内部`GCounters`。通过合并内部P和N计数器来处理合并。
计数器的值是P计数器的值减去N计数器的值。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #pncounter }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #pncounter }

`GCounter` and `PNCounter` have support for [delta-CRDT](#delta-crdt) and don't need causal
delivery of deltas.

`GCounter`和`PNCounter`支持 [delta-CRDT](#delta-crdt) ，不需要因果递送。

Several related counters can be managed in a map with the `PNCounterMap` data type.
When the counters are placed in a `PNCounterMap` as opposed to placing them as separate top level
values they are guaranteed to be replicated together as one unit, which is sometimes necessary for
related data.

可以使用`PNCounterMap`数据类型在`Map`中管理多个相关联的计数器。
当计数器放在`PNCounterMap`中而不是将它们作为单独的顶级值放置时，它们可以保证作为一个单元一起复制，
这有时是相关数据所必需的。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #pncountermap }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #pncountermap }

### Sets

If you only need to add elements to a set and not remove elements the `GSet` (grow-only set) is
the data type to use. The elements can be any type of values that can be serialized.
Merge is the union of the two sets.

如果你只需要向集合中添加元素而不删除元素，则`GSet`（仅增长set）是要使用的数据类型。元素是可以序列化的任何类型的值。
合并是两个set的并集（操作）。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #gset }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #gset }

`GSet` has support for [delta-CRDT](#delta-crdt) and it doesn't require causal delivery of deltas.

`GSet`支持`delta-CRDT`，它不需要因果递送。

If you need add and remove operations you should use the `ORSet` (observed-remove set).
Elements can be added and removed any number of times. If an element is concurrently added and
removed, the add will win. You cannot remove an element that you have not seen.

如果需要添加和删除操作，则应使用`ORSet`（observe-remove set）。可以多次添加和删除元素。
如果同时添加和删除元素，则添加将获胜。你无法删除尚未看到的元素。

The `ORSet` has a version vector that is incremented when an element is added to the set.
The version for the node that added the element is also tracked for each element in a so
called "birth dot". The version vector and the dots are used by the `merge` function to
track causality of the operations and resolve concurrent updates.

`ORSet`具有一个版本向量，当元素添加到集合时，该向量会递增。还会为所谓的“出生点”中的每个元素跟踪添加元素的节点的版本。
`merge`函数使用版本向量和（出生）点来跟踪操作的因果关系并解决并发更新。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #orset }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #orset }

`ORSet` has support for [delta-CRDT](#delta-crdt) and it requires causal delivery of deltas.

`ORSet`支持`delta-CRDT`也它需要因果递送。

### Maps

`ORMap` (observed-remove map) is a map with keys of `Any` type and the values are `ReplicatedData`
types themselves. It supports add, update and remove any number of times for a map entry.

`ORMap`（observe-remove map）是一个具有Any类型key，value是`ReplicatedData`类型。
它支持为`Map`条目（entry）add，update和remove任意次。

If an entry is concurrently added and removed, the add will win. You cannot remove an entry that
you have not seen. This is the same semantics as for the `ORSet`.

如果同时添加和删除条目，则添加将获胜。你无法删除尚未看到的条目。这与`ORSet`的语义相同。

If an entry is concurrently updated to different values the values will be merged, hence the
requirement that the values must be `ReplicatedData` types.

如果条目同时更新为不同的值，则将合并这些值，因此要求值必须为`ReplicatedData`类型。

It is rather inconvenient to use the `ORMap` directly since it does not expose specific types
of the values. The `ORMap` is intended as a low level tool for building more specific maps,
such as the following specialized maps.

直接使用`ORMap`相当不方便，因为它不会暴露特定类型的值。`ORMap`旨在用作构建更具体`Map`的低级工具，例如以下专用`Map`：

`ORMultiMap` (observed-remove multi-map) is a multi-map implementation that wraps an
`ORMap` with an `ORSet` for the map's value.

`ORMultiMap`（observe-remove multi-map）是一个多映射（值）实现，它使用`ORSet`包装`ORMap`以获取映射的value。

`PNCounterMap` (positive negative counter map) is a map of named counters (where the name can be of any type).
It is a specialized `ORMap` with `PNCounter` values.

`PNCounterMap`（正负计数器map）是命名计数器的map（其中名称可以是任何类型）。它是具有`PNCounter` value的专用`ORMap`。

`LWWMap` (last writer wins map) is a specialized `ORMap` with `LWWRegister` (last writer wins register)
values.

`LWWMap`（最后一个写赢map）是一个带有`LWWRegister`（最后一个注册获胜）value的专用`ORMap`。

`ORMap`, `ORMultiMap`, `PNCounterMap` and `LWWMap` have support for [delta-CRDT](#delta-crdt) and they require causal
delivery of deltas. Support for deltas here means that the `ORSet` being underlying key type for all those maps
uses delta propagation to deliver updates. Effectively, the update for map is then a pair, consisting of delta for the `ORSet`
being the key and full update for the respective value (`ORSet`, `PNCounter` or `LWWRegister`) kept in the map.

`ORMap`，`ORMultiMap`，`PNCounterMap`和`LWWMap`支持 [delta-CRDT](#delta-crdt) ，它们需要因果递送。
这里对增量的支持意味着作为所有这些映射的基础key类型的`ORSet`使用增量传播来提供更新。实际上，`map`的更新是成对的，
包括作为key的`ORSet`的delta和对映射中保存的相应值（`ORSet`，`PNCounter`或`LWWRegister`）的完全更新。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #ormultimap }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #ormultimap }

When a data entry is changed the full state of that entry is replicated to other nodes, i.e.
when you update a map, the whole map is replicated. Therefore, instead of using one `ORMap`
with 1000 elements it is more efficient to split that up in 10 top level `ORMap` entries
with 100 elements each. Top level entries are replicated individually, which has the
trade-off that different entries may not be replicated at the same time and you may see
inconsistencies between related entries. Separate top level entries cannot be updated atomically
together.

更改数据条目时，该条目的完整状态将复制到其他节点，即更新map时，将复制整个map。因此，
不是将一个`ORMap`与1000个元素一起使用，而是将它分成10个顶级`ORMap`条目，每个元素包含100个元素。顶级条目是单独复制的，
这需要权衡不同的条目可能不会同时复制，你可能会看到相关条目之间的不一致。单独的顶级条目无法一起原子更新。

There is a special version of `ORMultiMap`, created by using separate constructor
`ORMultiMap.emptyWithValueDeltas[A, B]`, that also propagates the updates to its values (of `ORSet` type) as deltas.
This means that the `ORMultiMap` initiated with `ORMultiMap.emptyWithValueDeltas` propagates its updates as pairs
consisting of delta of the key and delta of the value. It is much more efficient in terms of network bandwidth consumed.

`ORMultiMap`有一个特殊版本，它使用单独的构造函数`ORMultiMap.emptyWithValueDeltas[A，B]`创建，
它还将更新传播到其value（`ORSet`类型）作为增量。这意味着使用`ORMultiMap.emptyWithValueDeltas`启动的`ORMultiMap`
将其更新传播为由key的delta和value的delta组成的对。就消耗的网络带宽而言，它更有效。

However, this behavior has not been made default for `ORMultiMap` and if you wish to use it in your code, you
need to replace invocations of `ORMultiMap.empty[A, B]` (or `ORMultiMap()`) with `ORMultiMap.emptyWithValueDeltas[A, B]`
where `A` and `B` are types respectively of keys and values in the map.

但是，对于`ORMultiMap`，此尚未是默认行为，如果你希望在代码中使用它，则需要使用`ORMultiMap.emptyWithValueDeltas[A，B]`
替换`ORMultiMap.empty[A，B]`（或`ORMultiMap()`）的调用。其中`A`和`B`分别是Map中key和value的类型。

Please also note, that despite having the same Scala type, `ORMultiMap.emptyWithValueDeltas`
is not compatible with 'vanilla' `ORMultiMap`, because of different replication mechanism.
One needs to be extra careful not to mix the two, as they have the same
type, so compiler will not hint the error.
Nonetheless `ORMultiMap.emptyWithValueDeltas` uses the same `ORMultiMapKey` type as the
'vanilla' `ORMultiMap` for referencing.

注意，尽管具有相同的Scala类型，但由于复制机制不同，`ORMultiMap.emptyWithValueDeltas`与“vanilla”（香草）
`ORMultiMap`不兼容。需要特别注意不要混淆两者，因为它们具有相同的类型，因此编译器不会提示错误。尽管如此，
`ORMultiMap.emptyWithValueDeltas`使用与“vanilla”（香草）`ORMultiMap`相同的`ORMultiMapKey`类型进行引用。

Note that `LWWRegister` and therefore `LWWMap` relies on synchronized clocks and should only be used
when the choice of value is not important for concurrent updates occurring within the clock skew. Read more
in the below section about `LWWRegister`.

注意，`LWWRegister`和`LWWMap`依赖于同步时钟，并且只应在value的选择对时钟偏差内发生的并发更新不重要时使用。
请阅读以下有关`LWWRegister`的部分。

### Flags and Registers
### 旗帜和登记

`Flag` is a data type for a boolean value that is initialized to `false` and can be switched
to `true`. Thereafter it cannot be changed. `true` wins over `false` in merge.

`Flag`是布尔值的数据类型，初始化为`false`并且可以切换为`true`。此后它无法更改。合并是的`true`胜过`fals`e。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #flag }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #flag }

`LWWRegister` (last writer wins register) can hold any (serializable) value.

`LWWRegister`（最后一个注册写获胜）可以保存任何（可序列化）值。

Merge of a `LWWRegister` takes the register with highest timestamp. Note that this
relies on synchronized clocks. *LWWRegister* should only be used when the choice of
value is not important for concurrent updates occurring within the clock skew.

`LWWRegister`的合并时使具有最高时间戳register（有效）。请注意，这取决于同步时钟。
仅当值的选择对时钟偏差内发生的并发更新不重要时，才应使用`LWWRegister`。

Merge takes the register updated by the node with lowest address (`UniqueAddress` is ordered)
if the timestamps are exactly the same.

如果时间戳完全相同，则Merge将使用具有最低地址的节点来更新register（`UniqueAddress`是有序的）。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #lwwregister }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #lwwregister }

Instead of using timestamps based on `System.currentTimeMillis()` time it is possible to
use a timestamp value based on something else, for example an increasing version number
from a database record that is used for optimistic concurrency control.

可以使用基于其他内容的时间戳值来代替使用基于`System.currentTimeMillis()`的时间戳。例如，
用于乐观并发控制的数据库记录中的递增版本号。

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #lwwregister-custom-clock }

Java
: @@snip [DistributedDataDocTest.java](/akka-docs/src/test/java/jdocs/ddata/DistributedDataDocTest.java) { #lwwregister-custom-clock }

For first-write-wins semantics you can use the `LWWRegister#reverseClock` instead of the
`LWWRegister#defaultClock`.

对于第一个写成功（first-write-wins）语义，你可以使用`LWWRegister#reverseClock`而不是`LWWRegister#defaultClock`。

The `defaultClock` is using max value of `System.currentTimeMillis()` and `currentTimestamp + 1`.
This means that the timestamp is increased for changes on the same node that occurs within
the same millisecond. It also means that it is safe to use the `LWWRegister` without
synchronized clocks when there is only one active writer, e.g. a Cluster Singleton. Such a
single writer should then first read current value with `ReadMajority` (or more) before
changing and writing the value with `WriteMajority` (or more).

`defaultClock`使用`System.currentTimeMillis()`和`currentTimestamp + 1`的最大值。
这意味着对于在同一毫秒内发生的同一节点上的更改，时间戳会增加。这也意味着当只有一个活动的写入器时，
使用没有同步时钟的`LWWRegister`是安全的。比如：集群单例。然后，在使用`WriteMajority`（或更多）更改和写入值之前，
这样的单个writer应首先使用`ReadMajority`（或更多）读取当前值。

### Custom Data Type
### 自定义数据类型

You can implement your own data types. The only requirement is that it implements
the @scala[`merge`]@java[`mergeData`] function of the @scala[`ReplicatedData`]@java[`AbstractReplicatedData`] trait.

你可以实现自己的数据类型。只需要实现`ReplicatedData` trait 的 `merge` 函数即可。

A nice property of stateful CRDTs is that they typically compose nicely, i.e. you can combine several
smaller data types to build richer data structures. For example, the `PNCounter` is composed of
two internal `GCounter` instances to keep track of increments and decrements separately.

有状态CRDT的一个很好的特性是它们通常组合得很好，即你可以组合几种较小的数据类型来构建更丰富的数据结构。例如，
`PNCounter`由两个内部`GCounter`实例组成，以分别跟踪增量和减量。

Here is s simple implementation of a custom `TwoPhaseSet` that is using two internal `GSet` types
to keep track of addition and removals.  A `TwoPhaseSet` is a set where an element may be added and
removed, but never added again thereafter.

这是一个自定义`TwoPhaseSet`的简单实现，它使用两个内部`GSet`类型来跟踪添加和删除。
`TwoPhaseSet`是一个可以添加和删除元素的Set，但添加之后不可再此添加。

Scala
: @@snip [TwoPhaseSet.scala](/akka-docs/src/test/scala/docs/ddata/TwoPhaseSet.scala) { #twophaseset }

Java
: @@snip [TwoPhaseSet.java](/akka-docs/src/test/java/jdocs/ddata/TwoPhaseSet.java) { #twophaseset }

Data types should be immutable, i.e. "modifying" methods should return a new instance.

数据类型应该是不可变的，即“修改”方法应该返回一个新实例。

Implement the additional methods of @scala[`DeltaReplicatedData`]@java[`AbstractDeltaReplicatedData`] if it has support for delta-CRDT replication.

如果实现了`DeltaReplicatedData`的附加方法则可以支持`delta-CRDT`复制。

#### Serialization
#### 序列化

The data types must be serializable with an @ref:[Akka Serializer](serialization.md).
It is highly recommended that you implement  efficient serialization with Protobuf or similar
for your custom data types. The built in data types are marked with `ReplicatedDataSerialization`
and serialized with `akka.cluster.ddata.protobuf.ReplicatedDataSerializer`.

数据类型必须使用 @ref:[Akka Serializer](serialization.md) 进行序列化。
强烈建议你使用Protobuf或类似的自定义数据类型实现高效序列化。内置数据类型使用`ReplicatedDataSerialization`标记，
并使用`akka.cluster.ddata.protobuf.ReplicatedDataSerializer`进行序列化。

Serialization of the data types are used in remote messages and also for creating message
digests (SHA-1) to detect changes. Therefore it is important that the serialization is efficient
and produce the same bytes for the same content. For example sets and maps should be sorted
deterministically in the serialization.

数据类型的序列化用于远程消息，也用于创建消息摘要（SHA-1）以检测更改。因此，
序列化是有效的并且为相同内容产生相同的字节是很重要的。例如，应该在序列化中确定性地对集合和映射进行排序。

This is a protobuf representation of the above `TwoPhaseSet`:

这是上述`TwoPhaseSet`的protobuf表示：

@@snip [TwoPhaseSetMessages.proto](/akka-docs/src/test/../main/protobuf/TwoPhaseSetMessages.proto) { #twophaseset }

The serializer for the `TwoPhaseSet`:

`TwoPhaseSet`的序列化程序：

Scala
: @@snip [TwoPhaseSetSerializer.scala](/akka-docs/src/test/scala/docs/ddata/protobuf/TwoPhaseSetSerializer.scala) { #serializer }

Java
: @@snip [TwoPhaseSetSerializer.java](/akka-docs/src/test/java/jdocs/ddata/protobuf/TwoPhaseSetSerializer.java) { #serializer }

Note that the elements of the sets are sorted so the SHA-1 digests are the same
for the same elements.

请注意，set的元素已排序，因此SHA-1摘要对于相同的元素是相同的。

You register the serializer in configuration:

你在配置中注册序列化程序：

Scala
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #serializer-config }

Java
: @@snip [DistributedDataDocSpec.scala](/akka-docs/src/test/scala/docs/ddata/DistributedDataDocSpec.scala) { #japi-serializer-config }

Using compression can sometimes be a good idea to reduce the data size. Gzip compression is
provided by the @scala[`akka.cluster.ddata.protobuf.SerializationSupport` trait]@java[`akka.cluster.ddata.protobuf.AbstractSerializationSupport` interface]:

使用压缩有时可能是减少数据大小的好主意。Gzip压缩由 `akka.cluster.ddata.protobuf.SerializationSupport` trait提供。

Scala
: @@snip [TwoPhaseSetSerializer.scala](/akka-docs/src/test/scala/docs/ddata/protobuf/TwoPhaseSetSerializer.scala) { #compression }

Java
: @@snip [TwoPhaseSetSerializerWithCompression.java](/akka-docs/src/test/java/jdocs/ddata/protobuf/TwoPhaseSetSerializerWithCompression.java) { #compression }

The two embedded `GSet` can be serialized as illustrated above, but in general when composing
new data types from the existing built in types it is better to make use of the existing
serializer for those types. This can be done by declaring those as bytes fields in protobuf:

两个嵌入式`GSet`可以如上所述进行序列化，但通常在从现有内置类型编写新数据类型时，最好对这些类型使用现有的序列化程序。
这可以通过在protobuf中声明为字节字段来完成：

@@snip [TwoPhaseSetMessages.proto](/akka-docs/src/test/../main/protobuf/TwoPhaseSetMessages.proto) { #twophaseset2 }

and use the methods `otherMessageToProto` and `otherMessageFromBinary` that are provided
by the `SerializationSupport` trait to serialize and deserialize the `GSet` instances. This
works with any type that has a registered Akka serializer. This is how such an serializer would
look like for the `TwoPhaseSet`:

并使用`SerializationSupport` trait提供的方法`otherMessageToProto`和`otherMessageFromBinary`来序列化和反序列化`GSet`实例。
 这适用于具有已注册的Akka序列化程序的任何类型。这就是这样的序列化器对于`TwoPhaseSet`的样子：

Scala
: @@snip [TwoPhaseSetSerializer2.scala](/akka-docs/src/test/scala/docs/ddata/protobuf/TwoPhaseSetSerializer2.scala) { #serializer }

Java
: @@snip [TwoPhaseSetSerializer2.java](/akka-docs/src/test/java/jdocs/ddata/protobuf/TwoPhaseSetSerializer2.java) { #serializer }

<a id="ddata-durable"></a>
### Durable Storage
### 耐用（持久）的存储

By default the data is only kept in memory. It is redundant since it is replicated to other nodes
in the cluster, but if you stop all nodes the data is lost, unless you have saved it
elsewhere.

默认情况下，数据仅保留在内存中。它是冗余的，因为它被复制到集群中的其他节点。但如果你停止所有节点数据将丢失，
除非你已将其保存在其他位置。

Entries can be configured to be durable, i.e. stored on local disk on each node. The stored data will be loaded
next time the replicator is started, i.e. when actor system is restarted. This means data will survive as
long as at least one node from the old cluster takes part in a new cluster. The keys of the durable entries
are configured with:

条目可以配置为持久，即存储在每个节点上的本地磁盘上。下次replicator启动时，即当重新启动actor系统时，将加载存储的数据。
这意味着只要旧集群中的至少一个节点参与新集群，数据就会存在。持久条目的key配置为：

```
akka.cluster.distributed-data.durable.keys = ["a", "b", "durable*"]
```

Prefix matching is supported by using `*` at the end of a key.

通过在键的末尾使用`*`来支持前缀匹配。

All entries can be made durable by specifying:

通过指定以下内容，可以使所有条目持久化：

```
akka.cluster.distributed-data.durable.keys = ["*"]
```

@scala[[LMDB](https://symas.com/products/lightning-memory-mapped-database/)]@java[[LMDB](https://github.com/lmdbjava/lmdbjava/)] is the default storage implementation. It is
possible to replace that with another implementation by implementing the actor protocol described in
`akka.cluster.ddata.DurableStore` and defining the `akka.cluster.distributed-data.durable.store-actor-class`
property for the new implementation.

(https://symas.com/products/lightning-memory-mapped-database/) 是默认的存储实现。
通过实现`akka.cluster.ddata.DurableStore`中描述的actor协议并为新实现定义
`akka.cluster.distributed-data.durable.store-actor-class`属性，可以将其替换为另一个实现。

The location of the files for the data is configured with:

数据文件的位置配置为：

Scala
:   ```
# Directory of LMDB file. There are two options:
# 1. A relative or absolute path to a directory that ends with 'ddata'
#    the full name of the directory will contain name of the ActorSystem
#    and its remote port.
# 2. Otherwise the path is used as is, as a relative or absolute path to
#    a directory.
# LMDB文件的目录，有两种选择：
# 1. 以 'ddata' 结尾的目录的相对或绝对路径，该目录的全名将包含ActorSystem的名称及远程端口。
# 2. 否则，路径将按原样使用，目录的相对路径或绝对路径。
akka.cluster.distributed-data.durable.lmdb.dir = "ddata"
```

Java
:   ```
# Directory of LMDB file. There are two options:
# 1. A relative or absolute path to a directory that ends with 'ddata'
#    the full name of the directory will contain name of the ActorSystem
#    and its remote port.
# 2. Otherwise the path is used as is, as a relative or absolute path to
#    a directory.
akka.cluster.distributed-data.durable.lmdb.dir = "ddata"
```


When running in production you may want to configure the directory to a specific
path (alt 2), since the default directory contains the remote port of the
actor system to make the name unique. If using a dynamically assigned
port (0) it will be different each time and the previously stored data
will not be loaded.

在生产中运行时，你可能希望将目录配置为特定路径（alt 2），因为默认目录包含actor系统的远程端口以使名称唯一。
如果使用动态分配的端口(0)，则每次都会有所不同，并且不会加载先前存储的数据。

Making the data durable has a performance cost. By default, each update is flushed
to disk before the `UpdateSuccess` reply is sent. For better performance, but with the risk of losing
the last writes if the JVM crashes, you can enable write behind mode. Changes are then accumulated during
a time period before it is written to LMDB and flushed to disk. Enabling write behind is especially
efficient when performing many writes to the same key, because it is only the last value for each key
that will be serialized and stored. The risk of losing writes if the JVM crashes is small since the
data is typically replicated to other nodes immediately according to the given `WriteConsistency`.

使数据持久具有性能成本。默认情况下，在发送`UpdateSuccess`应答之前，每次更新都会刷新到磁盘。
为了获得更好的性能你可以启用后写模式，但如果JVM崩溃可能会丢失最后一次写入。
然后在将数据写入LMDB并刷新到磁盘之前的一段时间内累积更改。在对同一个key执行多次写入时，启用后写功能特别有效，
因为它只是每个将被序列化和存储的key的最后一个值。如果JVM崩溃，则丢失写入的风险很小，
因为数据通常根据给定的`WriteConsistency`立即复制到其他节点。

```
akka.cluster.distributed-data.durable.lmdb.write-behind-interval = 200 ms
```

Note that you should be prepared to receive `WriteFailure` as reply to an `Update` of a
durable entry if the data could not be stored for some reason. When enabling `write-behind-interval`
such errors will only be logged and `UpdateSuccess` will still be the reply to the `Update`.

请注意，如果由于某种原因无法存储数据，你应该准备接收`WriteFailure`作为对持久条目的更新的回复。
启用`write-behind-interval`时，只会记录此类错误，`UpdateSuccess`仍将是`Update`的回复。

There is one important caveat when it comes pruning of [CRDT Garbage](#crdt-garbage) for durable data.
If an old data entry that was never pruned is injected and merged with existing data after
that the pruning markers have been removed the value will not be correct. The time-to-live
of the markers is defined by configuration
`akka.cluster.distributed-data.durable.remove-pruning-marker-after` and is in the magnitude of days.
This would be possible if a node with durable data didn't participate in the pruning
(e.g. it was shutdown) and later started after this time. A node with durable data should not
be stopped for longer time than this duration and if it is joining again after this
duration its data should first be manually removed (from the lmdb directory).

在修复 [CRDT Garbage](#crdt-garbage) 以获取持久数据时，有一个重要的警告。
如果从未修剪过的旧数据条目被注入并与现有数据合并，则删除修剪标记后，该值将不正确。
标记的生存时间由配置`akka.cluster.distributed-data.durable.remove-pruning-marker-after`定义，单位为天。
如果具有持久数据的节点未参与修剪（例如，它已关闭）并且稍后在此时间之后启动，则这是可能的。
具有持久数据的节点不应该停止比此持续时间更长的时间，并且如果它在此持续时间之后再次加入，
则应首先手动删除其数据（从lmdb目录）。

<a id="crdt-garbage"></a>
### CRDT Garbage
### CRDT垃圾

One thing that can be problematic with CRDTs is that some data types accumulate history (garbage).
For example a `GCounter` keeps track of one counter per node. If a `GCounter` has been updated
from one node it will associate the identifier of that node forever. That can become a problem
for long running systems with many cluster nodes being added and removed. To solve this problem
the `Replicator` performs pruning of data associated with nodes that have been removed from the
cluster. Data types that need pruning have to implement the `RemovedNodePruning` trait. See the
API documentation of the `Replicator` for details.

CRDT可能存在的一个问题是某些数据类型会累积历史记录（垃圾）。 例如，`GCounter`跟踪每个节点的一个计数器。
如果`GCounter`已从一个节点更新，它将永远关联该节点的标识符。对于添加和删除了许多集群节点的长时间运行的系统，
这可能会成为一个问题。为解决此问题，`Replicator`执行与已从集群中删除的节点关联的数据的修剪。
需要修剪的数据类型必须实现`RemovedNodePruning` trait。有关详细信息，请参阅`Replicator`的API文档。

## Samples
## 示例

Several interesting samples are included and described in the
tutorial named @scala[@extref[Akka Distributed Data Samples with Scala](ecs:akka-samples-distributed-data-scala) (@extref[source code](samples:akka-sample-distributed-data-scala))]@java[@extref[Akka Distributed Data Samples with Java](ecs:akka-samples-distributed-data-java) (@extref[source code](samples:akka-sample-distributed-data-java))]

在名为 @extref[Akka分布式数据示例](ecs:akka-samples-distributed-data-scala)
@extref[源码](samples:akka-sample-distributed-data-scala) 的教程中包含并描述了几个有趣的示例（源代码）

 * Low Latency Voting Service
 * Highly Available Shopping Cart
 * Distributed Service Registry
 * Replicated Cache
 * Replicated Metrics

 * 低延迟投票服务
 * 高度可用的购物车
 * 分布式Service Registry
 * 复制缓存
 * 复制指标

## Limitations
## 限制

There are some limitations that you should be aware of.

你应该注意一些限制。

CRDTs cannot be used for all types of problems, and eventual consistency does not fit
all domains. Sometimes you need strong consistency.

CRDT不能用于所有类型的问题，并且最终一致性不适合所有领域。有时你需要强一致性。

It is not intended for *Big Data*. The number of top level entries should not exceed 100000.
When a new node is added to the cluster all these entries are transferred (gossiped) to the
new node. The entries are split up in chunks and all existing nodes collaborate in the gossip,
but it will take a while (tens of seconds) to transfer all entries and this means that you
cannot have too many top level entries. The current recommended limit is 100000. We will
be able to improve this if needed, but the design is still not intended for billions of entries.

它不适用于 *大数据*。顶级条目的数量不应超过100000。将新节点添加到集群时，所有这些条目都将传输（gossip）到新节点。
条目按块分开，所有现有节点在gossip中协作，但转移所有条目需要一段时间（几十秒），这意味着你不能拥有太多顶级条目。
目前的建议限制是100000。如果需要，我们将能够改进这一限制，但设计仍然不适用于数十亿条目。

All data is held in memory, which is another reason why it is not intended for *Big Data*.

所有数据都保存在内存中，这是其不适用于 *大数据* 的另一个原因。

When a data entry is changed the full state of that entry may be replicated to other nodes
if it doesn't support [delta-CRDT](#delta-crdt). The full state is also replicated for delta-CRDTs,
for example when new nodes are added to the cluster or when deltas could not be propagated because
of network partitions or similar problems. This means that you cannot have too large
data entries, because then the remote message size will be too large.

更改数据条目时，如果该条目不支持delta-CRDT，则该条目的完整状态可以复制到其他节点。还会为delta-CRDT复制完整状态，例如，
当新节点添加到集群或由于网络分区或类似问题而无法传播增量时。这意味着你不能拥有太大的数据条目，
因为这样远程消息的大小就会太大。

## Learn More about CRDTs
## 了解有关CRDT的更多信息

 * [Eventually Consistent Data Structures](https://vimeo.com/43903960)
talk by Sean Cribbs
 * [Strong Eventual Consistency and Conflict-free Replicated Data Types (video)](https://www.youtube.com/watch?v=oyUHd894w18&feature=youtu.be)
talk by Mark Shapiro
 * [A comprehensive study of Convergent and Commutative Replicated Data Types](http://hal.upmc.fr/file/index/docid/555588/filename/techreport.pdf)
paper by Mark Shapiro et. al.

 * Sean Cribbs [采用最终一致性的数据结构](https://vimeo.com/43903960) 演讲
 * Mark Shapiro [强最终一致性和无冲突的复制数据类型（视频）](https://www.youtube.com/watch?v=oyUHd894w18&feature=youtu.be) 演讲
 * Mark Shapiro等人 [“收敛和交换复制数据类型”的综合研究]()http://hal.upmc.fr/file/index/docid/555588/filename/techreport.pdf)。

## Configuration
## 配置

The `DistributedData` extension can be configured with the following properties:

可以使用以下属性配置`DistributedData`扩展：

@@snip [reference.conf](/akka-distributed-data/src/main/resources/reference.conf) { #distributed-data }
