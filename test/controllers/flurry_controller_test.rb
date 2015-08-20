require 'test_helper'

class FlurryControllerTest < ActionController::TestCase
  test "should get metrics" do
    get :metrics
    assert_response :success
  end

end
