# Distributed Publish Subscribe in Cluster

# 集群的分布式发布、订阅

## Dependency

## 依赖

To use Distributed Publish Subscribe you must add the following dependency in your project:

要使用分布式发布、订阅功能，你需要将下列依赖加入你的项目：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-cluster-tools_$scala.binary_version$"
  version="$akka.version$"
}

## Introduction

## 介绍

How do I send a message to an actor without knowing which node it is running on?

如何在不知道actor运行在哪个节点的情况下发送消息？

How do I send messages to all actors in the cluster that have registered interest
in a named topic?

如何向集群内对命名主题感兴趣的所有注册actor发送消息？

This pattern provides a mediator actor, `akka.cluster.pubsub.DistributedPubSubMediator`,
that manages a registry of actor references and replicates the entries to peer
actors among all cluster nodes or a group of nodes tagged with a specific role.

这个模式提供了一个中介actor，`akka.cluster.pubsub.DistributedPubSubMediator`。管理actor引用的注册表，
并将其（注册的actor引用）复制到集群内所有节点或标记有特定角色的节点组中的对待actor（中介actor）。

The `DistributedPubSubMediator` actor is supposed to be started on all nodes,
or all nodes with specified role, in the cluster. The mediator can be
started with the `DistributedPubSub` extension or as an ordinary actor.

应该在集群中的所有节点或指定角色的节点上启动`DistributedPubSubMediator` actor。中介可以使用 `DistributedPubSub` 扩展或作为普通actor来启动。

The registry is eventually consistent, i.e. changes are not immediately visible at
other nodes, but typically they will be fully replicated to all other nodes after
a few seconds. Changes are only performed in the own part of the registry and those
changes are versioned. Deltas are disseminated in a scalable way to other nodes with
a gossip protocol.

注册表是最终一致性的，即更改不会立即在其它节点可见，但通常它们将在几秒钟后完全复制到所有节点。
更改仅在注册表自己的部分中执行，并且这些更改是版本化的。Deltas使用gossip协议以可扩展的方式传播到其它节点。

Cluster members with status @ref:[WeaklyUp](cluster-usage.md#weakly-up),
will participate in Distributed Publish Subscribe, i.e. subscribers on nodes with
`WeaklyUp` status will receive published messages if the publisher and subscriber are on
same side of a network partition.

集群成员状态为 @ref:[WeaklyUp](cluster-usage.md#weakly-up) 将参与分布式发布、订阅。
即具有`WeaklyUp`状态的节点上的订阅者将收到已发布的消息，如果发布者和订阅者在相同的网络分区一侧。

You can send messages via the mediator on any node to registered actors on
any other node.

你可以通过任何节点上的中介将消息发送到任何其它节点上的已注册actor。

There a two different modes of message delivery, explained in the sections
[Publish](#distributed-pub-sub-publish) and [Send](#distributed-pub-sub-send) below.

有两种不同的消息传递模式，在下面的 [Publish](#distributed-pub-sub-publish) 和 [Send](#distributed-pub-sub-send) 部分进行了解释。

@@@ div { .group-scala }

A more comprehensive sample is available in the
tutorial named [Akka Clustered PubSub with Scala!](https://github.com/typesafehub/activator-akka-clustering).

名为 [Akka Clustered PubSub with Scala!](https://github.com/typesafehub/activator-akka-clustering) 的教程中提供了更全面的示例。

@@@

<a id="distributed-pub-sub-publish"></a>
## Publish

## 发布

This is the true pub/sub mode. A typical usage of this mode is a chat room in an instant
messaging application.

这是真正的发布/订阅模式。这个模式的典型用法是即时消息应用程序中的聊天室。

Actors are registered to a named topic. This enables many subscribers on each node.
The message will be delivered to all subscribers of the topic.

多个actor注册到命名主题。这种每个节点上的订阅者。消息将传递给这个主题的所有订阅者。

For efficiency the message is sent over the wire only once per node (that has a matching topic),
and then delivered to all subscribers of the local topic representation.

为了提高效率，每个节点仅通过线路发送一次消息（具有匹配的主题），然后传递给本地主题表示的所有订阅者。

You register actors to the local mediator with `DistributedPubSubMediator.Subscribe`.
Successful `Subscribe` and `Unsubscribe` is acknowledged with
`DistributedPubSubMediator.SubscribeAck` and `DistributedPubSubMediator.UnsubscribeAck`
replies. The acknowledgment means that the subscription is registered, but it can still
take some time until it is replicated to other nodes.

使用`DistributedPubSubMediator.Subscribe`将你的actor注册到本地中介。
成功的`Subscribe`和`Unsubscribe`由`DistributedPubSubMediator.SubscribeAck`和`DistributedPubSubMediator.UnsubscribeAck`回复确认。
这意味着订阅已经注册，但它仍然需要一些时间（才可用），直到它被复制到其它节点。

You publish messages by sending `DistributedPubSubMediator.Publish` message to the
local mediator.

你通过`DistributedPubSubMediator.Publish`消息发送消息（实际的消息由Publish来携带发送）到本地中介。

Actors are automatically removed from the registry when they are terminated, or you
can explicitly remove entries with `DistributedPubSubMediator.Unsubscribe`.

终止时，actor会自动从注册表中删除，或者你可以使用`DistributedPubSubMediator.Unsubscribe`显示删除条目。

An example of a subscriber actor:

订阅者actor的一个例子：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #subscriber }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #subscriber }

Subscriber actors can be started on several nodes in the cluster, and all will receive
messages published to the "content" topic.

订阅者actor可在集群中的多个节点上启动，并且所有节点都将收到发布到"content"主题的消息。

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #start-subscribers }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #start-subscribers }

A simple actor that publishes to this "content" topic:

发布消息到"content"主题的简单演员：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #publisher }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #publisher }

It can publish messages to the topic from anywhere in the cluster:

可以从集群的任何地方向主题发布消息：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #publish-message }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #publish-message }

### Topic Groups

### 主题组

Actors may also be subscribed to a named topic with a `group` id.
If subscribing with a group id, each message published to a topic with the
`sendOneMessageToEachGroup` flag set to `true` is delivered via the supplied `RoutingLogic`
(default random) to one actor within each subscribing group.

actor也可以通过`group`（组）ID订阅命名主题。如果订阅时使用了组ID，则每个发布到主题的设置`sendOneMessageToEachGroup`标志位为`true`的消息，
将通过`RoutingLogic`（默认随机）传递给每个订阅组里的一个actor。

If all the subscribed actors have the same group id, then this works just like
`Send` and each message is only delivered to one subscriber.

如果所有订阅者actor拥有相同的组ID，则工作方式相当于`Send｀，每条消息只传递给一个订阅者。

If all the subscribed actors have different group names, then this works like
normal `Publish` and each message is broadcasted to all subscribers.

如何所有订阅者actor拥有不同的组ID，则工作方式相当于通常的`Publish`，每条消息将广播给所有订阅者。

@@@ note

Note that if the group id is used it is part of the topic identifier.
Messages published with `sendOneMessageToEachGroup=false` will not be delivered
to subscribers that subscribed with a group id.
Messages published with `sendOneMessageToEachGroup=true` will not be delivered
to subscribers that subscribed without a group id.

注意，如果使用组ID，则它是主题标识符的一部分。使用`sendOneMessageToEachGroup=false`发布的消息将不会被传递给使用了组ID的订阅者。
使用`sendOneMessageToEachGroup=true`发布的消息将不会被传递给没有使用组ID的订阅者。

@@@

<a id="distributed-pub-sub-send"></a>
## Send

## 发送

This is a point-to-point mode where each message is delivered to one destination,
but you still do not have to know where the destination is located.
A typical usage of this mode is private chat to one other user in an instant messaging
application. It can also be used for distributing tasks to registered workers, like a
cluster aware router where the routees dynamically can register themselves.

这是一种点对点模式，其中每条消息都传递到一个目的地，但你仍然不需要知道目的地的位置。
此模式的典型用法是即时通信应用的私密聊天。它可以将任务分发给已注册的工作人员，例如：集群感知路由可以动态的注册自己。

The message will be delivered to one recipient with a matching path, if any such
exists in the registry. If several entries match the path because it has been registered
on several nodes the message will be sent via the supplied `RoutingLogic` (default random)
to one destination. The sender of the message can specify that local affinity is preferred,
i.e. the message is sent to an actor in the same local actor system as the used mediator actor,
if any such exists, otherwise route to any other matching entry.

如果注册表里存在任何此类actor，则将使用匹配的路径将消息传递到收件者。如果注册在多个节点上的多个条目（actor）与路径匹配，
消息将通过`RoutingLogic`（默认随机）发送到一个目的地。消息的发送者可以指定本地亲和性，
即消息将发送到与所使用的中介者相同actor系统中匹配的（路径）actor，否则将路由到任一其它匹配的条目。

You register actors to the local mediator with `DistributedPubSubMediator.Put`.
The `ActorRef` in `Put` must belong to the same local actor system as the mediator.
The path without address information is the key to which you send messages.
On each node there can only be one actor for a given path, since the path is unique
within one local actor system.

使用`DistributedPubSubMediator.Put`将actor注册到本地中介。`Put`中的`ActorRef`必需与中介为相同的本地actor系统（ActorSystem）。
发送消息里key的路径不包含地址信息。在每个节点上，给定路径只能有一个actor，因为该路径在一个本地actor系统中是唯一的。

You send messages by sending `DistributedPubSubMediator.Send` message to the
local mediator with the path (without address information) of the destination
actors.

你通过使用`DistributedPubSubMediator.Send`以目标actor的路径（没有地址信息）来发送消息。

Actors are automatically removed from the registry when they are terminated, or you
can explicitly remove entries with `DistributedPubSubMediator.Remove`.

终止时actor会自动从注册表里移除，或者你可以调用`DistributedPubSubMediator.Remove`来显示删除条目。

An example of a destination actor:

目的actor的一个例子：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #send-destination }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #send-destination }

Destination actors can be started on several nodes in the cluster, and all will receive
messages sent to the path (without address information).

可以在在集群内的多个节点上启动目的actor，且所有节点将收到发送到路径的消息（不包含地址信息）。

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #start-send-destinations }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #start-send-destinations }

A simple actor that sends to the path:

发送到路径的简单actor：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #sender }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #sender }

It can send messages to the path from anywhere in the cluster:

可以从集群的任何位置向路径发送消息：

Scala
:  @@snip [DistributedPubSubMediatorSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/pubsub/DistributedPubSubMediatorSpec.scala) { #send-message }

Java
:  @@snip [DistributedPubSubMediatorTest.java](/akka-cluster-tools/src/test/java/akka/cluster/pubsub/DistributedPubSubMediatorTest.java) { #send-message }

It is also possible to broadcast messages to the actors that have been registered with
`Put`. Send `DistributedPubSubMediator.SendToAll` message to the local mediator and the wrapped message
will then be delivered to all recipients with a matching path. Actors with
the same path, without address information, can be registered on different nodes.
On each node there can only be one such actor, since the path is unique within one
local actor system.

也可以像已经使用`Put`注册了的actor广播消息。使用`DistributedPubSubMediator.SendToAll`将消息发送到本地中介，
然后将消息传递到所有匹配路径的收件者。具有相同路径的actor（不使用地址信息）可以注册到不同的节点。
在每个节点上只能有一个这样的actor，因为在同一个本地actor系统中路径是唯一的。

Typical usage of this mode is to broadcast messages to all replicas
with the same path, e.g. 3 actors on different nodes that all perform the same actions,
for redundancy. You can also optionally specify a property (`allButSelf`) deciding
if the message should be sent to a matching path on the self node or not.

这个模式的典型用法是向相同路径的收件者广播消息。例如：3个actor在不同的节点上执行相同的动作以使用冗余。
你可以选择指定（`allButSelf`）属性决定消息是否发送到匹配的自身节点（与发送者相同的节点）上。

## DistributedPubSub Extension

In the example above the mediator is started and accessed with the `akka.cluster.pubsub.DistributedPubSub` extension.
That is convenient and perfectly fine in most cases, but it can be good to know that it is possible to
start the mediator actor as an ordinary actor and you can have several different mediators at the same
time to be able to divide a large number of actors/topics to different mediators. For example you might
want to use different cluster roles for different mediators.

The `DistributedPubSub` extension can be configured with the following properties:

@@snip [reference.conf](/akka-cluster-tools/src/main/resources/reference.conf) { #pub-sub-ext-config }

It is recommended to load the extension when the actor system is started by defining it in
`akka.extensions` configuration property. Otherwise it will be activated when first used
and then it takes a while for it to be populated.

```
akka.extensions = ["akka.cluster.pubsub.DistributedPubSub"]
```

## Delivery Guarantee

As in @ref:[Message Delivery Reliability](general/message-delivery-reliability.md) of Akka, message delivery guarantee in distributed pub sub modes is **at-most-once delivery**.
In other words, messages can be lost over the wire.

If you are looking for at-least-once delivery guarantee, we recommend [Kafka Akka Streams integration](http://doc.akka.io/docs/akka-stream-kafka/current/home.html).
