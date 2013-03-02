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

  shared_examples 'Relational collections' do
    specify { expect { returned }.not_to raise_error }
    it { should be_a ActiveRecord::Relation }
  end

  shared_examples 'Empty relational collections' do
    include_examples 'Relational collections'
    it { should be_empty }
  end

  shared_examples 'Non-empty relational collections' do
    include_examples 'Relational collections'
    it { should_not be_empty }
  end

  shared_context 'Proper .duplicate results' do
    let(:returned) { User.duplicate }

    it 'only returns unique rows' do
      expect(returned.to_sql).to match(/ DISTINCT/)
    end

    it 'returns the results in an ascending order by id' do
      klass.stub_chain(:select, :uniq, :from, :joins, :where) { mock_relation }
      mock_relation.should_receive(:order).with(/id/) { null_relation }
      returned
    end

    it 'limits the result size to 0 by default' do
      klass.stub_chain(:select, :uniq, :from, :joins, :where, :order) { mock_relation }
      mock_relation.should_receive(:limit).with(0)
      returned
    end

    context 'with force: true' do
      subject(:returned) { klass.duplicate(force: true) }

      it 'only returns unique rows' do
        expect(returned.to_sql).to match(/ DISTINCT/)
      end

      it 'returns the results in an ascending order by id' do
        klass.stub_chain(:select, :uniq, :from, :joins, :where) { mock_relation }
        mock_relation.should_receive(:order).with(/id/) { null_relation }
        returned
      end

      it 'does not limit the result size to 0' do
        klass.stub_chain(:select, :uniq, :from, :joins, :where, :order) { mock_relation }
        mock_relation.should_receive(:limit).with(nil)
        returned
      end
    end
  end

  shared_examples 'Proper .originals results' do
    subject(:returned) { klass.duplicate.originals }

    it 'removes the default limit of 0' do
      ActiveRecord::Relation.any_instance.should_receive(:except).with(:limit) { null_relation }
      returned
    end

    it 'restricts the results to those which are the earliest created records' do
      ActiveRecord::Relation.any_instance.should_receive(:except).with(:limit) { mock_relation.as_null_object }
      mock_relation.stub(:where) do |arg|
        sql = arg
        expect(sql).to match(/HAVING.* MIN.*=/)
      end
      returned
    end

    it 'has no element for which even older duplicates can be found' do
      returned.each do |original|
        original.duplicates.each do |dupe|
          dupe.id.should be > original.id
        end
      end
    end
  end

  shared_context 'Proper .copies results' do
    subject(:returned) { klass.duplicate.copies }

    it 'removes the default limit of 0' do
      ActiveRecord::Relation.any_instance.should_receive(:except).with(:limit) { null_relation }
      returned
    end

    it 'restricts the results to those which are not the earliest created records' do
      ActiveRecord::Relation.any_instance.should_receive(:except).with(:limit) { mock_relation }
      mock_relation.stub(:where) do |arg|
        sql = arg
        expect(sql).to match(/ < /)
        expect(sql).not_to match(/ > /)
      end
      returned
    end

    it 'has no element for which a older duplicates canNOT be found' do
      expect(returned).to satisfy do |copies|
        (copies & klass.duplicate.originals).empty?
      end
    end
  end

  shared_context 'Proper .find_duplicates_for results' do
    subject(:returned) { klass.find_duplicates_for(user) }

    it 'utilizes the instance-level conditions helper' do
      user.should_receive(:_duplicate_conditions) { :helper_return }
      klass.should_receive(:where).with(:helper_return) { null_relation }
      returned
    end

    it 'makes sure not to return the original item among results' do
      klass.stub_chain(:where, :where) do |arg|
        sql = arg
        expect(sql).to match %r{ != }
      end
      returned
    end
  end

  shared_context 'Proper #duplicates results' do
    subject(:returned) { user.duplicates }

    it 'calls the proxy class method' do
      klass.should_receive(:find_duplicates_for).with(user)
      returned
    end
  end

  shared_context 'Proper #_duplicate_conditions results' do
    subject(:returned) { user._duplicate_conditions }

    it 'calls the class-level list of matcher attributes' do
      user.should_receive(:duplicate_matchers).and_call_original
      klass.should_receive(:duplicate_matchers) { [] }
      returned
    end

    it 'iterates through matcher attributes to construct a key-val composition' do
      Hash.should_receive(:[]).with(instance_of Array)
      returned
    end

    it 'returns a hash composed of keys from the class-level list' do
      expect(returned).to be_a Hash
      expect(returned.keys).to eq klass.duplicate_matchers
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
          let(:returned) { klass.duplicate.originals }
          include_context 'Proper .originals results'
          it_behaves_like 'Non-empty relational collections'

          it 'is composed of records for which exactly one counterpart exists outside of this set' do
            returned.each do |record|
              dupe, * = dupes = record.duplicates
              expect(dupes).to have(9).records
              expect(dupe).not_to be_in returned
              expect(dupe).to be_in User.duplicate.copies
            end
          end
        end
      end
    end
  end
end
