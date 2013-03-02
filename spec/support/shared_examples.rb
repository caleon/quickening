# encoding: utf-8

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
