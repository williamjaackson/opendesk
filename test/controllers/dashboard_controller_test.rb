require "test_helper"

class RootRoutingTest < ActionDispatch::IntegrationTest
  test "authenticated users are redirected to organisations" do
    sign_in_as users(:one)
    get root_path
    assert_redirected_to organisations_path
  end

  test "unauthenticated users see landing page" do
    get root_path
    assert_response :success
  end
end
