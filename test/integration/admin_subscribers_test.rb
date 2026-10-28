require "test_helper"

class AdminSubscribersTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "subscriber list is restricted to administrators" do
    get admin_subscribers_path
    assert_redirected_to new_user_session_path

    %w[reader editor].each do |role|
      sign_in User.create!(email: "#{role}@example.test", password: "password123", display_name: role, role: role)
      get admin_subscribers_path
      assert_response :forbidden
    end
  end

  test "administrator sees subscriber addresses and dates" do
    sign_in_admin
    get admin_subscribers_path
    assert_response :success
    assert_select ".admin-empty", text: /Пока нет подписчиков/

    NewsletterSubscriber.create!(email: "active@example.test", personal_data_consent_at: Time.current, marketing_consent_at: Time.current)
    NewsletterSubscriber.create!(email: "no-consent@example.test", personal_data_consent_at: Time.current)
    NewsletterSubscriber.create!(email: "unsubscribed@example.test", personal_data_consent_at: Time.current,
      marketing_consent_at: Time.current, unsubscribed_at: Time.current)

    get admin_subscribers_path
    assert_response :success
    assert_select "a[aria-current='page'][href='#{admin_subscribers_path}']"
    assert_select "tbody tr", count: 3
    assert_select "tbody tr:first-child", text: /unsubscribed@example.test/
    assert_select "tbody tr", text: /no-consent@example.test/
    assert_select "tbody tr", text: /active@example.test/
    assert_select "time[datetime]", count: 3
    assert_select "thead th", count: 3
    assert_select ".admin-subscriber-status", count: 0
  end

  test "subscriber list paginates with newest entries first" do
    sign_in_admin
    31.times do |i|
      NewsletterSubscriber.create!(email: "subscriber#{i}@example.test", personal_data_consent_at: Time.current)
    end
    get admin_subscribers_path
    assert_select "tbody tr", count: 30
    assert_select "tbody tr:first-child", text: /subscriber30@example.test/
    assert_select "a[href=?]", admin_subscribers_path(page: 2), text: "Далее →"

    get admin_subscribers_path(page: 2)
    assert_select "tbody tr", count: 1
    assert_select "tbody tr", text: /subscriber0@example.test/
    assert_select "a", text: "Далее →", count: 0
  end

  private

  def sign_in_admin
    sign_in User.create!(email: "admin@example.test", password: "password123", display_name: "Admin", role: "admin")
  end
end
