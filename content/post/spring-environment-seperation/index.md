---
categories: spring
date: "2022-08-13T00:00:00Z"
tags: ['spring', 'platform', 'profile']
title: '스프링에서 환경을 분리하는 방법'
---

프로젝트를 `local`에서만 개발하는게 아니라면, 그리고 `develop` 이나 `staging`, `production` 을 구분해서 개발하게 된다면 필연적으로 서로 다른 설정값이 필요하게 된다.

`local` 에서는 테스트 용도이므로 H2 의 in-memory DB 를 사용할 수 있지만, `production` 환경에서는 반드시 안정적인 밴더사의 RDBMS와 인스턴스를 사용하게 된다.

가령, `local`에서 개발을 마치고, 이제 `production` 에서 코드를 가져와 실행하려면 당연히 `datasource` 를 바꿔주어야 한다. 

```yml
# as-is (local)
spring:
  datasource:
    url: jdbc:h2:mem:testdb;MODE=MYSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: sa

# to-be (production, or develop ...)
spring:
  datasource:
    url: jdbc:h2:192.168.XXX.XXX:3306;MODE=MYSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: sa
```

그런데 이를 매번 바꿔주려니 여간 귀찮은 일이 아니다. 개인 노트북에서 작업을 끝낸 후, ssh 로 들어가거나, 어찌저찌 자동화해서 정상적으로 github에서 코드를 `clone` 해왔더라도, 위 설정파일을 수작업으로 매 번 고쳐주어야 한다. 

### 1.1 Profile

이를 위해 스프링에서는 `profile` 이라는 개념이 존재한다. 스프링에서는 다음과 같이 설명한다. 

> Spring Profiles provide a way to segregate parts of your application configuration and make it only available in certain environments.

즉, 어플리케이션의 설정의 일부를 분리해서, 특정 환경에서만 사용할 수 있는 기능을 제공한다. 다음은 사용법이다.

```yaml
spring:
  profiles:
    active: local

---

spring:
  config:
    activate:
      on-profile: prd
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://${DATABASE_HOST}:3306/${DATABASE_NAME}?serverTimezone=Asia/Seoul&character_set_server=utf8mb4
    username: ${USERNAME}
    password: ${PASSWORD}
---

spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:h2:mem:testdb;MODE=MYSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: ${USERNAME}
  h2:
    console:
      enabled: true
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        format_sql: true
```

가장 먼저 살펴볼 부분은, 파일이 `---` 으로 구분되었다는 점이다. 이 세 개의 dash를 기준으로 각 설정파일이 분리됨을 의미하며, `properties` 에서는 Springboot 2.4.0 부터 `#---` 기호로 구분할 수 있다.

> Note. 파일을 직접 분리해서 여러 개로 관리할 수도 있다. 이 때는 `application-${env}.yml` 혹은 `application-${env}.properties` 의 형태로 관리하며, env 가 밑에서 설명할 각각의 `profile`이 된다.

```yml
spring:
  profiles:
    active: local
```
다음으로는 가장 맨 위의 section 에 있는, `active` 이다. 이는 현재 내가 실행하고자 하는 `profile` 을 나타내며, 쉼표로 구분해 여러 개의 profile을 가져올 수도 있다. 즉, 여기서는 `local` 을 사용하겠다는 의미이다.


두 번째는 잠시 넘어가고 세 번째 section을 살펴보겠다. 

```yml
spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:h2:mem:testdb;MODE=MYSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    username: ${USERNAME}
  h2:
    console:
      enabled: true
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        format_sql: true
```

밑에서부터 잠깐 보면, datasource는 memory-db 로 설정되어 있고, h2-console 도 실행하고, sql도 모두 출력하는 등, `production` 환경에서 사용하지 않을 옵션들을 지정하였다. 

그리고 가장 위쪽을 보면 `on-profile` 에 `local` 로 지정되어 있다. 즉, `profile`이 `local`로 설정된 경우에 이 section, 즉 세 번째 section을 설정하겠다는 의미이다. 따라서 위 `active` 키에서 local로 지정하였으므로 해당 section을 설정하게 된다. 
![](2022-08-14-22-38-58.png)


반대로 `production` 환경은 실제 운영 환경에서 사용할 옵션들을 지정한다. 실제 데이터베이스 URL을 통해, 아이디/패스워드를 사용해 로그인하겠다는 설정들이 담겨 있다.

```yml
spring:
  config:
    activate:
      on-profile: prd
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://${DATABASE_HOST}:3306/${DATABASE_NAME}?serverTimezone=Asia/Seoul&character_set_server=utf8mb4
    username: ${USERNAME}
    password: ${PASSWORD}
```

그런데 보다보면 `${}` 이런 형태로 값을 사용하는 부분이 있다.이는 [property placeholder](https://docs.spring.io/spring-boot/reference/features/external-config.html#features.external-config.files.property-placeholders) 라고 불리며 (혹은 interpolation), 이미 정의된 application.yml, jvm property, 혹은 system property(OS) 에서 값을 가져와 사용할 수 있다. 

![](2022-08-14-22-45-07.png)

### 1.2 JVM property
Java의 jar 파일은 다음과 같은 형태로 실행할 수 있다.

```sh
java -jar MY_PROJECT-0.0.1.jar
```

이 때, `-D` 를 이용해 `JVM` 의 `System property`를 설정할 수 있다. 이 `property`는 스프링에게까지 전달되며, 스프링에 대한 옵션을 지정할 수 있다. 일례로, 다음과 같이 실행하여 스프링의 기본 포트인 `8080`을 `8181`로 수정할 수 있다. 

```bash
java -jar -Dserver.port=8181 MY_PROJECT-0.0.1.jar
```

그렇다면, 이런식으로 위에서 보았던 `profile`도 설정해줄 수 있으리라고 짐작할 수 있다. 즉, 다음과 같이 실행한다.

```bash
java -jar -DSpring.profiles.active=prd MY_PROJECT-0.0.1.jar
```

스프링의 설정은 대부분 **"구체적일수록"** 우선권을 가진다. `application.yml` 에 설정한 `local`보다, 실행할 때 지정해준 `prd` 가 더 구체적이기 때문에, 최종 active 는 `prd` 가 된다.

![](2022-08-14-22-57-17.png)

이렇게 우리는 clone해온 코드에 한 줄도 고치지 않고 환경을 바꿔가며 실행할 수 있다.

### 1.3 환경변수

어플리케이션을 배포하는 방법에는 여러가지가 있겠지만, 가장 간단한 방법은 쉘스크립트를 작성하는 것이다. 위에서 작성한 명령어에 몇 줄을 추가하여 쉘 스크립트를 작성해보겠다.

```bash
export DATABASE_HOST=192.168.XXX.XXX
export DATABASE_NAME=my_database
export USERNAME=my_username
export PASSWORD=mypassword

java -jar -DSpring.profiles.active=prd MY_PROJECT-0.0.1.jar
```

위와같이 작성한뒤, 스크립트를 실행하면 앞서 yml 파일에서 작성했던 `${DATABASE_HOST}` 와 같은 부분이 작성한 `192.168.XXX.XXX` 로 변해서 실행되는 것을 확인할 수 있다. 


## Platform
: 데이터베이스 스키마, 혹은 데이터 또한 상황에 따라 나눌 수 있다. 위 예시와 같이 `production`과 `local` 환경에 따라 기존 테이블을 drop할지 말지, 혹은 더미 데이터를 넣어둘지 말지 등을 결정할 수 있다. 혹은, A 밴더사의 RDBMS에서 제공하는 SQL 문법이 B 밴더사의 RDBMS 에서 동작하지 않을 수 있는 경우도 있다.

이러한 경우에 활용할 수 있는 것이 바로 [platform](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto.data-initialization.using-basic-sql-scripts) 이다.

스프링은 구동시 classpath(여기서는 `src/main/resources` 혹은 `src/test/resources`)로부터 `schema.sql`, 혹은 `data.sql` 로부터 DDL을 읽어와 실행한다. 

그리고 이 때, 위 `application-${env}.yml` 과 마찬가지로, `schema-${platform}.sql` 혹은 `data-${platform}.sql` 의 형태로 내가 지정한 `platform` 에 맞는 DDL을 읽어올 수 있다. 다음은 사용 예시이다.

```yml
spring:
  sql:
    init:
      platform: local
      mode: always
```

위처럼 `platform`을 `local` 이라고 설정해두면, `schema-local.sql`, `data-local.sql` 을 찾아 실행하게 된다.

그 아래에 있는 `mode`에는 `never`, `embedded`, `always`의 세 가지 옵션이 있다. 각각의 이름에서 유추할 수 있듯이, DDL 스크립트로부터 초기화하지 않으려면 `never`를, embedded(in-memory)인 경우에만 초기화하려면 `embedded`, 항상 초기화하려면 `always`	를 사용하면 된다.

> 단, 이 때 DDL 스크립트가 비어있으면 안된다. 아예 파일 자체가 존재하지 않는건 괜찮지만, DDL 스크립트가 비어있으면 스프링을 구동하는 도중 예외를 던진다.

역시 `profile`과 마찬가지로 스프링 실행시 `System property` 로 설정할 수도 있다. (`-Dspring.sql.init.platform=local`) 또한, `profile`과 적절히 조합하여 특정 profile에 걸맞는 DDL 을 실행할 수도 있다.


