# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookBag, type: :model do
  subject(:book_bag) { described_class.new }
  let(:client) { instance_double(Mysql2::Client) }
  let(:statement) { instance_double(Mysql2::Statement, execute: true) }
  let(:delete_statement) { instance_double(Mysql2::Statement, execute: true) }
  let(:insert_statement) { instance_double(Mysql2::Statement, execute: true) }
  let(:mysql_error_message) { "Duplicate entry '1' for key 'PRIMARY'" }
  let(:mysql_errno) { 1062 }

  around do |example|
    original_env = ENV.to_hash
    described_class.class_variable_set(:@@bagname, nil)
    described_class.class_variable_set(:@@bookmarkname, nil)
    example.run
  ensure
    ENV.replace(original_env)
    described_class.class_variable_set(:@@bagname, nil)
    described_class.class_variable_set(:@@bookmarkname, nil)
  end

  def mysql_error(message = mysql_error_message, errno = mysql_errno)
    error = Mysql2::Error.new(message)
    allow(error).to receive(:error).and_return(message)
    allow(error).to receive(:errno).and_return(errno)
    error
  end

  describe '#connect' do
    it 'raises when configuration is missing' do
      ENV.delete('BAG_MYSQL_HOST')
      allow(Dotenv).to receive(:load!)
      expect { book_bag.connect }.to raise_error('Missing BookBag configuration.')
      expect(Dotenv).to have_received(:load!)
    end

    it 'creates a client when configuration is present' do
      ENV['BAG_MYSQL_HOST']     = 'localhost'
      ENV['BAG_MYSQL_USER']     = 'user'
      ENV['BAG_MYSQL_PASSWORD'] = 'pass'
      ENV['BAG_MYSQL_DATABASE'] = 'db'
      allow(Mysql2::Client).to receive(:new).and_return(client)
      allow(client).to receive(:info).and_return({})
      expect(book_bag.connect).to eq(client)
    end

    it 'reuses an existing client' do
      allow(client).to receive(:info).and_return({})
      book_bag.instance_variable_set(:@client, client)
      expect(Mysql2::Client).not_to receive(:new)
      expect(book_bag.connect).to eq(client)
    end
  end

  describe '#set_bagname' do
    it 'sets the bagname for valid input' do
      book_bag.set_bagname('user@example.com')
      expect(book_bag.bagname).to eq('user@example.com')
      expect(book_bag.find_bookmark_name).to eq('user@example.com-bm')
    end

    it 'raises for invalid bagname' do
      expect { book_bag.set_bagname('bad name') }
        .to raise_error('BookBag initialize invalid bookbag name: (bad name)')
    end
  end

  describe '#find_bookmark_name' do
    it 'raises when bagname is not set' do
      expect { book_bag.find_bookmark_name }
        .to raise_error('Tring to set bookmark name before bagname.')
    end
  end

  describe '.enabled?' do
    it 'is false when bagname is unset' do
      expect(described_class.enabled?).to be(false)
    end

    it 'is true when bagname is set' do
      book_bag.set_bagname('user@example.com')
      expect(described_class.enabled?).to be(true)
      expect(book_bag.enabled?).to be(true)
    end
  end

  describe '#create_table' do
    it 'creates the table' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query)
      expect { book_bag.create_table }.not_to raise_error
    end

    it 'handles mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_raise(mysql_error)
      expect { book_bag.create_table }.not_to raise_error
    end
  end

  describe '#create_all' do
    before { book_bag.set_bagname('user@example.com') }

    it 'inserts each bibid' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_return(statement)
      expect(statement).to receive(:execute).with('user@example.com', '1')
      expect(statement).to receive(:execute).with('user@example.com', '2')
      book_bag.create_all(%w[1 2])
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_raise(mysql_error)
      expect { book_bag.create_all(['1']) }
        .to raise_error("BookBag create_all error: #{mysql_error_message}")
    end
  end

  describe '#delete_all' do
    before { book_bag.set_bagname('user@example.com') }

    it 'deletes each bibid' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_return(statement)
      expect(statement).to receive(:execute).with('user@example.com', '1')
      expect(statement).to receive(:execute).with('user@example.com', '2')
      book_bag.delete_all(%w[1 2])
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_raise(mysql_error)
      expect { book_bag.delete_all(['1']) }
        .to raise_error("BookBag delete_all error: #{mysql_error_message}")
    end
  end

  describe '#cache' do
    it 'delegates to create_all with a string id' do
      expect(book_bag).to receive(:create_all).with(['123'])
      book_bag.cache(123)
    end
  end

  describe '#uncache' do
    it 'delegates to delete_all with a string id' do
      expect(book_bag).to receive(:delete_all).with(['123'])
      book_bag.uncache(123)
    end
  end

  describe '#index' do
    before { book_bag.set_bagname('user@example.com') }

    it 'returns bibids as strings' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_return([{ 'bibid' => 1 }, { 'bibid' => 2 }])
      expect(book_bag.index).to eq(%w[1 2])
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_raise(mysql_error)
      expect { book_bag.index }.to raise_error("BookBag index error: #{mysql_error_message}")
    end
  end

  describe '#count' do
    before { book_bag.set_bagname('user@example.com') }

    it 'counts rows for the bagname' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_return([{ 'bibid' => 1 }, { 'bibid' => 2 }])
      expect(book_bag.count).to eq(2)
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_raise(mysql_error)
      expect { book_bag.count }.to raise_error("BookBag count error: #{mysql_error_message}")
    end
  end

  describe '#clear' do
    before { book_bag.set_bagname('user@example.com') }

    it 'clears rows and returns affected rows' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query)
      allow(client).to receive(:affected_rows).and_return(3)
      expect(book_bag.clear).to eq(3)
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_raise(mysql_error)
      expect { book_bag.clear }.to raise_error("BookBag clear error: #{mysql_error_message}")
    end
  end

  describe '#replace_bookmarks' do
    before { book_bag.set_bagname('user@example.com') }

    it 'replaces bookmark rows' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_return(delete_statement, insert_statement)
      expect(delete_statement).to receive(:execute).with('user@example.com-bm')
      expect(insert_statement).to receive(:execute).with('user@example.com-bm', '1')
      expect(insert_statement).to receive(:execute).with('user@example.com-bm', '2')
      book_bag.replace_bookmarks(%w[1 2])
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:prepare).and_raise(mysql_error)
      expect { book_bag.replace_bookmarks(['1']) }
        .to raise_error("BookBag replace_bookmarks error: #{mysql_error_message}")
    end
  end

  describe '#get_bookmarks' do
    before { book_bag.set_bagname('user@example.com') }

    it 'returns bookmark bibids as strings' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_return([{ 'bibid' => 1 }, { 'bibid' => 2 }])
      expect(book_bag.get_bookmarks).to eq(%w[1 2])
    end

    it 'raises when mysql errors' do
      allow(book_bag).to receive(:connect).and_return(client)
      allow(client).to receive(:query).and_raise(mysql_error)
      expect { book_bag.get_bookmarks }.to raise_error("BookBag get_bookmarks error: #{mysql_error_message}")
    end
  end

  describe '#export' do
    it 'invokes debug output' do
      book_bag.define_singleton_method(:current_user) { nil }
      book_bag.define_singleton_method(:current_or_guest_user) { nil }
      book_bag.define_singleton_method(:user_session) { nil }
      allow(book_bag).to receive(:debug)
      book_bag.export
      expect(book_bag).to have_received(:debug)
    end
  end
end