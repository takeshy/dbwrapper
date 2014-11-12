require_relative "dbwrapper/version"
require "logger"
require "csv"
require "fileutils"

module Dbwrapper
  class DB
    attr_reader :adapter,:client,:result
    def initialize(option)
      setting = {}.tap{|h| option.each{|k,v| h[k.to_sym] = v}}
      raise ArgumentError,"database is not specified! for sqlite3" unless setting[:database]
      @adapter = setting[:adapter]
      case @adapter
      when "sqlite3"
        require 'sqlite3'
        
        @client = SQLite3::Database.new(setting[:database])
        @client.execute("PRAGMA count_changes=ON;")
      when "mysql2"
        require 'mysql2-cs-bind'
        db_params = {:database => setting[:database]}
        if setting[:username]
          db_params[:username] = setting[:username]
        end
        if setting[:password]
          db_params[:password] = setting[:password]
        end
        if setting[:host]
          db_params[:host] = setting[:host]
        end
        if setting[:port]
          db_params[:port] = setting[:port]
        end
        @client = Mysql2::Client.new(db_params)
      when "postgresql"
        require 'pg'
        require 'pg_typecast'
        db_params = {:dbname => setting[:database]}
        if setting[:host]
          db_params[:host] = setting[:host]
        end
        if setting[:port]
          db_params[:port] = setting[:port]
        end
        if setting[:username]
          db_params[:user]  = setting[:username]
        end
        if setting[:password]
          db_params[:password] = setting[:password]
        end
        @client = PG::Connection.open(db_params)
      else
        raise ArgumentError,"adapter is not specified. sqlite3 or mysql2 or postgresql"
      end
      if setting[:log]
        @log = Logger.new(setting[:log])
      else
        @log = Logger.new(STDOUT)
      end
      if setting[:log_level]
        case setting[:log_level]
        when "fatal"
          @log.level = Logger::FATAL
        when "error"
          @log.level = Logger::ERROR
        when "warn"
          @log.level = Logger::WARN
        when "info"
          @log.level = Logger::INFO
        when "debug"
          @log.level = Logger::DEBUG
        end
      else
        @log.level = Logger::WARN
      end
    end

    def xinsert(table,args)
      raise ArgumentError,"args should  not be empty" if args.size == 0
      unless args.is_a?(Array)
        args = [args]
      end
      key_set = args.map{|a| a.keys.join(",")}.uniq
      if key_set.length != 1
        raise ArgumentError,"keys of records shuoud be same."
      end
      keys = args[0].keys
      raise ArgumentError,"key shuoud be at least one." if keys.length == 0
      case @adapter 
      when "sqlite3"
        args.each do |r|
          query("insert into #{table} (#{keys.join(",")}) values (#{r.values.map{|v| "'#{v}'"}.join(",")})")
        end
      when "postgresql","mysql2"
        vals = args.map(&:values).map{|r| "(" + r.map{|v| "'#{v}'"}.join(",") + ")"}
        sql = "insert into #{table} (#{keys.join(",")}) values #{vals.join(",")}"
        query(sql)
      end
    end

    def query(*args)
      @log.debug(args)
      case @adapter 
      when "sqlite3"
        m = args[0].match(/[sS][eE][lL][eE][cC][tT]\s+(.*)\s+[fF][rR][oO][mM]\s+(\S*)\s*/)
        if m
          rows = []
          if m[1] =~ /\*/
            fields = []
            @client.table_info(m[2]) do |row|
              fields << row["name"]
            end
          else
            fields = m[1].split(/,/).map{|d| d.gsub(/\s/,"")}
          end
          @client.execute(*args.map{|f| f.kind_of?(Date) || f.kind_of?(Time)  ? f.strftime("%Y-%m-%d %H:%M:%S.%N")[0..-4] : f}) do |rec|
            t = {}
            fields.each_with_index do |f,i|
              t[f] = rec[i]
            end
            rows.push(t)
          end
          rows
        else
          @result = @client.execute(*args.map{|f| f.kind_of?(Date) || f.kind_of?(Time)  ? f.strftime("%Y-%m-%d %H:%M:%S.%N")[0..-4] : f})
        end
      when "mysql2"
        @result = @client.xquery(*args)
        @result.to_a
      when "postgresql"
        cnt=0
        sql = args[0].gsub("?"){|w| "$" + (cnt+=1).to_s }
        m = args[0].match(/^[iI][nN][sS][eE][rR][tT]\s+/)
        if m
          sql += " returning *"
        end
        @result = @client.exec(sql,args[1 .. -1].map{|f| f.kind_of?(Date) || f.kind_of?(Time)  ? f.strftime("%Y-%m-%d %H:%M:%S.%N")[0..-4] : f}.flatten)
        if m
          @last_id = 0
          if @result.count > 0
            @last_id = @result[@result.count - 1]["id"].to_i
          end
          res = @result
        elsif args[0].match(/[sS][eE][lL][eE][cC][tT]\s+(.*)\s+[fF][rR][oO][mM]\s+(\S*)\s*/)
          res = @result.map{|r| {}.tap{|h| r.each{|k,v| h[k.to_s] = v}}}
        else
          res = @result
        end
        res.to_a
      end
    end

    def affected_rows
      case @adapter 
      when "sqlite3"
        if @result.count > 0
          @result[0][0]
        else
          0
        end
      when "mysql2"
        @client.affected_rows()
      when "postgresql"
        @result.result_status
      end
    end

    def last_id
      case @adapter 
      when "sqlite3"
        @client.last_insert_row_id
      when "mysql2"
        @client.last_id
      when "postgresql"
        @last_id
      end
    end

    def backup_table(t,path)
      FileUtils.mkdir_p(path)
      results = query("SELECT * FROM #{t}")
      CSV.open("#{path}/#{t}.csv", "wb") do |csv|
        csv << results.first.keys if results.first
        results.each do |result|
          csv << result.values.map{|r| if r == nil then 'null' elsif r.is_a?(Numeric) then r elsif r.is_a?(Time) then "'#{r.strftime("%Y-%m-%d %H:%M:%S.%N")[0..-4]}'" else "'#{r}'" end }
        end
      end
    end

    def restore_table(t,path)
      cnt = 0
      fields = nil
      CSV.foreach("#{path}/#{t}.csv") do |row|
        if cnt == 0
          fields = row.join(",")
        else
          query("insert into #{t} (#{fields}) values (#{row.join(",")})")
        end
        cnt+=1
      end
    end

    def truncate(t)
      case @adapter
      when "sqlite3"
        query("delete from #{t}")
      when "mysql2","postgresql"
        query("TRUNCATE TABLE #{t}")
      end
    end

    def close
      case @adapter
      when "postgresql"
        @client.finish
      else
        @client.close
      end
    end
  end
end
