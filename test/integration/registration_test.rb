require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  test "authentication pages render branded forms and navigation" do
    get new_user_session_path
    assert_response :success
    assert_select "body.public-page--auth"
    assert_select "form[action='#{user_session_path}'] input[autocomplete='current-password']"
    assert_select "a[href='#{new_user_registration_path}']", "Зарегистрироваться"
    assert_select ".site-footer"

    get new_user_registration_path
    assert_response :success
    assert_select "body.public-page--auth"
    assert_select "input[name='user[display_name]'][required]"
    assert_select "input[aria-describedby='password-hint']"
    assert_select "a[href='#{new_user_session_path}']", "Войти"
  end

  test "invalid sign in displays feedback in the styled form" do
    post user_session_path, params: { user: { email: "unknown@example.test", password: "incorrect" } }
    assert_response :unprocessable_content
    assert_select "body.public-page--auth"
    assert_select ".auth-message[role='alert']"
  end

  test "registration saves profile and ignores supplied role" do
    post user_registration_path, params: { user: { email: "registration@example.test",
      password: "password123", password_confirmation: "password123", display_name: "Имя", role: "admin" } }
    assert_response :redirect
    user = User.find_by!(email: "registration@example.test")
    assert_equal "reader", user.role
    assert_equal "Имя", user.profile.display_name
  end

  test "registration without display name does not create an account" do
    assert_no_difference [ "User.count", "Profile.count" ] do
      post user_registration_path, params: { user: { email: "invalid@example.test",
        password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_content
  end
end
