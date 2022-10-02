


----
scheduled + transactional

scheduled를 서비스에 걸었더니 트랜잭셔널이 안걸렸다.
-> 찾아보니까 scheduled가 먼저 처리되더라(왜?)
-> 그래서 scheduled를 별도로 분리했는데, transcational 이 안먹힘
-> 로깅을 찍어봤음.
	-> 트랜잭셔널이 안먹히고 있었음.
	-> SimpleJpaRepository를 상속하고있었음. 왜 ?
	-> 조회할때는 transaction이 필요가 없었음.
-> 왜 안먹힐까... 게다가 이미 JpaTransactionalManagment?인가 그걸 쓰고있었음(DataSoure가 아니고)
-> 알고보니 trnasctional이 public 이어야했음 시발.




---메모

1.formula를 얻기위해 flush를 해야하는이유
2. 트랜잭셔널 + 스케쥴드 왜 동작을 안할까?
게다가 트랜잭셔널없이 쿼리가 어떻게 나갈까? 그리고 왜 findbyid는 트랜잭셔널이 자동으로 생길까? 

1.동일성
2. simplejparepository

--
+ repo를 상속했는데 왜심플 로그가 나올까?
왜 스케쥴드가먼저처리될까?

--
poll.doPoll 이후 발생하는 예외는 트랜잭션에서 발생하는 예외이기 때문에 rollbackexception으로 감싸진다

--

별도 스레드에서 도는게 뭐길래 트랜잭션이안걸려

--

조회로직은 transaction이 필요없다. + transctional 바깥에서 동작하는 JPA ?
https://stackoverflow.com/a/21673304/11686638

--

--

`bean validation`
https://docs.jboss.org/hibernate/stable/validator/reference/en-US/html_single/#section-validating-bean-constraints

---


jpa 베이직
http://java.boot.by/scbcd5-guide/ch06.html
---레퍼런스
트랜잭션쓸때 실수
1. 자기자신 메소드 호출할때 트랜잭션 안걸린다
2. rollbackfor를 런타임으로 잡으면 안좋다
3. 격리레벨과 전파를 신중하게써라

https://medium.com/javarevisited/spring-transactional-mistakes-everyone-did-31418e5a6d6b

그냥 참고용
https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#transactional-query-methods	

---

https://docs.spring.io/spring-framework/docs/current/reference/html/data-access.html#transaction-declarative-annotations-method-visibility

이거네 시발
---

[2022-08-21 03:29:00:3322][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Creating new transaction with name [org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT
[2022-08-21 03:29:00:3323][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Opened new EntityManager [SessionImpl(1970721103<open>)] for JPA transaction
[2022-08-21 03:29:00:3324][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Exposing JPA transaction as JDBC [org.springframework.orm.jpa.vendor.HibernateJpaDialect$HibernateConnectionHandle@145b8cfc]
Hibernate: 
    insert 
    into
        member
        (id, created_at, updated_at, name, oauth_id, profile_url) 
    values
        (default, ?, ?, ?, ?, ?)
[2022-08-21 03:29:00:3364][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Initiating transaction commit
[2022-08-21 03:29:00:3364][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Committing JPA transaction on EntityManager [SessionImpl(1970721103<open>)]
[2022-08-21 03:29:00:3367][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Closing JPA EntityManager [SessionImpl(1970721103<open>)] after transaction
[2022-08-21 03:29:00:3368][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Creating new transaction with name [org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT
[2022-08-21 03:29:00:3368][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Opened new EntityManager [SessionImpl(1417779789<open>)] for JPA transaction
[2022-08-21 03:29:00:3368][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Exposing JPA transaction as JDBC [org.springframework.orm.jpa.vendor.HibernateJpaDialect$HibernateConnectionHandle@d89b31e]
Hibernate: 
    insert 
    into
        team
        (id, created_at, updated_at, code, name) 
    values
        (default, ?, ?, ?, ?)
[2022-08-21 03:29:00:3372][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Initiating transaction commit
[2022-08-21 03:29:00:3372][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Committing JPA transaction on EntityManager [SessionImpl(1417779789<open>)]
[2022-08-21 03:29:00:3373][scheduled-task-pool-1] DEBUG o.s.orm.jpa.JpaTransactionManager - Closing JPA EntityManager [SessionImpl(1417779789<open>)] after transaction
[2022-08-21 03:29:00:3373][scheduled-task-pool-1] ERROR o.s.s.s.TaskUtils$LoggingErrorHandler - Unexpected error occurred in scheduled task
java.lang.RuntimeException: RUNTIME!!

트랜잭션이 다르기때문에, 엔티티매니저를 새로 열고 닫았다가 한다..



------

AbstractAutowireCapableBeanFactory - 450
여기서 Bean 생성하고 나서, postprocess를 해줌

그 processor중 하나가 얘

AbstractAdvisorAutoProxyCreator
얘가 PostProcessor인데, Transactional이 걸려있으면 처리해줌

그리고 proceesor list 중, 14번째에는 scheduled 관련해서 postprocessor를 처리해줌

근데 왜 안될까 ?

scheduled 는 별도 스레드에서 요청이 날아옴.. event 기반 ?
