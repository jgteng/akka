# Multi JVM Testing
# 多JVM测试

Supports running applications (objects with main methods) and ScalaTest tests in multiple JVMs at the same time.
Useful for integration testing where multiple systems communicate with each other.

支持在多个JVM中同时运行应用程序（具有main方法的object）和ScalaTest测试。适用于多个系统相互通信的集成测试。

## Setup
## 设置

The multi-JVM testing is an sbt plugin that you can find at [https://github.com/sbt/sbt-multi-jvm](https://github.com/sbt/sbt-multi-jvm).
To configure it in your project you should do the following steps:

多JVM测试是一个sbt插件，你可以在 [https://github.com/sbt/sbt-multi-jvm](https://github.com/sbt/sbt-multi-jvm) 找到它。
要在项目中配置它，你应该执行以下步骤：

1. Add it as a plugin by adding the following to your project/plugins.sbt:
    通过将以下内容添加到 [plugins.sbt](/project/plugins.sbt) 中将其添加为插件：

    @@snip [plugins.sbt](/project/plugins.sbt) { #sbt-multi-jvm }

2. Add multi-JVM testing to `build.sbt` or `project/Build.scala` by enabling `MultiJvmPlugin` and
setting the `MultiJvm` config.
    通过启用`MultiJvmPlugin`并设置`MultiJvm`配置，将多JVM测试添加到`build.sbt`或`project/Build.scala`。

    ```none
    lazy val root = (project in file("."))
      .enablePlugins(MultiJvmPlugin)
      .configs(MultiJvm)
    ```

**Please note** that by default MultiJvm test sources are located in `src/multi-jvm/...`,
and not in `src/test/...`.

**请注意**，默认情况下MultiJvm测试代码位于`src/multi-jvm/...`中，而不是`src/test/....`。

Here is an example of a @extref[sample project](samples:akka-sample-multi-node-scala) that uses the `sbt-multi-jvm` plugin.

以下是使用`sbt-multi-jvm`插件的 @extref[示例项目](samples:akka-sample-multi-node-scala) 示例。

## Running tests
## 运行测试

The multi-JVM tasks are similar to the normal tasks: `test`, `testOnly`,
and `run`, but are under the `multi-jvm` configuration.

多JVM任务与通常的`test`、`testOnly`、`run`任务类似，但是在`multi-jvm`配置下。

So in Akka, to run all the multi-JVM tests in the akka-remote project use (at
the sbt prompt):

所以在Akka中，要在`akka-remote`项目中运行多JVM测试（在sbt提示符下）：

```none
akka-remote-tests/multi-jvm:test
```

Or one can change to the `akka-remote-tests` project first, and then run the
tests:

或者，首先可以更改为`akka-remote-tests`项目，然后运行测试：

```none
project akka-remote-tests
multi-jvm:test
```

To run individual tests use `testOnly`:

运行单个测试使用`testOnly`：

```none
multi-jvm:testOnly akka.remote.RandomRoutedRemoteActor
```

More than one test name can be listed to run multiple specific
tests. Tab-completion in sbt makes it easy to complete the test names.

可以列出多个测试名称以运行多个特定测试。 sbt中的制表符自动完成功能可以轻松完成测试名称。

It's also possible to specify JVM options with `testOnly` by including those
options after the test names and `--`. For example:

通过在测试名称和 -- 之后包含这些选项，还可以使用testOnly指定JVM选项。 例如：

```none
multi-jvm:testOnly akka.remote.RandomRoutedRemoteActor -- -Dsome.option=something
```

## Creating application tests
## 创建应用测试

The tests are discovered, and combined, through a naming convention. MultiJvm test sources
are located in `src/multi-jvm/...`. A test is named with the following pattern:

通过命名约定发现测试。多JVM测试源码位于`src/multi-jvm/...`目录。测试的命名模式如下：

```none
{TestName}MultiJvm{NodeName}
```

That is, each test has `MultiJvm` in the middle of its name. The part before
it groups together tests/applications under a single `TestName` that will run
together. The part after, the `NodeName`, is a distinguishing name for each
forked JVM.

也就是说，每个测试都在其名称中间有`MultiJvm`。它之前的部分将测试/应用程序组合在一起运行的单个`TestName`下。
后面的部分`NodeName`是区别每个分叉（forked）JVM的名称。

So to create a 3-node test called `Sample`, you can create three applications
like the following:

因此，要创建名为`Sample`的3个测试节点，你可以创建三个应用程序，如下所示：

```scala
package sample

object SampleMultiJvmNode1 {
  def main(args: Array[String]) {
    println("Hello from node 1")
  }
}

object SampleMultiJvmNode2 {
  def main(args: Array[String]) {
    println("Hello from node 2")
  }
}

object SampleMultiJvmNode3 {
  def main(args: Array[String]) {
    println("Hello from node 3")
  }
}
```

When you call `multi-jvm:run sample.Sample` at the sbt prompt, three JVMs will be
spawned, one for each node. It will look like this:

在sbt提示符下调用`multi-jvm:run sample.Sample`时，将生成三个JVM，每个节点一个。它看起像这样：

```none
> multi-jvm:run sample.Sample
...
[info] * sample.Sample
[JVM-1] Hello from node 1
[JVM-2] Hello from node 2
[JVM-3] Hello from node 3
[success] Total time: ...
```

## Changing Defaults
## 更改默认值

You can specify JVM options for the forked JVMs:

你可以为forked的JVM指定JVM选项：

```
jvmOptions in MultiJvm := Seq("-Xmx256M")
```

You can change the name of the multi-JVM test source directory by adding the following
configuration to your project:

你可以通过以下配置来添加更多的多JVM测试目录到你的项目：

```none
unmanagedSourceDirectories in MultiJvm :=
   Seq(baseDirectory(_ / "src/some_directory_here")).join.value
```

You can change what the `MultiJvm` identifier is. For example, to change it to
`ClusterTest` use the `multiJvmMarker` setting:

你可以更改`MultiJvm`标识符。例如：使用`multiJvmMarker`将其更改为`ClusterTest`：

```none
multiJvmMarker in MultiJvm := "ClusterTest"
```

Your tests should now be named `{TestName}ClusterTest{NodeName}`.

你的测试将被命名为`{TestName}ClusterTest{NodeName}`。

## Configuration of the JVM instances
## 配置JVM实例

You can define specific JVM options for each of the spawned JVMs. You do that by creating
a file named after the node in the test with suffix `.opts` and put them in the same
directory as the test.

你可以为每个生成的JVM定义特定的JVM选项。你可以通过在测试中使用后缀`.opts`创建一个以节点命名的文件，
并将它们放在与测试相同的目录中。

For example, to feed the JVM options `-Dakka.remote.port=9991` and `-Xmx256m` to the `SampleMultiJvmNode1`
let's create three `*.opts` files and add the options to them. Separate multiple options with
space.

例如，要将JVM选项`-Dakka.remote.port = 9991`和`-Xmx256m`提供给`SampleMultiJvmNode1`，
让我们创建三个`*.opts`文件并将选项添加到进去。用空格分隔多个选项。

`SampleMultiJvmNode1.opts`:

```
-Dakka.remote.port=9991 -Xmx256m
```

`SampleMultiJvmNode2.opts`:

```
-Dakka.remote.port=9992 -Xmx256m
```

`SampleMultiJvmNode3.opts`:

```
-Dakka.remote.port=9993 -Xmx256m
```

## ScalaTest

There is also support for creating ScalaTest tests rather than applications. To
do this use the same naming convention as above, but create ScalaTest suites
rather than objects with main methods. You need to have ScalaTest on the
classpath. Here is a similar example to the one above but using ScalaTest:

还支持创建ScalaTest测试而不是应用程序。为此，请使用与上面相同的命名约定，但是创建ScalaTest套件而不是使用main方法的对象。
你需要在类路径上使用ScalaTest。以下是与上面相似但使用ScalaTest的示例：

```scala
package sample

import org.scalatest.WordSpec
import org.scalatest.matchers.MustMatchers

class SpecMultiJvmNode1 extends WordSpec with MustMatchers {
  "A node" should {
    "be able to say hello" in {
      val message = "Hello from node 1"
      message must be("Hello from node 1")
    }
  }
}

class SpecMultiJvmNode2 extends WordSpec with MustMatchers {
  "A node" should {
    "be able to say hello" in {
      val message = "Hello from node 2"
      message must be("Hello from node 2")
    }
  }
}
```

To run just these tests you would call `multi-jvm:testOnly sample.Spec` at
the sbt prompt.

你可以在sbt命令提示符调用`multi-jvm:testOnly sample.Spec`来运行这些测试。

## Multi Node Additions
## 多节点附加（功能）

There has also been some additions made to the `SbtMultiJvm` plugin to accommodate the
@ref:[may change](common/may-change.md) module @ref:[multi node testing](multi-node-testing.md),
described in that section.

这里有些附加功能对`SbtMultiJvm`插件进行了一些补充，以适应可能的 @ref:[更改](common/may-change.md) 模块
@ref:[多节点测试](multi-node-testing.md) ，如本节所述。
