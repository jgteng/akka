# Classic Cluster Client

@@@ note

Akka Classic is the original Actor APIs, which have been improved by more type safe and guided Actor APIs, 
known as Akka Typed. Akka Classic is still fully supported and existing applications can continue to use 
the classic APIs. It is also possible to use Akka Typed together with classic actors within the same 
ActorSystem, see @ref[coexistence](typed/coexisting.md). For new projects we recommend using the new Actor APIs.

Instead of the cluster client we recommend Akka gRPC (FIXME https://github.com/akka/akka/issues/26175)

@@@

# 集群客户端

## Dependency

To use Cluster Client, you must add the following dependency in your project:

要使用集群客户端，你必须如下依赖项添加到你的项目中：

@@dependency[sbt,Maven,Gradle] {
  group=com.typesafe.akka
  artifact=akka-cluster-tools_$scala.binary_version$
  version=$akka.version$
}

## Introduction

## 介绍

An actor system that is not part of the cluster can communicate with actors
somewhere in the cluster via the @apidoc[ClusterClient], the client can run in an `ActorSystem` that is part of
another cluster. It only needs to know the location of one (or more) nodes to use as initial
contact points. It will establish a connection to a @apidoc[akka.cluster.client.ClusterReceptionist] somewhere in
the cluster. It will monitor the connection to the receptionist and establish a new
connection if the link goes down. When looking for a new receptionist it uses fresh
contact points retrieved from previous establishment, or periodically refreshed contacts,
i.e. not necessarily the initial contact points.

不属于集群一部分的某个actor系统可以通过 @unidoc[ClusterClient] 与集群中的某个actor进行通信，
客户端可以作为另一个集群的一部分运行在`ActorSystem`中。它只需要知道一个（或多个）节点的位置来作为初始联系点，
它将在集群中的某个位置建立与 @unidoc[akka.cluster.client.ClusterReceptionist] 的连接。它将监视与receptionist的连接，
并在链路断开时建立新连接。当查找receptionist时，它使用从先前建立连接的联系点来检索新的接触点（节点），
或者定期刷新联系人（contacts），即receptionist可能不在初始联系点上。

Using the @apidoc[ClusterClient] for communicating with a cluster from the outside requires that the system with the client
can both connect and be connected to with Akka Remoting from all the nodes in the cluster with a receptionist.
This creates a tight coupling in that the client and cluster systems may need to have the same version of 
both Akka, libraries, message classes, serializers and potentially even the JVM. In many cases it is a better solution 
to use a more explicit and decoupling protocol such as [HTTP](https://doc.akka.io/docs/akka-http/current/index.html) or 
[gRPC](https://doc.akka.io/docs/akka-grpc/current/).

Additionally since Akka Remoting is primarily designed as a protocol for Akka Cluster there is no explicit resource
management, when a @apidoc[ClusterClient] has been used it will cause connections with the cluster until the ActorSystem is 
stopped (unlike other kinds of network clients). 

@apidoc[ClusterClient] should not be used when sending messages to actors that run
within the same cluster. Similar functionality as the @apidoc[ClusterClient] is
provided in a more efficient way by @ref:[Distributed Publish Subscribe in Cluster](distributed-pub-sub.md) for actors that
belong to the same cluster.

向同一集群中运行的actor发送消息时，不应使用 @unidoc[ClusterClient]。对于属于同一集群的actor，
集群中的 @ref:[分布式发布/订阅](distributed-pub-sub.md) 以更有效的方式提供了与`ClusterClient`类似的功能。

It is necessary that the connecting system has its `akka.actor.provider` set  to `remote` or `cluster` when using
the cluster client.

此外，请注意在使用集群客户端时需要将`akka.actor.provider`从`local`改为`remote`或`cluster`。

The receptionist is supposed to be started on all nodes, or all nodes with specified role,
in the cluster. The receptionist can be started with the @apidoc[akka.cluster.client.ClusterReceptionist] extension
or as an ordinary actor.

receptionist应该在集群中的所有节点或指定角色的节点上启动。
receptionist可以使用 @apidoc[akka.cluster.client.ClusterReceptionist] 扩展或作为普通actor来启动。

You can send messages via the @apidoc[ClusterClient] to any actor in the cluster that is registered
in the @apidoc[DistributedPubSubMediator] used by the @apidoc[akka.cluster.client.ClusterReceptionist].
The @apidoc[ClusterClientReceptionist] provides methods for registration of actors that
should be reachable from the client. Messages are wrapped in `ClusterClient.Send`,
@scala[@scaladoc[`ClusterClient.SendToAll`](akka.cluster.client.ClusterClient$)]@java[`ClusterClient.SendToAll`] or @scala[@scaladoc[`ClusterClient.Publish`](akka.cluster.client.ClusterClient$)]@java[`ClusterClient.Publish`].

Both the @apidoc[ClusterClient] and the @apidoc[ClusterClientReceptionist] emit events that can be subscribed to.
The @apidoc[ClusterClient] sends out notifications in relation to having received a list of contact points
from the @apidoc[ClusterClientReceptionist]. One use of this list might be for the client to record its
contact points. A client that is restarted could then use this information to supersede any previously
configured contact points.

The @apidoc[ClusterClientReceptionist] sends out notifications in relation to having received a contact
from a @apidoc[ClusterClient]. This notification enables the server containing the receptionist to become aware of
what clients are connected.

@unidoc[ClusterClientReceptionist] 发出与从 @unidoc[ClusterClient] 接收联系有关的通知。
此通知使包含receptionist的服务器能够了解客户端连接的内容。

1. **ClusterClient.Send**

    The message will be delivered to one recipient with a matching path, if any such
    exists. If several entries match the path the message will be delivered
    to one random destination. The sender of the message can specify that local
    affinity is preferred, i.e. the message is sent to an actor in the same local actor
    system as the used receptionist actor, if any such exists, otherwise random to any other
    matching entry.

    如果存在任何此类消息，则将使用匹配的路径将消息传递给一个receptionist。如果多个条目与路径匹配，则将消息传递到一个随机目标。
    消息的发送者可以指定本地亲和性是优选的，即，如果存在任何这样的receptionist，
    则将消息发送到与所使用的receptionist actor相同的本地actor系统中的actor，否则随机地发送到任何其他匹配的条目。

2. **ClusterClient.SendToAll**

    The message will be delivered to all recipients with a matching path.

    消息将以匹配的路径发送给所有recipients。

3. **ClusterClient.Publish**

    The message will be delivered to all recipients Actors that have been registered as subscribers
    to the named topic.

    该消息将传递给已注册为指定主题的订阅者的所有recipients。

Response messages from the destination actor are tunneled via the receptionist
to avoid inbound connections from other cluster nodes to the client:

来自目标actor的响应消息通过receptionist进行隧道传输，以避免从其他集群节点到客户端的入站连接：

* @scala[@scaladoc[`sender()`](akka.actor.Actor)]@java[@javadoc[`getSender()`](akka.actor.Actor)], as seen by the destination actor, is not the client itself,
  but the receptionist
* @scala[@scaladoc[`sender()`](akka.actor.Actor)] @java[@javadoc[`getSender()`](akka.actor.Actor)] of the response messages, sent back from the destination and seen by the client,
  is `deadLetters`

* 目的actor看到的 @scaladoc[`sender()`](akka.actor.Actor) 不是客户端，而是receptionist
* 从目的actor发回并由客户端看到响应消息的 @scaladoc[`sender()`](akka.actor.Actor) 是 `deadLetters`
  
since the client should normally send subsequent messages via the @apidoc[ClusterClient].
It is possible to pass the original sender inside the reply messages if
the client is supposed to communicate directly to the actor in the cluster.

因为客户端通常应该通过 @unidoc[ClusterClient] 发送后续消息。如果客户端应该直接与集群中的actor通信，
则可以在回复消息中传递原始发送者。

While establishing a connection to a receptionist the @apidoc[ClusterClient] will buffer
messages and send them when the connection is established. If the buffer is full
the @apidoc[ClusterClient] will drop old messages when new messages are sent via the client.
The size of the buffer is configurable and it can be disabled by using a buffer size of 0.

在建立与receptionist的连接时， @unidoc[ClusterClient] 将缓冲消息并在建立连接时发送消息。如果缓冲区已满，
则当通过客户端发送新消息时， @unidoc[ClusterClient] 将丢弃旧消息。缓冲区的大小是可配置的，可以设置为0来禁用缓存区。

It's worth noting that messages can always be lost because of the distributed nature
of these actors. As always, additional logic should be implemented in the destination
(acknowledgement) and in the client (retry) actors to ensure at-least-once message delivery.

值得注意的是，由于这些参与者的分布式特性，消息总是会丢失。与往常一样，
应在目标（确认）和客户端（重试）actor中实现其他逻辑，以确保至少一次消息传递。

## An Example

## 一个示例

On the cluster nodes first start the receptionist. Note, it is recommended to load the extension
when the actor system is started by defining it in the `akka.extensions` configuration property:

在集群节点上首先启动receptionist。注意，建议在启动actor系统时通过在`akka.extensions`配置属性中定义它来加载扩展：

```
akka.extensions = ["akka.cluster.client.ClusterClientReceptionist"]
```

Next, register the actors that should be available for the client.

下一步，注册应该供客户端使用的actor。

Scala
:  @@snip [ClusterClientSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/client/ClusterClientSpec.scala) { #server }

Java
:  @@snip [ClusterClientTest.java](/akka-cluster-tools/src/test/java/akka/cluster/client/ClusterClientTest.java) { #server }

On the client you create the @apidoc[ClusterClient] actor and use it as a gateway for sending
messages to the actors identified by their path (without address information) somewhere
in the cluster.

在客户上，你可以创建 @unidoc[ClusterClient] actor，并将其作为网关，
以便将消息发送到集群内由路径（ActorPath，没有地址信息）标记得actor位置。

Scala
:  @@snip [ClusterClientSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/client/ClusterClientSpec.scala) { #client }

Java
:  @@snip [ClusterClientTest.java](/akka-cluster-tools/src/test/java/akka/cluster/client/ClusterClientTest.java) { #client }

The `initialContacts` parameter is a @scala[`Set[ActorPath]`]@java[`Set<ActorPath>`], which can be created like this:

`initialContacts`参数是一个 @scala[`Set[ActorPath]`]，你可以这样创建：

Scala
:  @@snip [ClusterClientSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/client/ClusterClientSpec.scala) { #initialContacts }

Java
:  @@snip [ClusterClientTest.java](/akka-cluster-tools/src/test/java/akka/cluster/client/ClusterClientTest.java) { #initialContacts }

You will probably define the address information of the initial contact points in configuration or system property.
See also [Configuration](#cluster-client-config).

你可能会在配置或系统属性中定义初始联系点的地址信息。另请参见[配置](#cluster-client-config)。

A more comprehensive sample is available in the tutorial named
@scala[[Distributed workers with Akka and Scala](https://github.com/typesafehub/activator-akka-distributed-workers).]
@java[[Distributed workers with Akka and Java](https://github.com/typesafehub/activator-akka-distributed-workers-java).]

在名为 @scala[Distributed workers with Akka和Scala](https://github.com/typesafehub/activator-akka-distributed-workers) 的教程中提供了更全面的示例。

## ClusterClientReceptionist Extension

## ClusterClientReceptionist扩展

In the example above the receptionist is started and accessed with the `akka.cluster.client.ClusterClientReceptionist` extension.
That is convenient and perfectly fine in most cases, but it can be good to know that it is possible to
start the `akka.cluster.client.ClusterReceptionist` actor as an ordinary actor and you can have several
different receptionists at the same time, serving different types of clients.

在上面的示例中，使用`akka.cluster.client.ClusterClientReceptionist`扩展来启动和访问receptionist。在大多数情况下，
这很方便，也很完美，但是知道可以将`akka.cluster.client.ClusterReceptionist` 演员作为一个普通演员开始并且你可以同时拥有几个不同的receptionist，
服务不同客户的类型。

Note that the @apidoc[ClusterClientReceptionist] uses the @apidoc[DistributedPubSub] extension, which is described
in @ref:[Distributed Publish Subscribe in Cluster](distributed-pub-sub.md).

请注意，@unidoc[ClusterClientReceptionist] 使用 @unidoc[DistributedPubSub] 扩展，该扩展在
@ref:[“集群中的分布式发布订阅”](distributed-pub-sub.md) 中进行了描述。

It is recommended to load the extension when the actor system is started by defining it in the
`akka.extensions` configuration property:

建议在actor系统启动时通过在`akka.extensions`配置属性中定义扩展来加载扩展：

```
akka.extensions = ["akka.cluster.client.ClusterClientReceptionist"]
```

## Events

## 事件

As mentioned earlier, both the @apidoc[ClusterClient] and @apidoc[ClusterClientReceptionist] emit events that can be subscribed to.
The following code snippet declares an actor that will receive notifications on contact points (addresses to the available
receptionists), as they become available. The code illustrates subscribing to the events and receiving the @apidoc[ClusterClient]
initial state.

如前所述， @unidoc[ClusterClient] 和 @unidoc[ClusterClientReceptionist] 都会发出可以订阅的事件。
以下代码段声明了一个actor，它将在接触点（contacts point，可用receptionist的地址）上接收通知，因为它们可用。
该代码说明了怎样订阅事件和接收 @unidoc[ClusterClient] 初始状态。

Scala
:  @@snip [ClusterClientSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/client/ClusterClientSpec.scala) { #clientEventsListener }

Java
:  @@snip [ClusterClientTest.java](/akka-cluster-tools/src/test/java/akka/cluster/client/ClusterClientTest.java) { #clientEventsListener }

Similarly we can have an actor that behaves in a similar fashion for learning what cluster clients are connected to a @apidoc[ClusterClientReceptionist]:

类似地，我们可以让一个actor以类似的方式运行，以了解哪些集群客户端连接到 @unidoc[ClusterClientReceptionist] ：

Scala
:  @@snip [ClusterClientSpec.scala](/akka-cluster-tools/src/multi-jvm/scala/akka/cluster/client/ClusterClientSpec.scala) { #receptionistEventsListener }

Java
:  @@snip [ClusterClientTest.java](/akka-cluster-tools/src/test/java/akka/cluster/client/ClusterClientTest.java) { #receptionistEventsListener }

<a id="cluster-client-config"></a>
## Configuration

## 配置

The @apidoc[ClusterClientReceptionist] extension (or @apidoc[akka.cluster.client.ClusterReceptionistSettings]) can be configured
with the following properties:

可以使用以下属性配置 @unidoc[ClusterClientReceptionist] 扩展（或 @unidoc[akka.cluster.client.ClusterReceptionistSettings] ）：

@@snip [reference.conf](/akka-cluster-tools/src/main/resources/reference.conf) { #receptionist-ext-config }

The following configuration properties are read by the @apidoc[ClusterClientSettings]
when created with a @scala[@scaladoc[`ActorSystem`](akka.actor.ActorSystem)]@java[@javadoc[`ActorSystem`](akka.actor.ActorSystem)] parameter. It is also possible to amend the @apidoc[ClusterClientSettings]
or create it from another config section with the same layout as below. @apidoc[ClusterClientSettings] is
a parameter to the @scala[@scaladoc[`ClusterClient.props`](akka.cluster.client.ClusterClient$)]@java[@javadoc[`ClusterClient.props`](akka.cluster.client.ClusterClient$)] factory method, i.e. each client can be configured
with different settings if needed.

使用 @scaladoc[`ActorSystem`](akka.actor.ActorSystem) 参数创建时，@unidoc[ClusterClientSettings] 将读取以下配置属性。
也可以修改 @unidoc[ClusterClientSettings] 或使用与下面相同的布局从另一个config部分创建它。
@unidoc[ClusterClientSettings] 是 @scaladoc[`ClusterClient.props`](akka.cluster.client.ClusterClient$) 工厂方法的参数，
即如果需要，可以为每个客户端配置不同的设置。

@@snip [reference.conf](/akka-cluster-tools/src/main/resources/reference.conf) { #cluster-client-config }

## Failure handling

## 故障处理

When the cluster client is started it must be provided with a list of initial contacts which are cluster
nodes where receptionists are running. It will then repeatedly (with an interval configurable
by `establishing-get-contacts-interval`) try to contact those until it gets in contact with one of them.
While running, the list of contacts are continuously updated with data from the receptionists (again, with an
interval configurable with `refresh-contacts-interval`), so that if there are more receptionists in the cluster
than the initial contacts provided to the client the client will learn about them.

启动集群客户端时，必须为其提供初始联系人列表，这些联系人是正在运行receptionist的集群节点。
然后重复（通过`establishing-get-contacts-interval`配置间隔）尝试联系那些直到它与其中一个接触。在运行时，
联系人列表会不断更新来自receptionist的数据（同样，可以使用`refresh-contacts-interval`配置间隔），这样，
如果集群中的receptionist多于提供给客户端的初始联系人将了解他们。

While the client is running it will detect failures in its connection to the receptionist by heartbeats
if more than a configurable amount of heartbeats are missed the client will try to reconnect to its known
set of contacts to find a receptionist it can access.

当客户端正在运行时，如果错过了超过可配置的心跳量，客户端将尝试重新连接到其已知的联系人集以找到它可以访问的receptionist，
它将通过心跳检测其与receptionist的连接中的故障。

## When the cluster cannot be reached at all

## 当完全无法访问集群时

It is possible to make the cluster client stop entirely if it cannot find a receptionist it can talk to
within a configurable interval. This is configured with the `reconnect-timeout`, which defaults to `off`.
This can be useful when initial contacts are provided from some kind of service registry, cluster node addresses
are entirely dynamic and the entire cluster might shut down or crash, be restarted on new addresses. Since the
client will be stopped in that case a monitoring actor can watch it and upon `Terminate` a new set of initial
contacts can be fetched and a new cluster client started.

如果集群客户端无法找到在可配置间隔内与之通信的receptionist，则可以使集群客户端完全停止。
这是使用`reconnect-timeout`配置的，默认为off。当从某种服务注册表提供初始联系人时这可能很有用，集群节点地址完全是动态的，
整个集群可能会关闭或崩溃，在新地址上重新启动。由于在这种情况下客户端将被停止，监控参与者可以监视它，并且在终止时，
可以获取一组新的初始联系人并启动新的集群客户端。
