require "test_helper"

class RootRoutingTest < ActionDispatch::IntegrationTest
  test "authenticated users see organisations index" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
  end

  test "unauthenticated users see landing page" do
    get root_path
    assert_response :success
  end
end
