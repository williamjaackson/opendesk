require "test_helper"

class InboxControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @user.update!(email_address: "two@example.com")
    sign_in_as @user

    @organisation = organisations(:one)
    @invite = @organisation.organisation_invites.create!(email: @user.email_address)
    @notification = Notification.find_by(user: @user, notifiable: @invite)
  end

  test "should get index" do
    get inbox_path
    assert_response :success
  end

  test "index shows notifications" do
    get inbox_path
    assert_response :success
    assert_select "li", minimum: 1
  end

  test "accept marks notification as read" do
    assert_nil @notification.read_at

    post accept_inbox_path(@invite)

    assert_redirected_to inbox_path
    assert @notification.reload.read?
    assert @invite.reload.accepted?
  end

  test "decline marks notification as read" do
    delete decline_inbox_path(@invite)

    assert_redirected_to inbox_path
    assert @notification.reload.read?
    assert @invite.reload.declined?
  end

  test "cannot accept another users invite" do
    other_invite = @organisation.organisation_invites.create!(email: "other@example.com")

    post accept_inbox_path(other_invite)
    assert_response :not_found
  end

  test "cannot decline another users invite" do
    other_invite = @organisation.organisation_invites.create!(email: "other@example.com")

    delete decline_inbox_path(other_invite)
    assert_response :not_found
  end

  test "requires authentication" do
    sign_out

    get inbox_path
    assert_redirected_to new_session_path
  end
end
