# encoding: utf-8

require 'spec_helper'

describe CloneWars do
  subject(:mod) { described_class }
  it { should be_a Module }

  describe CloneWars::VERSION do
    subject(:konstant) { CloneWars::VERSION }

    it { should be_a String }
    it { should =~ /^(\d+\.){2,}\d+$/ }
    it { should be > '0.0.0' }
  end

  describe CloneWars::Model do
    subject(:mod) { described_class }
    it { should be_a Module }
  end

  describe CloneWars::ORM::ActiveRecord do
    subject(:mod) { described_class }
    it { should be_a Module }
  end
end

describe 'Dummy App' do

  [Admin].each do |k|

    describe k do
      let(:klass) { k }
      subject { klass }

      its(:superclass) { should be ActiveRecord::Base }

      it { should respond_to :clone_wars }
      it { should_not include CloneWars::Model }
      it { should_not respond_to :duplicate_matchers }
      it { should_not respond_to :duplicate_matchers= }
      it { should_not respond_to :duplicate }
      it { should_not respond_to :find_duplicates_for }

      it 'does not make available the instance methods' do
        [:duplicates, :_duplicate_conditions].each do |method|
          klass.instance_methods.should_not include method
        end
      end

      describe 'Instance thereof' do
        subject(:user) { klass.new }

        it { should be_a klass }
        it { should be_a ActiveRecord::Base }
        it { should_not be_a CloneWars::Model }

        it { should_not respond_to :duplicate_matchers }
        it { should_not respond_to :duplicate_matchers= }
        it { should_not respond_to :duplicates }
      end
    end
  end

  context 'when clone_wars is called in the class' do
    let(:klass) { User }

    describe 'the enabled class' do
      subject { klass }

      it { should respond_to :clone_wars }
      it { should include CloneWars::Model }
      it { should respond_to :duplicate_matchers }
      it { should respond_to :duplicate_matchers= }
      it { should respond_to :duplicate }
      its(:duplicate) { should respond_to :originals }
      its(:duplicate) { should respond_to :copies }
      it { should respond_to :find_duplicates_for }

      it 'makes available the instance methods' do
        [:duplicates, :_duplicate_conditions].each do |method|
          klass.instance_methods.should include method
        end
      end

      its(:duplicate_matchers) { should eq [:first_name, :last_name] }

      describe 'Instance thereof' do
        subject(:user) { klass.new }

        it { should be_a klass }
        it { should be_a ActiveRecord::Base }
        it { should be_a CloneWars::Model }

        it { should respond_to :duplicate_matchers }
        it { should_not respond_to :duplicate_matchers= }
        it { should respond_to :duplicates }
      end
    end
  end

  let(:klass) { described_class }
  let(:null_relation) { klass.limit(0) }
  let(:mock_relation) { mock('Relation') }
  let(:returned) {}

  context 'when there are no duplicates' do
    before(:all) do
      User.delete_all
      @users = 10.times.map { FactoryGirl.create(:user) }
    end

    after(:all) { User.delete_all }

    describe User do
      let(:user) { @users[0] }
      subject { returned }

      describe '.duplicate' do
        include_context 'Proper .duplicate results'
        it_behaves_like 'Empty relational collections'

        describe '.originals' do
          include_context 'Proper .originals results'
          it_behaves_like 'Empty relational collections'
        end

        describe '.copies' do
          include_context 'Proper .copies results'
          it_behaves_like 'Empty relational collections'
        end
      end

      describe '.find_duplicates_for' do
        include_context 'Proper .find_duplicates_for results'
        it_behaves_like 'Empty relational collections'
      end

      describe '#duplicates' do
        include_context 'Proper #duplicates results'
        it_behaves_like 'Empty relational collections'
      end

      describe '#_duplicate_conditions' do
        include_context 'Proper #_duplicate_conditions results'
      end
    end
  end

  context 'when half are duplicates of the other half' do
    before(:all) do
      User.delete_all
      @users1 = 5.times.map { FactoryGirl.create(:user) }
      @users2 = @users1.map { |u| FactoryGirl.create(:user, first_name: u.first_name,
                                                             last_name: u.last_name) }
      @users = @users1 + @users2
    end
    after(:all) { User.delete_all }

    describe User do
      let(:user) { @users[0] }
      subject { returned }

      describe '.duplicate' do
        include_context 'Proper .duplicate results'
        it_behaves_like 'Empty relational collections'

        context 'but this time, with force: true' do
          let(:returned) { User.duplicate(force: true) }
          it_behaves_like 'Non-empty relational collections'
          it { should have(10).records }
        end

        describe '.originals' do
          include_context 'Proper .originals results'
          it_behaves_like 'Non-empty relational collections'
          it { should have(5).records }

          it 'is composed of records for which exactly one counterpart exists outside of this set' do
            returned.each do |record|
              dupe, * = dupes = record.duplicates
              expect(dupes).to have(1).record
              expect(dupe).not_to be_in returned
              expect(dupe).to be_in User.duplicate.copies
            end
          end
        end

        describe '.copies' do
          include_context 'Proper .copies results'
          it_behaves_like 'Non-empty relational collections'
          it { should have(5).records }

          it 'is composed of records for which exactly one counterpart exists outside of this set' do
            returned.each do |record|
              dupe, * = dupes = record.duplicates
              expect(dupes).to have(1).record
              expect(dupe).not_to be_in returned
              expect(dupe).to be_in User.duplicate.originals
            end
          end
        end
      end

      describe '.find_duplicates_for' do
        include_context 'Proper .find_duplicates_for results'
        it_behaves_like 'Non-empty relational collections'

        it { should have(1).record }
        it { should_not include user }
      end

      describe '#duplicates' do
        include_context 'Proper #duplicates results'
        it_behaves_like 'Non-empty relational collections'

        it { should have(1).record }
        it { should_not include user }
        its('first.duplicates') { should have(1).record }
        its('first.duplicates.first') { should == user }
      end

      describe '#_duplicate_conditions' do
        include_context 'Proper #_duplicate_conditions results'
      end
    end
  end

  context 'when there are 10 items, all a duplicate of one another' do
    before(:all) do
      User.delete_all
      @users = FactoryGirl.create_list(:user, 10, first_name: 'John',
                                                   last_name: 'Malkovich')
    end

    after(:all) { User.delete_all }

    describe User do
      let(:user) { @users[0] }
      subject { returned }

      describe '.duplicate' do
        include_context 'Proper .duplicate results'
        it_behaves_like 'Empty relational collections'

        context 'but this time, with force: true' do
          let(:returned) { User.duplicate(force: true) }
          it_behaves_like 'Non-empty relational collections'
          it { should have(10).records }
        end

        describe '.originals' do
          include_context 'Proper .originals results'
          it_behaves_like 'Non-empty relational collections'

          it 'is composed of one record for which exactly nine counterparts exist outside of this set' do
            returned.each do |record|
              dupe, * = dupes = record.duplicates
              expect(dupes).to have(9).records
              expect(dupe).not_to be_in returned
              expect(dupe).to be_in User.duplicate.copies
            end
          end
        end

        describe '.copies' do
          include_context 'Proper .copies results'
          it_behaves_like 'Non-empty relational collections'
          it { should have(9).records }

          it 'is composed of records for which exactly one counterpart exists outside of this set' do
            returned.each do |record|
              dupe, * = dupes = record.duplicates
              expect(dupes).to have(9).records
              expect(record).not_to be_in User.duplicate.originals
            end
          end
        end
      end

      describe '.find_duplicates_for' do
        include_context 'Proper .find_duplicates_for results'
        it_behaves_like 'Non-empty relational collections'

        it { should have(9).records }
        it { should_not include user }
      end

      describe '#duplicates' do
        include_context 'Proper #duplicates results'
        it_behaves_like 'Non-empty relational collections'

        it { should have(9).records }
        it { should_not include user }

        it 'contains records, each of which refer this record as one of its duplicates' do
          returned.each do |record|
            expect(record.duplicates).to have(9).records
            expect(record.duplicates).to include user
          end
        end
      end

      describe '#_duplicate_conditions' do
        include_context 'Proper #_duplicate_conditions results'
      end
    end
  end
end
