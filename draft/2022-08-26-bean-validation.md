---
categories: spring
date: "2022-08-26T00:00:00Z"
tags: ['java', 'spring', 'jpa']
title: '# @validation 은 언제 사용해야 하는가?'
---

# 0. 계기
[validation 어노테이션](https://beanvalidation.org/)은 JSR-303 에 처음 등장하였습니다.(이러한 어노테이션을 통칭해 `@validation` 이라 부르겠습니다.) 객체에 `@NotNull`과 같은 간단한 어노테이션을 붙여주는 것만으로 검증을 수행할 수 있습니다. 그리고 이러한 어노테이션을 읽고, 검증을 처리해주는 `bean validator` 라는 녀석이 필요합니다. `hibernate validator`는 해당 스펙에 대한 구현체로, 스프링 또한 `hibernate validator`를 사용하고 있습니다.

[모락 프로젝트]()에서, entity 를 관리할 것인가에 대한 이야기로 회의를 진행했습니다. 당시에, 외부(controller)에서 들어오는 요청값에 대한 null 혹은 blank에 대한 검사라던지, 도메인 규칙에 따른 길이 제한과 같은 제약사항들을 어떻게 다룰지 내부적으로 많은 이야기가 오고 갔었죠. 최종적으로 저희가 사용하기로 한 규칙은 다음과 같습니다.

1. request DTO에 대한 검증에는 도메인 규칙을 담지 않는다. 즉, `@NotNull` 과 같이 "순수 데이터" 관점에서 필요한 로직만 검증한다.
2. entity 에서는 모든 도메인 로직과 값 자체의 유효성 검증을 수행한다.
   1. 간단한 로직(e.g. 길이제한)은 `@validation` 어노테이션으로 처리한다.
   2. 복잡한 로직이나, 여러 속성에 걸쳐 검증해야 하는 경우, 생성자에서 검증한다.

물론 위와 같은 규칙을 세우기 위해 아래와 같은 consensus 를 합의했기 때문입니다.

1. view layer에 도메인 로직을 넣는 것은 옳지 않다.
   - 도메인을 믿고 사용할 수 있으려면, 도메인 내부에 검증 로직이 있어야 한다.
   - request DTO 에 검증 로직을 담으면, 검증 로직이 분산되어 유지보수의 어려움이 생길것이다.
2. 검증해야 할 로직이 너무 많다.
   - 객체의 무결성을 보장하기 위해, 모든 사소한 로직(not-null)들을 검사해야 하는데, 이를 위한 entity와 각 attribute가 너무 많다. 이를 모두 작성하는건 bolierplate 다.
3. database 를 신뢰할 수 있는가 ?
   - RDBMS 는 여러 어플리케이션에서 사용할 수 있다. 그런데 다른 어플리케이션에서 잘못된 값을 넣어버리면 우리 어플리케이션에서 문제가 발생한다.
   - table 에 제약조건을 넣을수도 있지만, 도메인 로직 상 오류(e.g. URL 형태인가?)는 잡아낼 수 없다.

# 1. 문제의 발견
그렇게 한참 프로젝트를 진행하던 중, QA 과정에서 무언가 이상한 오류를 발견했습니다.  

`javax.persistence.RollbackException: Error while committing the transaction`

오류가 발생해야 하는 상황은 맞는데, 위와 같이 처음 보는(*그리고 불친절한*) 예외가 발생하고 있었죠. 잠깐 문제의 원인을 살펴보자면 다음과 같습니다.

기본적으로, declarative transaction인 `@Transactional` 어노테이션은 `AOP`를 기반으로합니다. 그리고 java spring에서의 `AOP`는 proxy를 통해 수행되고 있구요. 따라서 트랜잭션이 동작하는 프록시 객체의 메소드는 다음과 같이 구성되어 있습니다.

{{< figure src="/assets/images/2022-08-26-bean-validation/2022-08-26-22-53-49.png" width="300px" align="center">}}

그런데, 객체가 **transaction commit** 에 의해 영속성 컨텍스트에 진입한다면 예외는 "내가 정의한 메소드 바깥", 즉 프록시 객체 메소드에서 발생하게 됩니다.

> 저희 프로젝트에서는 entity에 **양방향** 연관관계를 맺어둔 뒤, `CascadeType.ALL` 혹은 `CascadeType.PERSIST` 를 걸어둔채로 연관 객체를 넣어주고 있었습니다.

{{< figure src="/assets/images/2022-08-26-bean-validation/2022-08-26-23-44-51.png" width="350px" align="center">}}

그리고 여기서 발생한 exception은 `RollBackException`으로 한번 wrapping되어 예외를 던지게 됩니다. 이를 해결하려면 메소드내에서 의도적으로 연관객체를 `save` 하거나, 외부에서 `bean validator`를 가져와 검증하는 등의 방법이 있겠죠.

이와 관련한 트러블 슈팅을 하던 중, 지나가던 몇몇 크루들이 들어와서 저희의 코드를 보고는 "entity 객체에서 bean validation을 쓰네요?" 라며 의문을 표했습니다. 심지어 한 크루는 "bean validation이 애초에 이렇게 쓰라고 나온게 아니다" 라는 이야기까지 해주었습니다.

당시 저는 entity에서 `@validation`을 쓰는 예제를 수없이 봐왔고, jboss에서 제공하는 [hibernate validator](https://docs.jboss.org/hibernate/stable/validator/reference/en-US/html_single/)에서도 이에 대한 가이드를 안내하고 있었기 때문에, 왜 다른 크루들이 이러한 이야기를 하는지 이해가 되지 않았습니다.

# 2. 그럼 어디에서 사용해야 할까

[JSR-303 1.2 Specification Goal](https://beanvalidation.org/1.0/spec/) 을 살펴보면, 다음과 같은 문장이 나옵니다.

> *Validating data is a common task that is copied in many different layers of an application, from the presentation tier to the persistentce layer. Many times the exact same validations will have to be implemented in each separate validation framework, proving time consuming and error-prone.*   
> 
> ...  
> 
> *The validation API developed by this JSR is not intended for use in any one tier or programming model. It is specifically not tied to either the web tier or the persistence tier, and is available for both server-side application programming, as well as rich client Swing application developers.* 

한 문장씩 살펴보면 다음과 같습니다. 

![](/assets/images/2022-08-26-bean-validation/2022-08-27-00-14-55.png)
> *데이터를 검증하는 것은 presentation tier 부터 persistence layr까지 어플리케이션의 다양한 영역에 걸쳐 반복되는 흔한 작업입니다. 여러 검증 프레임워크에 의해 동일한 검증이 여러 번 발생하는데, 이는 시간 소모적이고 오류를 일으키기 쉽습니다.*  

![](/assets/images/2022-08-26-bean-validation/2022-08-27-00-16-46.png)
> *JSR에 의해 개발된 검증 API는 어떤 한 계층이나 프로그래밍 모델에서 사용되도록 의도된 것이 아닙니다. 특히, web tier나 persistence tier에 관련되지 않으며, server-side 어플리케이션 프로그래밍 뿐만 아니라 rich client Swing 어플리케이션 개발자도 사용할 수 있습니다.*

즉, 태생 자체는 도메인 객체에서 사용할 것을 의도하고 나온 것입니다.

# 2. 하지만 현실은

하지만 실제로 개발할 때에는 위 내용과 조금 다른 경우가 있습니다.

## 2.1. 테스트
가장 첫 번째로 발견되는 문제는 테스트입니다. 객체를 생성할 때, 올바른 값을 가지고 있는지 검증하는 작업은 빈번하게 발생합니다. 하지만 이와 같이 `@validation`을 사용하게 되면, 실질적으로 이를 검증해주는 `validator`가 필요하게 되죠. 따라서 저희 팀은 자연스럽게 `hibernate validator`를 사용하기 위해서 "객체 자체에 대한 class"의 test가 아닌 "객체 repository" Test 에서 수행하고 있었습니다.

```java
@DataJpaTest
class MemberRepositoryTest {
   @Test
    void 길이가_0인_이름은_저장할_수_없다() {
        // given
        Member member = Member.builder()
                .oauthId("1234")
                .name("")
                .profileUrl("http://sample-image.com")
                .build();

        // when & then
        assertThatThrownBy(() -> memberRepository.save(member))
                .isInstanceOf(ConstraintViolationException.class);
    }
}
```

객체에 대한 unit-test에서 `bean validator` 객체를 [직접 생성해서 사용](https://docs.jboss.org/hibernate/stable/validator/reference/en-US/html_single/#section-validating-executable-constraints)하는 것도 하나의 대안이 될 수 있겠습니다만, 실제 사용법을 보면 이는 꽤나 귀찮은 작업이 됩니다.

## 2.2. DTO
![](/assets/images/2022-08-26-bean-validation/2022-08-27-00-16-46.png)

위 그림을 다시 보면, domain model 이 client 부터 시작해 database까지 모든 layer에 걸쳐 존재하는 것을 확인할 수 있습니다. 만약 이 그림을 곧이 곧대로 받아들인다면, controller에서 요청을 entity 객체로 받는 경우를 상상해볼 수 있겠죠.

하지만 외부에서는 어떤 값이 들어올지 알 수 없습니다. 따라서 view 와 domain에 대한 관심사의 분리와 같은 이유도 있지만, 여기서는 외부에서 어떤 잘못된 값이 주어질지 알 수 없기 때문에, (대개 entity 객체와 유사한 필드를 가진) DTO 라는 객체로 받아서 이를 entity 객체로 변환해주는 작업을 합니다.

> domain 객체, entity 객체 등에 대해서 의문을 표할수도 있겠습니다. 여기서 설명하는 domain 객체는 "문제를 해결하기 위해 필요한 객체"를, entity 객체는 "domain 객체를 영구저장하기 위한 객체" 로 정의하겠습니다.

그렇다면 이 DTO 를 어떻게 해야할지에 대한 문제도 발생합니다.

## 2.3. 신뢰성
기본적으로 도메인에 모든 검증 로직이 모여있기 때문에, 도메인은 항상 올바른 값만 들어있다고 가정하는 경우가 많습니다. 하지만, 누군가 데이터베이스에 직접 접근해서, 잘못된 값을 입력했다면 어떻게 될까요 ?

hibernate에서 `@validation` 은 영속성 컨텍스트에 **진입**할 때 일어납니다. 따라서, DB로부터 쿼리를 가져와 객체를 생성할 때는 검증하지 않습니다. 따라서 아무리 `@validation`을 붙였다고 한들, 올바르지 않은 객체를 잘못 사용할 가능성이 존재하죠. 게다가 read 역할을 하는 API를 호출하는 경우에는 사용자가 잘못된 응답을 받을 가능성이 존재합니다.

# 3. 그렇다면 어떻게 해야할까 
만약 정책이 바뀐다면, 기존에 존재하는 데이터는 모두 잘못된 값일까 ? (e.g. http://를 https:// 만 허용한다면 ?)

이와 관련해서 여러 레퍼런스를 찾아봤지만, 명확한 답은 존재하지 않는 것 같습니다. 

[entity 에서만 검증해서는 안된다](https://reflectoring.io/bean-validation-anti-patterns/)

[누군가는 애초에 객체 자체에 대해서 항상 검증하는 것은 틀렸다](https://jeffreypalermo.com/2009/05/the-fallacy-of-the-always-valid-entity/)라고도 얘기합니다. 


--
<!-- 그렇다면 엔티티에서만 어노테이션을 붙여야 할까요? 제 생각엔 꼭 그렇지만은 않습니다. -->



# 4. 결론

따라서 제 나름대로 내린 결론은, "DTO 에서는 값 자체의 유효성을, entity에서는 도메인 로직에 한해서만 어노테이션을 사용하자" + CQS

어쩌면 'domain' 의 정의에 대해서 잘못 이해하고 있는 것일수도 있구요.

걍 둘다 써라. 대신 관점의 차이를 두어라.

<!-- 비즈니스 레이어에서 잘못된 데이터를 사용한다 -->
<!-- 여러 db에서 사용하지 않을 것이다. -->
<!-- Postconstruct -->
<!-- design by contract -->

## 참고자료

- https://beanvalidation.org/1.0/spec/
- https://docs.jboss.org/hibernate/stable/validator/reference/en-US/html_single/
