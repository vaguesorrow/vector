require "test_helper"

class SubscribersTest < ActionDispatch::IntegrationTest
  test "home page offers a public subscription form with unchecked consent" do
    get root_path
    assert_response :success
    assert_select "form[action=?][method=post]", subscribers_path
    assert_select "input[type=email][name=email][required]"
    assert_select "input[type=checkbox][name=consent][required]:not([checked])"
    assert_select "input[type=checkbox][name=marketing_consent]:not([required]):not([checked])"
  end

  test "guest subscribes and sees confirmation" do
    assert_difference "NewsletterSubscriber.count", 1 do
      post subscribers_path, params: { email: " EXAMPLE@Mail.ru ", consent: "1" }
    end
    assert_equal "example@mail.ru", NewsletterSubscriber.last.email
    assert NewsletterSubscriber.last.personal_data_consent_at.present?
    assert_nil NewsletterSubscriber.last.marketing_consent_at
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", "Спасибо! Вы подписались."
  end

  test "marketing consent is recorded only when explicitly selected" do
    post subscribers_path, params: { email: "marketing@example.test", consent: "1", marketing_consent: "1",
      personal_data_consent_at: "2000-01-01", marketing_consent_at: "2000-01-01" }
    subscriber = NewsletterSubscriber.find_by!(email: "marketing@example.test")
    assert_in_delta Time.current.to_i, subscriber.personal_data_consent_at.to_i, 5
    assert_in_delta Time.current.to_i, subscriber.marketing_consent_at.to_i, 5
    assert_no_difference "NewsletterSubscriber.count" do
      post subscribers_path, params: { email: "rejected@example.test", marketing_consent: "1" }
    end
  end

  test "consent is required on the server" do
    [ nil, "0", "true" ].each do |consent|
      assert_no_difference "NewsletterSubscriber.count" do
        post subscribers_path, params: { email: "example@mail.ru", consent: consent }
      end
      follow_redirect!
      assert_select "[role=alert]", "Нужно согласие на обработку данных."
    end
  end

  test "invalid addresses are rejected" do
    [ "", "invalid" ].each do |email|
      assert_no_difference "NewsletterSubscriber.count" do
        post subscribers_path, params: { email: email, consent: "1" }
      end
      follow_redirect!
      assert_select "[role=alert]", "Не удалось подписаться. Проверьте адрес."
    end
  end

  test "duplicate address displays an already subscribed notice" do
    subscriber = NewsletterSubscriber.subscribe!(email: "example@mail.ru", personal_data_consent: true)
    assert_no_difference "NewsletterSubscriber.count" do
      post subscribers_path, params: { email: " EXAMPLE@MAIL.RU ", consent: "1" }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", "Вы уже подписались на уведомления"
    assert_select "[role=alert]", count: 0
    assert_nil subscriber.reload.marketing_consent_at
    assert_raises(ActiveRecord::RecordNotUnique) do
      NewsletterSubscriber.insert_all!([ { email: "example@mail.ru", personal_data_consent_at: Time.current } ])
    end
  end

  test "only explicit marketing consent restores an unsubscribed address" do
    subscriber = NewsletterSubscriber.subscribe!(email: "return@example.test", personal_data_consent: true,
      marketing_consent: true)
    subscriber.update!(unsubscribed_at: Time.current)

    post subscribers_path, params: { email: " RETURN@example.test ", consent: "1" }
    assert subscriber.reload.unsubscribed_at
    assert_not NewsletterSubscriber.active.exists?(subscriber.id)

    assert_no_difference "NewsletterSubscriber.count" do
      post subscribers_path, params: { email: " RETURN@example.test ", consent: "1", marketing_consent: "1" }
    end
    assert_nil subscriber.reload.unsubscribed_at
    assert NewsletterSubscriber.active.exists?(subscriber.id)
  end
end
