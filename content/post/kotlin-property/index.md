---
categories: kotlin
date: "2022-06-09T14:25:36Z"
tags: ['kotlin', 'property']
title: 'kotlin property'
---

코틀린을 처음 접하면, 익숙한 `field` 라는 용어 대신 `property` 라는 용어를 접하게 된다. `property` 라는 용어는 지난 [파이썬 Property까지 가는 길](https://cjlee38.github.io/post/language/python/2021-09-16-journey-to-property/) 에서 한번 다뤘던 개념과 사실상 같다고 보아도 무방하다. property는 단순하게 이야기하면 클래스 내에 담겨있는 `field`, `getter` , `setter` 를 통칭하여 의미하다.  `Java` 에서는 이를 `private` 으로 필드를 숨기고, `getter` 와 `setter` 를 제공함으로서 `property`를 흉내낸다. 

```java
public class SomeObject {

	private int someInteger;
	private String someString;

	public int getSomeInteger() {
		return this.someInteger;
	}

	public String getSomeString() {
		return this.someString;
	}

	public void setSomeInteger(int otherInteger) {
		this.someInteger = otherInteger;
	}

	public void setSomeString(String otherString) {
		this.someString = otherString;
	}
}
```

코틀린에서 변수는 기본적으로 `val` 과 `var` 를 통해 작성한다. `val`은 `value` 를 의미하여 한 번 초기화 된 이후로는 `read-only` 이다. `Java` 의 `final` 키워드를 붙인 변수라고 생각할 수 있다. `var` 는 `variable` 을 의미하며, ‘변할 수 있는 값’, 즉 ‘변수’ 이라는 의미에 걸맞게 값을 수정할 수 있다. 그리고 이를 `property` 관점에서 살펴보면 `var` 는 순수 `property` , `val` 은 `read-only property` 라고 표현하다. 하지만 편의상 둘 다 묶어 `property` 라고 표현한다.

```kotlin
class SomeObject {
	val someString: String = "string"
	var someInteger: Int = 123
}
```

`property`는 겉에서 보기에는 마치 `public` 으로 열려있는 `field` 처럼 보이지만, 내부적으로 `getter` 와 `setter` 메소드 호출을 통해 이루어진다.(The syntax for reading and writing of properties is like for fields, but property reads and writes are (usually) translated to 'getter' and 'setter' method calls.) 그리고 이러한 `getter`, `setter` 를 묶어서 `accessor`, 즉 접근자라고 부른다.

하지만 `property`를 아무런 추가 작업 없이 순수하게 `getter`, `setter` 로만 사용한다면 큰 의미가 없다. 뭔가 내가 원하는대로 작업을 할 수 있어야 한다. `property` 는 다음과 같은 형태를 가지고 있다.

```kotlin
var <propertyName>[: <PropertyType>] [= <property_initializer>]
    [<getter>]
    [<setter>]
```

위에 보이는 형태에서 getter, setter 부분을 우리가 직접 정의할 수 있고, 이를 `custom accessor` 라고 부른다. 다음은 `Age` 라는 '나이'에 해당하는 클래스에 대한 예제이다.

```kotlin
class Age {
    val value = 20
        get() = field + 1
}

fun main() {
    val age = Age()
    println(age.value) // 21
}

```

위 코드를 보면, `Age` 클래스 내부에 `value`에 대한 값을 20으로 정의하였다. 하지만 그 값을 얻어내는 데 있어 그 값을 1 늘려서 받도록 처리하였다. 그렇기에 `age.value` 는 20 대신 21이라는 값을 얻어냄을 확인할 수 있다. 여기서 주의해서 볼 점은, `custom getter` 를 정의할 때 `field` 라는 키워드를 사용한다는 점이다.

`property`가 `field`와 `accessor`를 묶어서 부른다는 점을 감안하면, `field`라는 값이 실제로 들어있는 값에 해당함을 직감할 수 있다. 엄밀하게는 공식 문서에서는 이를 `backing field` 라고 부르며, 다음과 같이 설명한다.

> In Kotlin, a field is only used as a part of a property to hold its value in memory. Fields cannot be declared directly. However, when a property needs a backing field, Kotlin provides it automatically. This backing field can be referenced in the accessors using the field identifier

다음은 `setter`에 대한 예제이다.

```kotlin
class Age {
    var value = 20
        get() = field + 1
        set(value) {
            field = value - 2
        }
}
```

위 예제에서는 `custom setter`가 추가 된 것 이외에도, value의 타입이 `var` 로 바뀌었다는 점에 주목해야 한다. 즉, `val` 은 앞서 언급했다시피 `final`에 해당하므로, `setter`가 동작할 수 없다. 한편 `var`는 변경가능하므로, `setter`를 정의할 수 있다.

또한 `property` 에 대해 한 가지 더 알아야 할 점은, "반드시 `field`를 가질 필요는 없다" 라는 것이다. 위 `Age` 코드에서, '성인인가?'에 대한 `boolean` 값을 메소드가 아닌 `property`로 저장할 필요가 있다고 가정해보겠다.

```kotlin
class Age {
    var value = 20
        get() = field + 1
        set(value) {
            field = value - 2
        }
    val isAdult = value > 20
}

fun main() {
    val age = Age()
    println(age.value) // 21
    println(age.isAdult) // true // #1

    age.value = 10

    println(age.isAdult) // ? #2
}
```

위 코드를 실행했을 때, `#2` 에 해당하는 print문은 어떤 결과물을 내놓을까 ? 정답은 `true` 이다. 왜냐하면, instance가 생성되는 시점에 isAdult가 초기화되고, 그 값은 변하지 않기 때문이다. 

> `#1` 에 해당하는 코드 또한 `true`를 반환하다는 점도 유의해서 살펴보자. `isAdult`가 참조하고 있는 대상이 `value` 이고, `custom getter` 를 통해 가져오기 때문에 `true`가 반환된다.

이 상황에서 우리는 `isAdult`가 '매 번 새로이 계산되는 것' 을 원한다. 이를 `value의 custom setter`에 `isAdult`를 초기화하는 것 대신 `property`의 특성을 활용하면 다음과 같이 작성할 수 있다.

```kotlin
class Age {
    var value = 20
        get() = field + 1
        set(value) {
            field = value - 2
        }
    val isAdult: Boolean
        get() = value > 20
}
```

`isAdult` 에는 아무런 값도 할당되어 있지 않지만, `getter`를 통해 매 번 새로운 값을 가져올 수 있고, `val` 이기 때문에 `setter`를 정의할 수 없으므로 `isAdult`를 사용함에 있어 전혀 문제가 되지 않는다.

> 이러한 특성을 활용해 `Backing Property` 라는 개념도 있다. `Backing Property`는 외부에 드러내는 값을 드러내고, 내부로 숨기고 싶은 값을 `private` 접근자와 함께 이름 앞에 `_`(언더스코어)를 붙여주는것이 관례다. [공식문서 참고](https://kotlinlang.org/docs/properties.html#backing-properties)

