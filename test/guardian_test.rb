require 'test_helper'

describe Grut::Guardian do
  before do
    @user = User.new(42)
    @guardian = Grut::Guardian.new(@user, :manager)
    @statement = Grut::Statement.new(@user)
  end

  after do
    TestsHelper.clean_db
  end

  describe '#permit' do
    it 'allows to set permissions for many roles' do
      @guardian.permit(:manage_store, id: 1)

      guardian2 = Grut::Guardian.new(@user, :admin)
      guardian2.permit(:manage_store, id: 2)

      assert guardian2.permitted?(:manage_store, id: 2)
      refute guardian2.permitted?(:manage_store, id: 1)

      assert @guardian.permitted?(:manage_store, id: 1)
      refute @guardian.permitted?(:manage_store, id: 2)
    end

    it "doesn't create duplicated records for overlapping contracts" do
      def entries_count
        @statement.all(role: :manager, permission: :manage_store).size
      end

      @guardian.permit(:manage_store, all: true)
      assert_equal 1, entries_count
      @guardian.permit(:manage_store, id: true)
      assert_equal 1, entries_count

      @guardian.forbid(:manage_store, all: true)
      assert_equal 0, entries_count

      @guardian.permit(:manage_store, id: 1)
      assert_equal 1, entries_count
      @guardian.permit(:manage_store, all: true)
      assert_equal 1, entries_count

      @guardian.forbid(:manage_store, all: true)
      assert_equal 0, entries_count
      @guardian.permit(:manage_store, all: true, id: 1)
      assert_equal 1, entries_count
    end

    it 'allows to set permission to manage all' do
      @guardian.permit(:manage, all: true)
      assert @guardian.permitted?(:manage_store, id: 1)
      assert @guardian.permitted?(:manage_store, all: true)
      assert @guardian.permitted?(:read_store, id: 1)
      assert @guardian.permitted?(:read_store, all: true)
      assert @guardian.permitted?(:delete_store, id: 1)
      assert @guardian.permitted?(:delete_store, all: true)

      assert_equal 1, @statement.all(role: :manager).size
      @guardian.permit(:manage_store, all: true)
      assert_equal 1, @statement.all(role: :manager).size
    end

    it 'sets permissions with params' do
      refute @guardian.permitted?(:manage_store, id: 2)
      @guardian.permit(:manage_store, id: 2)
      assert @guardian.permitted?(:manage_store, id: 2)
    end

    it 'sets permissions for all' do
      refute @guardian.permitted?(:manage_store, id: 2)
      @guardian.permit(:manage_store, all: true)
      assert @guardian.permitted?(:manage_store, id: 2)
    end

    it 'sets permissions for all' do
      refute @guardian.permitted?(:manage_store, all: true)
      @guardian.permit(:manage_store, all: true)
      assert @guardian.permitted?(:manage_store, all: true)
    end

    it 'unsets permissions with params' do
      @guardian.permit(:manage_store, id: 2)
      @guardian.forbid(:manage_store, id: 2)
      refute @guardian.permitted?(:manage_store, id: 2)
    end

    it 'unsets permissions for all' do
      @guardian.permit(:manage_store, id: 2)
      @guardian.forbid(:manage_store, all: true)
      refute @guardian.permitted?(:manage_store, id: 2)
    end

    it 'unsets permissions for all' do
      @guardian.permit(:manage_store, all: true)
      @guardian.forbid(:manage_store, all: true)
      refute @guardian.permitted?(:manage_store, id: 2)
    end
  end

  describe '#forbid' do
    it 'does nothing when nothing to forbit' do
      @guardian.forbid(:manage_store, all: true)
      refute @guardian.permitted?(:manage_store, id: 2)
      refute @guardian.permitted?(:manage_store, all: true)
    end
  end
end
