# Вектор — модель данных и задание для Codex

## Задача

Создай с нуля Rails-проект для медиа-сервиса «Вектор» и реализуй модель данных ниже: миграции, модели, связи ActiveRecord, внешние ключи, индексы, валидации и сиды. Исходной базы данных и старого кода нет. Используй доступную совместимую версию Rails/Ruby, SQLite для локальной разработки и Devise для авторизации. Если приложение уже создано в текущей рабочей папке в ходе этой задачи, продолжай в нём, не создавай вложенный второй проект. Сначала реализуй данные и их проверку; дизайн интерфейса — отдельная задача.

## Основание и границы

Модель составлена по прочитанному прототипу Figma 27.10.2026:

- Файл: https://www.figma.com/design/2Cb4FmSTtlxhHIKNA4Ul6Q
- Десктопный прототип: node-id=96-10.
- Мобильный прототип: node-id=417-1032.
- Существующий черновик модели: node-id=105-3.
- Статьи: 270:241; статья: 283:403.
- Профиль: 209:286; подробности траектории: 258:628.
- Интерактивы: 294:627; вопросы теста и экран результата: 356:318–384:1132.
- Заглушка со сбором email: 145:79.

Подтверждённые интерфейсом функции: статьи с автором, датой и фильтрами; поиск; тесты с одним ответом, переходами назад/вперёд и результатом; профиль с именем, аватаром и статусом; вкладки траекторий, подписок, лайков и комментариев; несколько траекторий поступления; вуз, факультет, программа, способ и год поступления; дедлайны с отметкой выполнения; сбор email до запуска. Есть карточка интерактива «ВУЗы Москвы: дизайн» и пункт «сообщество», но подробные механики этих разделов не показаны.

Названия таблиц, нормализация, ограничения и поведение удаления ниже — проектные решения для реализации этих функций. Они не являются извлечённой из Figma готовой схемой базы. В частности, подписки трактуются как подписки на категории; лайки и комментарии — как действия со статьями.

## Общие правила

- Для локальной разработки используй SQLite; версии Rails/Ruby должны быть совместимы с выбранной версией Devise.
- Для новых таблиц: id: bigint, created_at: datetime, updated_at: datetime. Эти поля подразумеваются в каждой модели ниже.
- Тип каждого внешнего ключа должен совпадать с типом связанного первичного ключа с учётом отображения типов в SQLite.
- Все поля обязательны (NOT NULL), кроме помеченных `nullable`. Пустая строка не заменяет обязательное значение: добавь presence-валидации.
- Все *_id — настоящие внешние ключи с индексами. Уникальные сочетания защищай и в модели, и уникальным индексом БД.
- Справочники и используемый опубликованный контент архивируй или запрещай удалять при наличии зависимостей. Не удаляй пользовательские маршруты при удалении вуза.
- В enum храни string с указанным набором значений. Добавь default и проверку включения; ограничения БД используй, если поддерживаются текущим адаптером.
- Названия моделей ниже — целевые имена для нового проекта.

## 1. Пользователь и профиль

### User / users

```text
email: string, unique
role: string, default "reader"; reader | editor | admin
```

Для авторизации используй Devise: database_authenticatable, registerable, recoverable, rememberable, validatable. Поля encrypted_password, reset_password_token, reset_password_sent_at и remember_created_at создавай через Devise. Не добавляй password_digest и вторую систему авторизации. Username не нужен: отображаемое имя хранится в Profile.

Связи:

```ruby
has_one :profile, dependent: :destroy
has_many :articles, dependent: :restrict_with_error
has_many :comments, dependent: :destroy
has_many :article_likes, dependent: :destroy
has_many :liked_articles, through: :article_likes, source: :article
has_many :category_subscriptions, dependent: :destroy
has_many :subscribed_categories, through: :category_subscriptions, source: :category
has_many :admission_routes, dependent: :destroy
has_many :quiz_attempts, dependent: :nullify
```

### Profile / profiles

```text
user_id: FK users, unique
display_name: string
avatar_url: string, nullable
bio: text, nullable
audience_stage: string, default "applicant"; school_student | applicant | first_year_student
```

Связь: `belongs_to :user`. Роль доступа хранится в User, статус «абитуриент» — в Profile. Один пользователь имеет один профиль. Создание пользователя и его профиля выполняй согласованно в транзакции; имя запрашивай при регистрации.

## 2. Статьи, фильтры и действия читателя

### Article / articles

```text
user_id: FK users — автор
category_id: FK categories
title: string
body: text
excerpt: text, nullable
cover_url: string, nullable
published: boolean, default false
published_at: datetime, nullable для черновика
```

Связи:

```ruby
belongs_to :user
belongs_to :category
has_many :article_tags, dependent: :destroy
has_many :tags, through: :article_tags
has_many :comments, dependent: :destroy
has_many :article_likes, dependent: :destroy
has_many :liking_users, through: :article_likes, source: :user
```

В публичной выдаче показывать published=true и published_at <= текущее время. Для опубликованной статьи published_at обязателен.

Содержание статьи строить из заголовков body. Отдельную таблицу для каждого абзаца или пункта содержания не создавать. Для первого варианта body хранит Markdown; при отображении преобразовывай его в безопасный HTML.

### Category / categories

```text
name: string, unique
slug: string, unique
```

Связи: `has_many :articles, dependent: :restrict_with_error`; `has_many :category_subscriptions, dependent: :destroy`; `has_many :subscribers, through: :category_subscriptions, source: :user`.

Проектное решение: у статьи одна основная категория. Примеры категорий из фильтров: документы, миграционные вопросы, университеты, быт.

### Tag / tags

```text
name: string, unique
slug: string, unique
```

Связи: `has_many :article_tags, dependent: :destroy`; `has_many :articles, through: :article_tags`.

Для дополнительных фильтров, например «Москва», «Санкт-Петербург». Город университета отдельно хранится в University.city; тег фильтра статьи не заменяет эти данные.

### ArticleTag / article_tags

```text
article_id: FK articles
tag_id: FK tags
unique(article_id, tag_id)
```

Связи: `belongs_to :article`; `belongs_to :tag`.

### Comment / comments

```text
user_id: FK users
article_id: FK articles
body: text
```

Связи: `belongs_to :user`; `belongs_to :article`. Вкладка профиля получает комментарии через current_user.comments. Вложенные ответы пока не нужны: они не показаны в прототипе.

### ArticleLike / article_likes

```text
user_id: FK users
article_id: FK articles
unique(user_id, article_id)
```

Связи: `belongs_to :user`; `belongs_to :article`. Повторный лайк не создаёт дубликат. Снятие лайка удаляет только эту связь. Счётчик выводить по связям; отдельный вручную изменяемый likes_count не нужен.

### CategorySubscription / category_subscriptions

```text
user_id: FK users
category_id: FK categories
unique(user_id, category_id)
```

Связи: `belongs_to :user`; `belongs_to :category`. Это подписка на тему. Она не означает согласия на email-рассылку.

Поиск и фильтрация статей — запросы к Article, Category и Tag. Отдельные модели Search, Filter, ArticleCard и Feed не создавать. Назначение статьи автору само по себе не даёт права редактора.

## 3. Траектории поступления и дедлайны

Цепочка справочников: University → Faculty → EducationalProgram. Доступный вариант поступления задаётся сочетанием программы, способа и года. Пользователь выбирает такой вариант и получает собственный маршрут с личными отметками выполнения.

### University / universities

```text
name: string
short_name: string, nullable
city: string
description: text, nullable
website_url: string, nullable
cover_url: string, nullable
```

Связи: `has_many :faculties, dependent: :restrict_with_error`; `has_many :educational_programs, through: :faculties`.

### Faculty / faculties

```text
university_id: FK universities
name: string
unique(university_id, name)
```

Связи: `belongs_to :university`; `has_many :educational_programs, dependent: :restrict_with_error`.

### EducationalProgram / educational_programs

```text
faculty_id: FK faculties
name: string
description: text, nullable
website_url: string, nullable
unique(faculty_id, name)
```

Связи: `belongs_to :faculty`; `has_one :university, through: :faculty`; `has_many :admission_options, dependent: :restrict_with_error`.

### AdmissionMethod / admission_methods

```text
name: string, unique
description: text, nullable
```

Связь: `has_many :admission_options, dependent: :restrict_with_error`.

Примеры из макета: вступительные испытания, ЕГЭ, квота, конкретная олимпиада. Способ не хранить только строкой в профиле: один способ может быть доступен для нескольких программ.

### AdmissionOption / admission_options

```text
educational_program_id: FK educational_programs
admission_method_id: FK admission_methods
admission_year: integer
source_url: string, nullable
verified_at: datetime, nullable
unique(educational_program_id, admission_method_id, admission_year)
```

Связи: `belongs_to :educational_program`; `belongs_to :admission_method`; `has_many :deadlines, dependent: :restrict_with_error`; `has_many :admission_routes, dependent: :restrict_with_error`.

Эта таблица связывает допустимые варианты. Нельзя разрешать выбрать для программы произвольный способ, отсутствующий в admission_options. Год кампании отделён от календарного года дедлайна: поступление в 2027 может иметь регистрацию в 2026.

### Deadline / deadlines

```text
admission_option_id: FK admission_options
title: string
description: text, nullable
due_on: date
position: integer, default 0
source_url: string, nullable
verified_at: datetime, nullable
```

Связи: `belongs_to :admission_option`; `has_many :route_tasks, dependent: :restrict_with_error`.

due_on — календарная дата без выдуманного точного времени. Если позже потребуется время закрытия приёма, добавить отдельное поле с часовым поясом по подтверждённому требованию. Один вариант поступления имеет много дедлайнов.

### AdmissionRoute / admission_routes

```text
user_id: FK users
admission_option_id: FK admission_options
unique(user_id, admission_option_id)
```

Связи:

```ruby
belongs_to :user
belongs_to :admission_option
has_many :route_tasks, dependent: :destroy
has_many :deadlines, through: :route_tasks
```

Один пользователь может иметь несколько маршрутов. Вуз, факультет, программа, год и способ на экране маршрута берутся через admission_option. Эти поля не дублировать в profiles и admission_routes.

### RouteTask / route_tasks

```text
admission_route_id: FK admission_routes
deadline_id: FK deadlines
completed_at: datetime, nullable
unique(admission_route_id, deadline_id)
```

Связи: `belongs_to :admission_route`; `belongs_to :deadline`.

Флажок на экране — completed_at.present?. Снятие флажка обнуляет completed_at. Поле completed:boolean дополнительно не нужно.

Обязательная валидация: deadline.admission_option_id должен совпадать с admission_route.admission_option_id. Внешние ключи по отдельности это соответствие не обеспечивают. Проверять в модели/сервисе; если адаптер позволяет, дополнительно обеспечить составными внешними ключами.

Сервис создания маршрута в транзакции создаёт AdmissionRoute и RouteTask для каждого Deadline выбранного AdmissionOption. Повторный вызов не создаёт дублей. При добавлении нового дедлайна создавать недостающие RouteTask для существующих маршрутов этого варианта, сохраняя выполненные отметки. Обновление даты дедлайна видно всем маршрутам, а отметки выполнения принадлежат каждому пользователю отдельно.

Не разрешать менять admission_option_id у уже созданного маршрута или дедлайна с зависимыми задачами: для другого варианта создаётся новый маршрут/дедлайн. Просроченность вычислять из due_on и completed_at, не хранить отдельным флагом.

## 4. Тесты

### Quiz / quizzes

```text
title: string
description: text, nullable
cover_url: string, nullable
article_id: FK articles, nullable
published: boolean, default false
```

Связи: `belongs_to :article, optional: true`; `has_many :quiz_questions, dependent: :restrict_with_error`; `has_many :quiz_attempts, dependent: :restrict_with_error`.

Статья — необязательный материал для перехода после теста; у статьи может быть несколько тестов (`has_many :quizzes, dependent: :nullify`). Число вопросов в карточке вычисляется из quiz_questions, не задаётся вручную.

### QuizQuestion / quiz_questions

```text
quiz_id: FK quizzes
body: text
position: integer
explanation: text, nullable
unique(quiz_id, position)
```

Связи: `belongs_to :quiz`; `has_many :answer_options, dependent: :destroy`; `has_many :quiz_answers, dependent: :restrict_with_error`.

### AnswerOption / answer_options

```text
quiz_question_id: FK quiz_questions
body: text
position: integer
correct: boolean, default false
unique(quiz_question_id, position)
```

Связи: `belongs_to :quiz_question`; `has_many :quiz_answers, dependent: :restrict_with_error`.

В прототипе один правильный ответ. Перед публикацией теста проверять: есть хотя бы один вопрос, у каждого минимум два варианта и ровно один правильный. Тест может иметь 4 варианта или 2 для формата «правда/ложь». Число 10 не зашивать в код: в каталоге есть тест на 6 вопросов.

### QuizAttempt / quiz_attempts

```text
quiz_id: FK quizzes
user_id: FK users, nullable
guest_token_digest: string, nullable
started_at: datetime
completed_at: datetime, nullable
```

Связи: `belongs_to :quiz`; `belongs_to :user, optional: true`; `has_many :quiz_answers, dependent: :destroy`.

Прототип не показывает обязательный вход перед тестом, поэтому разрешить гостевое прохождение. Для гостя выдавать случайный токен в защищённой сессии, хранить только digest, добавить уникальный индекс на ненулевой guest_token_digest. Без авторизации или подходящего токена читать/менять чужую попытку нельзя. После удаления пользователя его попытки могут остаться обезличенными и недоступными для продолжения.

### QuizAnswer / quiz_answers

```text
quiz_attempt_id: FK quiz_attempts
quiz_question_id: FK quiz_questions
answer_option_id: FK answer_options
unique(quiz_attempt_id, quiz_question_id)
```

Связи: `belongs_to :quiz_attempt`; `belongs_to :quiz_question`; `belongs_to :answer_option`.

Проверки: вопрос относится к тесту попытки; выбранный вариант относится к этому вопросу. При возврате назад изменяется существующий ответ, дубликат не создаётся. Завершённая попытка неизменяема; «пройти заново» создаёт новую.

Результат вычислять на сервере: количество выбранных правильных вариантов / количество вопросов. Завершение и запись последнего ответа выполнять согласованно в транзакции; завершать только после ответа на все вопросы. Не принимать результат и correct от клиента и не включать correct в публичный ответ API до завершения.

После появления попыток запретить изменение вопросов, порядка и вариантов теста, влияющее на результат; для новой редакции создавать копию Quiz. Иначе старые результаты пересчитаются по новым ответам. Обычные опечатки можно исправлять, если смысл и правильность не меняются.

## 5. Сбор email

### NewsletterSubscriber / newsletter_subscribers

```text
email: string, unique
personal_data_consent_at: datetime
marketing_consent_at: datetime, nullable
unsubscribed_at: datetime, nullable
```

Самостоятельная сущность: оставить email может человек без аккаунта. Email нормализовать до сохранения (strip и lowercase); обеспечить уникальность нормализованного значения. Отдельно фиксировать два флажка из макета. Значения времени согласия выставлять на сервере по явно переданным отметкам формы, не проставлять согласие по умолчанию. Активен для рассылки только адрес с marketing_consent_at и без unsubscribed_at. Подписка на категорию не создаёт согласие на рассылку. Повторная отправка email не должна снимать отписку без нового явного согласия.

В Profile не добавлять дублирующий boolean email-подписки. В рамках этой задачи реальные письма не отправлять.

## 6. Что пока не реализовывать

Эти части обозначены, но их подробные экраны и сценарии не показаны. Не добавлять их автоматически вместе с основными моделями.

- Сообщество: при реализации каталога внешних чатов достаточно CommunityLink(name:string, description:text nullable, url:string, university_id:FK nullable). Это ссылки, а не форум и не собственный мессенджер.
- Карточки вузов: данные самих вузов брать из University. Если интерактив — подборка, добавить UniversityCollection(title:string, description:text nullable, published:boolean default false) и CollectionUniversity(university_collection_id:FK, university_id:FK, position:integer, unique(university_collection_id, university_id)). Точный сценарий требует отдельного решения.
- Калькулятор цен, мероприятия, уведомления, избранные статьи, ответы на комментарии, отдельная форма заявки в команду: не добавлять без уточнения сценария.
- «О нас», шапка, футер, кнопки, поисковая строка, табы профиля, состояния hover/pressed и мобильная версия не являются отдельными моделями БД.
- Не создавать универсальную polymorphic-таблицу для всех интерактивов: сейчас показаны тесты и одна карточка подборки, этого недостаточно для общей архитектуры.

## 7. Соответствие экранов данным

| Экран | Источник данных |
| --- | --- |
| Каталог статей, поиск, фильтры | Article + Category + Tag через ArticleTag |
| Статья и автор | Article → User → Profile |
| Профиль: имя, фото, статус | User → Profile |
| Профиль: лайки | User → ArticleLike → Article |
| Профиль: комментарии | User → Comment → Article |
| Профиль: подписки | User → CategorySubscription → Category |
| Карточки траекторий | User → AdmissionRoute → AdmissionOption → EducationalProgram |
| Вуз и факультет маршрута | EducationalProgram → Faculty → University |
| Способ и год | AdmissionOption → AdmissionMethod; AdmissionOption.admission_year |
| Дедлайны и личные отметки | AdmissionRoute → RouteTask → Deadline |
| Каталог тестов | Quiz + число QuizQuestion |
| Вопрос и варианты | QuizQuestion → AnswerOption |
| Выбранный ответ | QuizAttempt → QuizAnswer → AnswerOption |
| Результат | QuizAttempt + QuizAnswer + AnswerOption.correct |
| Заглушка: сбор email | NewsletterSubscriber |

## 8. Порядок реализации

1. Прочитай AGENTS.md, если он есть. Проверь доступные Ruby/Rails и совместимость зависимостей. Создай приложение в рабочей папке; если она непустая, не перезаписывай посторонние файлы.
2. Подключи Devise и создай User. Затем создай Profile и регистрацию с display_name. Роль reader назначается сервером.
3. Создай модели в порядке зависимостей: пользователи и профиль; категории и теги; статьи и связи; справочники вузов и поступления; маршруты; тесты; сбор email.
4. Создай миграции с индексами, внешними ключами и ограничениями; добавь связи и валидации моделей.
5. Явно настрой dependent на обеих сторонах по смыслу. На уровне БД не используй каскадное удаление там, где модель требует restrict. Удаление пользователя с авторскими статьями блокируется; удаление аккаунта автора с сохранением статей требует отдельного сценария переназначения.
6. Реализуй сервис создания маршрута и сервис прохождения теста. Персональные связи меняй только для current_user; автора статьи и роли не принимай от обычного пользователя через mass assignment.
7. Для пользовательского маршрута scopes/контроллеры должны выбирать запись через current_user.admission_routes. Аналогично для комментариев, лайков и подписок. Справочники и редакционные данные меняют только соответствующие роли.
8. Создай seeds идемпотентно: повторный запуск не должен очищать БД или создавать дубликаты. Используй find_or_create_by!/find_or_initialize_by и стабильные ключи.
9. Запусти миграции и релевантные проверки. В конце перечисли изменённые файлы, созданные связи, результаты проверок и команды для локального запуска.

## 9. Тестовые данные и проверка результата

Используй явно помеченные демонстрационные данные: вуз → факультет → программа; способ → вариант поступления → несколько дедлайнов; два пользователя с маршрутом к одному варианту; статьи с категориями и тегами; лайк, комментарий и подписку; один тест с вопросами и вариантами; пользовательскую и гостевую попытки. Даты в Figma — пример макета, а не проверенные сроки приёма. Не публикуй их как реальные требования вузов.

Проверь поведением, а не только наличием таблиц:

- У пользователя не возникает второго профиля, повторного лайка, подписки или одинакового маршрута.
- У одного пользователя может быть несколько разных маршрутов.
- Отметка дедлайна в маршруте первого пользователя не меняет маршрут второго.
- Нельзя привязать задачу к дедлайну другого варианта поступления.
- Новый дедлайн появляется у существующих маршрутов без потери отметок.
- Нельзя ответить вариантом от другого вопроса или вопросом другого теста.
- Возврат назад обновляет ответ; результат вычисляется сервером; повторное прохождение создаёт новую попытку.
- Гость не получает доступ к чужой попытке по одному id.
- Черновики статей и тестов не попадают в публичную выдачу.
- Сиды запускаются повторно без дубликатов и удаления существующих данных.

Критерий готовности: новый проект создан, миграции применены, связи ActiveRecord работают, данные сохраняются и целевые сценарии проверены. Сам файл модели не означает, что миграции уже выполнены.
