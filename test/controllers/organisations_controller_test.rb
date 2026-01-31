require "test_helper"

class OrganisationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "should get index" do
    get organisations_path
    assert_response :success
  end

  test "should get new" do
    get new_organisation_path
    assert_response :success
  end

  test "should create organisation" do
    assert_difference "Organisation.count", 1 do
      post organisations_path, params: { organisation: { name: "New Org" } }
    end

    assert_redirected_to organisations_path
  end

  test "should show organisation" do
    get organisation_path(organisations(:one))
    assert_response :success
  end

  test "should get edit" do
    get edit_organisation_path(organisations(:one))
    assert_response :success
  end

  test "should update organisation" do
    org = organisations(:one)
    patch organisation_path(org), params: { organisation: { name: "Updated Name" } }
    assert_redirected_to organisation_path(org)
    assert_equal "Updated Name", org.reload.name
  end

  test "should not update organisation with blank name" do
    org = organisations(:one)
    patch organisation_path(org), params: { organisation: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy organisation" do
    org = organisations(:one)
    assert_difference "Organisation.count", -1 do
      delete organisation_path(org)
    end

    assert_redirected_to organisations_path
  end
end
