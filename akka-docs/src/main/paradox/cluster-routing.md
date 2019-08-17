# Classic Cluster Aware Routers

@@@ note

Akka Classic is the original Actor APIs, which have been improved by more type safe and guided Actor APIs, 
known as Akka Typed. Akka Classic is still fully supported and existing applications can continue to use 
the classic APIs. It is also possible to use Akka Typed together with classic actors within the same 
ActorSystem, see @ref[coexistence](typed/coexisting.md). For new projects we recommend using the new Actor APIs.

For the new API see @ref[routers](typed/routers.md).

@@@

# 集群感知路由器

# 集群感知路由器

All @ref:[routers](routing.md) can be made aware of member nodes in the cluster, i.e.
deploying new routees or looking up routees on nodes in the cluster.
When a node becomes unreachable or leaves the cluster the routees of that node are
automatically unregistered from the router. When new nodes join the cluster, additional
routees are added to the router, according to the configuration. Routees are also added
when a node becomes reachable again, after having been unreachable.

所有 @ref:[路由器](routing.md) 知道集群中的成员节点，即在集群中的节点上部署新路由或查找路由。当节点无法访问或离开集群时，
该节点的路由将自动从路由器中注销。当新节点加入集群，根据配置将期路由加入路由器。当节点从无法访问后再次变为可访问时，
也会添加路由。

Cluster aware routers make use of members with status [WeaklyUp](#weakly-up) if that feature
is enabled.

如果 [WeaklyUp](#weakly-up) 特性已启用，则集群感知路由器也可使用这个状态的成员。

There are two distinct types of routers.

有两种不同类型的路由器。

 * **Group - router that sends messages to the specified path using actor selection**
The routees can be shared among routers running on different nodes in the cluster.
One example of a use case for this type of router is a service running on some backend
nodes in the cluster and used by routers running on front-end nodes in the cluster.
 * **Pool - router that creates routees as child actors and deploys them on remote nodes.**
Each router will have its own routee instances. For example, if you start a router
on 3 nodes in a 10-node cluster, you will have 30 routees in total if the router is
configured to use one instance per node. The routees created by the different routers
will not be shared among the routers. One example of a use case for this type of router
is a single master that coordinates jobs and delegates the actual work to routees running
on other nodes in the cluster.

 * **Group - 使用actor selection将消息发送给指定路径的路由器**，这些路由可以在集群中的不同节点上运行、共享。
此类路由器的用例的一个示例是在群集中的某些后端节点上运行的服务，并由在群集中的前端节点上运行的路由器使用。
 * **Pool - 路由器将创建路由作为子节点，并在远程节点上部署它们**。每个路由器都有自己的routee实例。例如，
如果在10个节点的集群中，每个路由器在3个节点上启动，则如果路由器配置为每个节点使用一个实例，则总共将有30个路由（routee）。
不同路由器创建的路由不会在路由器之间共享。这种类型的路由器的用例的一个示例是单个主机，
其协调作业并将实际工作委托给在集群中的其他节点上运行的路由。

## Dependency

To use Cluster aware routers, you must add the following dependency in your project:

要使用集群感知路由器，你必须在你的项目中添加以下依赖项：

@@dependency[sbt,Maven,Gradle] {
  group="com.typesafe.akka"
  artifact="akka-cluster_$scala.binary_version$"
  version="$akka.version$"
}

## Router with Group of Routees

## 路由器与路由组

When using a `Group` you must start the routee actors on the cluster member nodes.
That is not done by the router. The configuration for a group looks like this::

使用`Group`时，你必须在集群成员节点上（先）启动routee actor，路由器不会启动它管理的routee。组的配置如下所示：

```
akka.actor.deployment {
  /statsService/workerRouter {
      router = consistent-hashing-group
      routees.paths = ["/user/statsWorker"]
      cluster {
        enabled = on
        allow-local-routees = on
        use-roles = ["compute"]
      }
    }
}
```

@@@ note

The routee actors should be started as early as possible when starting the actor system, because
the router will try to use them as soon as the member status is changed to 'Up'.

应在启动actor系统时尽量早的启动routee actor，因为路由器将在成员状态变为`Up`时使用它们。

@@@

The actor paths that are defined in `routees.paths` are used for selecting the
actors to which the messages will be forwarded to by the router. The path should not contain protocol and address information because they are retrieved dynamically from the cluster membership. 
Messages will be forwarded to the routees using @ref:[ActorSelection](actors.md#actorselection), so the same delivery semantics should be expected.
It is possible to limit the lookup of routees to member nodes tagged with a particular set of roles by specifying `use-roles`.

消息将被路由器转发给从`routees.paths`中定义的actor路径中被选中的actor。该路径不应该包含协议和地址信息，
因为它们是从集群成员中动态检索获得的。消息将被使用 @ref:[ActorSelection](actors.md#actorselection) 重定向到 routees，
因此应该期望使用相同的传递语义。通过指定`use-roles`可以将routees查找限制为标记有特定角色的成员节点。

`max-total-nr-of-instances` defines total number of routees in the cluster. By default `max-total-nr-of-instances`
is set to a high value (10000) that will result in new routees added to the router when nodes join the cluster.
Set it to a lower value if you want to limit total number of routees.

`max-total-nr-of-instances`定义了集群中路由总数（每个路由器）。`max-total-nr-of-instances`默认值为10000，
这将使节点加入集群时新的路由被添加到路由器。如果要限制路由总数，请将其设置为较低的值。

The same type of router could also have been defined in code:

也可以在代码中定义相似类型的路由器：

Scala
:  @@snip [StatsService.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsService.scala) { #router-lookup-in-code }

Java
:  @@snip [StatsService.java](/akka-docs/src/test/java/jdocs/cluster/StatsService.java) { #router-lookup-in-code }

See @ref:[reference configuration](general/configuration.md#config-akka-cluster) for further descriptions of the settings.

有关设置的进一步说明，请参阅 @ref:[参考配置](general/configuration.md#config-akka-cluster)。

### Router Example with Group of Routees

### 具有路由组的路由器示例

Let's take a look at how to use a cluster aware router with a group of routees,
i.e. router sending to the paths of the routees.

让我们来看看如何使用一组routee的集群感知路由器，路由器（将消息）发送到routee路径（代表的actor）

The example application provides a service to calculate statistics for a text.
When some text is sent to the service it splits it into words, and delegates the task
to count number of characters in each word to a separate worker, a routee of a router.
The character count for each word is sent back to an aggregator that calculates
the average number of characters per word when all results have been collected.

这个示例提供计算文本统计信息的服务。当一些文本被发送到服务时，它将其拆分为单词，
并由路由器将每个词的字符计数任务委托给单独的工作者routee。每个单词的字符计数将被发送回聚合器，
由该聚合器收集所有结果后计算出单词的平均字符数。

Messages:

消息：

Scala
:  @@snip [StatsMessages.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsMessages.scala) { #messages }

Java
:  @@snip [StatsMessages.java](/akka-docs/src/test/java/jdocs/cluster/StatsMessages.java) { #messages }

The worker that counts number of characters in each word:

计算每个单词中字符个数的工作者：

Scala
:  @@snip [StatsWorker.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsWorker.scala) { #worker }

Java
:  @@snip [StatsWorker.java](/akka-docs/src/test/java/jdocs/cluster/StatsWorker.java) { #worker }

The service that receives text from users and splits it up into words, delegates to workers and aggregates:

从用户处接收文本并拆分为单词，委托给worker和聚合结果的服务：

@@@ div { .group-scala }

@@snip [StatsService.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsService.scala) { #service }

@@@

@@@ div { .group-java }

@@snip [StatsService.java](/akka-docs/src/test/java/jdocs/cluster/StatsService.java) { #service }
@@snip [StatsAggregator.java](/akka-docs/src/test/java/jdocs/cluster/StatsAggregator.java) { #aggregator }

@@@

Note, nothing cluster specific so far, just plain actors.

注意，目前为止并没有指定集群，只是普通的actor。

All nodes start `StatsService` and `StatsWorker` actors. Remember, routees are the workers in this case.
The router is configured with `routees.paths`::

在所有节点上启动`StatsService`和`StatsWorker` actor。记住，在这种情况下routee（路由）是worker。
由路由器通过`routees.paths`配置：

```
akka.actor.deployment {
  /statsService/workerRouter {
    router = consistent-hashing-group
    routees.paths = ["/user/statsWorker"]
    cluster {
      enabled = on
      allow-local-routees = on
      use-roles = ["compute"]
    }
  }
}
```

This means that user requests can be sent to `StatsService` on any node and it will use
`StatsWorker` on all nodes.

这意味着可以将用户请求发送到任何节点上的`StatsService`，并且它（`StatsService`）将使用所有节点上的`StatsWorker`。

The easiest way to run **Router Example with Group of Routees** example yourself is to try the
@scala[@extref[Akka Cluster Sample with Scala](samples:akka-samples-cluster-scala)]@java[@extref[Akka Cluster Sample with Java](samples:akka-samples-cluster-java)].
It contains instructions on how to run the **Router Example with Group of Routees** sample.
 
## Router with Pool of Remote Deployed Routees

## 具有远程部署路由池的路由器

When using a `Pool` with routees created and deployed on the cluster member nodes
the configuration for a router looks like this::

使用在集群成员节点上创建并部署了路由的池时，路由器的配置如下所示：

```
akka.actor.deployment {
  /statsService/singleton/workerRouter {
      router = consistent-hashing-pool
      cluster {
        enabled = on
        max-nr-of-instances-per-node = 3
        allow-local-routees = on
        use-roles = ["compute"]
      }
    }
}
```

It is possible to limit the deployment of routees to member nodes tagged with a particular set of roles by
specifying `use-roles`.

通过指定`use-roles`，可以将路由部署限制为标记有特定角色的成员节点。

`max-total-nr-of-instances` defines total number of routees in the cluster, but the number of routees
per node, `max-nr-of-instances-per-node`, will not be exceeded. By default `max-total-nr-of-instances`
is set to a high value (10000) that will result in new routees added to the router when nodes join the cluster.
Set it to a lower value if you want to limit total number of routees.

`max-total-nr-of-instances`定义集群中的路由总数，但不会超过每个节点的路由数量`max-nr-of-instances-per-node`。
默认情况下，`max-total-nr-of-instances`设置为高值（10000），这将导致在节点加入群集时将新路由添加到路由器。
如果要限制路线总数，请将其设置为较低的值。

The same type of router could also have been defined in code:

也可以在代码中定义相同类型的路由器：

Scala
:  @@snip [StatsService.scala](/akka-cluster-metrics/src/multi-jvm/scala/akka/cluster/metrics/sample/StatsService.scala) { #router-deploy-in-code }

Java
:  @@snip [StatsService.java](/akka-docs/src/test/java/jdocs/cluster/StatsService.java) { #router-deploy-in-code }

See @ref:[reference configuration](general/configuration.md#config-akka-cluster) for further descriptions of the settings.

When using a pool of remote deployed routees you must ensure that all parameters of the `Props` can
be @ref:[serialized](serialization.md).

### Router Example with Pool of Remote Deployed Routees

### 具有远程部署路由池的路由器示例

Let's take a look at how to use a cluster aware router on single master node that creates
and deploys workers. To keep track of a single master we use the @ref:[Cluster Singleton](cluster-singleton.md)
in the cluster-tools module. The `ClusterSingletonManager` is started on each node:

我们来看看如何在创建和部署工作线程的单个主节点上使用群集感知路由器。为了跟踪单个主服务器，我们使用集群工具模块中的
@ref[集群单例](cluster-singleton.md)。`ClusterSingletonManager`在每个节点上启动：

Scala
:   @@@vars
    ```
    system.actorOf(
      ClusterSingletonManager.props(
        singletonProps = Props[StatsService],
        terminationMessage = PoisonPill,
        settings = ClusterSingletonManagerSettings(system).withRole("compute")),
      name = "statsService")
    ```
    @@@

Java
:  @@snip [StatsSampleOneMasterMain.java](/akka-docs/src/test/java/jdocs/cluster/StatsSampleOneMasterMain.java) { #create-singleton-manager }

We also need an actor on each node that keeps track of where current single master exists and
delegates jobs to the `StatsService`. That is provided by the `ClusterSingletonProxy`:

我们还需要每个节点上的一个actor来跟踪当前单个master存在的位置，并将作业委托给`StatsService`。
这是由`ClusterSingletonProxy`提供的：

Scala
:   @@@vars
    ```
    system.actorOf(
      ClusterSingletonProxy.props(
        singletonManagerPath = "/user/statsService",
        settings = ClusterSingletonProxySettings(system).withRole("compute")),
      name = "statsServiceProxy")
    ```
    @@@

Java
:  @@snip [StatsSampleOneMasterMain.java](/akka-docs/src/test/java/jdocs/cluster/StatsSampleOneMasterMain.java) { #singleton-proxy }

The `ClusterSingletonProxy` receives text from users and delegates to the current `StatsService`, the single
master. It listens to cluster events to lookup the `StatsService` on the oldest node.

`ClusterSingletonProxy`从用户处接收文本并委托给当前`StatsService`（单个主服务器。
它侦听集群事件以在最旧的节点上查找`StatsService`。

All nodes start `ClusterSingletonProxy` and the `ClusterSingletonManager`. The router is now configured like this::

所有节点都启动`ClusterSingletonProxy`和`ClusterSingletonManager`。路由器现在配置如下：

```
akka.actor.deployment {
  /statsService/singleton/workerRouter {
    router = consistent-hashing-pool
    cluster {
      enabled = on
      max-nr-of-instances-per-node = 3
      allow-local-routees = on
      use-roles = ["compute"]
    }
  }
}
```
The easiest way to run **Router Example with Pool of Routees** example yourself is to try the
@scala[@extref[Akka Cluster Sample with Scala](samples:akka-samples-cluster-scala)]@java[@extref[Akka Cluster Sample with Java](samples:akka-samples-cluster-java)].
It contains instructions on how to run the **Router Example with Pool of Routees** sample.
