require 'test_helper'

class ContributorsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get contributors_show_url
    assert_response :success
  end

end
