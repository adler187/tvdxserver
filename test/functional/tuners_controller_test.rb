require 'test_helper'

class TunersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tuners)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tuner" do
    assert_difference('Tuner.count') do
      post :create, :tuner => { }
    end

    assert_redirected_to tuner_path(assigns(:tuner))
  end

  test "should show tuner" do
    get :show, :id => tuners(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => tuners(:one).to_param
    assert_response :success
  end

  test "should update tuner" do
    put :update, :id => tuners(:one).to_param, :tuner => { }
    assert_redirected_to tuner_path(assigns(:tuner))
  end

  test "should destroy tuner" do
    assert_difference('Tuner.count', -1) do
      delete :destroy, :id => tuners(:one).to_param
    end

    assert_redirected_to tuners_path
  end
end
