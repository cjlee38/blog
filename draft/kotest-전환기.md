---
categories: kotlin
date: "2022-08-23T00:00:00Z"
tags: ['kotlin', 'kotest']
title: 'junit5 to kotest 전환기'
---
 
# 0. 서론
우아한테크코스 지원플랫폼은 코틀린으로 작성되어있습니다. 온보딩기간에 주어진 미션은 기존 Junit5 에서 kotest로 전환하는 것이었습니다.

Junit5 는 `J` 라는 이름에서 알 수 있듯이 자바진영에서 활용되고 있는 테스트 프레임워크입니다. 어노테이션 기반으로 간단하게 테스트를 작성할 수 있다는 장점은 있지만, DCI 패턴을 표현하기엔 충분하지 않습니다. (물론 Nested를 활용해 DCI 패턴을 구현할 수 있지만, 상당히 귀찮습니다. 링크 : 기계인간)

kotest는 코틀린 진영에서 0000개의 star를 받은 오픈소스 프로젝트로, 테스트 코드를 더욱 코틀린스러운 코드로 작성하기 위한 다양한 spec을 제공합니다.

간략한 kotest 소개와 함께 전환시 겪었던 문제들을 소개합니다.

# 1. kotest spec 소개
- annotation spec
- describe sepc
- behaviour spec

# 2. 스프링 연동
https://github.com/woowacourse/service-apply/issues/534

# 3. rest-docs 문제
manualDocumentation

# 4. 참고
https://techblog.woowahan.com/5825/
https://jaehhh.tistory.com/118

