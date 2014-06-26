require 'spec_helper'
require 'fileutils'
require 'date'

DummyDate = Time.utc(2014,6,26,0,0).utc
describe Dbwrapper do
  describe "sqlite3" do
    before(:all) do
      @db=DBwrapper::DB.new(database: "test.sqlite3",adapter: "sqlite3")
      @db.query("create table users (id integer,name text,created_at text)")
    end
    before do
      @db.xinsert("users",{id: 1,name: "good",created_at: DummyDate})
      @db.xinsert("users",[{id: 2,name: "hello",created_at: DummyDate},{id: 3,name: "good",created_at: DummyDate}])
      @last_id = @db.last_id
      @db.query("update users set name=? where id = ?","hay",1)
      @affected_rows = @db.affected_rows
      @db.backup_table("users",File.dirname(__FILE__) + "/table/sqlite3")
    end
    it 'select' do
      @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
    end
    it 'last_id' do
      @last_id.should == 3
    end
    it 'affected_rows' do
      @affected_rows == 1
    end
    after do
      @db.truncate("users")
    end
    after(:all) do
      @db.close
      FileUtils.rm("test.sqlite3")
    end
  end
  describe "psotgres" do
    before(:all) do
      @db=DBwrapper::DB.new(database: "test",adapter: "postgresql")
      @db.query("create table users (id int,name text,created_at timestamp)")
    end
    before do
      @db.xinsert("users",{id: 1,name: "good",created_at: DummyDate})
      @db.xinsert("users",[{id: 2,name: "hello",created_at: DummyDate},{id: 3,name: "good",created_at: DummyDate}])
      @last_id = @db.last_id
      @db.query("update users set name=? where id = ?","hay",1)
      @affected_rows = @db.affected_rows
      @db.backup_table("users",File.dirname(__FILE__) + "/table/postgresql")
    end
    it 'select' do
      @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
    end
    it 'last_id' do
      @last_id.should == 3
    end
    it 'affected_rows' do
      @affected_rows == 1
    end
    after do
      @db.truncate("users")
    end
    after(:all) do
      @db.query("drop table users")
      @db.close
    end
  end
  describe "mysql2" do
    before(:all) do
      @db=DBwrapper::DB.new(database: "test",adapter: "mysql2")
      @db.query("create table users (id int AUTO_INCREMENT,name text,created_at datetime,primary key(id))")
    end
    before do
      @db.xinsert("users",{id: 1,name: "good",created_at: DummyDate})
      @db.xinsert("users",[{id: 2,name: "hello",created_at: DummyDate},{id: 3,name: "good",created_at: DummyDate}])
      @last_id = @db.last_id
      @db.query("update users set name=? where id = ?","hay",1)
      @affected_rows = @db.affected_rows
      @db.backup_table("users",File.dirname(__FILE__) + "/table/mysql2")
    end
    it 'select' do
      @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
    end
    it 'last_id' do
      @last_id.should == 3
    end
    it 'affected_rows' do
      @affected_rows == 1
    end
    after do
      @db.truncate("users")
    end
    after(:all) do
      @db.query("drop table users")
      @db.close
    end
  end
  describe "restore sqlite3" do
    describe "postgresql" do
      before do
        @db=DBwrapper::DB.new(database: "test.sqlite3",adapter: "sqlite3")
        @db.query("create table users (id integer,name text,created_at text)")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/postgresql")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
        FileUtils.rm("test.sqlite3")
      end
    end
    describe "mysql2" do
      before do
        @db=DBwrapper::DB.new(database: "test.sqlite3",adapter: "sqlite3")
        @db.query("create table users (id integer,name text,created_at text)")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/mysql2")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
        FileUtils.rm("test.sqlite3")
      end
    end
  end
  describe "restore postgresql" do
    describe "sqlite3" do
      before do
        @db=DBwrapper::DB.new(database: "test",adapter: "postgresql")
        @db.query("create table users (id integer,name text,created_at timestamp)")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/sqlite3")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
      end
    end
    describe "mysql2" do
      before do
        @db=DBwrapper::DB.new(database: "test",adapter: "postgresql")
        @db.query("create table users (id integer,name text,created_at timestamp)")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/mysql2")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
      end
    end
  end
  describe "restore mysql2" do
    describe "sqlite3" do
      before do
        @db=DBwrapper::DB.new(database: "test",adapter: "mysql2")
        @db.query("create table users (id int AUTO_INCREMENT,name text,created_at datetime,primary key(id))")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/sqlite3")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
      end
    end
    describe "postgresql" do
      before do
        @db=DBwrapper::DB.new(database: "test",adapter: "mysql2")
        @db.query("create table users (id int AUTO_INCREMENT,name text,created_at datetime,primary key(id))")
        @db.restore_table("users",File.dirname(__FILE__) + "/table/postgresql")
      end
      it 'select' do
        @db.query("select id,name from users").should =~ [{"id" => 1,"name" => "hay"},{"id" => 2,"name" => "hello"},{"id" => 3,"name" => "good"}]
      end
      after do
        @db.query("drop table users")
        @db.close
      end
    end
  end
end
