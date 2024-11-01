require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @invitation = invitations(:one)
  end

  test "should get new" do
    get new_invitation_url
    assert_response :success
  end

  test "should create invitation for member" do
    assert_difference("Invitation.count") do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        post invitations_url, params: {
          invitation: {
            email: "new@example.com",
            role: "member"
          }
        }
      end
    end

    invitation = Invitation.order(created_at: :desc).first
    assert_equal "member", invitation.role
    assert_equal @user, invitation.inviter
    assert_equal "new@example.com", invitation.email
    assert_redirected_to settings_profile_path
    assert_equal I18n.t("invitations.create.success"), flash[:notice]
  end

  test "non-admin cannot create invitations" do
    sign_in users(:family_member)

    assert_no_difference("Invitation.count") do
      post invitations_url, params: {
        invitation: {
          email: "new@example.com",
          role: "admin"
        }
      }
    end

    assert_redirected_to settings_profile_path
    assert_equal I18n.t("invitations.create.failure"), flash[:alert]
  end

  test "admin can create admin invitation" do
    assert_difference("Invitation.count") do
      post invitations_url, params: {
        invitation: {
          email: "new@example.com",
          role: "admin"
        }
      }
    end

    invitation = Invitation.last
    assert_equal "admin", invitation.role
    assert_equal @user.family, invitation.family
    assert_equal @user, invitation.inviter
  end

  test "should handle invalid invitation creation" do
    assert_no_difference("Invitation.count") do
      post invitations_url, params: {
        invitation: {
          email: "",
          role: "member"
        }
      }
    end

    assert_redirected_to settings_profile_path
    assert_equal I18n.t("invitations.create.failure"), flash[:alert]
  end

  test "should accept invitation and redirect to registration" do
    get accept_invitation_url(@invitation.token)
    assert_redirected_to new_registration_path(invitation: @invitation.token)
  end

  test "should not accept invalid invitation token" do
    get accept_invitation_url("invalid-token")
    assert_response :not_found
  end
end
