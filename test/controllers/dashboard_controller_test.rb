require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "show when authenticated" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
  end

  test "show redirects when not authenticated" do
    get root_path
    assert_redirected_to new_session_path
  end
end
