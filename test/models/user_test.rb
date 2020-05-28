require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Example User", email: "user@example.com")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "  "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "  "
    assert_not @user.valid?
  end

  test "name should not be long" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "email should not be long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    invalid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
      invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert @user.valid?, "#{invalid_address.inspect} should be valid"
    end
  end
end
