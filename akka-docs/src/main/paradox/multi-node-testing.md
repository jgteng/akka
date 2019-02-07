# Multi Node Testing
# 多节点测试

## Dependency
## 依赖

To use Multi Node Testing, you must add the following dependency in your project:

要使用多节点测试，你必需在项目中添加如下依赖项：

@@dependency[sbt,Maven,Gradle] {
  group=com.typesafe.akka
  artifact=akka-multi-node-testkit_$scala.binary_version$
  version=$akka.version$
}

## Sample project
## 示例项目

You can look at the
@extref[Multi Node example project](samples:akka-samples-multi-node-scala)
to see what this looks like in practice.

你可以查看 @extref[多节点示例项目](samples:akka-samples-multi-node)，以了解实际情况。

## Multi Node Testing Concepts
## 多节点测试概念

When we talk about multi node testing in Akka we mean the process of running coordinated tests on multiple actor
systems in different JVMs. The multi node testing kit consist of three main parts.

当我们在Akka中讨论多节点测试时，我们指的是在不同JVM中的多个actor系统上运行、协调测试的过程。
多节点测试套件包括三个主要部分。

 * [The Test Conductor](#the-test-conductor). that coordinates and controls the nodes under test.
 * [The Multi Node Spec](#the-multi-node-spec). that is a convenience wrapper for starting the `TestConductor` and letting all
nodes connect to it.
 * [The SbtMultiJvm Plugin](#the-sbtmultijvm-plugin). that starts tests in multiple JVMs possibly on multiple machines.

 * [测试指挥者（TestConductor）](#the-test-conductor)。协调和控制被测节点。
 * [多节点Spec](#the-multi-node-spec)。这是一个方便的包装（wrapper），用于启动`TestConductor`并让所有节点连接到它。
 * [The SbtMultiJvm Plugin](#the-sbtmultijvm-plugin)。可以在多台机器上启动多个JVM测试。

## The Test Conductor
## 测试指挥者

The basis for the multi node testing is the `TestConductor`. It is an Akka Extension that plugs in to the
network stack and it is used to coordinate the nodes participating in the test and provides several features
including:

多节点测试的基础是`TestConductor`。这是一个插入网络堆栈的Akka扩展，用于协调参与测试的节点，并提供以下几个功能：

 * Node Address Lookup: Finding out the full path to another test node (No need to share configuration between
test nodes)
 * Node Barrier Coordination: Waiting for other nodes at named barriers.
 * Network Failure Injection: Throttling traffic, dropping packets, unplugging and plugging nodes back in.

 * 节点地址查找：找出另一个测试节点的完整路径（无需在测试节点之间共享配置）。
 * 节点屏障（barrier）协调：在命名屏障处等待其它节点。
 * 网络故障注入：流量限制、丢包、拔出和插入节点。

This is a schematic overview of the test conductor.

这是测试指挥者的示意图。

![akka-remote-testconductor.png](./images/akka-remote-testconductor.png)

The test conductor server is responsible for coordinating barriers and sending commands to the test conductor
clients that act upon them, e.g. throttling network traffic to/from another client. More information on the
possible operations is available in the `akka.remote.testconductor.Conductor` API documentation.

测试指挥服务器负责协调屏障（barrier）并向作用于它们的测试指挥客户端发送命令，例如，限制进出其他客户端的网络流量。
有关可有操作的更多信息，请参见`akka.remote.testconductor.Conductor`的API文档。

## The Multi Node Spec
## 多节点Spec

The Multi Node Spec consists of two parts. The `MultiNodeConfig` that is responsible for common
configuration and enumerating and naming the nodes under test. The `MultiNodeSpec` that contains a number
of convenience functions for making the test nodes interact with each other. More information on the possible
operations is available in the `akka.remote.testkit.MultiNodeSpec` API documentation.

多节点Spec由两部分组成。`MultiNodeConfig`，负责通用配置，枚举和命名被测节点。`MultiNodeSpec`包含许多方便函数，
用于使测试节点相互交互。有关可用操作的更多信息，请参见`akka.remote.testkit.MultiNodeSpec`的API文档。

The setup of the `MultiNodeSpec` is configured through java system properties that you set on all JVMs that's going to run a
node under test. These can be set on the JVM command line with `-Dproperty=value`.

`MultiNodeSpec`的设置是通过你在将要运行被测节点的所有JVM上设置的java系统属性配置的。
可以使用`-Dproperty=value`在JVM命令行上设置它们。

These are the available properties:
:
 *
   `multinode.max-nodes`
   The maximum number of nodes that a test can have.
 *
   `multinode.host`
   The host name or IP for this node. Must be resolvable using InetAddress.getByName.
 *
   `multinode.port`
   The port number for this node. Defaults to 0 which will use a random port.
 *
   `multinode.server-host`
   The host name or IP for the server node. Must be resolvable using InetAddress.getByName.
 *
   `multinode.server-port`
   The port number for the server node. Defaults to 4711.
 *
   `multinode.index`
   The index of this node in the sequence of roles defined for the test. The index 0 is special and that machine
will be the server. All failure injection and throttling must be done from this node.

这些可用的属性有：::

 * `multinode.max-nodes` 测试可以拥有的最大节点数
 * `multinode.host` （此）测试节点的主机名和IP地址，必须可以被`InetAddress.getByName`解析。
 * `multinode.port` （此）测试节点的（网络）端口号
 * `multinode.server-host` 服务器节点的主机名或IP，必须可以被`InetAddress.getByName`解析。
 * `multinode.server-port` 服务器节点的端口号，默认为4711。
 * `multinode.index` 为测试定义的角色序列中此节点的索引。索引0是特殊的，该机器将是服务器。
   必须从此节点完成所有故障注入和限制。

## The SbtMultiJvm Plugin
## SbtMultiJvm插件

The @ref:[SbtMultiJvm Plugin](multi-jvm-testing.md) has been updated to be able to run multi node tests, by
automatically generating the relevant `multinode.*` properties. This means that you can run multi node tests
on a single machine without any special configuration by running them as normal multi-jvm tests. These tests can
then be run distributed over multiple machines without any changes by using the multi-node additions to the
plugin.

@ref:[SbtMultiJvm插件](multi-jvm-testing.md) 已更新为能够通过自动生成相关的`multinode.*`属性来运行多节点测试。
这意味着你可以在没有任何特殊配置的情况下在单个计算机上运行多节点测试，方法是将它们作为正常的`multi-jvm`测试运行。然后，
通过使用插件的多节点附加功能，可以在多台计算机上分布运行这些测试而无需任何更改。

### Multi Node Specific Additions
### 多节点规范附加功能

The plugin also has a number of new `multi-node-*` sbt tasks and settings to support running tests on multiple
machines. The necessary test classes and dependencies are packaged for distribution to other machines with
[SbtAssembly](https://github.com/sbt/sbt-assembly) into a jar file with a name on the format
`<projectName>_<scalaVersion>-<projectVersion>-multi-jvm-assembly.jar`

该插件还具有许多新的`multi-node-*`的sbt任务和设置，以支持在多台计算机上运行测试。打包必要的测试类和依赖项，
以便将带有 [SbtAssembly](https://github.com/sbt/sbt-assembly) 的其他计算机分发到一个jar文件中，其名称格式为
`<projectName>_<scalaVersion>-<projectVersion>-multi-jvm-assembly.jar`。

@@@ note

To be able to distribute and kick off the tests on multiple machines, it is assumed that both host and target
systems are POSIX like systems with `ssh` and `rsync` available.

为了能够在多台机器上分发和启动测试，假设主机和目标系统都是POSIX类似系统，可以使用ssh和rsync。

@@@

These are the available sbt multi-node settings:
:
 *
   `multiNodeHosts`
   A sequence of hosts to use for running the test, on the form `user@host:java` where host is the only required
part. Will override settings from file.
 *
   `multiNodeHostsFileName`
   A file to use for reading in the hosts to use for running the test. One per line on the same format as above.
Defaults to `multi-node-test.hosts` in the base project directory.
 *
   `multiNodeTargetDirName`
   A name for the directory on the target machine, where to copy the jar file. Defaults to `multi-node-test` in
the base directory of the ssh user used to rsync the jar file.
 *
   `multiNodeJavaName`
   The name of the default Java executable on the target machines. Defaults to `java`.

这些是可用的多sbt节点设置荐：::

 * `multiNodeHosts` 用于运行测试的主机列表，格式为`user@host:java`，其中`host`是唯一必需的。这将覆盖文件中的设置。
 * `multiNodeHostsFileName`　用于在主机中读取用于运行测试的文件。每行一个，格式与上述相同。默认为本项目目录中的
   `multi-node-test.hosts`。
 * `multiNodeTargetDirName` 目标计算机上目录的名称，用于复制jar文件的位置。默认为`multi-node-test`中ssh用户的基本目录
   并使用rsync来传输jar文件。
 * `multiNodeJavaName` 目标计算机上的默认Java可执行文件的名称，默认为`java（Java命令行程序）。

Here are some examples of how you define hosts:
:
 *
   `localhost`
   The current user on localhost using the default java.
 *
   `user1@host1`
   User `user1` on host `host1` with the default java.
 *
   `user2@host2:/usr/lib/jvm/java-7-openjdk-amd64/bin/java`
   User `user2` on host `host2` using java 7.
 *
   `host3:/usr/lib/jvm/java-6-openjdk-amd64/bin/java`
   The current user on host `host3` using java 6.

以下是你如何定义主机的一些示例：::

 * `localhost` localhost上当前用户使用的默认java。（TODO？）
 * `user1@host1` 用户`user1`在主机`host1`上使用的默认java。
 * `user2@host2:/usr/lib/jvm/java-7-openjdk-amd64/bin/java` 用户`user2`在主机`host2`上使用的默认java全路径。
 * `host3:/usr/lib/jvm/java-6-openjdk-amd64/bin/java` 主机`host3`上的当前用户使用java 6。

### Running the Multi Node Tests
### 运行多节点测试

To run all the multi node test in multi-node mode (i.e. distributing the jar files and kicking off the tests
remotely) from inside sbt, use the `multiNodeTest` task:

要从sbt内部以多节点模式运行所有多节点测试（即分发jar文件并远程启动测试），请使用`multiNodeTest`任务：

```none
multiNodeTest
```

To run all of them in multi-jvm mode (i.e. all JVMs on the local machine) do:

要以多Jvm模式运行所有测试（即本地计算机上的所有JVM），执行以下操作：

```none
multi-jvm:test
```

To run individual tests use the `multiNodeTestOnly` task:

要运行单个测试，请使用`multiNodeTestOnly`任务：

```none
multiNodeTestOnly your.MultiNodeTest
```

To run individual tests in the multi-jvm mode do:

要在`multi-jvm`模式下运行单个测试，请执行以下操作：

```none
multi-jvm:testOnly your.MultiNodeTest
```

More than one test name can be listed to run multiple specific tests. Tab completion in sbt makes it easy to
complete the test names.

可以列出多个测试名称以运行多个特定测试。在sbt中使用自动完成功能可以轻松获得完整的测试名称。

## A Multi Node Testing Example
## 多节点测试示例

First we need some scaffolding to hook up the `MultiNodeSpec` with your favorite test framework. Lets define a trait
`STMultiNodeSpec` that uses ScalaTest to start and stop `MultiNodeSpec`.

首先，我们需要一些脚手架来将`MultiNodeSpec`与你最喜欢的测试框架连接起来。让我们定义一个`STMultiNodeSpec` trait，
它使用`ScalaTest`来启动和停止`MultiNodeSpec`。

@@snip [STMultiNodeSpec.scala](/akka-remote-tests/src/test/scala/akka/remote/testkit/STMultiNodeSpec.scala) { #example }

Then we need to define a configuration. Lets use two nodes `"node1` and `"node2"` and call it
`MultiNodeSampleConfig`.

然后我们需要定义一个配置。让我们使用两个节点`node1和`node2`并使用`MultiNodeSampleConfig`来调用它。

@@snip [MultiNodeSample.scala](/akka-remote-tests/src/multi-jvm/scala/akka/remote/sample/MultiNodeSample.scala) { #package #config }

And then finally to the node test code. That starts the two nodes, and demonstrates a barrier, and a remote actor
message send/receive.

然后最后到节点测试代码。这将启动两个节点，并演示barrier和远程actor的send/receive消息功能。

@@snip [MultiNodeSample.scala](/akka-remote-tests/src/multi-jvm/scala/akka/remote/sample/MultiNodeSample.scala) { #package #spec }

The easiest way to run this example yourself is to download the ready to run
@extref[Akka Multi-Node Testing Sample with Scala](ecs:akka-samples-multi-node-scala)
together with the tutorial. The source code of this sample can be found in the @extref[Akka Samples Repository](samples:akka-sample-multi-node-scala).

自己运行此示例的最简单方法是下载 @extref[运行的Akka多节点测试示例](ecs:akka-samples-multi-node-scala) 以及教程。
该示例的源代码可以在 @extref[Akka示例仓库](samples:akka-sample-multi-node-scala) 中找到。

## Things to Keep in Mind
## 要记住的事情

There are a couple of things to keep in mind when writing multi node tests or else your tests might behave in
surprising ways.

在编写多节点测试时要记住几件事，否则你的测试可能会以令人惊讶的方式运行。

 * Don't issue a shutdown of the first node. The first node is the controller and if it shuts down your test will break.
 * To be able to use `blackhole`, `passThrough`, and `throttle` you must activate the failure injector and
throttler transport adapters by specifying `testTransport(on = true)` in your MultiNodeConfig.
 * Throttling, shutdown and other failure injections can only be done from the first node, which again is the controller.
 * Don't ask for the address of a node using `node(address)` after the node has been shut down. Grab the address before
shutting down the node.
 * Don't use MultiNodeSpec methods like address lookup, barrier entry et.c. from other threads than the main test
thread. This also means that you shouldn't use them from inside an actor, a future, or a scheduled task.

 * 不要关闭第一个节点。第一个节点是控制器，如果它关闭，你的测试就会中断。
 * 为了能够使用`blackhole`、`passThrough`和`throttle`，你必须通过在`MultiNodeConfig`中指定`testTransport(on = true)`
   来激活故障注入器和throttler传输适配器。
 * 限制（Throttling），关闭和其他故障注入只能从第一个节点完成，第一个节点也是控制器。
 * 在节点关闭后，不要使用`node(address)`询问节点的地址。在关闭节点之前获取地址。
 * 不要在其他线程而不是主测试线程使用`MultiNodeSpec`的方法，如地址查找（address lookup）、屏障输入（barrier entry）等。
   这也意味着你不应该在actor，future或调度（scheduled）任务中使用它们。

## Configuration
## 配置

There are several configuration properties for the Multi-Node Testing module, please refer
to the @ref:[reference configuration](general/configuration.md#config-akka-multi-node-testkit).

多节点测试模块有多个配置属性，请参考 @ref:[配置参考](general/configuration.md#config-akka-multi-node-testkit)。
