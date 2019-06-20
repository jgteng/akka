# Cluster Singleton

# 集群单例

## Dependency

To use Cluster Singleton, you must add the following dependency in your project:

要使用集群单例，你必需在你的项目中添加以下依赖：

@@dependency[sbt,Maven,Gradle] {
  group=com.typesafe.akka
  artifact=akka-cluster-tools_$scala.binary_version$
  version=$akka.version$
}

## Introduction

## 介绍

For some use cases it is convenient and sometimes also mandatory to ensure that
you have exactly one actor of a certain type running somewhere in the cluster.

当你需要只有一个特定类型的actor在集群中的某个地方运行时，对于某些用例它很方便，有时也是强制性的。

Some examples:

 * single point of responsibility for certain cluster-wide consistent decisions, or
coordination of actions across the cluster system
 * single entry point to an external system
 * single master, many workers
 * centralized naming service, or routing logic

 一些示例：

 * 对于某些集群范围内的一致性决策的单一责任点，或协调集群系统中的操作
 * 单个入口到外部系统（外部系统通过一个入口来访问）
 * 单master，多worker
 * 集中命名服务，或路由逻辑

Using a singleton should not be the first design choice. It has several drawbacks,
such as single-point of bottleneck. Single-point of failure is also a relevant concern,
but for some cases this feature takes care of that by making sure that another singleton
instance will eventually be started.

使用单例不应该是第一选择。它有些缺点，比如单点瓶颈。单点故障也是一个相关的问题，但是在某些情况下，这个功能可通过确保另一个单例（被运行）来解决这个问题，实例最终将开始。

The cluster singleton pattern is implemented by `akka.cluster.singleton.ClusterSingletonManager`.
It manages one singleton actor instance among all cluster nodes or a group of nodes tagged with
a specific role. `ClusterSingletonManager` is an actor that is supposed to be started as early as possible
on all nodes, or all nodes with specified role, in the cluster. The actual singleton actor is
started by the `ClusterSingletonManager` on the oldest node by creating a child actor from
supplied `Props`. `ClusterSingletonManager` makes sure that at most one singleton instance
is running at any point in time.

集群单例模式由`akka.cluster.singleton.ClusterSingletonManager`实现。它管理所有集群节点中的一个单独的actor实例或一个标记有特定角色的节点组。
`ClusterSingletonManager`是一个应该在集群中的所有节点或具有指定角色的所有节点上尽早启动的actor。通过从提供的`Props`创建子actor，`ClusterSingletonManager`在最旧的节点上启动实际的单例actor。`ClusterSingletonManager`确保在任何时间最多只运行一个单例实例。

The singleton actor is always running on the oldest member with specified role.
The oldest member is determined by `akka.cluster.Member#isOlderThan`.
This can change when removing that member from the cluster. Be aware that there is a short time
period when there is no active singleton during the hand-over process.

单例actor始终在具有特定角色的最旧成员上运行。最旧成员由`akka.cluster.Member#isOlderThan`决定。
从集群中删除该成员时，这可能会更改。请注意，在切换过程中没有活动单例的时间很短。

The cluster failure detector will notice when oldest node becomes unreachable due to
things like JVM crash, hard shut down, or network failure. Then a new oldest node will
take over and a new singleton actor is created. For these failure scenarios there will
not be a graceful hand-over, but more than one active singletons is prevented by all
reasonable means. Some corner cases are eventually resolved by configurable timeouts.

故障检测器将注意到由于JVM崩溃、硬件关闭或网络故障等原因导致的最旧节点不能访问。然后，新的最旧节点将接管并创建新的单例actor。对于这些失败场景，将不会有优雅的（控制）移交，但是通过所有合理的手段阻止了多个活动单例的存在。一些极端情况最终可通过可配置的超时来解决。

You can access the singleton actor by using the provided `akka.cluster.singleton.ClusterSingletonProxy`,
which will route all messages to the current instance of the singleton. The proxy will keep track of
the oldest node in the cluster and resolve the singleton's `ActorRef` by explicitly sending the
singleton's `actorSelection` the `akka.actor.Identify` message and waiting for it to reply.
This is performed periodically if the singleton doesn't reply within a certain (configurable) time.
Given the implementation, there might be periods of time during which the `ActorRef` is unavailable,
e.g., when a node leaves the cluster. In these cases, the proxy will buffer the messages sent to the
singleton and then deliver them when the singleton is finally available. If the buffer is full
the `ClusterSingletonProxy` will drop old messages when new messages are sent via the proxy.
The size of the buffer is configurable and it can be disabled by using a buffer size of 0.

你可以使用提供的`akka.cluster.singleton.ClusterSingletonProxy`来访问单例actor，它将所有消息路由到单例的当前实例。
代理将跟踪集群里最老的节点和显示通过`actorSelection`发送`akka.actor.Identify`消息并等待它回复来解析单例的`ActorRef`。
如果单例在指定（可配置）时间内没有回复，则会定期执行此操作。给定实现，可能存在`ActorRef`不可达（不可用）的时间段，
例如：当节点离开集群时。在这些情况下，代理将缓冲发送给单例的消息直到最终单例再次可达（可访问）。如果缓冲已满，
则`ClusterSingletonProxy`将在通过代理发送新消息时（proxy收到新消息时）移除旧消息。缓冲区的大小是可配置的，设为0来禁用。

It's worth noting that messages can always be lost because of the distributed nature of these actors.
As always, additional logic should be implemented in the singleton (acknowledgement) and in the
client (retry) actors to ensure at-least-once message delivery.

值得注意的是，由于这些actor的分布式特性，消息总是会丢失。一样，应该在单例（确认）和客户端（重试）actor之间实施额外的逻辑确保至少一次消息传递。

The singleton instance will not run on members with status @ref:[WeaklyUp](cluster-usage.md#weakly-up).

单例实现不会运行在状态为 @ref:[WeaklyUp](cluster-usage.md#weakly-up) 的成员上。

## Potential problems to be aware of

## 需要注意的潜在问题

This pattern may seem to be very tempting to use at first, but it has several drawbacks, some of them are listed below:

这个模式最初看起来很诱人，但它有些缺陷，其中一些罗列如下：

 * the cluster singleton may quickly become a *performance bottleneck*,
 * you can not rely on the cluster singleton to be *non-stop* available — e.g. when the node on which the singleton has
been running dies, it will take a few seconds for this to be noticed and the singleton be migrated to another node,
 * in the case of a *network partition* appearing in a Cluster that is using Automatic Downing  (see docs for
@ref:[Auto Downing](cluster-usage.md#automatic-vs-manual-downing)),
it may happen that the isolated clusters each decide to spin up their own singleton, meaning that there might be multiple
singletons running in the system, yet the Clusters have no way of finding out about them (because of the partition).

* 集群单例可能很快成为 *性能瓶颈*，
* 你不可依赖集群单例 *不停* 可用——例如，当单例所在节点已经挂掉，这将需要些时间才能被注意到并将单例迁移到其它节点，
* 如果 *网络分区* 出现，在使用 Automatic Downing （见文档 @ref:[自动关闭](cluster-usage.md#authomatic-vs-manual-downing)）
的集群中，可能会发生隔离的每个集群都决定启用（spin up）它们自己的单例，这意味着可能有多个单例运行在系统中，但集群无法找到它们（因为网络分区）。

*因为每个分区都认为它们自己是一个独立、完整的集群*

Especially the last point is something you should be aware of — in general when using the Cluster Singleton pattern
you should take care of downing nodes yourself and not rely on the timing based auto-down feature.

你应该特别注意最后一点——通常在使用集群单例模式时，你应该自己处理节点关闭，而不是依赖基于时序的自动关闭功能。

@@@ warning

**Don't use Cluster Singleton together with Automatic Downing**,
since it allows the cluster to split up into two separate clusters, which in turn will result
in *multiple Singletons* being started, one in each separate cluster!

@@@

@@@ warning

**不要在集群单例上使用自动关闭**，因为它允许集群被分裂成两个单独的集群，这反过来导致启动 *多个单例*，因为每个单独的集群中有一个。

@@@

## An Example

## 示例

Assume that we need one single entry point to an external system. An actor that
receives messages from a JMS queue with the strict requirement that only one
JMS consumer must exist to make sure that the messages are processed in order.
That is perhaps not how one would like to design things, but a typical real-world
scenario when integrating with external systems.

假设我们需要一个外部系统的单一入口点。一个actor从JMS队列接收消息，它严格要求只有一个JMS消息者存在，以确保消息的处理是有序的。
这可能不是人们想要的设计（不好在设计），但是与外部系统集成时的典型现实场景。

Before explaining how to create a cluster singleton actor, let's define message classes @java[and their corresponding factory methods]
which will be used by the singleton.

在解释怎样创建集群单例之前，让我们先定义单例实用的消息类。

Scala
:  @@snip [ClusterSingletonManagerSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/singleton/ClusterSingletonManagerSpec.scala) { #singleton-message-classes }

Java
:  @@snip [ClusterSingletonManagerTest.java](/akka-cluster-tools/src/test/java/akka/cluster/singleton/TestSingletonMessages.java) { #singleton-message-classes }

On each node in the cluster you need to start the `ClusterSingletonManager` and
supply the `Props` of the singleton actor, in this case the JMS queue consumer.

在集群中的每个节点上，你需要启动`ClusterSingletonManager`并提供创建单例actor的`Props`，本例为JMS队列消费者。

Scala
:  @@snip [ClusterSingletonManagerSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/singleton/ClusterSingletonManagerSpec.scala) { #create-singleton-manager }

Java
:  @@snip [ClusterSingletonManagerTest.java](/akka-cluster-tools/src/test/java/akka/cluster/singleton/ClusterSingletonManagerTest.java) { #create-singleton-manager }

Here we limit the singleton to nodes tagged with the `"worker"` role, but all nodes, independent of
role, can be used by not specifying `withRole`.

这里我们将单例限制为被标记为 `"worker"` 的节点（上可启动），而不是所有节点。也可以通过不指定 `withRole` 来使用与角色夫关的所有节点。

We use an application specific `terminationMessage` @java[(i.e. `TestSingletonMessages.end()` message)] to be able to close the
resources before actually stopping the singleton actor. Note that `PoisonPill` is a
perfectly fine `terminationMessage` if you only need to stop the actor.

我们使用特定于应用程序的`terminationMessage`（消息）来在实际停止单例actor之前关闭资源。注意：如果你只是想停止actor，
则`PoisonPill`是一个完美的`terminationMessage`。

Here is how the singleton actor handles the `terminationMessage` in this example.

以下是单例actor在本例中怎样处理`terminationMessage`。

Scala
:  @@snip [ClusterSingletonManagerSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/singleton/ClusterSingletonManagerSpec.scala) { #consumer-end }

Java
:  @@snip [ClusterSingletonManagerTest.java](/akka-cluster-tools/src/test/java/akka/cluster/singleton/Consumer.java) { #consumer-end }

With the names given above, access to the singleton can be obtained from any cluster node using a properly
configured proxy.

使用上面给出的名称（singleton proxy name），可以使用正确配置的代理从集群任何节点获取单例的访问。

Scala
:  @@snip [ClusterSingletonManagerSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/singleton/ClusterSingletonManagerSpec.scala) { #create-singleton-proxy }

Java
:  @@snip [ClusterSingletonManagerTest.java](/akka-cluster-tools/src/test/java/akka/cluster/singleton/ClusterSingletonManagerTest.java) { #create-singleton-proxy }

A more comprehensive sample is available in the tutorial named 
@scala[[Distributed workers with Akka and Scala!](https://github.com/typesafehub/activator-akka-distributed-workers)]@java[[Distributed workers with Akka and Java!](https://github.com/typesafehub/activator-akka-distributed-workers-java)].

[使用Akka和Scala进行分布式工作](https://github.com/typesafehub/activator-akka-distributed-workers)教程提供了更全面的示例。

## Configuration

## 配置

The following configuration properties are read by the `ClusterSingletonManagerSettings`
when created with a `ActorSystem` parameter. It is also possible to amend the `ClusterSingletonManagerSettings`
or create it from another config section with the same layout as below. `ClusterSingletonManagerSettings` is
a parameter to the `ClusterSingletonManager.props` factory method, i.e. each singleton can be configured
with different settings if needed.

使用 `ActorSystem` 创建时，`ClusterSingletonManagerSettings`将读取以下配置属性。也可以修改`ClusterSingletonManagerSettings`
或从另一个配置部分创建它，其布局也下面相同。`ClusterSingletonManagerSettings`是`ClusterSingletonManager.props`工厂方法的参数。
如果需要，每个单例都可以配置不同的设置。

@@snip [reference.conf](/akka-cluster-tools/src/main/resources/reference.conf) { #singleton-config }

The following configuration properties are read by the `ClusterSingletonProxySettings`
when created with a `ActorSystem` parameter. It is also possible to amend the `ClusterSingletonProxySettings`
or create it from another config section with the same layout as below. `ClusterSingletonProxySettings` is
a parameter to the `ClusterSingletonProxy.props` factory method, i.e. each singleton proxy can be configured
with different settings if needed.

使用 `ActorSystem` 创建时，`ClusterSingletonProxySettings`将读取以下配置属性。也可以修改`ClusterSingletonProxySettings`
或从另一个配置部分创建它，其布局也下面相同。`ClusterSingletonProxySettings`是`ClusterSingletonProxy.props`工厂方法的参数。
如果需要，每个单例代理都可以配置不同的设置。

@@snip [reference.conf](/akka-cluster-tools/src/main/resources/reference.conf) { #singleton-proxy-config }

## Supervision

## 监督

There are two actors that could potentially be supervised. For the `consumer` singleton created above these would be: 

对于上面创建的`consumer`单例，有两个actor可能被受到监督：

* Cluster singleton manager e.g. `/user/consumer` which runs on every node in the cluster
* The user actor e.g. `/user/consumer/singleton` which the manager starts on the oldest node

* 集群单例管理器，如何：`/user/consumer`在集群中的每个节点上运行
* 用户actor，如：`/user/consumer/singleton`由管理员在最老的节点启动

The Cluster singleton manager actor should not have its supervision strategy changed as it should always be running.
However it is sometimes useful to add supervision for the user actor.
To accomplish this add a parent supervisor actor which will be used to create the 'real' singleton instance.
Below is an example implementation (credit to [this StackOverflow answer](https://stackoverflow.com/a/36716708/779513))

集群单例actor不应该改变其监督策略，因为穷乡僻壤需要运行。但是，为用户actor添加监督有时很有用。为此，添加一个父管理员actor，
用于创建“真正”的单例实例。下面是一个实现（归功于 [StackOverflow答案](https://stackoverflow.com/a/36716708/779513)）

Scala
:  @@snip [ClusterSingletonSupervision.scala](/akka-docs/src/test/scala/docs/cluster/singleton/ClusterSingletonSupervision.scala) { #singleton-supervisor-actor }

Java
:  @@snip [SupervisorActor.java](/akka-docs/src/test/java/jdocs/cluster/singleton/SupervisorActor.java) { #singleton-supervisor-actor }

And used here

这样使用

Scala
:  @@snip [ClusterSingletonSupervision.scala](/akka-docs/src/test/scala/docs/cluster/singleton/ClusterSingletonSupervision.scala) { #singleton-supervisor-actor-usage }

Java
:  @@snip [ClusterSingletonSupervision.java](/akka-docs/src/test/java/jdocs/cluster/singleton/ClusterSingletonSupervision.java) { #singleton-supervisor-actor-usage-imports }
@@snip [ClusterSingletonSupervision.java](/akka-docs/src/test/java/jdocs/cluster/singleton/ClusterSingletonSupervision.java) { #singleton-supervisor-actor-usage }

## Lease

A @ref[lease](coordination.md) can be used as an additional safety measure to ensure that two singletons 
don't run at the same time. Reasons for how this can happen:

* Network partitions without an appropriate downing provider
* Mistakes in the deployment process leading to two separate Akka Clusters
* Timing issues between removing members from the Cluster on one side of a network partition and shutting them down on the other side

A lease can be a final backup that means that the singleton actor won't be created unless
the lease can be acquired. 

To use a lease for singleton set `akka.cluster.singleton.use-lease` to the configuration location
of the lease to use. A lease with with the name `<actor system name>-singleton-<singleton actor path>` is used and
the owner is set to the @scala[`Cluster(system).selfAddress.hostPort`]@java[`Cluster.get(system).selfAddress().hostPort()`].

If the cluster singleton manager can't acquire the lease it will keep retrying while it is the oldest node in the cluster.
If the lease is lost then the singleton actor will be terminated then the lease will be re-tried.

