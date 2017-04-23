require 'test_helper'

describe Grut::Guardian do
  User = Struct.new(:id)

  before do
    @user = User.new(42)
    @guardian = Grut::Guardian.new(@user, :manager)
  end

  describe 'permissions set and check' do
    it 'sets permissions with params' do
      refute @guardian.permitted?(:manage_store, id: 2)
      @guardian.permit(:manage_store, id: 2)
      assert @guardian.permitted?(:manage_store, id: 2)
    end
  end
end
