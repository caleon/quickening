require 'spec_helper'

describe CloneWars do
  subject(:mod) { described_class }

  describe CloneWars::VERSION do
    subject(:konstant) { CloneWars::VERSION }

    it { should be_a String }
    it { should =~ /^(\d+\.){2,}\d+$/ }
    it { should be > '0.0.0' }
  end

  describe CloneWars::Model do

  end
end
