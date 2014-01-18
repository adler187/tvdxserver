require 'test_helper'

class TimeIntervalsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:time_intervals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create time_interval" do
    assert_difference('TimeInterval.count') do
      post :create, :time_interval => { }
    end

    assert_redirected_to time_interval_path(assigns(:time_interval))
  end

  test "should show time_interval" do
    get :show, :id => time_intervals(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => time_intervals(:one).to_param
    assert_response :success
  end

  test "should update time_interval" do
    put :update, :id => time_intervals(:one).to_param, :time_interval => { }
    assert_redirected_to time_interval_path(assigns(:time_interval))
  end

  test "should destroy time_interval" do
    assert_difference('TimeInterval.count', -1) do
      delete :destroy, :id => time_intervals(:one).to_param
    end

    assert_redirected_to time_intervals_path
  end
end
