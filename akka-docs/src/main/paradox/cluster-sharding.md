# Cluster Sharding

# 集群分片

## Dependency

## 依赖

To use Cluster Sharding, you must add the following dependency in your project:

要使用集群分片，必须在项目中添加以下依赖项：

@@dependency[sbt,Maven,Gradle] {
  group=com.typesafe.akka
  artifact=akka-cluster-sharding_$scala.binary_version$
  version=$akka.version$
}

## Sample project

## 简单项目

You can look at the
@java[@extref[Cluster Sharding example project](samples:akka-samples-cluster-sharding-java)]
@scala[@extref[Cluster Sharding example project](samples:akka-samples-cluster-sharding-scala)]
to see what this looks like in practice.

你可以查看 @extref[集群分片示例项目](samples:akka-samples-cluster-sharding-scala) ，以了解它在实践中的效果。

## Introduction

## 介绍

Cluster sharding is useful when you need to distribute actors across several nodes in the cluster and want to
be able to interact with them using their logical identifier, but without having to care about
their physical location in the cluster, which might also change over time.

当你需要在集群中的多个节点之间分配actor并希望能够使用其逻辑标识符与它们进行交互时，集群分片非常有用。
但无需关心它们在集群中的物理位置，因为这可能随着时间的推移而发生变化。

It could for example be actors representing Aggregate Roots in Domain-Driven Design terminology.
Here we call these actors "entities". These actors typically have persistent (durable) state,
but this feature is not limited to actors with persistent state.

例如，它可以是代表领域驱动设计术语中的聚合根的参与者。在这里，我们称这些actor为“entities”。
这些actor通常具有持久（durable）状态，但此功能不仅限于具有持久状态的actor。

Cluster sharding is typically used when you have many stateful actors that together consume
more resources (e.g. memory) than fit on one machine. If you only have a few stateful actors
it might be easier to run them on a @ref:[Cluster Singleton](cluster-singleton.md) node.

当你有许多有状态的actor一起消耗更多的资源（例如内存）而不是一台机器上的资源时，通常会使用集群分片。
如果你只有几个有状态的actor，则可能使用 @ref:[集群单例](cluster-singleton.md) 在节点上运行更简单。

In this context sharding means that actors with an identifier, so called entities,
can be automatically distributed across multiple nodes in the cluster. Each entity
actor runs only at one place, and messages can be sent to the entity without requiring
the sender to know the location of the destination actor. This is achieved by sending
the messages via a `ShardRegion` actor provided by this extension, which knows how
to route the message with the entity id to the final destination.

在此上下文中，分片意味着具有标识符（所谓的实体）的参与者可以自动分布在集群中的多个节点上。每个实体actor仅在一个地方运行，
并且可以将消息发送到实体，而不需要发送者知道目标actor的位置。这是通过此扩展提供的`ShardRegion` actor发送消息来实现的，
该扩展知道如何将带有实体id的消息路由到最终目的地。

Cluster sharding will not be active on members with status @ref:[WeaklyUp](cluster-usage.md#weakly-up)
if that feature is enabled.

如果启用了该功能，则状态为 @ref:[WeaklyUp](cluster-usage.md#weakly-up) 的成员上的集群分片将不会处于活动状态。

@@@ warning

**Don't use Cluster Sharding together with Automatic Downing**,
since it allows the cluster to split up into two separate clusters, which in turn will result
in *multiple shards and entities* being started, one in each separate cluster!
See @ref:[Downing](cluster-usage.md#automatic-vs-manual-downing).

**不要在集群分片中使用自动关闭**，因为它允许集群分成两个独立的集群，这反过来将导致多个分片和实体被启动，
每个独立的集群中有一个！见 @ref:[Downing](cluster-usage.md#automatic-vs-manual-downing) 。

@@@

## An Example

## 一个示例

This is how an entity actor may look like:

实体actor看起来如下所示：

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #counter-actor }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #counter-actor }

The above actor uses event sourcing and the support provided in @scala[`PersistentActor`] @java[`AbstractPersistentActor`] to store its state.
It does not have to be a persistent actor, but in case of failure or migration of entities between nodes it must be able to recover
its state if it is valuable.

上面的actor使用事件溯源和 @scala[`PersistentActor`] 中提供的支持来存储其状态。它不一定是持久性actor，
但是如果节点之间的实体发生故障或迁移，它必须能够恢复其状态（如果它是有价值的）。

Note how the `persistenceId` is defined. The name of the actor is the entity identifier (utf-8 URL-encoded).
You may define it another way, but it must be unique.

请注意如何定义`persistenceId`。actor的名称是实体标识符（utf-8 URL编码）。你可以用另一种方式定义它，但它必须是唯一的。

When using the sharding extension you are first, typically at system startup on each node
in the cluster, supposed to register the supported entity types with the `ClusterSharding.start`
method. `ClusterSharding.start` gives you the reference which you can pass along.
Please note that `ClusterSharding.start` will start a `ShardRegion` in [proxy only mode](#proxy-only-mode) 
in case if there is no match between the roles of the current cluster node and the role specified in 
`ClusterShardingSettings`.

使用分片扩展时，首先，通常在集群中每个节点上的系统启动时应该使用`ClusterSharding.start`方法注册支持的实体类型。
`ClusterSharding.start`为你提供可以传递的引用。请注意，
如果当前集群节点的角色与`ClusterShardingSettings`中指定的角色不匹配，
则`ClusterSharding.start`将 [仅在代理模式](#proxy-only-mode) 下启动`ShardRegion`。

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #counter-start }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #counter-start }

The @scala[`extractEntityId` and `extractShardId` are two] @java[`messageExtractor` defines] application specific @scala[functions] @java[methods] to extract the entity
identifier and the shard identifier from incoming messages.

@scala[`extractEntityId`] 和 @scala[`extractShardId`] 是两个特定于应用程序的函数，
用于从传入消息中提取实体标识符和分片标识符。

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #counter-extractor }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #counter-extractor }

This example illustrates two different ways to define the entity identifier in the messages:

此示例说明了在消息中定义实体标识符的两种不同方法：

 * The `Get` message includes the identifier itself.
 * The `EntityEnvelope` holds the identifier, and the actual message that is
sent to the entity actor is wrapped in the envelope.

 * `Get`消息包括了标识符本身。
 * `EntityEnvelope`保存标识符，发送给实体actor的实际消息包含在信封中。

Note how these two messages types are handled in the @scala[`extractEntityId` function] @java[`entityId` and `entityMessage` methods] shown above.
The message sent to the entity actor is @scala[the second part of the tuple returned by the `extractEntityId`] @java[what `entityMessage` returns] and that makes it possible to unwrap envelopes
if needed.

请注意如何在上面显示的 @scala[`extractEntityId`] 函数中处理这两种消息类型。发送给实体actor的消息是
@scala[`extractEntityId`] 返回的元组的第二部分，如果需要，可以解包信封。

A shard is a group of entities that will be managed together. The grouping is defined by the
`extractShardId` function shown above. For a specific entity identifier the shard identifier must always
be the same. Otherwise the entity actor might accidentally be started in several places at the same time.

分片是指将会一起管理的一组实体。分组由上面显示的`extractShardId`函数定义。对于特定实体标识符，分片标识符必须始终相同。
否则，实体actor可能会意外地在几个地方同时启动。

Creating a good sharding algorithm is an interesting challenge in itself. Try to produce a uniform distribution,
i.e. same amount of entities in each shard. As a rule of thumb, the number of shards should be a factor ten greater
than the planned maximum number of cluster nodes. Less shards than number of nodes will result in that some nodes
will not host any shards. Too many shards will result in less efficient management of the shards, e.g. rebalancing
overhead, and increased latency because the coordinator is involved in the routing of the first message for each
shard. The sharding algorithm must be the same on all nodes in a running cluster. It can be changed after stopping
all nodes in the cluster.

创建一个好的分乍算法本身就是一个有趣的挑战。尝试产生均匀分布，即每个分片中的实体数量相同。根据经验，
分片数量应比计划的最大集群节点数大10倍。分片数少于节点数将导致某些节点不会托管任何分片。
太多的分片将导致对分片的管理效率降低，例如，重新平衡开销，并增加延迟。因为协调器参与每个分片的第一条消息的路由。
在运行的集群中的所有节点上，分片算法必须相同。停止集群中的所有节点后，可以更改它。

A simple sharding algorithm that works fine in most cases is to take the absolute value of the `hashCode` of
the entity identifier modulo number of shards. As a convenience this is provided by the
`ShardRegion.HashCodeMessageExtractor`.

在大多数情况下工作正常的简单分片算法是获取实体标识符hashCode与分片数量的模数的绝对值。为方便起见，
这是由`ShardRegion.HashCodeMessageExtractor`提供的。

Messages to the entities are always sent via the local `ShardRegion`. The `ShardRegion` actor reference for a
named entity type is returned by `ClusterSharding.start` and it can also be retrieved with `ClusterSharding.shardRegion`.
The `ShardRegion` will lookup the location of the shard for the entity if it does not already know its location. It will
delegate the message to the right node and it will create the entity actor on demand, i.e. when the
first message for a specific entity is delivered.

始终通过本地`ShardRegion`发送给实体的消息。`ClusterSharding.start`返回指定实体类型的`ShardRegion` actor引用，
也可以使用`ClusterSharding.shardRegion`检索它。如果尚未知道实体的位置，`ShardRegion`将查找该实体的分片位置。
它将消息委托给正确的节点，当传递特定实体的第一条消息时它（节点）将按需创建实体actor。

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #counter-usage }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #counter-usage }

@@@ div { .group-scala }

A more comprehensive sample is available in the
tutorial named [Akka Cluster Sharding with Scala!](https://github.com/typesafehub/activator-akka-cluster-sharding-scala).

更详细的示例可在名为 [Akka Cluster Sharding with Scala！](https://github.com/typesafehub/activator-akka-cluster-sharding-scala) 的教程中找到。

@@@

## How it works

## 怎样工作

The `ShardRegion` actor is started on each node in the cluster, or group of nodes
tagged with a specific role. The `ShardRegion` is created with two application specific
functions to extract the entity identifier and the shard identifier from incoming messages.
A `Shard` is a group of entities that will be managed together. For the first message in a
specific shard the `ShardRegion` requests the location of the shard from a central coordinator,
the `ShardCoordinator`.

`ShardRegion` actor在集群中的每个节点上启动，或者由标记有特定角色的节点组启动。
使用两个特定于应用程序的函数创建`ShardRegion`，以从传入消息中提取实体标识符和分片标识符。Shard是一组将一起管理的实体。
对于特定分片中的第一条消息，`ShardRegion`从中央协调器`ShardCoordinator`上请求分片的位置。

The `ShardCoordinator` decides which `ShardRegion` shall own the `Shard` and informs
that `ShardRegion`. The region will confirm this request and create the `Shard` supervisor
as a child actor. The individual `Entities` will then be created when needed by the `Shard`
actor. Incoming messages thus travel via the `ShardRegion` and the `Shard` to the target
`Entity`.

`ShardCoordinator`决定哪个`ShardRegion`拥有`Shard`并通知`ShardRegion`。该地区（region）将确认此请求，
并将创建`Shard`监督作为子actor（TODO？create the `Shard` supervisor as a child actor.）。然后，`Shard` actor需要时创建各个实体。因此，
传入消息通过`ShardRegion`和`Shard`传播到目标`Entity`。

If the shard home is another `ShardRegion` instance messages will be forwarded
to that `ShardRegion` instance instead. While resolving the location of a
shard incoming messages for that shard are buffered and later delivered when the
shard home is known. Subsequent messages to the resolved shard can be delivered
to the target destination immediately without involving the `ShardCoordinator`.

如果shard home是另一个`ShardRegion`实例，则消息将转发到该`ShardRegion`实例。在解析分片的位置时，
将缓冲该分片的传入消息一直到shard home已知。到已解析的分片的后续消息可以立即传递到目标，而不涉及`ShardCoordinator`。

### Scenarios

### 方案

Once a `Shard` location is known `ShardRegion`s send messages directly. Here are the
scenarios for getting to this state. In the scenarios the following notation is used:

一旦知道`Shard`位置，`ShardRegion`就会直接发送消息。以下是进入此状态的方案。在场景使用以下表示法：

* `SC` - ShardCoordinator
* `M#` - Message 1, 2, 3, etc
* `SR#` - ShardRegion 1, 2 3, etc
* `S#` - Shard 1 2 3, etc
* `E#` - Entity 1 2 3, etc. An entity refers to an Actor managed by Cluster Sharding.

Where `#` is a number to distinguish between instances as there are multiple in the Cluster.

* `SC` - ShardCoordinator
* `M#` - 消息 1, 2, 3, 等
* `SR#` - ShardRegion 1, 2 3, 等
* `S#` - Shard 1 2 3, 等
* `E#` - Entity 1 2 3, 等。实体是指由Cluster Sharding管理的actor。

其中 `#` 是区分实例的数字，因为集群中有多个实例。

#### Scenario 1: Message to an unknown shard that belongs to the local ShardRegion

 1. Incoming message `M1` to `ShardRegion` instance `SR1`.
 2. `M1` is mapped to shard `S1`. `SR1` doesn't know about `S1`, so it asks the `SC` for the location of `S1`.
 3. `SC` answers that the home of `S1` is `SR1`.
 4. `R1` creates child actor for the entity `E1` and sends buffered messages for `S1` to `E1` child
 5. All incoming messages for `S1` which arrive at `R1` can be handled by `R1` without `SC`. It creates entity children as needed, and forwards messages to them.

#### 场景1：发送到本地 ShardRegion 的未知分片的消息

 1. 消息`M1`传入到`ShardRegion`实例`SR1`。
 2. `M1`被映射到分片`S1`。`SR1`不知道`S1`，所以它要求`SC`提供`S1`的位置。
 3. `SC`回答`S1`的家（home）是`SR1`。
 4. `R1`为实体`E1`创建子actor并将`S1`缓冲的消息发送给`E1`子节点。
 5. 到达`R1`的`S1`的所有传入消息都可以由`R1`处理页不需要`SC`。它根据需要创建实体子项，并将消息转发给它们。

#### Scenario 2: Message to an unknown shard that belongs to a remote ShardRegion 

 1. Incoming message `M2` to `ShardRegion` instance `SR1`.
 2. `M2` is mapped to `S2`. SR1 doesn't know about `S2`, so it asks `SC` for the location of `S2`.
 3. `SC` answers that the home of `S2` is `SR2`.
 4. `SR1` sends buffered messages for `S2` to `SR2`.
 5. All incoming messages for `S2` which arrive at `SR1` can be handled by `SR1` without `SC`. It forwards messages to `SR2`.
 6. `SR2` receives message for `S2`, ask `SC`, which answers that the home of `S2` is `SR2`, and we are in Scenario 1 (but for `SR2`).

#### 场景2：发送到属于远程 ShardRegion 的未知分片的消息

 1. 消息`M2`传入到`ShardRegion`实例`SR1`.
 2. `M2`被映射到`S2`。`SR1`不知道`S2`，所以它要求`SC`提供`S2`的位置.
 3. `SC`回答`S2`的家（home）为`SR2`.
 4. `SR1`将缓冲的`S2`的消息发送给`SR2`.
 5. 到达的`SR1`的`S2`的传入消息都可以由`SR1`处理而不需要`SC`。它将消息转发给`SR2`。
 6. `SR2`接收`S2`来的消息，访问`SC`，它（`SC`）`S2`的家（home)是`SR2`，and we are in Scenario 1 (but for `SR2`).

### Shard location 
### 分片位置

To make sure that at most one instance of a specific entity actor is running somewhere
in the cluster it is important that all nodes have the same view of where the shards
are located. Therefore the shard allocation decisions are taken by the central
`ShardCoordinator`, which is running as a cluster singleton, i.e. one instance on
the oldest member among all cluster nodes or a group of nodes tagged with a specific
role.

为了确保特定实体actor的最多一个实例在集群中的某个位置运行，所有节点对于分片所在的位置具有相同的视图是很重要的。因此，
分片分配决策由中央`ShardCoordinator`分配并作为集群单例运行，
即所有集群节点中最旧成员上的一个实例或标记有特定角色的一组节点。

The logic that decides where a shard is to be located is defined in a pluggable shard
allocation strategy. The default implementation `ShardCoordinator.LeastShardAllocationStrategy`
allocates new shards to the `ShardRegion` with least number of previously allocated shards.
This strategy can be replaced by an application specific implementation.

### Shard Rebalancing

To be able to use newly added members in the cluster the coordinator facilitates rebalancing
of shards, i.e. migrate entities from one node to another. In the rebalance process the
coordinator first notifies all `ShardRegion` actors that a handoff for a shard has started.
That means they will start buffering incoming messages for that shard, in the same way as if the
shard location is unknown. During the rebalance process the coordinator will not answer any
requests for the location of shards that are being rebalanced, i.e. local buffering will
continue until the handoff is completed. The `ShardRegion` responsible for the rebalanced shard
will stop all entities in that shard by sending the specified `stopMessage`
(default `PoisonPill`) to them. When all entities have been terminated the `ShardRegion`
owning the entities will acknowledge the handoff as completed to the coordinator.
Thereafter the coordinator will reply to requests for the location of
the shard and thereby allocate a new home for the shard and then buffered messages in the
`ShardRegion` actors are delivered to the new location. This means that the state of the entities
are not transferred or migrated. If the state of the entities are of importance it should be
persistent (durable), e.g. with @ref:[Persistence](persistence.md), so that it can be recovered at the new
location.

协调期重新平衡分片有且于使用集群中新添加的成员，即将实体从一个节点迁移到另一个节点。在重新平衡过程中，
协调器首先通知所有`ShardRegion` actor开始分片的切换。这意味着他们将开始缓冲该分片的传入消息，就像分片位置未知一样。
在重新平衡过程期间，协调器将不回答对正在重新平衡的分片的位置的任何请求，即本地缓冲将继续直到切换完成。
负责重新平衡的分片的`ShardRegion`将通过向它们发送指定的`stopMessage`（默认`PoisonPill`）来停止该分片中的所有实体。
当所有实体都被终止时，拥有实体的`ShardRegion`将向协调器确认已完成的切换。此后，协调器将回复对分片位置的请求，
从而为分片分配新的主页，然后将`ShardRegion` actor中的缓冲消息传递到新位置。这意味着不传输或迁移实体的状态。
如果实体的状态是重要的，则它应该是持久的（durable），例如，使用 @ref:[持久性](persistence.md) ，以便可以在新位置恢复。

The logic that decides which shards to rebalance is defined in a pluggable shard
allocation strategy. The default implementation `ShardCoordinator.LeastShardAllocationStrategy`
picks shards for handoff from the `ShardRegion` with most number of previously allocated shards.
They will then be allocated to the `ShardRegion` with least number of previously allocated shards,
i.e. new members in the cluster.

决定重新平衡哪些分片的逻辑是在可插入分片策略中定义的。默认实现`ShardCoordinator.LeastShardAllocationStrategy`
从具有大量先前分配的分片的`ShardRegion`中选择用于切换的分片。
然后将它们分配给具有最少数量的先前分配的分片的`ShardRegion`，即集群中的新成员。

For the `LeastShardAllocationStrategy` there is a configurable threshold (`rebalance-threshold`) of
how large the difference must be to begin the rebalancing. The difference between number of shards in
the region with most shards and the region with least shards must be greater than the `rebalance-threshold`
for the rebalance to occur.

对于`LeastShardAllocationStrategy`，有一个可配置的阈值（`rebalance-threshold`），表示开始重新平衡的差异必须有多大。
具有大多数分片的区域中的分片数与具有最少分片的区域之间的差异必须大于重新平衡发生的`rebalance-threshold`。

A `rebalance-threshold` of 1 gives the best distribution and therefore typically the best choice.
A higher threshold means that more shards can be rebalanced at the same time instead of one-by-one.
That has the advantage that the rebalance process can be quicker but has the drawback that the
the number of shards (and therefore load) between different nodes may be significantly different.

`rebalance-threshold`为1可提供最佳分布，因此通常是最佳选择。较高的阈值意味着可以同时重新平衡更多的分片，
而不是逐个重新分配。这具有以下优点：重新平衡过程可以更快但是具有不同节点之间的分片数量（并且因此负载）可能显着不同的缺点。（TODO？）

### ShardCoordinator State

### 分片协调员状态

The state of shard locations in the `ShardCoordinator` is persistent (durable) with
@ref:[Distributed Data](distributed-data.md) or @ref:[Persistence](persistence.md) to survive failures. When a crashed or
unreachable coordinator node has been removed (via down) from the cluster a new `ShardCoordinator` singleton
actor will take over and the state is recovered. During such a failure period shards
with known location are still available, while messages for new (unknown) shards
are buffered until the new `ShardCoordinator` becomes available.

`ShardCoordinator`中的分片位置状态是持久的（durable）， @ref:[分布式数据](distributed-data.md) 或
@ref:[持久性](persistence.md) 可以承受故障。当已从集群中删除（通过down）崩溃或无法访问的协调器节点时，
新的`ShardCoordinator`单一角色将接管并恢复状态。在这样的故障期间，具有已知位置的分片仍然可用，
而新（未知）分片的消息被缓冲，直到新的`ShardCoordinator`变得可用。

### Message ordering

### 消息顺序

As long as a sender uses the same `ShardRegion` actor to deliver messages to an entity
actor the order of the messages is preserved. As long as the buffer limit is not reached
messages are delivered on a best effort basis, with at-most once delivery semantics,
in the same way as ordinary message sending. Reliable end-to-end messaging, with
at-least-once semantics can be added by using `AtLeastOnceDelivery`  in @ref:[Persistence](persistence.md).

只要发送方使用相同的`ShardRegion` actor将消息传递给实体actor，就会保留消息的顺序。只要未达到缓冲区限制，
就会以尽力而为的方式传递消息，与普通消息发送方式相同保证最多一次传递语义。通过在 @ref:[Persistence](persistence.md)
中使用`AtLeastOnceDelivery`，可以添加具有至少一次语义的可靠端到端消息传递。

### Overhead

### 开销

Some additional latency is introduced for messages targeted to new or previously
unused shards due to the round-trip to the coordinator. Rebalancing of shards may
also add latency. This should be considered when designing the application specific
shard resolution, e.g. to avoid too fine grained shards. Once a shard's location is known
the only overhead is sending a message via the `ShardRegion` rather than directly.

由于协调器的往返，针对新的或以前未使用的分片的消息引入了一些额外的延迟。重新平衡分片也可能增加延迟。
在设计特定于应用程序的分片解析时应考虑这一点，例如：避免太细粒度的分片。 一旦知道了分片的位置，
唯一的开销是通过`ShardRegion`而不是直接发送消息。

<a id="cluster-sharding-mode"></a>
## Distributed Data vs. Persistence Mode

## 分布式数据 vs 持久化模型

The state of the coordinator and the state of [Remembering Entities](#cluster-sharding-remembering) of the shards
are persistent (durable) to survive failures. @ref:[Distributed Data](distributed-data.md) or @ref:[Persistence](persistence.md)
can be used for the storage. Distributed Data is used by default.

协调器的状态和分片的 [Remembering Entities](#cluster-sharding-remembering) 的状态是持久的（durable）以承受故障。
@ref:[分布式数据](distributed-data.md) 或 @ref:[持久性](persistence.md) 可用于存储。默认情况下使用分布式数据。

The functionality when using the two modes is the same. If your sharded entities are not using Akka Persistence
themselves it is more convenient to use the Distributed Data mode, since then you don't have to
setup and operate a separate data store (e.g. Cassandra) for persistence. Aside from that, there are
no major reasons for using one mode over the the other.

使用这两种模式时的功能是相同的。如果分片实体本身不使用Akka持久化，则使用分布式数据模式会更方便，
因为这样你就不必设置和操作单独的数据存储（例如Cassandra）来实现持久性。除此之外，
使用一种模式而不是另一种模式没有主要原因。

It's important to use the same mode on all nodes in the cluster, i.e. it's not possible to perform
a rolling upgrade to change this setting.

在集群中的所有节点上使用相同的模式非常重要，即无法执行滚动升级来更改此设置。

### Distributed Data Mode

### 分布式数据模式

This mode is enabled with configuration (enabled by default):

配置启用此模式（默认启用）：

```
akka.cluster.sharding.state-store-mode = ddata
```

The state of the `ShardCoordinator` will be replicated inside a cluster by the
@ref:[Distributed Data](distributed-data.md) module with `WriteMajority`/`ReadMajority` consistency.
The state of the coordinator is not durable, it's not stored to disk. When all nodes in
the cluster have been stopped the state is lost and not needed any more.

`ShardCoordinator`的状态将由具有`WriteMajority`/`ReadMajority`一致性的 @ref:[分布式数据](distributed-data.md)
模块在集群内复制。协调器的状态不是持久的，它不存储在磁盘上。当集群中的所有节点都已停止时，状态将丢失且不再需要。

The state of [Remembering Entities](#cluster-sharding-remembering) is also durable, i.e. it is stored to
disk. The stored entities are started also after a complete cluster restart.

[Remembering Entities](#cluster-sharding-remembering) 的状态也是持久的，即它存储在磁盘上。集群完成重启后，也会启动存储的实体。

Cluster Sharding is using its own Distributed Data `Replicator` per node role. In this way you can use a subset of
all nodes for some entity types and another subset for other entity types. Each such replicator has a name
that contains the node role and therefore the role configuration must be the same on all nodes in the
cluster, i.e. you can't change the roles when performing a rolling upgrade.

集群分片的每个节点角色使用自己的分布式数据`Replicator`。通过这种方式，你可以将所有节点的子集用于某些实体类型，
将另一个子集用于其他实体类型。每个此类replicator（复制器）都具有包含节点角色的名称，
因此角色配置在集群中的所有节点上必须相同，即在执行滚动升级时无法更改角色。

The settings for Distributed Data is configured in the the section
`akka.cluster.sharding.distributed-data`. It's not possible to have different
`distributed-data` settings for different sharding entity types.

分布式数据的设置在`akka.cluster.sharding.distributed-data`部分中配置。不能为不同的分片实体类型定义不同的
`distributed-data`设置。

### Persistence Mode

### 持久化模式

This mode is enabled with configuration:

使用配置启用此模式：

```
akka.cluster.sharding.state-store-mode = persistence
```

Since it is running in a cluster @ref:[Persistence](persistence.md) must be configured with a distributed journal.

由于它在集群中运行，困此必须使用分布式日志配置 @ref:[持久性](persistence.md) 。

## Startup after minimum number of members

## 在最少数量的成员之后启动

It's good to use Cluster Sharding with the Cluster setting `akka.cluster.min-nr-of-members` or
`akka.cluster.role.<role-name>.min-nr-of-members`. That will defer the allocation of the shards
until at least that number of regions have been started and registered to the coordinator. This
avoids that many shards are allocated to the first region that registers and only later are
rebalanced to other nodes.

最好将Cluster Sharding与集群设置`akka.cluster.min-nr-of-members`或`akka.cluster.role.<role-name>.min-nr-of-members`
一起使用。这将推迟分片的分配，直到至少已经启动并向协调器注册了该数量的区域。这避免了许多分片被分配给注册的第一个区域，
并且稍后才重新平衡到其他节点。

See @ref:[How To Startup when Cluster Size Reached](cluster-usage.md#min-members) for more information about `min-nr-of-members`.

有关`min-nr-of-members`的详细信息，请参阅 @ref:[如何在达到集群大小时启动](cluster-usage.md#min-member) 。

## Proxy Only Mode

## 仅代理模式

The `ShardRegion` actor can also be started in proxy only mode, i.e. it will not
host any entities itself, but knows how to delegate messages to the right location.
A `ShardRegion` is started in proxy only mode with the `ClusterSharding.startProxy` method.
Also a `ShardRegion` is started in proxy only mode in case if there is no match between the
roles of the current cluster node and the role specified in `ClusterShardingSettings` 
passed to the `ClusterSharding.start` method.

`ShardRegion` actor也可以仅在代理模式下启动，即它不会托管任何实体，但知道如何将消息委托给正确的位置。
使用`ClusterSharding.startProxy`方法在代理模式下启动`ShardRegion`。如果当前集群节点的角色与传递给
`ClusterSharding.start`方法的`ClusterShardingSettings`中指定的角色不匹配，则也只会以代理模式启动`ShardRegion`。

## Passivation

## 钝化

If the state of the entities are persistent you may stop entities that are not used to
reduce memory consumption. This is done by the application specific implementation of
the entity actors for example by defining receive timeout (`context.setReceiveTimeout`).
If a message is already enqueued to the entity when it stops itself the enqueued message
in the mailbox will be dropped. To support graceful passivation without losing such
messages the entity actor can send `ShardRegion.Passivate` to its parent `Shard`.
The specified wrapped message in `Passivate` will be sent back to the entity, which is
then supposed to stop itself. Incoming messages will be buffered by the `Shard`
between reception of `Passivate` and termination of the entity. Such buffered messages
are thereafter delivered to a new incarnation of the entity.

如果实体的状态是持久的，则可以停止不用的实体来减少内存消耗。这是通过实体actor的应用程序特定实现来完成的，
例如通过定义接收超时（`context.setReceiveTimeout`）。如果消息在实体停止时已经排队，则将删除邮箱中的排队消息。
为了支持优雅的钝化而不丢失此类消息，实体actor可以将`ShardRegion.Passivate`发送到其父Shard。
`Passivate`中指定的包装消息将被发送回实体，然后该实体应该自行停止。在接收`Passivate`和终止实体之间，
Shard将缓冲传入的消息。此后，这些缓冲的消息被传递给该实体的新化身。

### Automatic Passivation

### 自动钝化

The entities can be configured to be automatically passivated if they haven't received
a message for a while using the `akka.cluster.sharding.passivate-idle-entity-after` setting,
or by explicitly setting `ClusterShardingSettings.passivateIdleEntityAfter` to a suitable
time to keep the actor alive. Note that only messages sent through sharding are counted, so direct messages
to the `ActorRef` of the actor or messages that it sends to itself are not counted as activity. 
By default automatic passivation is disabled. 

如果实体使用`akka.cluster.sharding.passivate-idle-entity-after`设置后，或者通过将
`ClusterShardingSettings.passivateIdleEntityAfter`显式设置为适当的时间来保留一段时间，则可以活着的actor实体自动钝化。
请注意，只有通过分片发送的消息才会被计算，因此发送给actor的`ActorRef`的直接消息或它发送给自身的消息不会被计为活动。
默认情况下，禁用自动钝化。

<a id="cluster-sharding-remembering"></a>
## Remembering Entities

The list of entities in each `Shard` can be made persistent (durable) by setting
the `rememberEntities` flag to true in `ClusterShardingSettings` when calling
`ClusterSharding.start` and making sure the `shardIdExtractor` handles
`Shard.StartEntity(EntityId)` which implies that a `ShardId` must be possible to
extract from the `EntityId`.

通过在调用`ClusterSharding.start`并确保`shardIdExtractor`处理`Shard.StartEntity(EntityId)`时暗示必须可以提取`ShardId`，
可以使每个Shard中的实体列表成为持久（durable），方法是在`ClusterShardingSettings`中将`rememberEntities`标志设置为`true`。（TODO？）

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #extractShardId-StartEntity }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #extractShardId-StartEntity }

When configured to remember entities, whenever a `Shard` is rebalanced onto another
node or recovers after a crash it will recreate all the entities which were previously
running in that `Shard`. To permanently stop entities, a `Passivate` message must be
sent to the parent of the entity actor, otherwise the entity will be automatically
restarted after the entity restart backoff specified in the configuration.

当配置为remember entities时，每当Shard重新平衡到另一个节点上或在崩溃后恢复时，它将重新创建先前在该Shard中运行的所有实体。
要永久停止实体，必须将`Passivate`消息发送到实体actor的父级，否则在配置中指定的实体重新启动backoff后，实体将自动重新启动。

When [Distributed Data mode](#cluster-sharding-mode) is used the identifiers of the entities are
stored in @ref:[Durable Storage](distributed-data.md#ddata-durable) of Distributed Data. You may want to change the
configuration of the `akka.cluster.sharding.distributed-data.durable.lmdb.dir`, since
the default directory contains the remote port of the actor system. If using a dynamically
assigned port (0) it will be different each time and the previously stored data will not
be loaded.

使用 [分布式数据模式](#cluster-sharding-mode) 时，实体的标识符存储在分布式数据的
@ref:[持久存储](distributed-data.md#ddata-durable) 中。你可能希望更改
`akka.cluster.sharding.distributed-data.durable.lmdb.dir`的配置，因为默认目录包含actor系统的远程端口。
如果使用动态分配的端口（0），则每次都会有所不同，并且不会加载先前存储的数据。

When `rememberEntities` is set to false, a `Shard` will not automatically restart any entities
after a rebalance or recovering from a crash. Entities will only be started once the first message
for that entity has been received in the `Shard`. Entities will not be restarted if they stop without
using a `Passivate`.

当`rememberEntities`设置为false时，`Shard`将不会在重新平衡或从崩溃中恢复后自动重新启动任何实体。
只有在分片中收到该实体的第一条消息后，才会启动实体。如果实体在不使用`Passivate`的情况下停止，则不会重新启动实体。

Note that the state of the entities themselves will not be restored unless they have been made persistent,
e.g. with @ref:[Persistence](persistence.md).

注意，实体本身的状态将不会被恢复，除非它们已经被持久化，例如使用 @ref:[持久化](persistence.md) 。

The performance cost of `rememberEntities` is rather high when starting/stopping entities and when
shards are rebalanced. This cost increases with number of entities per shard and we currently don't
recommend using it with more than 10000 entities per shard.

启动/停止实体以及重新平衡分片时，`rememberEntities`的性能成本相当高。此成本随每个分片的实体数量而增加，
我们目前不建议每个分片使用超过10000个实体。

## Supervision

## 监督

If you need to use another `supervisorStrategy` for the entity actors than the default (restarting) strategy
you need to create an intermediate parent actor that defines the `supervisorStrategy` to the
child entity actor.

如果你需要为实体actor使用另一个`supervisorStrategy`而不是默认（restarting）策略，则需要创建一个中间父actor，
它将`supervisorStrategy`定义为实体actor的子级。

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #supervisor }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #supervisor }

You start such a supervisor in the same way as if it was the entity actor.

你可以与实体actor相同的方式来启动这个监督actor。

Scala
:  @@snip [ClusterShardingSpec.scala](/akka-cluster-sharding/src/multi-jvm/scala/akka/cluster/sharding/ClusterShardingSpec.scala) { #counter-supervisor-start }

Java
:  @@snip [ClusterShardingTest.java](/akka-docs/src/test/java/jdocs/sharding/ClusterShardingTest.java) { #counter-supervisor-start }

Note that stopped entities will be started again when a new message is targeted to the entity.

请注意，当新消息以实体为目标时，将再次启动已停止的实体。

## Graceful Shutdown

## 优雅的关闭

You can send the @scala[`ShardRegion.GracefulShutdown`] @java[`ShardRegion.gracefulShutdownInstance`] message
to the `ShardRegion` actor to hand off all shards that are hosted by that `ShardRegion` and then the
`ShardRegion` actor will be stopped. You can `watch` the `ShardRegion` actor to know when it is completed.
During this period other regions will buffer messages for those shards in the same way as when a rebalance is
triggered by the coordinator. When the shards have been stopped the coordinator will allocate these shards elsewhere.

你可以将`ShardRegion.GracefulShutdown`消息发送到`ShardRegion` actor以切换由该`ShardRegion`托管的所有分片，
然后`ShardRegion` actor将被停止。你可以watch `ShardRegion` actor以了解它何时（关闭）完成。在此期间，
其他区域将以与协调器触发重新平衡时相同的方式缓冲这些分片的消息。当分片被停止时，协调器将在其他地方分配这些分片。

This is performed automatically by the @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown) and is therefore part of the
graceful leaving process of a cluster member.

这些由 @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown) 自动执行，因此是集群成员正常离开过程的一部分

<a id="removeinternalclustershardingdata"></a>
## Removal of Internal Cluster Sharding Data

## 删除内部集群分片数据

The Cluster Sharding coordinator stores the locations of the shards using Akka Persistence.
This data can safely be removed when restarting the whole Akka Cluster.
Note that this is not application data.

Cluster Sharding协调器使用Akka Persistence存储分片的位置。重新启动整个Akka集群时，可以安全地删除此数据。请注意，这不是应用程序数据。

There is a utility program `akka.cluster.sharding.RemoveInternalClusterShardingData`
that removes this data.

有一个实用程序`akka.cluster.sharding.RemoveInternalClusterShardingData`可以删除这些数据。

@@@ warning

Never use this program while there are running Akka Cluster nodes that are
using Cluster Sharding. Stop all Cluster nodes before using this program.

在运行使用Cluster Sharding的Akka Cluster节点时，切勿使用此程序。在使用此程序之前停止所有Cluster节点。

@@@

It can be needed to remove the data if the Cluster Sharding coordinator
cannot startup because of corrupt data, which may happen if accidentally
two clusters were running at the same time, e.g. caused by using auto-down
and there was a network partition.

如果由于数据损坏而导致集群分片协调器无法启动，则可能需要删除数据，如果意外地两个集群同时运行，则可能会发生这种情况。
例如，使用自动关闭导致网络分区。

@@@ warning

**Don't use Cluster Sharding together with Automatic Downing**,
since it allows the cluster to split up into two separate clusters, which in turn will result
in *multiple shards and entities* being started, one in each separate cluster!
See @ref:[Downing](cluster-usage.md#automatic-vs-manual-downing).

**不要将Cluster Sharding与Automatic Downing一起使用** ，因为它允许群集分成两个独立的群集，
这反过来将导致多个分片和实体被启动，每个独立的群集中有一个！
见 @ref:[Downing](cluster-usage.md#automatic-vs-manual-downing) 。

@@@

Use this program as a standalone Java main program:

将此程序用作独立的Java主程序：

```
java -classpath <jar files, including akka-cluster-sharding>
  akka.cluster.sharding.RemoveInternalClusterShardingData
    -2.3 entityType1 entityType2 entityType3
```

The program is included in the `akka-cluster-sharding` jar file. It
is easiest to run it with same classpath and configuration as your ordinary
application. It can be run from sbt or Maven in similar way.

该程序包含在`akka-cluster-sharding` jar文件中。使用与普通应用程序相同的类路径和配置运行它是最简单的。
它可以以类似的方式从sbt或Maven运行。

Specify the entity type names (same as you use in the `start` method
of `ClusterSharding`) as program arguments.

指定实体类型名称（与在`ClusterSharding`的`start`方法中使用的名称相同）作为程序参数。

If you specify `-2.3` as the first program argument it will also try
to remove data that was stored by Cluster Sharding in Akka 2.3.x using
different persistenceId.

如果指定`-2.3`作为第一个程序参数，它还将尝试使用不同的`persistenceId`删除Akka 2.3.x中的Cluster Sharding存储的数据。

## Configuration

## 配置

The `ClusterSharding` extension can be configured with the following properties. These configuration
properties are read by the `ClusterShardingSettings` when created with a `ActorSystem` parameter.
It is also possible to amend the `ClusterShardingSettings` or create it from another config section
with the same layout as below. `ClusterShardingSettings` is a parameter to the `start` method of
the `ClusterSharding` extension, i.e. each each entity type can be configured with different settings
if needed.

可以使用以下属性配置`ClusterSharding`扩展。使用`ActorSystem`参数创建时，`ClusterShardingSettings`将读取这些配置属性。
也可以修改`ClusterShardingSettings`或使用与下面相同的布局从另一个配置部分创建它。`ClusterShardingSettings`是
`ClusterSharding`扩展的`start`方法的参数。即，如果需要，每个实体类型可以配置不同的设置。

@@snip [reference.conf](/akka-cluster-sharding/src/main/resources/reference.conf) { #sharding-ext-config }

Custom shard allocation strategy can be defined in an optional parameter to
`ClusterSharding.start`. See the API documentation of @scala[`ShardAllocationStrategy`] @java[`AbstractShardAllocationStrategy`] for details
of how to implement a custom shard allocation strategy.

可以在`ClusterSharding.start`的可选参数中定义自定义分片策略。有关如何实现自定义分片分配策略的详细信息，请参阅
@scala[`ShardAllocationStrategy`] 的API文档。

## Inspecting cluster sharding state

## 检查群集分片状态

Two requests to inspect the cluster state are available:

有两个检查群集状态的请求可用：

@scala[`ShardRegion.GetShardRegionState`] @java[`ShardRegion.getShardRegionStateInstance`] which will return
a @scala[`ShardRegion.CurrentShardRegionState`] @java[`ShardRegion.ShardRegionState`] that contains
the identifiers of the shards running in a Region and what entities are alive for each of them.

@scala[`ShardRegion.GetShardRegionState`]，它将返回一个 @scala[`ShardRegion.CurrentShardRegionState`]，
它包含在Region中运行的分片的标识符以及每个分片的实体。

`ShardRegion.GetClusterShardingStats` which will query all the regions in the cluster and return
a `ShardRegion.ClusterShardingStats` containing the identifiers of the shards running in each region and a count
of entities that are alive in each shard.

`ShardRegion.GetClusterShardingStats`将查询集群中的所有区域并返回`ShardRegion.ClusterShardingStats`，
其中包含在每个区域中运行的分片的标识符以及每个分片中处于活动状态的实体计数。

The type names of all started shards can be acquired via @scala[`ClusterSharding.shardTypeNames`]  @java[`ClusterSharding.getShardTypeNames`].

可以通过 @scala[`ClusterSharding.shardTypeNames`] 获取所有已启动分片的类型名称。

The purpose of these messages is testing and monitoring, they are not provided to give access to
directly sending messages to the individual entities.

这些消息的目的是测试和监视，它们不是为了提供直接向各个实体发送消息的访问权而提供的。

## Rolling upgrades

## 滚动升级

When doing rolling upgrades special care must be taken to not change any of the following aspects of sharding:

在进行滚动升级时，必须特别注意不要更改分片的以下任何方面：

 * the `extractShardId` function
 * the role that the shard regions run on
 * the persistence mode

 如果其中任何一个需要更改，则需要重新启动完整群集。

 * `extractShardId`函数
 * 分片区域运行的角色
 * 持久性模式

 If any one of these needs a change it will require a full cluster restart.
