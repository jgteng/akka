# Cluster Usage
# 集群使用

For introduction to the Akka Cluster concepts please see @ref:[Cluster Specification](common/cluster.md).

有关Akka集群概念的介绍，请参阅 @ref:[集群规范](common/cluster.md)。

The core of Akka Cluster is the cluster membership, to keep track of what nodes are part of the cluster and
their health. There are several @ref:[Higher level Cluster tools](cluster-usage.md#higher-level-cluster-tools) that are built
on top of the cluster membership.

Akka集群的核心是集群成员，用于跟踪集群中哪些节点及期运行状态。有几个 @ref:[高级集群工具](#higher-level-cluster-tools) 构建于集群成员之上。

## Dependency

To use Akka Cluster, you must add the following dependency in your project:

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-cluster_$scala.binary_version$"
  version="$akka.version$"
}

## Sample project

You can look at the
@java[@extref[Cluster example project](samples:akka-samples-cluster-java)]
@scala[@extref[Cluster example project](samples:akka-samples-cluster-scala)]
to see what this looks like in practice.

## When and where to use Akka Cluster

## 何时、何地（怎样）使用Akka集群

An architectural choice you have to make is if you are going to use a microservices architecture or
a traditional distributed application. This choice will influence how you should use Akka Cluster.

如果要使用微服务架构或传统的分布式应用程序，你必须做出架构选择。这个选择将影响你怎样使用Akka集群

### Microservices

### 微服务

Microservices has many attractive properties, such as the independent nature of microservices allows for
multiple smaller and more focused teams that can deliver new functionality more frequently and can
respond quicker to business opportunities. Reactive Microservices should be isolated, autonomous, and have
a single responsibility as identified by Jonas Bonér in the book
[Reactive Microsystems: The Evolution of Microservices at Scale](https://info.lightbend.com/ebook-reactive-microservices-the-evolution-of-microservices-at-scale-register.html).

微服务具有许多吸引人的特性，例如微服务的独立性允许多个更小、更集中的团队可以更频繁地提供新功能，并且可以更快地响应商机（业务变化）。
反应式微服务具有隔离、自主且单一职责，来自感戴Jonas Bonér所著书籍：
[反应式微系统: 规模化微服务的演变](https://info.lightbend.com/ebook-reactive-microservices-the-evolution-of-microservices-at-scale-register.html).

In a microservices architecture, you should consider communication within a service and between services.

在微服务架构中，你应该考虑服务内与服务之间的通信。

In general we recommend against using Akka Cluster and actor messaging between _different_ services because that
would result in a too tight code coupling between the services and difficulties deploying these independent of
each other, which is one of the main reasons for using a microservices architecture.
See the discussion on
@scala[[Internal and External Communication](https://www.lagomframework.com/documentation/current/scala/InternalAndExternalCommunication.html)]
@java[[Internal and External Communication](https://www.lagomframework.com/documentation/current/java/InternalAndExternalCommunication.html)]
in the docs of the [Lagom Framework](https://www.lagomframework.com) (where each microservice is an Akka Cluster)
for some background on this.

一般而言，我们不建议在不同服务之间使用Akka集群和actor消息传递，因为这会导致服务之间的代码耦合过于紧密，
并且难以彼此独立地部署这些服务，这是使用微服务架构的主要原因之一。有关此的一些背景，
请参阅[Lagom Framework](https://www.lagomframework.com)（其中每个微服务是个Akka集群）的
[内部和外部通信](https://www.lagomframework.com/documentation/current/scala/InternalAndExternalCommunication.html)。

Nodes of a single service (collectively called a cluster) require less decoupling. They share the same code and
are deployed together, as a set, by a single team or individual. There might be two versions running concurrently
during a rolling deployment, but deployment of the entire set has a single point of control. For this reason,
intra-service communication can take advantage of Akka Cluster, failure management and actor messaging, which
is convenient to use and has great performance.

单个服务的节点（统称为集群）需要较少的去耦。它们由一个团队或单个人一起，共享相同的代码和部署。
在流动部署期间可能有两个版本同时运行，但整个集群的部署只有一个控制点。因此，服务内通信可以利用Akka集群、故障管理和actor消息，
使用方便且性能优良。

Between different services [Akka HTTP](https://doc.akka.io/docs/akka-http/current) or
[Akka gRPC](https://doc.akka.io/docs/akka-grpc/current/) can be used for synchronous (yet non-blocking)
communication and [Akka Streams Kafka](https://doc.akka.io/docs/akka-stream-kafka/current/home.html) or other
[Alpakka](https://doc.akka.io/docs/alpakka/current/) connectors for integration asynchronous communication.
All those communication mechanisms work well with streaming of messages with end-to-end back-pressure, and the
synchronous communication tools can also be used for single request response interactions. It is also important
to note that when using these tools both sides of the communication do not have to be implemented with Akka,
nor does the programming language matter.

在不同的服务之间，[Akka HTTP](https://doc.akka.io/docs/akka-http/current)或[Akka gRPC](https://developer.lightbend.com/docs/akka-grpc/current/)
可用于同步（但非阻塞）通信，而[Akka Streams Kafka](https://doc.akka.io/docs/akka-stream-kafka/current/home.html)或其它
[Alpakka](https://developer.lightbend.com/docs/alpakka/current/)连接器可用于异步通信集成。所有这些通信机制都能很好地处理具有回压（功能）的端到端消息流，
并且同步通信工具也可用于单个请求的请求响应交互。同样重要的是注意，当使用这些工具时通信的两侧不要求必需使用Akka，编程语言也不重要（可选用不同的编程语言）。

### Traditional distributed application

### 传统分布式应用

We acknowledge that microservices also introduce many new challenges and it's not the only way to
build applications. A traditional distributed application may have less complexity and work well in many cases.
For example for a small startup, with a single team, building an application where time to market is everything.
Akka Cluster can efficiently be used for building such distributed application.

我们确认微服务也引入了许多新的挑战，而且这也不是构建应用的唯一方法。传统分布式应用程序可能具有较低的复杂性并且在许多方面工作得很好。
例如：对于一个小型创业公司，只有一个团队，构建一个应用程序，这时候上市时间（发布到市场）就是一切。Akka集群可有效地用于构建这样的分布式应用程序。

In this case, you have a single deployment unit, built from a single code base (or using traditional binary
dependency management to modularize) but deployed across many nodes using a single cluster.
Tighter coupling is OK, because there is a central point of deployment and control. In some cases, nodes may
have specialized runtime roles which means that the cluster is not totally homogenous (e.g., "front-end" and
"back-end" nodes, or dedicated master/worker nodes) but if these are run from the same built artifacts this
is just a runtime behavior and doesn't cause the same kind of problems you might get from tight coupling of
totally separate artifacts.

在这种情况下，你有一个单一地部署单元，由单个代码库（或使用传统二进制依赖管理进行模块化），部署到多个节点的单个集群上。
更紧密的耦合是可行的，因为存在集中和控制中心点。在某些情况下，节点也许具有专门的运行时角色，这意味着集群不是完全同质的
（如何：具有“前端”和“后端”节点，或专用的主/从模式节点）。但如何这些是从相同的构建工件运行的话，只是一个运行时行为，
并不会导致你从紧密耦合中获得同类问题的完全独立的产出物。

A tightly coupled distributed application has served the industry and many Akka users well for years and is
still a valid choice.

多年来一直为业界和Akka用户提供紧密耦合的分布式应用程序服务，这仍然是一个有效的选择。

### Distributed monolith

### 单体分布式

There is also an anti-pattern that is sometimes called "distributed monolith". You have multiple services
that are built and deployed independently from each other, but they have a tight coupling that makes this
very risky, such as a shared cluster, shared code and dependencies for service API calls, or a shared
database schema. There is a false sense of autonomy because of the physical separation of the code and
deployment units, but you are likely to encounter problems because of changes in the implementation of
one service leaking into the behavior of others. See Ben Christensen's
[Don’t Build a Distributed Monolith](https://www.microservices.com/talks/dont-build-a-distributed-monolith/).

还有一种反模式被称为“单体分布式”。你有多个彼此独立构建和部署的服务，但它们紧密耦合，这会非常危险。例如：共享集群、
服务API调用的共享代码和依赖，或者共享的数据库模式。由于代码和部署单元的物理分隔而存在一种错误的自治感，
但是由于一个服务的实现中的更改泄漏到其他人的行为中，这可能会遇到问题。见Ben Christensen的[不要构建单体分布式](https://www.microservices.com/talks/dont-build-a-distributed-monolith/)。

Organizations that find themselves in this situation often react by trying to centrally coordinate deployment
of multiple services, at which point you have lost the principal benefit of microservices while taking on
the costs. You are in a halfway state with things that aren't really separable being built and deployed
in a separate way. Some people do this, and some manage to make it work, but it's not something we would
recommend and it needs to be carefully managed.

发现自己处于这种情况的组织经常通过尝试集中协调多个服务的部署来做出反应，此时你在承担成本的同时失去了微服务的主要优势。
你处于一种半途而废的状态，以不同的方式构建和部署不可分享的事物。有些人这样做，有些人设法让其可工作，但这不是我们推荐的方式，
因为这需要更小心的管理。

## A Simple Cluster Example

## 一个简单的集群示例

The following configuration enables the `Cluster` extension to be used.
It joins the cluster and an actor subscribes to cluster membership events and logs them.

以下配置允许使用`Cluster`扩展。它加入集群，同时actor将订阅集群成员事件并（通过日志）记录它们（的状态）。

The `application.conf` configuration looks like this:

`application.conf`配置文件如下所示：

```
akka {
  actor {
    provider = "cluster"
  }
  remote.artery {
    canonical {
      hostname = "127.0.0.1"
      port = 2551
    }
  }

  cluster {
    seed-nodes = [
      "akka://ClusterSystem@127.0.0.1:2551",
      "akka://ClusterSystem@127.0.0.1:2552"]

    # auto downing is NOT safe for production deployments.
    # you may want to use it during development, read more about it in the docs.
    # auth-downing对于生产部署不安全。
    # 你可能希望在开发期间使用它，在文档中阅读更多相关信息。
    #
    # auto-down-unreachable-after = 10s
  }
}

# Enable metrics extension in akka-cluster-metrics.
# 通过akka-cluster-emtrics中启用指示（收集）扩展
akka.extensions=["akka.cluster.metrics.ClusterMetricsExtension"]

# Sigar native library extract location during tests.
# Note: use per-jvm-instance folder when running multiple jvm on one host.
# Sigar库在测试期间的本地提取位置。
# 注意：在一台主机上运行多个JVM时，使用每JVM实例一文件夹。${user.dir}为JVM进程运行目录。
akka.cluster.metrics.native-library-extract-folder=${user.dir}/target/native
```

To enable cluster capabilities in your Akka project you should, at a minimum, add the @ref:[Remoting](remoting-artery.md)
settings, but with `cluster`.
The `akka.cluster.seed-nodes` should normally also be added to your `application.conf` file.

要在Akka项目中启用集群功能，你至少应添加 @ref:[Remoting](remoting.md)设置，但应用使用`cluster`。
`akka.cluster.seed-nodes`通常应添加到你的`application.conf`配置文件。

@@@ note

If you are running Akka in a Docker container or the nodes for some other reason have separate internal and
external ip addresses you must configure remoting according to @ref:[Akka behind NAT or in a Docker container](remoting-artery.md#remote-configuration-nat-artery)

如果你在Docker容器中运行Akka或由于其它原因节点需要单独的内部和外部IP地址，
则必须根据 @ref:[在NAT或Docker容器后面的Akka](remoting.md#remote-configuration-nat) 配置远程处理。

@@@

The seed nodes are configured contact points for initial, automatic, join of the cluster.

种子节点配置了集群初始化时自动连接的联系点（需要被加入的集群里的Up状态节点）。

Note that if you are going to start the nodes on different machines you need to specify the
ip-addresses or host names of the machines in `application.conf` instead of `127.0.0.1`

请注意，如果要在不同地机器上启动节点，而需要在`application.conf`中指定计算机的IP地址或主机名来代替`127.0.0.1`。

An actor that uses the cluster extension may look like this:

使用集群扩展的actor可能如下所示：

Scala
:  @@snip [SimpleClusterListener.scala](/akka-docs/src/test/scala/docs/cluster/SimpleClusterListener.scala) { type=scala }

Java
:  @@snip [SimpleClusterListener.java](/akka-docs/src/test/java/jdocs/cluster/SimpleClusterListener.java) { type=java }

The actor registers itself as subscriber of certain cluster events. It receives events corresponding to the current state
of the cluster when the subscription starts and then it receives events for changes that happen in the cluster.

The easiest way to run this example yourself is to try the
@scala[@extref[Akka Cluster Sample with Scala](samples:akka-samples-cluster-scala)]@java[@extref[Akka Cluster Sample with Java](samples:akka-samples-cluster-java)].
It contains instructions on how to run the `SimpleClusterApp`.

## Joining to Seed Nodes

## 加入种子节点

@@@ note
  When starting clusters on cloud systems such as Kubernetes, AWS, Google Cloud, Azure, Mesos or others which maintain 
  DNS or other ways of discovering nodes, you may want to use the automatic joining process implemented by the open source
  [Akka Cluster Bootstrap](https://doc.akka.io/docs/akka-management/current/bootstrap/index.html) module.
@@@

### Joining configured seed nodes

### 加入已配置的种子节点

You may decide if joining to the cluster should be done manually or automatically
to configured initial contact points, so-called seed nodes. After the joining process
the seed nodes are not special and they participate in the cluster in exactly the same
way as other nodes.

你可以通过已配置的初始联系点来决定手动或自动加入集群，也叫种子节点（初始联系点）。在加入过程后，种子节点并不是特殊节点，
它们和其它节点以相同的方式参与集群。

When a new node is started it sends a message to all seed nodes and then sends join command to the one that
answers first. If no one of the seed nodes replied (might not be started yet)
it retries this procedure until successful or shutdown.

启动新节点时，它会向所有种子节点发送消息并将join命令发送给第一个响应的节点。如果没有一个种子节点回复（也许还未启动），
它将重试此过程直到成功或关闭（失败）。

You define the seed nodes in the [configuration](#cluster-configuration) file (application.conf):

你在[配置](#cluster-configuration)文件（application.conf）中定义种子节点：

```
akka.cluster.seed-nodes = [
  "akka://ClusterSystem@host1:2552",
  "akka://ClusterSystem@host2:2552"]
```

This can also be defined as Java system properties when starting the JVM using the following syntax:

在JVM应用启动时通过Java系统属性定义种子节点语法如下：

```
-Dakka.cluster.seed-nodes.0=akka://ClusterSystem@host1:2552
-Dakka.cluster.seed-nodes.1=akka://ClusterSystem@host2:2552
```

The seed nodes can be started in any order and it is not necessary to have all
seed nodes running, but the node configured as the **first element** in the `seed-nodes`
configuration list must be started when initially starting a cluster, otherwise the
other seed-nodes will not become initialized and no other node can join the cluster.
The reason for the special first seed node is to avoid forming separated islands when
starting from an empty cluster.
It is quickest to start all configured seed nodes at the same time (order doesn't matter),
otherwise it can take up to the configured `seed-node-timeout` until the nodes
can join.

种子节点可以以任何顺序启动，并且不必使所有种子节点都运行，但在最开始启动集群时必有先启动`seed-nodes`配置列表中 **第一个元素**
的节点，否则其它种子节点将不会被初始化，也没有其它节点可以加入集群。特殊的第一种子节点的原因是当从空集群启动时避免开发分离的islands（多个集群）。
最快的是同时启动所有已配置的种子节点（顺序无关紧要），否则它可能需要配置`seed-node-timeout`直到节点可以加入。

Once more than two seed nodes have been started it is no problem to shut down the first
seed node. If the first seed node is restarted, it will first try to join the other
seed nodes in the existing cluster. Note that if you stop all seed nodes at the same time
and restart them with the same `seed-nodes` configuration they will join themselves and
form a new cluster instead of joining remaining nodes of the existing cluster. That is
likely not desired and should be avoided by listing several nodes as seed nodes for redundancy
and don't stop all of them at the same time.

一旦启动了两个以上的种子节点，关闭第一个种子节点就没有问题。如果第一个种子节点被重启，
它将首先尝试加入现有集群中已存在的其它种子节点。请注意，如果同时停止并重启`seed-nodes`配置的所有种子点，
它们将自行连接成一个新的集群，而不是加入现有集群的其它节点（未在种子节点内的节点）。这可能不是希望的，
应用通过将多个节点列为冗余的种子节点来避免此行为的发生，并改名同时停止所有这些（种子）节点。

### Automatically joining to seed nodes with Cluster Bootstrap

### 使用Cluster Bootstrap自动连接到种子节点

Instead of manually configuring seed nodes, which is useful in development or statically assigned node IPs, you may want
to automate the discovery of seed nodes using your cloud providers or cluster orchestrator, or some other form of service
discovery (such as managed DNS). The open source Akka Management library includes the
[Cluster Bootstrap](https://doc.akka.io/docs/akka-management/current/bootstrap/index.html) module which handles
just that. Please refer to its documentation for more details.

你可能希望使用云提供商的程序或集群协调程序或其它某种形式的服务发现（如托管DNS）自动发现种子节点，
来替代开发阶段手动配置种子节点或静态分配节点IP地址。
开源的Akka Management库包含[Cluster Bootstrap](https://developer.lightbend.com/docs/akka-management/current/bootstrap/index.html)
模块，它可以处理这个问题。有关更多详细信息请参阅其文档。

### Programatically joining to seed nodes with `joinSeedNodes`

### 使用`joinSeedNodes`以编程方式连接到种子节点

You may also use @scala[`Cluster(system).joinSeedNodes`]@java[`Cluster.get(system).joinSeedNodes`] to join programmatically,
which is attractive when dynamically discovering other nodes at startup by using some external tool or API.
When using `joinSeedNodes` you should not include the node itself except for the node that is
supposed to be the first seed node, and that should be placed first in the parameter to
`joinSeedNodes`.

你可以通过使用`Cluster(system).joinSeedNodes`以编程方式加入，这在启动时使用某些外部工具或API动态发现其它节点很有吸引力。
使用`joinSeedNodes`时，除了应该是第一个种子节点之外的其它节点不应该将它（第一个）包含在其中，并且应该首先将该节点放在
`joinSeedNodes`的第一个参数中。

*简单说：first-seed-node只应该在它自身节点被添加，并作为seed-nodes的第一个元素。*

Scala
:  @@snip [ClusterDocSpec.scala](/akka-docs/src/test/scala/docs/cluster/ClusterDocSpec.scala) { #join-seed-nodes }

Java
:  @@snip [ClusterDocTest.java](/akka-docs/src/test/java/jdocs/cluster/ClusterDocTest.java) { #join-seed-nodes-imports #join-seed-nodes }

Unsuccessful attempts to contact seed nodes are automatically retried after the time period defined in
configuration property `seed-node-timeout`. Unsuccessful attempt to join a specific seed node is
automatically retried after the configured `retry-unsuccessful-join-after`. Retrying means that it
tries to contact all seed nodes and then joins the node that answers first. The first node in the list
of seed nodes will join itself if it cannot contact any of the other seed nodes within the
configured `seed-node-timeout`.

在配置属性`seed-node-timeout`定义的时间段之后，将自动重试联系种子节点。在配置的`retry-unsuccessful-join-after`之后，
将自动重试加入特定的种子节点。重试意味着尝试联系所有种子节点，然后加入首先回复的节点。
如果种子节点列表中的第一个节点在配置的`seed-node-timeout`时间内无法联系到其它任何种子节点，则它将连接自身。

The joining of given seed nodes will by default be retried indefinitely until
a successful join. That process can be aborted if unsuccessful by configuring a
timeout. When aborted it will run @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown),
which by default will terminate the ActorSystem. CoordinatedShutdown can also be configured to exit
the JVM. It is useful to define this timeout if the `seed-nodes` are assembled
dynamically and a restart with new seed-nodes should be tried after unsuccessful
attempts.

默认情况下，无限期的重试连接到给定的种子节点，直到连接成功。如果配置超时失败，则可以中止该过程。当中止时，它将运行
@ref:[协调关闭](actors.md#coordinated-shutdown)，默认情况下将终止ActorSystem。CoordinatedShutdown也可以配置为退出JVM。
如果`seed-nodes`通过动态组织或在尝试失败后使用新的种子节点重启，则定义此超时将很有用。

```
# 加入种子节点超时20s后触发coordinated-shutdown
akka.cluster.shutdown-after-unsuccessful-join-seed-nodes = 20s
# coordinated-shutdown被触发时终止ActorSystem
akka.coordinated-shutdown.terminate-actor-system = on
```

If you don't configure seed nodes or use `joinSeedNodes` you need to join the cluster manually, which can be performed by using [JMX](#cluster-jmx) or [HTTP](#cluster-http).

如果你不配置种子节点或使用`joinSeedNodes`则需要手动加入集群，这可以使用[JMX](#cluster-jmx)或[HTTP](#cluster-http)执行。

You can join to any node in the cluster. It does not have to be configured as a seed node.
Note that you can only join to an existing cluster member, which means that for bootstrapping some
node must join itself,and then the following nodes could join them to make up a cluster.

你可以加入集群中的任何节点，它不必需要为种子节点。请注意，你只能加入现有集群成员，这意味着在引导时，某些节点必有加入它自己，
然后跟随节点可以加入它来构成集群。

An actor system can only join a cluster once. Additional attempts will be ignored.
When it has successfully joined it must be restarted to be able to join another
cluster or to join the same cluster again. It can use the same host name and port
after the restart, when it come up as new incarnation of existing member in the cluster,
trying to join in, then the existing one will be removed from the cluster and then it will
be allowed to join.

actor系统只能加入集群一次，其它尝试将被忽略。加入成功后，必有重新生动才能加入另一个集群或再次加入同一集群。
它可以在重启后使用相同的主机名和端口。当它尝试作为集群中现有成员的新化身加入时，必有将现有成员删除后它才可允许被加入。

@@@ note

The name of the `ActorSystem` must be the same for all members of a cluster. The name is given when you start the `ActorSystem`.

对于集群中的所有成员，`ActorSystem`的名字必有相同。在启动`ActorSystem`时会给出名字。

@@@

<a id="automatic-vs-manual-downing"></a>
## Downing

## 关闭

When a member is considered by the failure detector to be unreachable the
leader is not allowed to perform its duties, such as changing status of
new joining members to 'Up'. The node must first become reachable again, or the
status of the unreachable member must be changed to 'Down'. Changing status to 'Down'
can be performed automatically or manually. By default it must be done manually, using
[JMX](#cluster-jmx) or [HTTP](#cluster-http).

当故障检测器认为某个成员不可访问（unreachable）时，不允许leader履行其职责，例如：将新加入成员的状态改为`Up`。
必有首先此其可访问（reachable），或者将无法访问的成员状态改为`Down`。将状态更改为`Down`可自动或手动执行。
默认情况下需通过[JMX](#cluster-jmx)或[HTTP](#cluster-http)手动完成。

It can also be performed programmatically with @scala[`Cluster(system).down(address)`]@java[`Cluster.get(system).down(address)`].

也可以编程的方式使用`Cluster(system).down(address)`执行。

If a node is still running and sees its self as Down it will shutdown. @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown) will automatically
run if `run-coordinated-shutdown-when-down` is set to `on` (the default) however the node will not try
and leave the cluster gracefully so sharding and singleton migration will not occur.

如果节点在运行中将自身示为`Down`，则它将关闭。若`run-coordinated-shutdown-when-down`设置为`on`（默认值），
则 @ref:[协调关闭](actors.md#coordinated-shutdown)将自动运行。但是节点不会尝试正常的离开集群，因此集群不会发生分片和单例迁移。

A pre-packaged solution for the downing problem is provided by
[Split Brain Resolver](http://developer.lightbend.com/docs/akka-commercial-addons/current/split-brain-resolver.html),
which is part of the [Lightbend Reactive Platform](http://www.lightbend.com/platform).
If you don’t use RP, you should anyway carefully read the [documentation](http://developer.lightbend.com/docs/akka-commercial-addons/current/split-brain-resolver.html)
of the Split Brain Resolver and make sure that the solution you are using handles the concerns
described there.

[Split Brain Resolver](http://developer.lightbend.com/docs/akka-commercial-addons/current/split-brain-resolver.html)提供了打包的脑裂解决方案，
它是[Lightbend Reactive Platform](http://www.lightbend.com/platform)的一部分。如果你不使用它，
你应用仔细阅读Split Brain Resolver的[文档](http://developer.lightbend.com/docs/akka-commercial-addons/current/split-brain-resolver.html)，
并确保你处理了解决方案那里描述的问题。


### Auto-downing (DO NOT USE)

### auth-downing（不要使用）

There is an automatic downing feature that you should not use in production. For testing purpose you can enable it with configuration:

有一个自动关闭功能，但你不应该在生产中使用。出于测试目的，你可以通过测试启用它：

```
akka.cluster.auto-down-unreachable-after = 120s
```

This means that the cluster leader member will change the `unreachable` node
status to `down` automatically after the configured time of unreachability.

这意味着集群负责人将在配置的不可达时间后自动将`unreachable`的节点状态改为`down`。

This is a naïve approach to remove unreachable nodes from the cluster membership.
It can be useful during development but in a production environment it will eventually breakdown the cluster. When a network partition occurs, both sides of the
partition will see the other side as unreachable and remove it from the cluster.
This results in the formation of two separate, disconnected, clusters 
(known as *Split Brain*).

这是一种从集群中删除不可达节点的天真方法。它在开发过程中很有用，但在生产环境中最终会破坏集群。当发生网络分区时，
分区的两端都会看到另一端不可访问，并将其从集群中删除。这导致形成两个独立的，断开的集群（称为 *脑裂*）。

This behaviour is not limited to network partitions. It can also occur if a node
in the cluster is overloaded, or experiences a long GC pause.

此行为不仅限于网络分区。如果集群中的节点过载或经历长时间的GC暂停也会发生此问题。

@@@ warning

We recommend against using the auto-down feature of Akka Cluster in production. It
has multiple undesirable consequences for production systems.

我们建议不要在生产环境使用auth-downing特性，它对生产系统有许多不良后果。

If you are using @ref:[Cluster Singleton](cluster-singleton.md) or
@ref:[Cluster Sharding](cluster-sharding.md) it can break the contract provided by 
those features. Both provide a guarantee that an actor will be unique in a cluster.
With the auto-down feature enabled, it is possible for multiple independent clusters
to form (*Split Brain*). When this happens the guaranteed uniqueness will no
longer be true resulting in undesirable behaviour in the system.

如果你使用 @ref:[集群单例](cluster-singleton.md)或 @ref:[集群分片](cluster-sharding.md)，它可能会破坏这些功能。
两者都保证了actor在集群中的唯一性。当auth-downing特性被启用，可能形成多个独立的集群（*脑裂*）。当发生这种情况时，
上述功能保证的actor唯一性将不再成立，从而导致系统中出现不良行为。

This is even more severe when @ref:[Akka Persistence](persistence.md) is used in
conjunction with Cluster Sharding. In this case, the lack of unique actors can 
cause multiple actors to write to the same journal. Akka Persistence operates on a
single writer principle. Having multiple writers will corrupt the journal
and make it unusable.

当 @ref:[Akka持久化](persistence.md)与集群分片结合使用时，这甚至更加严重。这种情况下，
缺乏唯一性的actor可能导致多个actor写入同一个journal。Akka持久化操作以单一写作为原则，拥有多个写（actor）将破坏journal并使其无法使用。

Finally, even if you don't use features such as Persistence, Sharding, or Singletons, 
auto-downing can lead the system to form multiple small clusters. These small
clusters will be independent from each other. They will be unable to communicate
and as a result you may experience performance degradation. Once this condition
occurs, it will require manual intervention in order to reform the cluster.

最后，即使你不使用持久化、分片、单例等特性，auth-downing也将使系统形成多个小的集群。这些小集群彼此独立，它们之间将无法进行通信。
因此，你可能遇到性能下降的问题。一旦出现这种情况，就需要人工干预才可恢复（reform）集群。

Because of these issues, auto-downing should **never** be used in a production environment.

由于这些问题，**永远** 不要在生产环境使用auth-downing。

@@@

## Leaving

## 离开

There are two ways to remove a member from the cluster.

有两种方式从集群中删除成员。

You can stop the actor system (or the JVM process). It will be detected
as unreachable and removed after the automatic or manual downing as described
above.

你可以停止actor系统（可JVM进程）。它会被检测到不可达，并在自动或手册downing后被删除。

A more graceful exit can be performed if you tell the cluster that a node shall leave.
This can be performed using [JMX](#cluster-jmx) or [HTTP](#cluster-http).
It can also be performed programmatically with:

如果告诉集群节点应离开（leave），则可以执行更优雅的退出。这可以使用[JMX](#cluster-jmx)或[HTTP](#cluster-http)实现。
也可通过以下方式编程执行。

Scala
:  @@snip [ClusterDocSpec.scala](/akka-docs/src/test/scala/docs/cluster/ClusterDocSpec.scala) { #leave }

Java
:  @@snip [ClusterDocTest.java](/akka-docs/src/test/java/jdocs/cluster/ClusterDocTest.java) { #leave }

Note that this command can be issued to any member in the cluster, not necessarily the
one that is leaving.

注意，这些命令可发布到集群中的任何成员，而不一定是要离开的成员（自身）。

The @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown) will automatically run when the cluster node sees itself as
`Exiting`, i.e. leaving from another node will trigger the shutdown process on the leaving node.
Tasks for graceful leaving of cluster including graceful shutdown of Cluster Singletons and
Cluster Sharding are added automatically when Akka Cluster is used, i.e. running the shutdown
process will also trigger the graceful leaving if it's not already in progress.

将集群将自身视为`Exiting`时，@ref[协调关闭](actors.md#coordinated-shutdown) 将自动运行。既，从另一个节点离开，
将触发离开节点上的关闭过程。当使用Akka集群时，会自动添加集群正常离开（graceful leaving）的任务，
包括集群单例和集群分片的正常关闭。既如果尚未正在进行（集群单例和分片的graceful leaving任务），运行关闭过程时也会触发正常离开。

Normally this is handled automatically, but in case of network failures during this process it might still
be necessary to set the node’s status to `Down` in order to complete the removal.

通常这都是自动处理的，但如果在此过程中出现网络故障，可能仍需要将节点的状态设置为`Down`来完成删除过程。

<a id="weakly-up"></a>
## WeaklyUp Members

## WeaklyUp成员

If a node is `unreachable` then gossip convergence is not possible and therefore any
`leader` actions are also not possible. However, we still might want new nodes to join
the cluster in this scenario.

如果节点`unreachable`，则无法进行gossip收敛，因此任何`leader`操作都不可能。但是，在此场景中我们仍然希望新节点可以加入。

`Joining` members will be promoted to `WeaklyUp` and become part of the cluster if
convergence can't be reached. Once gossip convergence is reached, the leader will move `WeaklyUp`
members to `Up`.

如果无法达到收敛，`Joining`成员将被提升为`WeaklyUp`状态并成为集群的一部分。一旦达到gossip收敛，领导者将`WeaklyUp`成员状态移为`Up`。

This feature is enabled by default, but it can be disabled with configuration option:

默认情况下启用此功能，但可以使用配置禁用此功能：

```
akka.cluster.allow-weakly-up-members = off
```

You can subscribe to the `WeaklyUp` membership event to make use of the members that are
in this state, but you should be aware of that members on the other side of a network partition
have no knowledge about the existence of the new members. You should for example not count
`WeaklyUp` members in quorum decisions.

你可以订阅`WeaklyUp`成员事件来使用处于这个状态的成员，但你应该知道网络分区的另一端的成员不知道新成员的存在。例如，
你应该在仲裁决策中不计算`WeaklyUp`状态的成员。

<a id="cluster-subscriber"></a>
## Subscribe to Cluster Events

## 订阅集群事件

You can subscribe to change notifications of the cluster membership by using
@scala[`Cluster(system).subscribe`]@java[`Cluster.get(system).subscribe`].

你可以使用`Cluster(system).subscribe`来订阅集群成员身份改变的通知。

Scala
:  @@snip [SimpleClusterListener2.scala](/akka-docs/src/test/scala/docs/cluster/SimpleClusterListener2.scala) { #subscribe }

Java
:  @@snip [SimpleClusterListener2.java](/akka-docs/src/test/java/jdocs/cluster/SimpleClusterListener2.java) { #subscribe }

A snapshot of the full state, `akka.cluster.ClusterEvent.CurrentClusterState`, is sent to the subscriber
as the first message, followed by events for incremental updates.

`akka.cluster.ClusterEvent.CurrentClusterState`将作为第一条消息将完整状态的快照发送给订阅者，然后是增量更新的事件。

Note that you may receive an empty `CurrentClusterState`, containing no members,
followed by `MemberUp` events from other nodes which already joined,
if you start the subscription before the initial join procedure has completed.
This may for example happen when you start the subscription immediately after `cluster.join()` like below.
This is expected behavior. When the node has been accepted in the cluster you will
receive `MemberUp` for that node, and other nodes.

注意，如果在初始join过程完成之前启动订阅，你可能收到一个空的`CurrentClusterState`，它不包含任何成员，
之后将跟着已加入集群的其它节点的`MemberUp`事件。例如，当你在`cluster.join()`之后立即开始订阅，可能会发生此情况，
这是预期的行为。在集群接受节点后，你将收到该节点和其它节点的`MemberUp`事件。

Scala
:  @@snip [SimpleClusterListener2.scala](/akka-docs/src/test/scala/docs/cluster/SimpleClusterListener2.scala) { #join #subscribe }

Java
:  @@snip [SimpleClusterListener2.java](/akka-docs/src/test/java/jdocs/cluster/SimpleClusterListener2.java) { #join #subscribe }

To avoid receiving an empty `CurrentClusterState` at the beginning, you can use it like shown in the following example,
to defer subscription until the `MemberUp` event for the own node is received:

为避免一开始接收到空的`CurrentClusterState`，你可以使用如下示例推迟订阅，直到收到自己节点的`MemberUp`事件：

Scala
:  @@snip [SimpleClusterListener2.scala](/akka-docs/src/test/scala/docs/cluster/SimpleClusterListener2.scala) { #join #register-on-memberup }

Java
:  @@snip [SimpleClusterListener2.java](/akka-docs/src/test/java/jdocs/cluster/SimpleClusterListener2.java) { #join #register-on-memberup }


If you find it inconvenient to handle the `CurrentClusterState` you can use
@scala[`ClusterEvent.InitialStateAsEvents`] @java[`ClusterEvent.initialStateAsEvents()`] as parameter to `subscribe`.
That means that instead of receiving `CurrentClusterState` as the first message you will receive
the events corresponding to the current state to mimic what you would have seen if you were
listening to the events when they occurred in the past. Note that those initial events only correspond
to the current state and it is not the full history of all changes that actually has occurred in the cluster.

如果你发现处理`CurrentClusterState`不方便，可以使用`ClusterEvent.InitialStateAsEvent`作为参数进行`subscribe`。
这意味着你不会接收`CurrentClusterState`作为第一条消息，而是接收与当前状态相对应的事件，以模仿你在过去发生事件时所听到的。
请注意，这些初始事件仅对应于当前状态，并不是集群中实际发生的所有更改的完整历史记录。

Scala
:  @@snip [SimpleClusterListener.scala](/akka-docs/src/test/scala/docs/cluster/SimpleClusterListener.scala) { #subscribe }

Java
:  @@snip [SimpleClusterListener.java](/akka-docs/src/test/java/jdocs/cluster/SimpleClusterListener.java) { #subscribe }

The events to track the life-cycle of members are:

跟踪成员生命周期的事件有：

 * `ClusterEvent.MemberJoined` - A new member has joined the cluster and its status has been changed to `Joining`
 * `ClusterEvent.MemberUp` - A new member has joined the cluster and its status has been changed to `Up`
 * `ClusterEvent.MemberExited` - A member is leaving the cluster and its status has been changed to `Exiting`
Note that the node might already have been shutdown when this event is published on another node.
 * `ClusterEvent.MemberRemoved` - Member completely removed from the cluster.
 * `ClusterEvent.UnreachableMember` - A member is considered as unreachable, detected by the failure detector
of at least one other node.
 * `ClusterEvent.ReachableMember` - A member is considered as reachable again, after having been unreachable.
All nodes that previously detected it as unreachable has detected it as reachable again.

 * `ClusterEvent.MemberJoined` - 一个新成员已加入集群，状态更改为`Joining`。
 * `ClusterEvent.MemberUp` - 一个新成员已加入集群，状态更改为`Up`。
 * `ClusterEvent.MemberExited` - 一个成员开始离开集群并且状态更改为`Exiting`。注意，当此事件在另一个节点上发布时（订阅者收到时），该节点可能已经关闭。
 * `ClusterEvent.MemberRemoved` - 已从集群中完全删除此成员。
 * `ClusterEvent.UnreachableMember` - 一个成员被视为无法访问，由至少一个其它节点的故障检测器检测到。
 * `ClusterEvent.ReachableMember` - 成员在无法访问后被视为可访问。之前将其视为无法访问的所有节点都已将其视为可访问。

There are more types of change events, consult the API documentation
of classes that extends `akka.cluster.ClusterEvent.ClusterDomainEvent`
for details about the events.

有更多更改事件的类型，请参阅扩展了`akka.cluster.ClusterEvent.ClusterDomainEvent`接口的所有类的API文档以获取有关事件的详细信息。

Instead of subscribing to cluster events it can sometimes be convenient to only get the full membership state with
@scala[`Cluster(system).state`]@java[`Cluster.get(system).state()`]. Note that this state is not necessarily in sync with the events published to a
cluster subscription.

可以使用`Cluster(system).state`获取完整的成员状态而不是订阅集群事件。注意，此状态不一定与发布到集群的订阅事件同步（可能不是最新的）。

### Worker Dial-in Example

### Dial-in工作者示例

Let's take a look at an example that illustrates how workers, here named *backend*,
can detect and register to new master nodes, here named *frontend*.

让我们看一个示例，该示例演示了名叫 *backend* 的worker如何检测并注册到新的主节点，这里（新的主节点）名为 *frontend*。

The example application provides a service to transform text. When some text
is sent to one of the frontend services, it will be delegated to one of the
backend workers, which performs the transformation job, and sends the result back to
the original client. New backend nodes, as well as new frontend nodes, can be
added or removed to the cluster dynamically.

示例应用程序提供了文本转换服务。当某些文本被发送到frontend服务时，它将被委托给执行转换作业的后端工作者之一，
并将结果发送回原客户端。可以向集群动态添加或删除新的后端节点以及前端节点。

Messages:

消息：

Scala
:  @@snip [TransformationMessages.scala](/akka-docs/src/test/scala/docs/cluster/TransformationMessages.scala) { #messages }

Java
:  @@snip [TransformationMessages.java](/akka-docs/src/test/java/jdocs/cluster/TransformationMessages.java) { #messages }

The backend worker that performs the transformation job:

执行转换作业的后端工作者：

Scala
:  @@snip [TransformationBackend.scala](/akka-docs/src/test/scala/docs/cluster/TransformationBackend.scala) { #backend }

Java
:  @@snip [TransformationBackend.java](/akka-docs/src/test/java/jdocs/cluster/TransformationBackend.java) { #backend }

Note that the `TransformationBackend` actor subscribes to cluster events to detect new,
potential, frontend nodes, and send them a registration message so that they know
that they can use the backend worker.

请注意，`TransformationBackend`actor订阅集群事件以检测新的，潜在的frontend节点，并向它发送注册消息以便它们可以使用的后端工作者。

The frontend that receives user jobs and delegates to one of the registered backend workers:

接收用户作业并委托到已注册的其中一个后端工作者：

Scala
:  @@snip [TransformationFrontend.scala](/akka-docs/src/test/scala/docs/cluster/TransformationFrontend.scala) { #frontend }

Java
:  @@snip [TransformationFrontend.java](/akka-docs/src/test/java/jdocs/cluster/TransformationFrontend.java) { #frontend }

Note that the `TransformationFrontend` actor watch the registered backend
to be able to remove it from its list of available backend workers.
Death watch uses the cluster failure detector for nodes in the cluster, i.e. it detects
network failures and JVM crashes, in addition to graceful termination of watched
actor. Death watch generates the `Terminated` message to the watching actor when the
unreachable cluster node has been downed and removed.

注意，`TransformationFronted`actor监视已注册的后端（worker），以便能够将其从可用后端工作者列表中删除。死亡监视（Death watch）
使用集群故障检测器来检测集群中的节点，既除了正常的终止监视的actor之外，它还检测网络故障和JVM崩溃。当无法访问被关闭并删除后，
Death watch将生成`Terminated`消息并发送给watching actor。

The easiest way to run **Worker Dial-in Example** example yourself is to try the
@scala[@extref[Akka Cluster Sample with Scala](samples:akka-samples-cluster-scala)]@java[@extref[Akka Cluster Sample with Java](samples:akka-samples-cluster-java)].
It contains instructions on how to run the **Worker Dial-in Example** sample.
 
## Node Roles

## 节点角色

Not all nodes of a cluster need to perform the same function: there might be one sub-set which runs the web front-end,
one which runs the data access layer and one for the number-crunching. Deployment of actors—for example by cluster-aware
routers—can take node roles into account to achieve this distribution of responsibilities.

不是集群内的所有节点都执行相同的功能：可能有一个子集运行Web front-end，一个运行数据访问层，而另一个执行数据运算。
actor的部署——例如通过集群感知路由——可以将节点角色考虑在内以实现这种责任分配。

The roles of a node is defined in the configuration property named `akka.cluster.roles`
and it is typically defined in the start script as a system property or environment variable.

节点角色在名为`akka.cluster.roles`的属性配置，并且通过在启动脚本中将其作为系统属性或环境变量。

The roles of the nodes is part of the membership information in `MemberEvent` that you can subscribe to.

节点角色是你可订阅的`MemberEvent`成员信息的一部分。

<a id="min-members"></a>
## How To Startup when Cluster Size Reached

## 如何在达到集群大小时启动

A common use case is to start actors after the cluster has been initialized,
members have joined, and the cluster has reached a certain size.

一个常见用例是集群初始化后，已加入成员达到某个数量后再启动actors。

With a configuration option you can define required number of members
before the leader changes member status of 'Joining' members to 'Up'.:

使用配置选项，你可以设置leader在处理成员状态从`Joining`到`Up`时前需要的成员数量。：

```
akka.cluster.min-nr-of-members = 3
```

In a similar way you can define required number of members of a certain role
before the leader changes member status of 'Joining' members to 'Up'.:

类似的方式，你可以在leader加成员从`Joining`状态更改为`Up`之前定义特定角色所需的成员数量。：

```
akka.cluster.role {
  frontend.min-nr-of-members = 1
  backend.min-nr-of-members = 2
}
```

You can start the actors in a `registerOnMemberUp` callback, which will
be invoked when the current member status is changed to 'Up', i.e. the cluster
has at least the defined number of members.

你可以在`registerOnMemberUp`回调函数中启动actor，当当前成员状态更改为`Up`时将调用该回调，既集群至少具有指定的成员数量时。

Scala
:  @@snip [FactorialFrontend.scala](/akka-docs/src/test/scala/docs/cluster/FactorialFrontend.scala) { #registerOnUp }

Java
:  @@snip [FactorialFrontendMain.java](/akka-docs/src/test/java/jdocs/cluster/FactorialFrontendMain.java) { #registerOnUp }

This callback can be used for other things than starting actors.

这个回调也可用于除启动actor之外的其它操作。

## How To Cleanup when Member is Removed

## 如何在成员被删除时进行清理

You can do some clean up in a `registerOnMemberRemoved` callback, which will
be invoked when the current member status is changed to 'Removed' or the cluster have been shutdown.

你可以在`registerOnMemberRemoved`回调中进行清理，当当前成员状态更改为`Removed`或集群关闭时将被调用。

An alternative is to register tasks to the @ref:[Coordinated Shutdown](actors.md#coordinated-shutdown).

另一种办法是将清理任务注册到 @ref:[协调关闭](actors.md#coordinated-shutdown)。

@@@ note

Register a OnMemberRemoved callback on a cluster that have been shutdown, the callback will be invoked immediately on
the caller thread, otherwise it will be invoked later when the current member status changed to 'Removed'. You may
want to install some cleanup handling after the cluster was started up, but the cluster might already be shutting
down when you installing, and depending on the race is not healthy.

在已关闭的集群上注册 OnMemberRemoved 回调，将在当前调用线程上立即执行回调，否则将在当前成员状态更改为`Removed`时执行。
你也许想在集群启动时就安装一些清理句柄，但在安装（清理）时集群可能已经关闭，这将依赖于不健壮的竞争条件。*可能与当前执行线程竞争资源*。

@@@

## Higher level Cluster tools

## 高级集群工具

### Cluster Singleton

### 集群单例

For some use cases it is convenient and sometimes also mandatory to ensure that
you have exactly one actor of a certain type running somewhere in the cluster.

对于某些用例它很方便，有时也是强制性的，以确保你只有一个特定类型的actor在集群中的某个位置运行。

This can be implemented by subscribing to member events, but there are several corner
cases to consider. Therefore, this specific use case is covered by the
@ref:[Cluster Singleton](cluster-singleton.md).

这可以通过订阅成员状态来实现，但需要考虑到几个极端情况。因此，@ref:[集群单例](cluster-singleton.md)涵盖了这个特定用例。

### Cluster Sharding

## 集群分片

Distributes actors across several nodes in the cluster and supports interaction
with the actors using their logical identifier, but without having to care about
their physical location in the cluster.

在集群中的多个节点上分布actor并支持使用逻辑标识符与其交互，同时，不需要关心它们的物理位置。

See @ref:[Cluster Sharding](cluster-sharding.md).

见 @ref:[集群分片](cluster-sharding.md)。

### Distributed Publish Subscribe

### 分布式发布/订阅

Publish-subscribe messaging between actors in the cluster, and point-to-point messaging
using the logical path of the actors, i.e. the sender does not have to know on which
node the destination actor is running.

在集群中的actor之前使用发布/订阅进行消息传递，和使用逻辑地在actor之间实现点对点消息传递。既，发送者不必知道目的actor运行在哪个节点。

See @ref:[Distributed Publish Subscribe in Cluster](distributed-pub-sub.md).

见 @ref:[集群中的分布式发布/订阅](distributed-pub-sub.md).

### Cluster Client

## 集群客户端

Communication from an actor system that is not part of the cluster to actors running
somewhere in the cluster. The client does not have to know on which node the destination
actor is running.

从一个不属性集群的一部分的actor系统上与集群中某处运行着的actor通信。客户端不需要知道目的actor正在集群的哪个节点运行。

See @ref:[Cluster Client](cluster-client.md).

见 @ref:[集群客户端](cluster-client.md).

### Distributed Data

### 分布式数据

*Akka Distributed Data* is useful when you need to share data between nodes in an
Akka Cluster. The data is accessed with an actor providing a key-value store like API.

当你需要在节点间共享数据时，*Akka分布式数据* 非常有用。提供像键/值存储这样的API来访问数据。

See @ref:[Distributed Data](distributed-data.md).

见 @ref:[分布式数据](distributed-data.md).

### Cluster Aware Routers

### 集群感知路由器

All @ref:[routers](routing.md) can be made aware of member nodes in the cluster, i.e.
deploying new routees or looking up routees on nodes in the cluster.
When a node becomes unreachable or leaves the cluster the routees of that node are
automatically unregistered from the router. When new nodes join the cluster, additional
routees are added to the router, according to the configuration.

可以使所有路由器知道集群中的成员节点，即在集群中的节点上部署新路由或查找路由。当节点无法访问或离开集群时，
该节点的路由将自动从路由器注销。当新节点加入集群时，根据配置将其他路由添加到路由器。

See @ref:[Cluster Aware Routers](cluster-routing.md).

见 @ref:[集群感知路由器](cluster-routing.md).

### Cluster Metrics

### 集群指标

The member nodes of the cluster can collect system health metrics and publish that to other cluster nodes
and to the registered subscribers on the system event bus.

集群的成员节点可以收集系统运行状况指标，并将其发布到其他集群节点和系统事件总线上的已注册订阅者。

See @ref:[Cluster Metrics](cluster-metrics.md).

见 @ref:[集群指标](cluster-metrics.md).

## Failure Detector

## 故障检测器

In a cluster each node is monitored by a few (default maximum 5) other nodes, and when
any of these detects the node as `unreachable` that information will spread to
the rest of the cluster through the gossip. In other words, only one node needs to
mark a node `unreachable` to have the rest of the cluster mark that node `unreachable`.

在集群中，每个节点由少数（默认最多5个）其他节点监视，并且当其中任何节点检测到该节点无法访问时，
该信息将通过gossip传播到集群的其余部分。换句话说，只需要要有一个节点来标记另一个节点不可达，
既可使集群其余部分（节点）标记该节点不可达。

The failure detector will also detect if the node becomes `reachable` again. When
all nodes that monitored the `unreachable` node detects it as `reachable` again
the cluster, after gossip dissemination, will consider it as `reachable`.

故障检测器还将检测节点是否再次可达。当监视不可达节点的所有节点都检测到它再次可达时，集群在gossip传播之后将认为它是可达的。

If system messages cannot be delivered to a node it will be quarantined and then it
cannot come back from `unreachable`. This can happen if the there are too many
unacknowledged system messages (e.g. watch, Terminated, remote actor deployment,
failures of actors supervised by remote parent). Then the node needs to be moved
to the `down` or `removed` states and the actor system of the quarantined node
must be restarted before it can join the cluster again.

如果系统消息无法传递到节点，它将被隔离，然后无法从`unreachable`的状态返回。如果存在太多未确认的系统消息（例如，观察，终止，
远程演员部署，由远程父母监督的演员的失败），则会发生这种情况。然后，需要将节点移动到`down`或`removed`的状态，
并且必须重新启动已隔离节点的actor系统才能再次加入集群。

The nodes in the cluster monitor each other by sending heartbeats to detect if a node is
unreachable from the rest of the cluster. The heartbeat arrival times is interpreted
by an implementation of
[The Phi Accrual Failure Detector](http://www.jaist.ac.jp/~defago/files/pdf/IS_RR_2004_010.pdf).

集群中的节点通过发送心跳来相互监视，以检测节点是否无法从集群的其余部分访问。
心跳到达时间由[Phi Accrual Failure Detector](http://www.jaist.ac.jp/~defago/files/pdf/IS_RR_2004_010.pdf)的实现解释。

The suspicion level of failure is given by a value called *phi*.
The basic idea of the phi failure detector is to express the value of *phi* on a scale that
is dynamically adjusted to reflect current network conditions.

怀疑的失败程度由一个名为phi的值给出。phi故障检测器的基本思想是在动态调整以反映当前网络状况的标度上表示phi的值。

The value of *phi* is calculated as:

*phi* 值计算方式如下：

```
phi = -log10(1 - F(timeSinceLastHeartbeat))
```

where F is the cumulative distribution function of a normal distribution with mean
and standard deviation estimated from historical heartbeat inter-arrival times.

其中F是正态分布的累计积分函数，根据历史心跳到达间隔时间估计平均值和标准差。

In the [configuration](#cluster-configuration) you can adjust the `akka.cluster.failure-detector.threshold`
to define when a *phi* value is considered to be a failure.

在[配置](#cluster-configuration)中，你可以调整`akka.cluster.failure-detector.threshold`以定义 *phi* 值何时被视为失败。

A low `threshold` is prone to generate many false positives but ensures
a quick detection in the event of a real crash. Conversely, a high `threshold`
generates fewer mistakes but needs more time to detect actual crashes. The
default `threshold` is 8 and is appropriate for most situations. However in
cloud environments, such as Amazon EC2, the value could be increased to 12 in
order to account for network issues that sometimes occur on such platforms.

低`threshold`值容易产生许多误报，但确保在真正崩溃的情况下快速检测。相反，高`threshold`值产生的错误更少，
但需要更多的时间来检测实际崩溃。默认`threshold`值为8，适用于大多数情况。但是，在Amazon EC2等云环境中，可以将值增加到12，
以便解决有时在此类平台上出现的网络问题。

The following chart illustrates how *phi* increase with increasing time since the
previous heartbeat.

下图说明了自上一次心跳以来 *phi* 值如何随着时间的增加而增加。

![phi1.png](./images/phi1.png)

Phi is calculated from the mean and standard deviation of historical
inter arrival times. The previous chart is an example for standard deviation
of 200 ms. If the heartbeats arrive with less deviation the curve becomes steeper,
i.e. it is possible to determine failure more quickly. The curve looks like this for
a standard deviation of 100 ms.

Phi是根据历史到达时间的平均值和标准差计算的。上图是标准偏差200ms时的示例。如果心跳以较小的偏差到达，则曲线变得更陡峭，
即可以更快地确定故障。对于100ms的标准偏差，曲线看起来像这样。

![phi2.png](./images/phi2.png)

To be able to survive sudden abnormalities, such as garbage collection pauses and
transient network failures the failure detector is configured with a margin,
`akka.cluster.failure-detector.acceptable-heartbeat-pause`. You may want to
adjust the [configuration](#cluster-configuration) of this depending on your environment.
This is how the curve looks like for `acceptable-heartbeat-pause` configured to
3 seconds.

为了能够承受突然的异常，例如垃圾收集暂停和瞬时网络故障，
故障检测器配置了一个余量`akka.cluster.failure-detector.acceptable-heartbeat-pause`。你可能需要根据你的环境调整此配置。
这是（下图）如何将可接受的心跳暂停配置为3秒时的曲线。

![phi3.png](./images/phi3.png)

Death watch uses the cluster failure detector for nodes in the cluster, i.e. it detects
network failures and JVM crashes, in addition to graceful termination of watched
actor. Death watch generates the `Terminated` message to the watching actor when the
unreachable cluster node has been downed and removed.

死亡监视器使用集群故障检测器来检测集群中的节点，即除了正常终止监视的actor之外，它还检测网络故障和JVM崩溃。
当无法访问的集群节点已被关闭（downed）和删除时（removed），死亡监视会向观看者（watching actor）生成`Terminated`消息。

If you encounter suspicious false positives when the system is under load you should
define a separate dispatcher for the cluster actors as described in [Cluster Dispatcher](#cluster-dispatcher).

如果在系统处于负载状态时遇到可疑误报，则应为集群角色定义单独的调度程序，如[集群调度器](#cluster-dispatcher)中所述。

@@@ div { .group-scala }

## How to Test

## 怎样测试

@ref:[Multi Node Testing](multi-node-testing.md) is useful for testing cluster applications.

@ref:[多节点测试](multi-node-testing.md)对于测试集群应用程序很有用。

Set up your project according to the instructions in @ref:[Multi Node Testing](multi-node-testing.md) and @ref:[Multi JVM Testing](multi-jvm-testing.md), i.e.
add the `sbt-multi-jvm` plugin and the dependency to `akka-multi-node-testkit`.

根据 @ref:[多节点测试](multi-node-testing.md) 和 @ref:[多JVM测试](multi-jvm-testing.md) 中的说明设置项目，
既将`sbt-multi-jvm`插件和依赖项添加到`akka-multi-node-testkit`。

First, as described in @ref:[Multi Node Testing](multi-node-testing.md), we need some scaffolding to configure the `MultiNodeSpec`.
Define the participating roles and their [configuration](#cluster-configuration) in an object extending `MultiNodeConfig`:

首先，如 @ref:[多节点测试](multi-node-testing.md) 中所述，我们需要一些脚手架来配置`MultiNodeSpec`。
在扩展了`MultiNodeConfig`的object中定义参与角色及其[配置](#cluster-configuration)。

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #MultiNodeConfig }

Define one concrete test class for each role/node. These will be instantiated on the different nodes (JVMs). They can be
implemented differently, but often they are the same and extend an abstract test class, as illustrated here.

为每个角色/节点定义一个具体的测试类。这些将在不同的节点（JVM）上实例化。它们可以以不同的方式实现，
但通常它们是相同的并扩展相同的抽象测试类，如此处所示。

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #concrete-tests }

Note the naming convention of these classes. The name of the classes must end with `MultiJvmNode1`, `MultiJvmNode2`
and so on. It is possible to define another suffix to be used by the `sbt-multi-jvm`, but the default should be
fine in most cases.

请注意这些类的命名约定。类的名称必须以`MultiJvmNode1`，`MultiJvmNode2`等结尾。
可以定义`sbt-multi-jvm`使用另一种后缀，但在大多数情况下默认值是没问题的。

Then the abstract `MultiNodeSpec`, which takes the `MultiNodeConfig` as constructor parameter.

然后是抽象的`MultiNodeSpec`，它将`MultiNodeConfig`作为构造函数参数。

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #abstract-test }

Most of this can be extracted to a separate trait to avoid repeating this in all your tests.

其中大部分可以提取到一个独立的trait，以避免在所有测试（代码）中重复。

Typically you begin your test by starting up the cluster and let the members join, and create some actors.
That can be done like this:

通常，你可以通过启动集群让成员加入并创建一个actor来开始测试。这可以这样做：

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #startup-cluster }

From the test you interact with the cluster using the `Cluster` extension, e.g. `join`.

在测试中你可以通过`Cluster`扩展与集群进行交互，如：`join`。

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #join }

Notice how the *testActor* from @ref:[testkit](testing.md) is added as [subscriber](#cluster-subscriber)
to cluster changes and then waiting for certain events, such as in this case all members becoming 'Up'.

注意testkit的testActor如何作为订阅者添加到集群，然后等待某些更改事件，例如在这种情况下所有成员都变为“Up”。

The above code was running for all roles (JVMs). `runOn` is a convenient utility to declare that a certain block
of code should only run for a specific role.

上面的代码是针对所有角色（JVM）运行的。 `runOn`是一个方便的实用程序，用于声明某个代码块应仅针对特定角色运行。

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #test-statsService }

Once again we take advantage of the facilities in @ref:[testkit](testing.md) to verify expected behavior.
Here using `testActor` as sender (via `ImplicitSender`) and verifying the reply with `expectMsgPF`.

我们再次利用 @ref:[testkit](testing.md) 中的工具来验证预期的行为。这里使用`testActor`作为发送者（通过`ImplicitSender`）
并使用`expectMsgPF`来验证回复。

In the above code you can see `node(third)`, which is useful facility to get the root actor reference of
the actor system for a specific role. This can also be used to grab the `akka.actor.Address` of that node.

在上面的代码中你能看到`node(third)`，这是从特定角色的actor系统中获取根actor引用的有用工具。
这也可用于获取该节点的`akka.actor.Address`

@@snip [StatsSampleSpec.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsSampleSpec.scala) { #addresses }

@@@

@@@ div { .group-java }

## How to Test

Currently testing with the `sbt-multi-jvm` plugin is only documented for Scala.
Go to the corresponding Scala version of this page for details.

@@@

## Management

## 管理

<a id="cluster-http"></a>
### HTTP

Information and management of the cluster is available with a HTTP API.
See documentation of [Akka Management](http://developer.lightbend.com/docs/akka-management/current/).

HTTP API提供了集群的信息和管理功能。请参阅[Akka管理](http://developer.lightbend.com/docs/akka-management/current/)的文档。

<a id="cluster-jmx"></a>
### JMX

Information and management of the cluster is available as JMX MBeans with the root name `akka.Cluster`.
The JMX information can be displayed with an ordinary JMX console such as JConsole or JVisualVM.

集群的信息和管理功能通过JMX MBeans的形式提供，其根名称为`akka.Cluster`。JMX信息可以使用常用的JMX控制台显示，
如JConsole或JVisualVM。

From JMX you can:

从JMX中你可以：

 * see what members that are part of the cluster
 * see status of this node
 * see roles of each member
 * join this node to another node in cluster
 * mark any node in the cluster as down
 * tell any node in the cluster to leave

 * 查看属于集群的成员
 * 查看此节点状态
 * 查看每个成员的角色
 * 将此节点通过另一个节点加入集群
 * 标记集群内任何节点为down
 * 告诉集群内任何节（开始）leave

Member nodes are identified by their address, in format *akka.**protocol**://**actor-system-name**@**hostname**:**port***.

成员节点由它的地址标识，格式为 *akka.<protocol>:://<actor-system-name>@<hostname>:<port>*。

<a id="cluster-command-line"></a>
### Command Line

@@@ warning

**Deprecation warning** - The command line script has been deprecated and is scheduled for removal
in the next major version. Use the [HTTP management](#cluster-http) API with [curl](https://curl.haxx.se/)
or similar instead.

**弃用警告** - 此命令行脚本已弃用并计划在下一个主要版本中删除。可以通过[HTTP管理](#cluster-http) API使用
[curl](https://curl.haxx.se/)或类似功能代替。

@@@

The cluster can be managed with the script `akka-cluster` provided in the Akka GitHub repository @extref[here](github:akka-cluster/jmx-client). Place the script and the `jmxsh-R5.jar` library in the same directory.

可以使用Akka GitHub存储库中 @extref[here](github:akka-cluster/jmx-client) 提供的脚本`akka-cluster`来管理集群。
将脚本和`jmxsh-R5.jar`库放在同一目录中。

Run it without parameters to see instructions about how to use the script:

通过不带参数运行可查看有关如何使用的说明：

```
Usage: ./akka-cluster <node-hostname> <jmx-port> <command> ...

Supported commands are:
           join <node-url> - Sends request a JOIN node with the specified URL
          leave <node-url> - Sends a request for node with URL to LEAVE the cluster
           down <node-url> - Sends a request for marking node with URL as DOWN
             member-status - Asks the member node for its current status
                   members - Asks the cluster for addresses of current members
               unreachable - Asks the cluster for addresses of unreachable members
            cluster-status - Asks the cluster for its current status (member ring,
                             unavailable nodes, meta data etc.)
                    leader - Asks the cluster who the current leader is
              is-singleton - Checks if the cluster is a singleton cluster (single
                             node cluster)
              is-available - Checks if the member node is available
Where the <node-url> should be on the format of
  'akka.<protocol>://<actor-system-name>@<hostname>:<port>'

Examples: ./akka-cluster localhost 9999 is-available
          ./akka-cluster localhost 9999 join akka://MySystem@darkstar:2552
          ./akka-cluster localhost 9999 cluster-status
```

To be able to use the script you must enable remote monitoring and management when starting the JVMs of the cluster nodes,
as described in [Monitoring and Management Using JMX Technology](http://docs.oracle.com/javase/8/docs/technotes/guides/management/agent.html).
Make sure you understand the security implications of enabling remote monitoring and management.

为了能够使用该脚本，必须在启动集群节点的JVM时启用远程监视和管理，如使用JMX技术进行监视和管理中所述。
确保你了解启用远程监视和管理的安全隐患。

<a id="cluster-configuration"></a>
## Configuration

## 配置

There are several configuration properties for the cluster. We refer to the
@ref:[reference configuration](general/configuration.md#config-akka-cluster) for more information.

集群有些配置属性。我们参考 @ref:[配置参考](general/configuration.md#config-akka-cluster) 以获取更多信息。

### Cluster Info Logging

### 集群日志信息

You can silence the logging of cluster events at info level with configuration property:

你可以使用配置属性在关闭info级别的集群事件日志。

```
akka.cluster.log-info = off
```

You can enable verbose logging of cluster events at info level, e.g. for temporary troubleshooting, with configuration property:

你可以启用详细的info级别的集群事件日志。例如：用于临时故障排除，使用的配置属性如下：

```
akka.cluster.log-info-verbose = on
```

<a id="cluster-dispatcher"></a>
### Cluster Dispatcher

### 集群调度器

Under the hood the cluster extension is implemented with actors. To protect them against
disturbance from user actors they are by default run on the internal dispatcher configured
under `akka.actor.internal-dispatcher`. The cluster actors can potentially be isolated even
further onto their own dispatcher using the setting `akka.cluster.use-dispatcher`.

在幕后，集群扩展是由actor实现的，可能需要为这些actor创建一个隔板，以避免来自其他actor的干扰。
特别是用于故障检测的心跳actor如果没有机会定期运行，就会产生误报。为此，你可以给集群actor定义一个单独的dispatcher：

### Configuration Compatibility Check

### 配置兼容性查检

Creating a cluster is about deploying two or more nodes and make then behave as if they were one single application. Therefore it's extremely important that all nodes in a cluster are configured with compatible settings. 

创建集群是关于部署两个或更多节点，然后使其表现得就好像它们是一个单独的应用程序一样。因此，集群中的所有节点都配置了兼容设置，
这一点非常重要。

The Configuration Compatibility Check feature ensures that all nodes in a cluster have a compatible configuration. Whenever a new node is joining an existing cluster, a subset of its configuration settings (only those that are required to be checked) is sent to the nodes in the cluster for verification. Once the configuration is checked on the cluster side, the cluster sends back its own set of required configuration settings. The joining node will then verify if it's compliant with the cluster configuration. The joining node will only proceed if all checks pass, on both sides.   

配置兼容性检查功能可确保集群中的所有节点都具有兼容的配置。每当新节点加入现有集群时，
其配置设置的子集（仅需要检查的那些）将发送到集群中的节点以进行验证。在集群端检查配置后，集群将发回其自己的一组所需配置设置。
然后，加入节点将验证它是否符合集群配置。只有在双方都通过所有检查时，才会继续加入节点。

New custom checkers can be added by extending `akka.cluster.JoinConfigCompatChecker` and including them in the configuration. Each checker must be associated with a unique key:

可以通过扩展`akka.cluster.JoinConfigCompatChecker`并将其包含在配置中来添加新的自定义检查器。每个检查器必须与唯一键关联：

```
akka.cluster.configuration-compatibility-check.checkers {
  my-custom-config = "com.company.MyCustomJoinConfigCompatChecker"
}
``` 

@@@ note

Configuration Compatibility Check is enabled by default, but can be disabled by setting `akka.cluster.configuration-compatibility-check.enforce-on-join = off`. This is specially useful when performing rolling updates. Obviously this should only be done if a complete cluster shutdown isn't an option. A cluster with nodes with different configuration settings may lead to data loss or data corruption. 

默认情况下启用配置兼容性检查，但可以通过设置`akka.cluster.configuration-compatibility-check.enforce-on-join = off`来禁用。
这在执行滚动更新时特别有用。显然，只有在无法选择完整的集群关闭时才能执行此操作。
具有不同配置设置的节点的集群可能会导致数据丢失或数据损坏。

This setting should only be disabled on the joining nodes. The checks are always performed on both sides, and warnings are logged. In case of incompatibilities, it is the responsibility of the joining node to decide if the process should be interrupted or not.  

只应在（新）加入节点上禁用此设置。始终在两侧执行检查，并记录警告。在不兼容的情况下，加入节点有责任决定是否应该中断该过程。

If you are performing a rolling update on cluster using Akka 2.5.9 or prior (thus, not supporting this feature), the checks will not be performed because the running cluster has no means to verify the configuration sent by the joining node, nor to send back its own configuration.  

如果使用Akka 2.5.9或之前的集群执行滚动更新（不支持此功能），则不会执行检查，因为正在运行的集群无法验证（新）加入节点发送的配置，
也无法验证发回自己的配置。

@@@ 
