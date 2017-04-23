# Grut

Define user permissions in a Ruby project dynamically and store them in a database with Grut's help.
This allows to manage access to specific entities for concrete users on the fly through a user interface.

## Installation

Grut requires already installed any of the database adapters supported by [sequel](https://github.com/jeremyevans/sequel). `pg` and `mysql2` are the most popular ones.

Add this line to your application's Gemfile:

```ruby
gem 'grut'
```

Configure the database connection after that in some place of the project that have Grut installed. For example, it could be the following line in the `config/application.rb` of a Rails project:

```ruby
Grut::Config.instance.db_url = 'postgres://ka8725:@localhost/check_development'
```

## Usage

There are two main classes: `Grut::Guardian` and `Grut::Statement`. Use `Grut::Guardian` to manage control
access for entries and `Grut::Statement` to get information about defined permissions for a given user.
Look into the following code snippet that demonstrates their usage:

```ruby
user = Struct.new(:id).new(42)
store = Struct.new(:id).new(12)

guardian = Grut::Guardian.new(user, :admin)
statement = Grut::Statement.new(user)

guardian.permitted?(:manage_store, all: true) # => false
guardian.permitted?(:manage_store, id: store.id) # => false
statement.all #=> []

guardian.permit(:manage_store, all: true)
guardian.permitted?(:manage_store, all: true) # => true
guardian.permitted?(:manage_store, id: store.id) # => true
statement.all #=> [#<struct Grut::Statement::Entry role="admin", permission="manage_store", contract_key="all", contract_value="true">]

guardian.forbid(:manage_store, all: true)
guardian.permitted?(:manage_store, all: true) # => false
guardian.permitted?(:manage_store, id: store.id) # => false
statement.all #=> []

guardian.permit(:manage_store, id: 1)
guardian.permitted?(:manage_store, all: true) # => true
guardian.permitted?(:manage_store, id: store.id) # => true
statement.all #=> [#<struct Grut::Statement::Entry role="admin", permission="manage_store", contract_key="id", contract_value="1">]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Andrey Koleshko/grut. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

