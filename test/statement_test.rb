require 'test_helper'

describe Grut::Statement do
  before do
    user = User.new(42)

    guardian = Grut::Guardian.new(user, :manager)
    guardian.permit(:manage_store, all: true)
    guardian.permit(:manage_product, id: 1)

    guardian = Grut::Guardian.new(user, :admin)
    guardian.permit(:purge_store, all: true)
    guardian.permit(:purge_product, id: 1)

    @statement = Grut::Statement.new(user)

    @entry1 = Grut::Statement::Entry.new('manager', 'manage_product', 'exclusive', {'id' => '1'})
    @entry2 = Grut::Statement::Entry.new('manager', 'manage_store', 'all', 'true')
    @entry3 = Grut::Statement::Entry.new('admin', 'purge_product', 'exclusive', {'id' => '1'})
    @entry4 = Grut::Statement::Entry.new('admin', 'purge_store', 'all', 'true')
  end

  after do
    TestsHelper.clean_db
  end

  describe '#all' do
    def all(*args)
      @statement.all(*args).sort_by(&:permission)
    end

    it 'returns all statement entries when no filters' do
      assert_equal [@entry1, @entry2, @entry3, @entry4], all
    end

    it 'allows to filter entries' do
      assert_equal [@entry3, @entry4], all(role: :admin)
      assert_equal [@entry4], all(role: :admin, permission: :purge_store)
      assert_equal [@entry3], all(role: :admin, permission: :purge_product)
      assert_equal [], all(role: :manager, permission: :purge_product)
      assert_equal [], all(role: :manager, permission: :purge_store)
      assert_equal [@entry2, @entry4], all(contract: {all: true})
    end
  end
end
