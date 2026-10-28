# Вектор

Ruby 4.0.7, Rails 8.1.4, SQLite, Devise.

## Запуск

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

`/`, `/index.html` и `/about.html` открыты без авторизации. Главная содержит ссылку «О проекте» и форму сбора email. Регистрация: `/users/sign_up`, вход: `/users/sign_in`.

## Администрирование

`/admin` доступен только пользователям с ролью `admin`.


