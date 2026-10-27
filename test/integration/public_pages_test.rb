require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "public pages open without signing in" do
    [ root_path, index_path ].each do |path|
      get path
      assert_response :success
      assert_select "a[href=?]", about_path, text: "о проекте"
      assert_select "a[href=?]", admin_root_path, count: 0
    end
    get about_path
    assert_response :success
    assert_select "h1", "я(мы) команда вектор"
    assert_select ".about-step", count: 3
    assert_select "a.about-button--start[href=?]", root_path
    assert_select "a.about-button--apply[href=?]", "https://t.me/vaguesorrow", text: /подать заявку/
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "admin sees the administration link on the public home page" do
    admin = User.create!(email: "public-admin@example.test", password: "password123", display_name: "Admin", role: "admin")
    sign_in admin
    get root_path
    assert_response :success
    assert_select "a[href=?]", admin_root_path, text: "Администрирование"
    get admin_root_path
    assert_response :success
  end
end
