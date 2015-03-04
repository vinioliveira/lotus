require 'test_helper'
require 'lotus/environment'
require 'lotus/commands/db'
require  FIXTURES_ROOT.join('sql_adapter')


describe 'CLI db migration' do
  let(:app_name)       { nil }
  let(:config)         { FIXTURES_ROOT.join('migrations/config/environment') }
  let(:opts)           { Hash[environment: config] }
  let(:adapter_config) { Lotus::Model::Config::Adapter.new(type: :sql, uri: SQLITE_CONNECTION_STRING) }
  let(:sequel)         { Sequel.connect(adapter_config.uri) }
  let(:env)            { Lotus::Environment.new(opts) }
  let(:db_command)     { Lotus::Commands::DB.new(app_name, env) } 

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join("migrations")
    drop_tables
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil
  end
  
  describe 'db migrate' do
    before do
      db_command.migrate   
    end

    describe 'when app param is not specified' do
      it 'applies migrations located on db/migration' do
        sequel.table_exists?(:posts).must_equal true
        sequel.table_exists?(:comments).must_equal true
        sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal ['20150122124515_create_posts.rb', '20150222124516_create_comments.rb']
      end
    end
    
    describe 'when app param is specified' do
      let(:app_name) { "web" }

      it 'applies migrations located on apps/web/db/migration' do
        sequel.table_exists?(:tasks).must_equal true
        sequel.table_exists?(:todos).must_equal true
        sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal ['20150226211334_create_task.rb', '20150226211534_create_todo.rb']
      end
    end
  end

  describe 'db rollback' do
    before do
      db_command.migrate   
      db_command.rollback
    end

    describe 'when app param is not specified' do
      it 'rollback last migration located on db/migration' do
        sequel.table_exists?(:comments).must_equal false
        sequel.table_exists?(:posts).must_equal true
        sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal ['20150122124515_create_posts.rb']
      end

      describe "when pass step" do
        let(:opts) { Hash[environment: config, step: 2] }

        it 'rollback 2 last migrations located on db/migration' do
          sequel.table_exists?(:comments).must_equal false
          sequel.table_exists?(:posts).must_equal false
          sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal []
        end
      end
    end

    describe 'when app param is specified' do
      let(:app_name) { "web" }

      it 'rollback last migration located on apps/web/db/migration' do
        sequel.table_exists?(:todos).must_equal false
        sequel.table_exists?(:tasks).must_equal true
        sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal ['20150226211334_create_task.rb']
      end

      describe "when pass step" do
        let(:opts) { Hash[environment: config, step: 2] }

        it 'rollback 2 last migrations located on apps/web/db/migration' do
          sequel.table_exists?(:todos).must_equal false
          sequel.table_exists?(:tasks).must_equal false
          sequel.from(:schema_migrations).all.map { |row| row[:filename] }.must_equal []
        end
      end
    end
  end
  
  private

  def drop_tables
    sequel.drop_table(:schema_migrations) if sequel.table_exists?(:schema_migrations)
    sequel.drop_table(:posts) if sequel.table_exists?(:posts)
    sequel.drop_table(:comments) if sequel.table_exists?(:comments)
    sequel.drop_table(:tasks) if sequel.table_exists?(:tasks)
    sequel.drop_table(:todos) if sequel.table_exists?(:todos)
  end
end