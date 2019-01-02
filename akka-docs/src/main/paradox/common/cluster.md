# Cluster Specification

# 集群规范

@@@ note

This document describes the design concepts of Akka Cluster.

本文档描述了Akka集群的设计概念

@@@

## Intro

## 简介

Akka Cluster provides a fault-tolerant decentralized peer-to-peer based cluster
[membership](#membership) service with no single point of failure or single point of bottleneck.
It does this using [gossip](#gossip) protocols and an automatic [failure detector](#failure-detector).

Akka集群提供基于对等的分布式容错集群 [成员](#membership) 服务，没有单点故障或单点瓶颈。
它使用 [gossip](#gossip) 协议和自动 [故障检测](#failure-detector)来实现。

Akka cluster allows for building distributed applications, where one application or service spans multiple nodes
(in practice multiple `ActorSystem`s). See also the discussion in
@ref:[When and where to use Akka Cluster](../cluster-usage.md#when-and-where-to-use-akka-cluster).

Akka集群允许构建分布式应用程序，一个应用程序或服务跨越多个节点（实际上是多个`ActorSystem`）。可查看 [何时、何地使用Akka集群](../cluster-usage.md#when-and-where-to-use-akka-cluster) 中的讨论。

## Terms

## 条款

**node**
: A logical member of a cluster. There could be multiple nodes on a physical
machine. Defined by a *hostname:port:uid* tuple.

**节点**
: 集群中的一个逻辑成员。在一个物理机器上可以有多个节点。使用 **hostname:port:uid** 元组定义。

**cluster**
: A set of nodes joined together through the [membership](#membership) service.

**集群**
: 通过成员服务连接在一起的一组节点。

**leader**
: A single node in the cluster that acts as the leader. Managing cluster convergence
and membership state transitions.

**领导**
: 集群中充当领导者的单个节点。管理集群聚合和成员状态转换。

## Membership

## 成员

A cluster is made up of a set of member nodes. The identifier for each node is a
`hostname:port:uid` tuple. An Akka application can be distributed over a cluster with
each node hosting some part of the application. Cluster membership and the actors running
on that node of the application are decoupled. A node could be a member of a
cluster without hosting any actors. Joining a cluster is initiated
by issuing a `Join` command to one of the nodes in the cluster to join.

集群由一组成员节点组成。每个节点的标识符是`hostname:port:uid`元组。可以在集群上分布Akka应用程序，每个节点托管应用程序的某些部分。
集群成员资格和在应用程序的该节点上运行的actor被解耦。节点可以是集群的成员而无需托管任何actor。
通过向要加入的集群中的一个节点发出Join命令来启动加入集群。

The node identifier internally also contains a UID that uniquely identifies this
actor system instance at that `hostname:port`. Akka uses the UID to be able to
reliably trigger remote death watch. This means that the same actor system can never
join a cluster again once it's been removed from that cluster. To re-join an actor
system with the same `hostname:port` to a cluster you have to stop the actor system
and start a new one with the same `hostname:port` which will then receive a different
UID.

节点标识符内部还包含一个UID，该UID在该`hostname:port`处唯一标识此actor系统实例。Akka使用UID能够可靠地触发远程死亡监视。
这意味着同一个actor系统一旦从该集群中删除，就永远不会再次加入集群。要将具有相同`hostname:port`的actor系统重新连接到集群，
您必须停止actor系统并启动具有相同`hostname:port`的新系统，然后将收到不同的UID。

The cluster membership state is a specialized [CRDT](http://hal.upmc.fr/docs/00/55/55/88/PDF/techreport.pdf), which means that it has a monotonic
merge function. When concurrent changes occur on different nodes the updates can always be
merged and converge to the same end result.

集群成员资格状态是一个专用的 [CRDT](http://hal.upmc.fr/docs/00/55/55/88/PDF/techreport.pdf)，这意味着它具有单调合并功能。
当在不同节点上发生并发更改时，总会合并更新并收敛到相同的最终结果。

### Gossip

The cluster membership used in Akka is based on Amazon's [Dynamo](http://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf) system and
particularly the approach taken in Basho's' [Riak](http://basho.com/technology/architecture/) distributed database.
Cluster membership is communicated using a [Gossip Protocol](http://en.wikipedia.org/wiki/Gossip_protocol), where the current
state of the cluster is gossiped randomly through the cluster, with preference to
members that have not seen the latest version.

Akka集群成员使用Amazon的 [Dynamo](http://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf) 系统，
特别是 Basho's 的 [Riak](http://basho.com/technology/architecture/) 分布式数据库使用的方法。集群成员间使用 [Gossip](http://en.wikipedia.org/wiki/Gossip_protocol) 协议通信。
其中集群的当前状态通过集群随机的 gossiped，优先选择没有看到最新版本的成员。

#### Vector Clocks

#### 向量时钟

[Vector clocks](http://en.wikipedia.org/wiki/Vector_clock) are a type of data structure and algorithm for generating a partial
ordering of events in a distributed system and detecting causality violations.

[向量时钟](http://en.wikipedia.org/wiki/Vector_clock)是一种数据结构和算法，用于在分布式系统中生成事件的部分排序并检测因果关系违规情况。

We use vector clocks to reconcile and merge differences in cluster state
during gossiping. A vector clock is a set of (node, counter) pairs. Each update
to the cluster state has an accompanying update to the vector clock.

我们使用向量时钟来协调和合并闲聊期间集群状态的差异。向量时钟是一组（节点，计数器）对。对集群状态的每次更新都伴随着向量时钟的更新。

#### Gossip Convergence

#### Gossip收敛

Information about the cluster converges locally at a node at certain points in time.
This is when a node can prove that the cluster state he is observing has been observed
by all other nodes in the cluster. Convergence is implemented by passing a set of nodes
that have seen current state version during gossip. This information is referred to as the
seen set in the gossip overview. When all nodes are included in the seen set there is
convergence.

关于集群的信息在某些时间点在节点处本地收敛。这是一个节点可以证明集群中所有其他节点已经观察到他正在观察的集群状态。
通过传递一组在八卦期间看到当前状态版本的节点来实现融合。此信息称为八卦概述中的可见集。
当所有节点都包含在所看到的集合中时，存在收敛。

Gossip convergence cannot occur while any nodes are `unreachable`. The nodes need
to become `reachable` again, or moved to the `down` and `removed` states
(see the [Membership Lifecycle](#membership-lifecycle) section below). This only blocks the leader
from performing its cluster membership management and does not influence the application
running on top of the cluster. For example this means that during a network partition
it is not possible to add more nodes to the cluster. The nodes can join, but they
will not be moved to the `up` state until the partition has healed or the unreachable
nodes have been downed.

任何节点无法访问时都不会发生八卦收敛。节点需要再次可访问，或者移动到向下和删除状态（请参阅下面的[“成员生命周期”](#membership-lifecycle)部分）。
这仅阻止领导者执行其集群成员资格管理，并且不会影响在集群顶部运行的应用程序。例如，这意味着在网络分区期间无法向群集添加更多节点。
节点可以加入，但是在分区已经修复或者无法访问的节点被丢弃之前，它们不会被移动到up状态。

#### Failure Detector

#### 失败（故障）检测

The failure detector is responsible for trying to detect if a node is
`unreachable` from the rest of the cluster. For this we are using an
implementation of [The Phi Accrual Failure Detector](https://pdfs.semanticscholar.org/11ae/4c0c0d0c36dc177c1fff5eb84fa49aa3e1a8.pdf) by Hayashibara et al.

故障检测器尝试检测节点是否与集群的其它部分`unreachable`（无法访问）。为此我们现在使用Hayashibara等人的[The Phi Accrual Failure Detector](https://pdfs.semanticscholar.org/11ae/4c0c0d0c36dc177c1fff5eb84fa49aa3e1a8.pdf)来实现。

An accrual failure detector decouples monitoring and interpretation. That makes
them applicable to a wider area of scenarios and more adequate to build generic
failure detection services. The idea is that it is keeping a history of failure
statistics, calculated from heartbeats received from other nodes, and is
trying to do educated guesses by taking multiple factors, and how they
accumulate over time, into account in order to come up with a better guess if a
specific node is up or down. Rather than only answering "yes" or "no" to the
question "is the node down?" it returns a `phi` value representing the
likelihood that the node is down.

应计故障检测器将监测和解释分离。 这使它们适用于更广泛的场景，更适合构建通用的故障检测服务。
这个想法是它保留了从其他节点收到的心跳计算的失败统计数据的历史，
并试图通过考虑多个因素以及它们如何随着时间的推移积累的方式进行有根据的猜测，以便提出更好的结果。
猜测特定节点是上升还是下降。 而不只是对问题回答“是”或“否”，“节点是否已关闭？”
它返回一个`phi`值，表示节点关闭的可能性。

The `threshold` that is the basis for the calculation is configurable by the
user. A low `threshold` is prone to generate many wrong suspicions but ensures
a quick detection in the event of a real crash. Conversely, a high `threshold`
generates fewer mistakes but needs more time to detect actual crashes. The
default `threshold` is 8 and is appropriate for most situations. However in
cloud environments, such as Amazon EC2, the value could be increased to 12 in
order to account for network issues that sometimes occur on such platforms.

作为计算基础的“阈值”可由用户配置。 低“阈值”容易产生许多可疑的错误，但确保在真正崩溃的情况下快速检测。
相反，高“阈值”会产生更少的错误，但需要更多时间来检测实际崩溃。 默认的“threshold”为8，适用于大多数情况。
但是，在Amazon EC2等云环境中，可以将值增加到12，以便解决有时在此类平台上出现的网络问题。

In a cluster each node is monitored by a few (default maximum 5) other nodes, and when
any of these detects the node as `unreachable` that information will spread to
the rest of the cluster through the gossip. In other words, only one node needs to
mark a node `unreachable` to have the rest of the cluster mark that node `unreachable`.

在一个集群中，每个节点由少数（默认最多5个）其他节点监控，当其中任何节点检测到该节点为“无法访问”时，
该信息将通过八卦传播到集群的其余部分。 换句话说，只有一个节点需要标记一个节点“无法访问”，
以使该节点的其余部分标记该节点“无法访问”*（只需要由一个节点来标记某一个节点的状态为“无法访问”，刚其它所有节点都可知道此节点“无法访问”）*。

The nodes to monitor are picked out of neighbors in a hashed ordered node ring.
This is to increase the likelihood to monitor across racks and data centers, but the order
is the same on all nodes, which ensures full coverage.

要监视的节点是从有序的散列节点环中的邻居中挑选出来的。
这是为了增加在机架和数据中心之间进行监控的可能性，但所有节点上的顺序相同，这可确保完全覆盖。

Heartbeats are sent out every second and every heartbeat is performed in a request/reply
handshake with the replies used as input to the failure detector.

心跳每秒发送一次，每次心跳都在请求/回复握手中执行，回复用作故障检测器的输入。

The failure detector will also detect if the node becomes `reachable` again. When
all nodes that monitored the `unreachable` node detects it as `reachable` again
the cluster, after gossip dissemination, will consider it as `reachable`.

故障检测器还将检测节点是否再次变得“可达”。当所有在监视“不可达”状态节点的节点再次检测到它“可达”，
集群在gossip传播后将视其为“可达”*（其它节点都认为它已变为“可达”）*。

If system messages cannot be delivered to a node it will be quarantined and then it
cannot come back from `unreachable`. This can happen if the there are too many
unacknowledged system messages (e.g. watch, Terminated, remote actor deployment,
failures of actors supervised by remote parent). Then the node needs to be moved
to the `down` or `removed` states (see the [Membership Lifecycle](#membership-lifecycle) section below)
and the actor system must be restarted before it can join the cluster again.

如果系统消息不能被传递到一个节点，则它 *（此节点）* 将被隔离，然后它无法从“不可访问”返回 *（变回“可访问”）*。
如何存在太多未确认的系统消息（例如：watch，Terminated，远程actor部署，由父actor监督的actor的失败消息），就会发生上述情况。
然后需要将节点移动到`down`或`removed`状态（见：[成员生命周期](#membership-lifecycle)一节），并且必需重新启动actor系统才能再次入加集群。

#### Leader

#### 领导者

After gossip convergence a `leader` for the cluster can be determined. There is no
`leader` election process, the `leader` can always be recognised deterministically
by any node whenever there is gossip convergence. The leader is only a role, any node
can be the leader and it can change between convergence rounds.
The `leader` is the first node in sorted order that is able to take the leadership role,
where the preferred member states for a `leader` are `up` and `leaving`
(see the [Membership Lifecycle](#membership-lifecycle) section below for more  information about member states).

在gossip收敛之后，可以确定集群的领导者。没有`leader`选举过程，只要gossip融合 *（convergence）*，任何节点都可以确定地识别领导者。
领导者只是一个角色，任何节点都可以成为领导者，它可以在融合轮次之间变换。领导者是排序顺序中的第一个能够担任领导角色的节点，
其中领导者的首选成员处于`up`和`leaving`状态（见[成员生命周期](#membership-lifecycle)一节参阅成员状态的更多信息）。

The role of the `leader` is to shift members in and out of the cluster, changing
`joining` members to the `up` state or `exiting` members to the `removed`
state. Currently `leader` actions are only triggered by receiving a new cluster
state with gossip convergence.

`leader`的角色是将成员移入或移出集群，将成员状态从`joining`更改为`up`或者将`exiting`更改为`removed`。
当前，`leader`的动作仅通过收到具有gossip收敛的新集群的状态来触发。

The `leader` also has the power, if configured so, to "auto-down" a node that
according to the [Failure Detector](#failure-detector) is considered `unreachable`. This means setting
the `unreachable` node status to `down` automatically after a configured time
of unreachability.

如果配置了“自动关闭”我，`leader`还具有可根据[故障检测](#failure-detector)将`unreachable`的节点自动关闭的功能。
这意味着，在配置的`unreachable`时间后自动将不可达节点状态设置为`down`。

#### Seed Nodes

#### 种子节点

The seed nodes are configured contact points for new nodes joining the cluster.
When a new node is started it sends a message to all seed nodes and then sends
a join command to the seed node that answers first.

种子节点是为新加入集群的节点配置的联系点。当新节点被启动，它将向所有种子节点发送消息，然后join命令将发送到第一个回答的节点。

The seed nodes configuration value does not have any influence on the running
cluster itself, it is only relevant for new nodes joining the cluster as it
helps them to find contact points to send the join command to; a new member
can send this command to any current member of the cluster, not only to the seed nodes.

种子节点的配置对正在运行的集群本身没有任何影响，它仅与加入集群的新节点相关，因为它有助于找到可接收join命令的联系点；
新成员可以将此命令发送到集群的任何成员，而不仅仅是种子节点列出的这些。

#### Gossip Protocol

#### Gossip协议

A variation of *push-pull gossip* is used to reduce the amount of gossip
information sent around the cluster. In push-pull gossip a digest is sent
representing current versions but not actual values; the recipient of the gossip
can then send back any values for which it has newer versions and also request
values for which it has outdated versions. Akka uses a single shared state with
a vector clock for versioning, so the variant of push-pull gossip used in Akka
makes use of this version to only push the actual state as needed.

Periodically, the default is every 1 second, each node chooses another random
node to initiate a round of gossip with. If less than ½ of the nodes resides in the
seen set (have seen the new state) then the cluster gossips 3 times instead of once
every second. This adjusted gossip interval is a way to speed up the convergence process
in the early dissemination phase after a state change.

The choice of node to gossip with is random but biased towards nodes that might not have seen
the current state version. During each round of gossip exchange, when convergence is not yet reached, a node
uses a very high probability (which is configurable) to gossip with another node which is not part of the seen set, i.e. 
which is likely to have an older version of the state. Otherwise it gossips with any random live node.

This biased selection is a way to speed up the convergence process in the late dissemination
phase after a state change.

For clusters larger than 400 nodes (configurable, and suggested by empirical evidence)
the 0.8 probability is gradually reduced to avoid overwhelming single stragglers with
too many concurrent gossip requests. The gossip receiver also has a mechanism to
protect itself from too many simultaneous gossip messages by dropping messages that
have been enqueued in the mailbox for too long of a time.

While the cluster is in a converged state the gossiper only sends a small gossip status message containing the gossip
version to the chosen node. As soon as there is a change to the cluster (meaning non-convergence)
then it goes back to biased gossip again.

The recipient of the gossip state or the gossip status can use the gossip version
(vector clock) to determine whether:

 1. it has a newer version of the gossip state, in which case it sends that back
to the gossiper
 2. it has an outdated version of the state, in which case the recipient requests
the current state from the gossiper by sending back its version of the gossip state
 3. it has conflicting gossip versions, in which case the different versions are merged
and sent back

If the recipient and the gossip have the same version then the gossip state is
not sent or requested.

The periodic nature of the gossip has a nice batching effect of state changes,
e.g. joining several nodes quickly after each other to one node will result in only
one state change to be spread to other members in the cluster.

The gossip messages are serialized with [protobuf](https://code.google.com/p/protobuf/) and also gzipped to reduce payload
size.

### Membership Lifecycle

### 成员生命周期

A node begins in the `joining` state. Once all nodes have seen that the new
node is joining (through gossip convergence) the `leader` will set the member
state to `up`.

节点从`joining`状态开始。一旦所有节点都看见这个新节点加入（通过gossip收敛），则`leader`将设置其成员状态为`up`。

If a node is leaving the cluster in a safe, expected manner then it switches to
the `leaving` state. Once the leader sees the convergence on the node in the
`leaving` state, the leader will then move it to `exiting`.  Once all nodes
have seen the exiting state (convergence) the `leader` will remove the node
from the cluster, marking it as `removed`.

如果节点安全的离开节点，期待以预期的方式离开集群，则它将切换到`leaving`状态。一个领导者在离开状态下看到节点上的收敛，
领导者就会将期移动到`exiting`状态。一旦所有节点都看到exiting状态，则`leader`将从集群中移除该节点，并将其标记为`removed`。

If a node is `unreachable` then gossip convergence is not possible and therefore
any `leader` actions are also not possible (for instance, allowing a node to
become a part of the cluster). To be able to move forward the state of the
`unreachable` nodes must be changed. It must become `reachable` again or marked
as `down`. If the node is to join the cluster again the actor system must be
restarted and go through the joining process again. The cluster can, through the
leader, also *auto-down* a node after a configured time of unreachability. If new
incarnation of unreachable node tries to rejoin the cluster old incarnation will be 
marked as `down` and new incarnation can rejoin the cluster without manual intervention. 

如果节点不可达，则无法进行八卦收敛，因此任何领导者操作也是不可能的（例如，允许节点成为群集的一部分）。
为了能够继续前进，必须更改不可达节点的状态。它必须再次可以访问或标记为关闭。如果节点要再次加入集群，
则必须重新启动actor系统并再次完成加入过程。通过引导程序，群集还可以在配置的不可达时间后自动关闭节点。
如果无法到达的节点的新化身尝试重新加入群集，则旧的化身将被标记为关闭，新的化身可以重新加入群集而无需人工干预。

@@@ note

If you have *auto-down* enabled and the failure detector triggers, you
can over time end up with a lot of single node clusters if you don't put
measures in place to shut down nodes that have become `unreachable`. This
follows from the fact that the `unreachable` node will likely see the rest of
the cluster as `unreachable`, become its own leader and form its own cluster.

如果你启用了 *auto-down*并且故障检测器被触发，那么如果你没有采取措施来关闭已成为`unreachable`的节点，
则可能随着时间的推移将形成大量单节点的集群。这是因为`unreachable`节点可能会将集群的其余部分视为`unreachable`，
自己成为领导者并形成自己的集群。

@@@

As mentioned before, if a node is `unreachable` then gossip convergence is not
possible and therefore any `leader` actions are also not possible. By enabling
`akka.cluster.allow-weakly-up-members` (enabled by default) it is possible to 
let new joining nodes be promoted while convergence is not yet reached. These 
`Joining` nodes will be promoted as `WeaklyUp`. Once gossip convergence is 
reached, the leader will move `WeaklyUp` members to `Up`.

如前所述，如果节点`unreachable`，则无法进行gossip收敛，因此任何领导者操作也是不可能的。
通过启用`akka.cluster.allow-weakly-up-members`（默认启用），可以在尚未达到收敛的情况下提升新的加入节点。
这些连接节点将被提升为`WeaklyUp`。一旦达到八卦收敛，领导者将把`WeaklyUp`成员移动到`Up`。

Note that members on the other side of a network partition have no knowledge about 
the existence of the new members. You should for example not count `WeaklyUp` 
members in quorum decisions.

请注意，网络分区另一端的成员不了解新成员的存在。例如，您应该在仲裁决策中不计算`WeaklyUp`成员。

#### State Diagram for the Member States (`akka.cluster.allow-weakly-up-members=off`)

#### 成员状态的状态图 (`akka.cluster.allow-weakly-up-members=off`)

![member-states.png](../images/member-states.png)

#### State Diagram for the Member States (`akka.cluster.allow-weakly-up-members=on`)

#### 成员状态的状态图 (`akka.cluster.allow-weakly-up-members=on`)

![member-states-weakly-up.png](../images/member-states-weakly-up.png)

#### Member States

#### 成员状态

 * **joining** - transient state when joining a cluster
 * **joining** - 加入集群的瞬时状态

 * **weakly up** - transient state while network split (only if `akka.cluster.allow-weakly-up-members=on`)
 * **weakly up** - 网络分裂时的瞬时状态（`akka.cluster.allow-weakly-up-members=on`）

 * **up** - normal operating state
 * **up** - 正常运行状态

 * **leaving** / **exiting** - states during graceful removal
 * **leaving** / **exiting** - 优雅移除期间的状态

 * **down** - marked as down (no longer part of cluster decisions)
 * **down** - 标记为down（不再是集群决策的一部分）

 * **removed** - tombstone state (no longer a member)
 * **removed** - 墓碑状态（不再是成员）

#### User Actions

#### 用户动作

 * **join** - join a single node to a cluster - can be explicit or automatic on
startup if a node to join have been specified in the configuration
 * **join** - 将单个节点加入集群 - 可以显示或自动加入节点，如果已在配置文件中指定要加入的节点。

 * **leave** - tell a node to leave the cluster gracefully
 * **leave** - 告诉节点优雅的离开集群

 * **down** - mark a node as down
 * **down** - 标记标点为down

#### Leader Actions

#### 操作者动作

The `leader` has the following duties:

`leader`有以下：

 * shifting members in and out of the cluster
    * joining -> up
    * weakly up -> up *(no convergence is required for this leader action to be performed)*
    * exiting -> removed

 * 将成员转入和转出集群
   * joining -> up
   * weakly up -> up *（领导者动作无需收敛）*
   * exiting -> removed

#### Failure Detection and Unreachability

#### 故障检测和不可达

 * **fd*** - the failure detector of one of the monitoring nodes has triggered
causing the monitored node to be marked as unreachable
 * **fd*** - 其中一个监控点的故障检测器已触发，导致被监控节点标记为不可达。
   
 * **unreachable*** - unreachable is not a real member states but more of a flag in addition to the state signaling that the cluster is unable to talk to this node, after being unreachable the failure detector may detect it as reachable again and thereby remove the flag
 * **unreachable*** - 无法访问（unreachable）不是真正的成员状态，但更多的是一个标志，除了状态信号表明集群无法与该节点通信，在无法访问后故障检测器可再次检测到它是否可达，从而删除此标志。
