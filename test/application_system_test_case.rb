require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: ENV["CI"].present? ? :headless_chrome : :chrome, screen_size: [ 1400, 1400 ]

  private

    def sign_in(user)
      visit new_session_path
      within "form" do
        fill_in "Email", with: user.email
        fill_in "Password", with: "password"
        click_on "Log in"
      end

      # Trigger Capybara's wait mechanism to avoid timing issues with logins
      find("h1", text: "Dashboard")
    end

    def sign_out
      find("#user-menu").click
      click_button "Logout"

      # Trigger Capybara's wait mechanism to avoid timing issues with logout
      find("h2", text: "Sign in to your account")
    end
end
