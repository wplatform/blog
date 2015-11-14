Scala语言学习笔记
==
Scala是Twitter使用的主要应用编程语言之一。Twitter很多的基础架构都是用scala写的。著名的开源项目有spark,kafka,marathon等。要熟悉这些项目的实现，熟悉Scala语言是必需的，虽然Scala最终编译成Java字节码运行在Java平台上，但它不是Java，而是把它作为一门新的语言。Scala提供很多工具使表达式可以很简洁， 这是对于习惯java编程风格的人而言算是一种新的事务，不好理解，个人觉得其学习的门槛会比Java要高。一门语言并不是你想精通就能够精通的，还是需要一个过程的，因为没有长时间工作于Scala语言之上，将学到关于Scala语言特性的整理成文，以便日后参考。


#1. 变量定义
val定义的是final的常量， val 定义的变量是不能再次被赋值的，也就是说这个变量名称和值是绑定的，不能改变，如果想改变这个名称和值得绑定，那么使用 var 定义变量， 如果获取变量的值是一个耗时的工作时，可以考虑使用lazy,使它只有真正被使用的时候才进行初始化. 
```Scala
val str = "hello"
var age = 20
lazy val forLater = someTimeConsumingOperation()
```
#2. 方法的定义
函数的定义用def开始，方法的定义格式：def 方法名（参数名：参数类型,…）：返回值类型={方法体}
```Scala
def max(x: Int, y: Int): Int = { 
if (x > y) 
    x
else
    y 
}
//变长参数
def echo(args: String*): Unit = {
    for (arg <- args) println(arg)
}

//这样定义,echo 可以被零个至多个 String 参数调用
echo()
echo ("One")
echo ("Hello","World")

/*echo 函数里被声明为类型“String*” 的 args 的类型实际上是 Array[String]。然而, 不能直接以数组做为入参，
 *需要在数组参数后添加一个冒号和一个_*符号,像这样:
 */

val arr = Array("What's", "up", "doc?")
echo(arr: _*)

```

#3. 方法的调
通常，scala和其他大多数的语言一样，对方法的调用使用是：<class instance>.<method>[(<parameters>)],但scala对于单参数方法的调用有种简化的写法，也就是把方法名当做一种操作符，使用对象 方法名 参数中间以空格分隔的方式：<object> <method> <parameter>。
import java.util.{Date, Locale}
import java.text.DateFormat
import java.text.DateFormat._
object FrenchDate {
    def main(args: Array[String]) {
        val now = new Date
        val df = getDateInstance(LONG, Locale.FRANCE)
        println(df format now) //和 df.format(now)的语义完全相同
    }
} 
```
这虽然是一个很小的语法细节，但它具有深远的影响。思考一下为什么会出现这种样式的方法调用，应该说这是用于引入了“操作符做方法名”而产生的一种自然需要！
```Scala
val a = 10
val b = 5
val = a + b // 同样的这个操作可以看做为一次名字为“＋”方法的调用 a.+(b)，意义大家体会一下。
```

#4. 一切皆为对象

Scala 中的一切都是对象，从这个意义上说，Scala 是纯粹的面向对象（pure object-oriented的语言。对象华比Java更彻底，因为Java中，原子类型（primitive types）和引用类型是有区别的.

```Scala
1+2*3/x 
```
实际上完全是由方法调用（method calls）构成的。前面章节已经提到过“单参数方法”的简化写法，所以，上述表达式实际上是下面这个表达式的等价简化写法：
```Scala
(1).+(((2).*(3))./(x))
```
由此我们还可以看到：+, *等符号在 Scala 中是合法的标识符。打开Scala Int类，果然定义了＋，－，＊，/等方法
```Scala
  def +(x : scala.Int) : scala.Int
  def -(x : scala.Int) : scala.Int
  def *(x : scala.Int) : scala.Int
  def /(x : scala.Int) : scala.Int
  //..........省略.............
```
#5. 对象的创建
对于习惯java编程风格的人都明白对象是使用new创建出来的道理，而在使用Scala时遇到下面的语句常常会感觉到困惑：
```Scala
val arr = Array(1,2,3,4)
val list = List("One","Two","Three")
val map = Map("foo" -> "bar")
```
以Scala创建数组为例，val arr = new Array[Int](3) 的方式创建能正常理解，上面的几条语句中并没有使用new，那对象是怎么产生的呢？Effective Java一本中提到的观点是静态工厂方法来代替new创建对象，如常见的写法有：
```Java
List<Integer> list = New.arrayList();
```
然而Scala没有静态这一说法，取而代之的是以单例对象为工厂使用，单例对象可以和类具有相同的名称，此时该对象也被称为“伴生对象”。通常将伴生对象作为工厂使用。下面是一个简单的例子，可以不需要使用’new’来创建一个实例了。
```Scala
class Bar(foo: String)

object Bar {
  def apply(foo: String) = new Bar(foo)
}

var bar = Bar("Bar") //＝Bar.apply("Bar")

//object(parameter)相当于调用object.apply(parameter)方法，如果Bar类这样定义，则有：
class Bar(foo: String) {
	def apply() = this.foo;
}
val b = bar() //=bar.apply()
```

#6. 方法和函数的区别

Scala方法和函数有些差别，大多数情况下我们都可以不去理会他们之间的区别。但是有时候我们必须要了解他们之间的不同。一个scala 方法，在java中是类的一部分，它有一个名字，一个签名，可选的注解 和字节码。在scala中一个函数是一个完整的object，在scala中有一系列的特质(trait)代表各种各样的带参数的函数：Function0到Function22（似乎函数最多只能支持22个参数）。具有一个参数的函数是Function1特质的一个实例。一个函数object有许多方法。这些方法之一就是apply方法，这个方法包含了实现这个函数的代码。 scala中apply有特殊的语法：如果你写一个函数名紧接着是一个带一系列参数列表的括号（或者仅有不带参数的括号），scala会将调用转换成对应名的object的apply方法。

```Scala
class Test {
    def m1(x:Int) = x+3 //方法
    val f1 = (x:Int) => x+3 //函数
}

```
Scala在编译器在作了一些动做使达式可以很简洁 (x:Int) => x+3 其实是干这样一件事情
```Scala
new Function1[Int, Int] {
  def apply(x: Int): Int = x + 1
}
```
编译后生成两个class文件，Test$$anonfun$1.class Test.class, 通过javap将会看到：
```Java
//Compiled from "Test.scala"
public class Test {
  public int m1(int);
  public scala.Function1<java.lang.Object, java.lang.Object> f1();
  public Test();
}

//Compiled from "Test.scala"
public final class Test$$anonfun$1 extends scala.runtime.AbstractFunction1$mcII$sp implements scala.Serializable {
  public static final long serialVersionUID;
  public final int apply(int);
  public int apply$mcII$sp(int);
  public final java.lang.Object apply(java.lang.Object);
  public Test$$anonfun$1(Test);
}
```
也可以通过使用一个存在的方法来定义一个函数，引用函数名 接着一个空格和一个下划线。修改test.scala 加上另一行：
```Scala
class test {
    def m1(x:Int) = x+3
    val f1 = (x:Int) => x+3
    val f2 = m1 _
}
```
这m1 _语法 告诉scala 把m1当做一个函数而不是通过调用那个方法来使用产生的值。作为另一种选择，你可以详细的声明 类型f2,这样你不需要包含一个末尾下划线：
```Scala
val f2 : (Int) => Int = m1
```
有时候不注意这些细节很容易掉入陷井，如下面的例子中，test2.m1 test2.f1效果是不一样的
```Scala
class Test2 {
  def m1() = println("m1") //方法
  val f1 = () => println("m1")  //函数
}

val test2= new Test2

test2.m1 //调用方法m1
test2.f1 //什么也不干

```
