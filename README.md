# Dbwrapper

This library manipulate various db(mysql2,sqlite,postgresql) in the same way.
you can use query with placeholder.
still more, multiple insert with hash array and csv backup  and csv restore.

## Installation

Add this line to your application's Gemfile:

    gem 'dbwrapper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dbwrapper

## Usage

``` ruby
#sqlite3
db=DBwrapper::DB.new(database: "test.sqlite3",adapter: "sqlite3")
#mysql2
db=DBwrapper::DB.new(database: "test",adapter: "mysql2")
#postgresql
db=DBwrapper::DB.new(database: "test",adapter: "postgresql")

#or merely
db=DBwrapper::DB.new(YAML::load(File.open('database.yml'))["development"])
#create table depends on db type this example is mysql2. because datetime is paticular mysql.
db.query("create table users (id integer,name text,created_at datetime)")
#insert
db.query('insert users (id,name,created_at) value(?,?,?)',1,"smith","2014-2014-06-26 00:00:00")
#last_id 1
@db.last_id
#select return array of hash [{"id"=>1, "name"=>"smith", "created_at"=>2014-06-26 00:00:00 +0900}]
db.query("select * from users")
#update
db.query("update users set name=? where id = ?","hay",1)
#affected_rows 1
db.affected_rows
#multiple insert with hash
db.xinsert("users",[{id: 2,name: "hello",created_at: "2014-2014-06-26 00:00:00"},{id: 3,name: "good",created_at: "2014-2014-06-27 00:00:00"}])
#backup_table tablename,path csv made in /var/backup/users.csv
db.backup_table("users","/var/backup")
#truncate
db.truncate("users")
#restore table
db.restore_table("users","/var/backup")
#close
db.close
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
